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

  /// Get all violations for a specific reported employee
  Future<List<Map<String, dynamic>>> getViolationsByEmployee(
    String reportedEmployeeId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('violation_report')
          .where('reportedEmployeeId', isEqualTo: reportedEmployeeId)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error fetching violations: $e');
      return [];
    }
  }

  /// Get reporter's email using reporterEmployeeId
  Future<String> getReporterEmail(String reporterEmployeeId) async {
    try {
      if (reporterEmployeeId.isEmpty || reporterEmployeeId == 'Not found') {
        return 'Unknown';
      }

      final querySnapshot = await _firestore
          .collection('users')
          .where('employeeId', isEqualTo: reporterEmployeeId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data()['email']?.toString() ??
            'Unknown';
      }
      return 'Unknown';
    } catch (e) {
      debugPrint('Error fetching reporter email: $e');
      return 'Unknown';
    }
  }

  /// Update violation status
  Future<void> updateViolationStatus(
    String violationId,
    String newStatus,
  ) async {
    try {
      await _firestore.collection('violation_report').doc(violationId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating status: $e');
      rethrow;
    }
  }

  List<Map<String, dynamic>> _filterReports(
    List<Map<String, dynamic>> reports,
  ) {
    if (_searchQuery.isEmpty) return reports;

    return reports.where((report) {
      final name = report['reportedName']?.toString().toLowerCase() ?? '';
      final position =
          report['reportedPosition']?.toString().toLowerCase() ?? '';
      final empId =
          report['reportedEmployeeId']?.toString().toLowerCase() ?? '';
      final location = report['location']?.toString().toLowerCase() ?? '';
      final violation = report['violation']?.toString().toLowerCase() ?? '';
      final status = report['status']?.toString().toLowerCase() ?? 'new';

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
                    final filteredReports = _filterReports(reports);
                    final paginatedReports = _getPaginatedReports(
                      filteredReports,
                    );

                    return Column(
                      children: [
                        Expanded(
                          child: isMobile
                              ? _buildMobileList(paginatedReports)
                              : _buildDesktopList(paginatedReports, isTablet),
                        ),
                        if (filteredReports.length > _itemsPerPage)
                          _buildPaginationControls(
                            filteredReports.length,
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
            color: Colors.grey.withAlpha(1),
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

  Widget _buildDesktopList(List<Map<String, dynamic>> reports, bool isTablet) {
    return ListView.builder(
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final report = reports[index];
        return _UserItemDesktop(
          name: report['reportedName']?.toString() ?? 'Unknown',
          employeeId: report['reportedEmployeeId']?.toString() ?? 'Unknown',
          reporterEmployeeId: report['reporterEmployeeId']?.toString() ?? '',
          position: report['reportedPosition']?.toString() ?? 'Unknown',
          location: report['location']?.toString() ?? 'N/A',
          status: report['status']?.toString() ?? 'New',
          isTablet: isTablet,
          reportData: report,
          getReporterEmail: () =>
              getReporterEmail(report['reporterEmployeeId']?.toString() ?? ''),
          fetchViolations: () => getViolationsByEmployee(
            report['reportedEmployeeId']?.toString() ?? '',
          ),
          updateStatus: updateViolationStatus,
        );
      },
    );
  }

  Widget _buildMobileList(List<Map<String, dynamic>> reports) {
    return ListView.builder(
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final report = reports[index];
        return _UserItemMobile(
          name: report['reportedName']?.toString() ?? 'Unknown',
          employeeId: report['reportedEmployeeId']?.toString() ?? 'Unknown',
          reporterEmployeeId: report['reporterEmployeeId']?.toString() ?? '',
          position: report['reportedPosition']?.toString() ?? 'Unknown',
          location: report['location']?.toString() ?? 'N/A',
          status: report['status']?.toString() ?? 'New',
          reportData: report,
          getReporterEmail: () =>
              getReporterEmail(report['reporterEmployeeId']?.toString() ?? ''),
          fetchViolations: () => getViolationsByEmployee(
            report['reportedEmployeeId']?.toString() ?? '',
          ),
          updateStatus: updateViolationStatus,
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
            color: Colors.grey.withAlpha(1),
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
    required this.reporterEmployeeId,
    required this.position,
    required this.location,
    required this.status,
    required this.isTablet,
    required this.reportData,
    required this.getReporterEmail,
    required this.fetchViolations,
    required this.updateStatus,
  });

  final String name;
  final String employeeId;
  final String reporterEmployeeId;
  final String position;
  final String location;
  final String status;
  final bool isTablet;
  final Map<String, dynamic> reportData;
  final Future<String> Function() getReporterEmail;
  final Future<List<Map<String, dynamic>>> Function() fetchViolations;
  final Future<void> Function(String, String) updateStatus;

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return Colors.purple;
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
              reportData: reportData,
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
      future: getReporterEmail(),
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
                color: Colors.grey.withAlpha(2),
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
    required this.reporterEmployeeId,
    required this.position,
    required this.location,
    required this.status,
    required this.reportData,
    required this.getReporterEmail,
    required this.fetchViolations,
    required this.updateStatus,
  });

  final String name;
  final String employeeId;
  final String reporterEmployeeId;
  final String position;
  final String location;
  final String status;
  final Map<String, dynamic> reportData;
  final Future<String> Function() getReporterEmail;
  final Future<List<Map<String, dynamic>>> Function() fetchViolations;
  final Future<void> Function(String, String) updateStatus;

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return Colors.purple;
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
              reportData: reportData,
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
      future: getReporterEmail(),
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
    required this.reportData,
    required this.updateStatus,
    required this.isTablet,
  });

  final String name;
  final String employeeId;
  final String status;
  final List<Map<String, dynamic>> violations;
  final Map<String, dynamic> reportData;
  final Future<void> Function(String violationId, String newStatus)
  updateStatus;
  final bool isTablet;

  @override
  State<_ViolationReportDialog> createState() => _ViolationReportDialogState();
}

class _ViolationReportDialogState extends State<_ViolationReportDialog> {
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.status;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return Colors.purple;
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
                    'Select new status:',
                    style: TextStyle(fontSize: widget.isTablet ? 13 : 14),
                  ),
                  const SizedBox(height: 16),
                  DropdownButton<String>(
                    value: selectedStatus,
                    isExpanded: true,
                    items: ['New', 'Under Investigation', 'Resolved', 'Closed']
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
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    await _updateStatus(selectedStatus);
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

  Future<void> _updateStatus(String newStatus) async {
    try {
      final violationId = widget.reportData['id']?.toString();
      if (violationId != null && violationId.isNotEmpty) {
        await widget.updateStatus(violationId, newStatus);
        setState(() {
          _currentStatus = newStatus;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Status updated to $newStatus'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                    'Total Reports',
                    widget.violations.length.toString(),
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
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: widget.violations.isEmpty
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
                      itemCount: widget.violations.length,
                      itemBuilder: (context, index) {
                        final violation = widget.violations[index];
                        final violationType =
                            violation['violation']?.toString() ??
                            'No description';
                        final location =
                            violation['location']?.toString() ?? 'N/A';
                        final time = violation['time']?.toString() ?? 'N/A';
                        final violationStatus =
                            violation['status']?.toString() ?? _currentStatus;
                        final submittedAt = violation['submittedAt'];
                        final reporterEmployeeId =
                            violation['reporterEmployeeId']?.toString() ??
                            'Unknown';

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
                                        maxLines: 2,
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
                                SizedBox(height: isMobile ? 8 : 12),
                                _buildViolationDetail(
                                  Icons.location_on,
                                  'Location',
                                  location,
                                  isMobile,
                                ),
                                _buildViolationDetail(
                                  Icons.access_time,
                                  'Time',
                                  time,
                                  isMobile,
                                ),
                                if (submittedAt != null)
                                  _buildViolationDetail(
                                    Icons.calendar_today,
                                    'Reported Date',
                                    _formatDate(submittedAt),
                                    isMobile,
                                  ),
                                _buildViolationDetail(
                                  Icons.person,
                                  'Reported By (EMP ID)',
                                  reporterEmployeeId,
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
      padding: EdgeInsets.only(bottom: isMobile ? 6 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: isMobile ? 14 : 16, color: Colors.grey[600]),
          SizedBox(width: isMobile ? 8 : 10),
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
      return '${date.toDate().month}/${date.toDate().day}/${date.toDate().year} ${date.toDate().hour}:${date.toDate().minute.toString().padLeft(2, '0')}';
    }
    return date.toString();
  }
}
