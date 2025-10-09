import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/app_user.dart';

class ViolationReportHistoryScreen extends StatefulWidget {
  const ViolationReportHistoryScreen({super.key, required this.user});

  final AppUser user;

  @override
  State<ViolationReportHistoryScreen> createState() =>
      _ViolationReportHistoryScreenState();
}

class _ViolationReportHistoryScreenState
    extends State<ViolationReportHistoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentPage = 0;
  final int _itemsPerPage = 10;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<List<Map<String, dynamic>>> getViolationReports() {
    return _firestore
        .collection('violation_report')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList(),
        );
  }

  Future<List<Map<String, dynamic>>> getViolationsByUser(
    String name,
    String position,
  ) async {
    final querySnapshot = await _firestore
        .collection('violation_report')
        .where('name', isEqualTo: name)
        .where('position', isEqualTo: position)
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  Future<String> getReportedUserEmail(String employeeDocId) async {
    try {
      final doc = await _firestore.collection('users').doc(employeeDocId).get();
      if (doc.exists) {
        return doc.data()?['email']?.toString() ?? 'Unknown';
      }
      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<void> updateViolationStatus(
    String violationId,
    String newStatus,
  ) async {
    await _firestore.collection('violation_report').doc(violationId).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  List<Map<String, dynamic>> _filterReports(
    List<Map<String, dynamic>> reports,
  ) {
    if (_searchQuery.isEmpty) return reports;

    return reports.where((report) {
      final name = report['name']?.toString().toLowerCase() ?? '';
      final position = report['position']?.toString().toLowerCase() ?? '';
      final empId = report['employeeId']?.toString().toLowerCase() ?? '';
      final location = report['location']?.toString().toLowerCase() ?? '';
      final violation = report['violation']?.toString().toLowerCase() ?? '';
      final status = report['status']?.toString().toLowerCase() ?? '';

      final query = _searchQuery.toLowerCase();
      return name.contains(query) ||
          position.contains(query) ||
          empId.contains(query) ||
          location.contains(query) ||
          violation.contains(query) ||
          status.contains(query);
    }).toList();
  }

  List<Map<String, dynamic>> _getPaginatedReports(
    List<Map<String, dynamic>> reports,
  ) {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return reports.length > startIndex
        ? reports.sublist(
            startIndex,
            endIndex > reports.length ? reports.length : endIndex,
          )
        : [];
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchSection(isMobile),
              SizedBox(height: isMobile ? 12 : 16),
              if (!isMobile) _buildTableHeader(isTablet),
              if (!isMobile) const SizedBox(height: 8),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: getViolationReports(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text('No violation reports found'),
                      );
                    }

                    final reports = snapshot.data!;
                    final filteredReports = reports
                        .where(
                          (r) =>
                              r['position'] == 'Driver' ||
                              r['position'] == 'Conductor' ||
                              r['position'] == 'Inspector',
                        )
                        .toList();

                    final users = {
                      for (var report in filteredReports)
                        '${report['name']}-${report['position']}': report,
                    }.values.toList();

                    final filteredUsers = _filterReports(users);
                    final paginatedUsers = _getPaginatedReports(filteredUsers);

                    return Column(
                      children: [
                        Expanded(
                          child: isMobile
                              ? _buildMobileList(paginatedUsers)
                              : _buildDesktopList(paginatedUsers, isTablet),
                        ),
                        if (filteredUsers.length > _itemsPerPage)
                          _buildPaginationControls(
                            filteredUsers.length,
                            isMobile,
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: isMobile
                    ? 'Search...'
                    : 'Search by name, position, EMP ID, location...',
                hintStyle: TextStyle(fontSize: isMobile ? 12 : 14),
                prefixIcon: Icon(
                  Icons.search,
                  color: const Color(0xFF0D2364),
                  size: isMobile ? 20 : 24,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: EdgeInsets.symmetric(
                  vertical: isMobile ? 8 : 12,
                  horizontal: isMobile ? 8 : 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _currentPage = 0;
                });
              },
            ),
          ),
          SizedBox(width: isMobile ? 6 : 8),
          Container(
            padding: EdgeInsets.all(isMobile ? 10 : 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0D2364),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.filter_list,
              color: Colors.white,
              size: isMobile ? 20 : 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 12 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2364),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'User / EMP ID',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: isTablet ? 13 : 14,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'Position',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: isTablet ? 13 : 14,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'Location',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: isTablet ? 13 : 14,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'Status',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: isTablet ? 13 : 14,
              ),
            ),
          ),
          const Expanded(flex: 1, child: SizedBox()),
        ],
      ),
    );
  }

  Widget _buildDesktopList(List<Map<String, dynamic>> users, bool isTablet) {
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final userData = users[index];
        return _UserItemDesktop(
          name: userData['name']?.toString() ?? 'Unknown',
          employeeId: userData['employeeId']?.toString() ?? 'Unknown',
          position: userData['position']?.toString() ?? 'Unknown',
          location: userData['location']?.toString() ?? 'N/A',
          status: userData['status']?.toString() ?? 'New',
          isTablet: isTablet,
          fetchViolations: () => getViolationsByUser(
            userData['name']?.toString() ?? '',
            userData['position']?.toString() ?? '',
          ),
          getEmail: () =>
              getReportedUserEmail(userData['employeeId']?.toString() ?? ''),
          updateStatus: (violationId, newStatus) =>
              updateViolationStatus(violationId, newStatus),
        );
      },
    );
  }

  Widget _buildMobileList(List<Map<String, dynamic>> users) {
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final userData = users[index];
        return _UserItemMobile(
          name: userData['name']?.toString() ?? 'Unknown',
          employeeId: userData['employeeId']?.toString() ?? 'Unknown',
          position: userData['position']?.toString() ?? 'Unknown',
          location: userData['location']?.toString() ?? 'N/A',
          status: userData['status']?.toString() ?? 'New',
          fetchViolations: () => getViolationsByUser(
            userData['name']?.toString() ?? '',
            userData['position']?.toString() ?? '',
          ),
          getEmail: () =>
              getReportedUserEmail(userData['employeeId']?.toString() ?? ''),
          updateStatus: (violationId, newStatus) =>
              updateViolationStatus(violationId, newStatus),
        );
      },
    );
  }

  Widget _buildPaginationControls(int totalItems, bool isMobile) {
    final totalPages = (totalItems / _itemsPerPage).ceil();

    return Container(
      margin: EdgeInsets.only(top: isMobile ? 8 : 16),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios, size: isMobile ? 16 : 20),
            onPressed: _currentPage > 0
                ? () {
                    setState(() {
                      _currentPage--;
                    });
                  }
                : null,
          ),
          Text(
            'Page ${_currentPage + 1} of $totalPages',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 12 : 14,
            ),
          ),
          IconButton(
            icon: Icon(Icons.arrow_forward_ios, size: isMobile ? 16 : 20),
            onPressed: _currentPage < totalPages - 1
                ? () {
                    setState(() {
                      _currentPage++;
                    });
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

// Desktop/Tablet Item Widget
class _UserItemDesktop extends StatelessWidget {
  const _UserItemDesktop({
    required this.name,
    required this.employeeId,
    required this.position,
    required this.location,
    required this.status,
    required this.isTablet,
    required this.fetchViolations,
    required this.getEmail,
    required this.updateStatus,
  });

  final String name;
  final String employeeId;
  final String position;
  final String location;
  final String status;
  final bool isTablet;
  final Future<List<Map<String, dynamic>>> Function() fetchViolations;
  final Future<String> Function() getEmail;
  final Future<void> Function(String violationId, String newStatus)
  updateStatus;

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.orange;
      case 'under investigation':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  void _showViolationReport(BuildContext context) async {
    try {
      final violations = await fetchViolations();

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return _ViolationReportDialog(
              name: name,
              employeeId: employeeId,
              status: status,
              violations: violations,
              updateStatus: updateStatus,
              isTablet: isTablet,
            );
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading violation details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getEmail(),
      builder: (context, snapshot) {
        final reporterEmail = snapshot.data ?? 'Loading...';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.all(isTablet ? 12 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isTablet ? 13 : 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'EMP ID: $employeeId',
                      style: TextStyle(
                        fontSize: isTablet ? 11 : 12,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Reported By: $reporterEmail',
                      style: TextStyle(
                        fontSize: isTablet ? 10 : 11,
                        color: Colors.grey[500],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  position,
                  style: TextStyle(fontSize: isTablet ? 13 : 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  location,
                  style: TextStyle(fontSize: isTablet ? 13 : 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isTablet ? 11 : 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: IconButton(
                  icon: Icon(
                    Icons.more_vert,
                    size: isTablet ? 18 : 20,
                    color: const Color(0xFF0D2364),
                  ),
                  onPressed: () => _showViolationReport(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Mobile Item Widget
class _UserItemMobile extends StatelessWidget {
  const _UserItemMobile({
    required this.name,
    required this.employeeId,
    required this.position,
    required this.location,
    required this.status,
    required this.fetchViolations,
    required this.getEmail,
    required this.updateStatus,
  });

  final String name;
  final String employeeId;
  final String position;
  final String location;
  final String status;
  final Future<List<Map<String, dynamic>>> Function() fetchViolations;
  final Future<String> Function() getEmail;
  final Future<void> Function(String violationId, String newStatus)
  updateStatus;

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.orange;
      case 'under investigation':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  void _showViolationReport(BuildContext context) async {
    try {
      final violations = await fetchViolations();

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return _ViolationReportDialog(
              name: name,
              employeeId: employeeId,
              status: status,
              violations: violations,
              updateStatus: updateStatus,
              isTablet: false,
            );
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading violation details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getEmail(),
      builder: (context, snapshot) {
        final reporterEmail = snapshot.data ?? 'Loading...';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: InkWell(
            onTap: () => _showViolationReport(context),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF0D2364),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.badge, 'EMP ID', employeeId),
                  const SizedBox(height: 4),
                  _buildInfoRow(Icons.work, 'Position', position),
                  const SizedBox(height: 4),
                  _buildInfoRow(Icons.location_on, 'Location', location),
                  const SizedBox(height: 4),
                  _buildInfoRow(Icons.person, 'Reported By', reporterEmail),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// Violation Report Dialog
class _ViolationReportDialog extends StatefulWidget {
  const _ViolationReportDialog({
    required this.name,
    required this.employeeId,
    required this.status,
    required this.violations,
    required this.updateStatus,
    required this.isTablet,
  });

  final String name;
  final String employeeId;
  final String status;
  final List<Map<String, dynamic>> violations;
  final Future<void> Function(String violationId, String newStatus)
  updateStatus;
  final bool isTablet;

  @override
  State<_ViolationReportDialog> createState() => _ViolationReportDialogState();
}

class _ViolationReportDialogState extends State<_ViolationReportDialog> {
  late List<Map<String, dynamic>> _violations;
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _violations = List.from(widget.violations);
    _currentStatus = widget.status;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.orange;
      case 'under investigation':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  void _showEditStatusDialog(BuildContext context) {
    String selectedStatus = _currentStatus;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Edit Status',
                style: TextStyle(
                  color: const Color(0xFF0D2364),
                  fontWeight: FontWeight.bold,
                  fontSize: widget.isTablet ? 16 : 18,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Select new status for all violations:',
                    style: TextStyle(fontSize: widget.isTablet ? 13 : 14),
                  ),
                  const SizedBox(height: 16),
                  DropdownButton<String>(
                    value: selectedStatus,
                    isExpanded: true,
                    items: ['Open', 'Under Investigation', 'Resolved', 'Closed']
                        .map((String status) {
                          return DropdownMenuItem<String>(
                            value: status,
                            child: Text(status),
                          );
                        })
                        .toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedStatus = newValue!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _currentStatus = selectedStatus;
                      for (final violation in _violations) {
                        violation['status'] = selectedStatus;
                      }
                    });
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Status changed to $selectedStatus'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D2364),
                  ),
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSaveConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'Save Changes',
            style: TextStyle(
              color: const Color(0xFF0D2364),
              fontWeight: FontWeight.bold,
              fontSize: widget.isTablet ? 16 : 18,
            ),
          ),
          content: Text(
            'Are you sure you want to save all status changes?',
            style: TextStyle(fontSize: widget.isTablet ? 13 : 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                try {
                  for (final violation in _violations) {
                    final violationId = violation['id']?.toString();
                    final newStatus =
                        violation['status']?.toString() ?? _currentStatus;

                    if (violationId != null && violationId.isNotEmpty) {
                      await widget.updateStatus(violationId, newStatus);
                    }
                  }

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All status changes saved successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error saving changes: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D2364),
              ),
              child: const Text('SAVE'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryItem(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: widget.isTablet ? 11 : 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: widget.isTablet ? 14 : 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0D2364),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Dialog(
      insetPadding: EdgeInsets.all(isMobile ? 16 : 20),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isMobile ? double.infinity : 800,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'VIOLATION REPORT - ${widget.name}',
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0D2364),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: isMobile ? 20 : 24),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem('EMP ID', widget.employeeId),
                  _buildSummaryItem(
                    'Total Violations',
                    _violations.length.toString(),
                  ),
                  _buildSummaryItem('Current Status', _currentStatus),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Violation Details',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0D2364),
                  ),
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(Icons.edit, size: isMobile ? 16 : 18),
                      label: Text(
                        'Edit Status',
                        style: TextStyle(fontSize: isMobile ? 12 : 14),
                      ),
                      onPressed: () => _showEditStatusDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D2364),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 12 : 16,
                          vertical: isMobile ? 8 : 10,
                        ),
                      ),
                    ),
                    SizedBox(width: isMobile ? 8 : 12),
                    ElevatedButton.icon(
                      icon: Icon(Icons.save, size: isMobile ? 16 : 18),
                      label: Text(
                        'Save',
                        style: TextStyle(fontSize: isMobile ? 12 : 14),
                      ),
                      onPressed: () => _showSaveConfirmationDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 12 : 16,
                          vertical: isMobile ? 8 : 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _violations.isEmpty
                  ? Center(
                      child: Text(
                        'No violation details found',
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _violations.length,
                      itemBuilder: (context, index) {
                        final violation = _violations[index];
                        final violationType =
                            violation['violation']?.toString() ??
                            'No violation description';
                        final violationStatus =
                            violation['status']?.toString() ?? _currentStatus;
                        final violationLocation = violation['location']
                            ?.toString();
                        final violationDate = violation['date'];
                        final violationDescription = violation['description']
                            ?.toString();
                        final reportedBy = violation['reportedBy']?.toString();
                        final evidence = violation['evidence']?.toString();

                        return Card(
                          margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
                          elevation: 1,
                          child: Padding(
                            padding: EdgeInsets.all(isMobile ? 12 : 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        violationType,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: isMobile ? 14 : 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(violationStatus),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        violationStatus,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: isMobile ? 10 : 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: isMobile ? 6 : 8),
                                if (violationLocation != null &&
                                    violationLocation.isNotEmpty)
                                  _buildViolationDetail(
                                    Icons.location_on,
                                    'Location',
                                    violationLocation,
                                    isMobile,
                                  ),
                                if (violationDate != null)
                                  _buildViolationDetail(
                                    Icons.calendar_today,
                                    'Date',
                                    _formatDate(violationDate),
                                    isMobile,
                                  ),
                                if (violationDescription != null &&
                                    violationDescription.isNotEmpty)
                                  _buildViolationDetail(
                                    Icons.description,
                                    'Description',
                                    violationDescription,
                                    isMobile,
                                  ),
                                if (reportedBy != null && reportedBy.isNotEmpty)
                                  _buildViolationDetail(
                                    Icons.person,
                                    'Reported By',
                                    reportedBy,
                                    isMobile,
                                  ),
                                if (evidence != null && evidence.isNotEmpty)
                                  _buildViolationDetail(
                                    Icons.attachment,
                                    'Evidence',
                                    evidence,
                                    isMobile,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViolationDetail(
    IconData icon,
    String label,
    String value,
    bool isMobile,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 4 : 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: isMobile ? 14 : 16, color: Colors.grey[600]),
          SizedBox(width: isMobile ? 6 : 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label:',
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    color: Colors.black87,
                  ),
                  softWrap: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown';
    if (date is Timestamp) {
      return '${date.toDate().month}/${date.toDate().day}/${date.toDate().year}';
    }
    return date.toString();
  }
}
