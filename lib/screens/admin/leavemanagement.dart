import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LeaveManagementScreen extends StatefulWidget {
  const LeaveManagementScreen({super.key});

  @override
  State<LeaveManagementScreen> createState() => _LeaveManagementScreenState();
}

class _LeaveManagementScreenState extends State<LeaveManagementScreen> {
  List<Map<String, dynamic>> _leaveRequests = [];
  List<Map<String, dynamic>> _filteredRequests = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = 'All';
  int _currentPage = 0;
  final int _itemsPerPage = 10;

  final List<String> _statusOptions = [
    'All',
    'Pending',
    'Approved',
    'Rejected',
  ];

  @override
  void initState() {
    super.initState();
    _loadLeaveRequests();
    _startAutoCleanup(); // Add auto-cleanup on init
  }

  /// ADDED: Auto-cleanup that runs periodically
  void _startAutoCleanup() {
    // Run cleanup immediately
    _cleanupOldLeaveApplications();

    // Schedule periodic cleanup (every hour)
    Future.delayed(const Duration(hours: 1), () {
      if (mounted) {
        _cleanupOldLeaveApplications();
        _startAutoCleanup(); // Reschedule
      }
    });
  }

  /// ADDED: Clean up old rejected and completed leave applications
  Future<void> _cleanupOldLeaveApplications() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final now = DateTime.now();
      final usersSnapshot = await firestore.collection('users').get();

      for (var userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        final leaveSnapshot = await firestore
            .collection('users')
            .doc(userId)
            .collection('leave_application')
            .get();

        for (var leaveDoc in leaveSnapshot.docs) {
          final data = leaveDoc.data();
          final status = data['status'] ?? '';
          final rejectedAt = (data['rejectedAt'] as Timestamp?)?.toDate();
          final endDate = (data['endDate'] as Timestamp?)?.toDate();

          bool shouldDelete = false;

          // Delete rejected applications after 5 days
          if (status == 'Rejected' && rejectedAt != null) {
            final daysSinceRejection = now.difference(rejectedAt).inDays;
            if (daysSinceRejection >= 5) {
              shouldDelete = true;
              debugPrint('Deleting rejected leave (${leaveDoc.id}) - $daysSinceRejection days old');
            }
          }

          // Delete completed leave applications (end date has passed)
          if (endDate != null && endDate.isBefore(now)) {
            shouldDelete = true;
            debugPrint('Deleting completed leave (${leaveDoc.id}) - ended on $endDate');
          }

          if (shouldDelete) {
            await firestore
                .collection('users')
                .doc(userId)
                .collection('leave_application')
                .doc(leaveDoc.id)
                .delete();
          }
        }
      }

      debugPrint('Cleanup completed at ${DateTime.now()}');
    } catch (e) {
      debugPrint('Error during cleanup: $e');
    }
  }

  /// Load all leave applications from Firestore
  Future<void> _loadLeaveRequests() async {
    try {
      // Run cleanup before loading
      await _cleanupOldLeaveApplications();

      final data = await _fetchAllLeaveApplications();
      if (mounted) {
        setState(() {
          _leaveRequests = data;
          _filteredRequests = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading leave applications: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Get all leave applications from all users
  Future<List<Map<String, dynamic>>> _fetchAllLeaveApplications() async {
    final firestore = FirebaseFirestore.instance;
    final List<Map<String, dynamic>> allLeaves = [];
    final now = DateTime.now();

    final usersSnapshot = await firestore.collection('users').get();
    for (var userDoc in usersSnapshot.docs) {
      final userId = userDoc.id;
      final userData = userDoc.data();

      final leaveSnapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('leave_application')
          .orderBy('submittedAt', descending: true)
          .get();

      for (var leaveDoc in leaveSnapshot.docs) {
        final data = leaveDoc.data();
        final status = data['status'] ?? '';
        final rejectedAt = (data['rejectedAt'] as Timestamp?)?.toDate();
        final endDate = (data['endDate'] as Timestamp?)?.toDate();

        // Skip applications that should be deleted
        bool shouldSkip = false;

        // Skip rejected applications older than 5 days
        if (status == 'Rejected' && rejectedAt != null) {
          final daysSinceRejection = now.difference(rejectedAt).inDays;
          if (daysSinceRejection >= 5) {
            shouldSkip = true;
          }
        }

        // Skip completed leave applications
        if (endDate != null && endDate.isBefore(now)) {
          shouldSkip = true;
        }

        if (!shouldSkip) {
          allLeaves.add({
            ...data,
            'userId': userId,
            'leaveId': leaveDoc.id,
            'name': userData['name'] ?? 'Unknown',
            'email': userData['email'] ?? 'N/A',
            'role': userData['role'] ?? '',
            'employeeId': userData['employeeId'] ?? 'N/A',
          });
        }
      }
    }

    return allLeaves;
  }

  /// Filter and search leave requests
  void _filterRequests() {
    List<Map<String, dynamic>> filtered = _leaveRequests;

    // Apply status filter
    if (_statusFilter != 'All') {
      filtered = filtered
          .where((request) => request['status'] == _statusFilter)
          .toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((request) {
        final name = request['name']?.toString().toLowerCase() ?? '';
        final role = request['role']?.toString().toLowerCase() ?? '';
        final employeeId =
            request['employeeId']?.toString().toLowerCase() ?? '';
        final leaveType = request['leaveType']?.toString().toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();

        return name.contains(query) ||
            role.contains(query) ||
            employeeId.contains(query) ||
            leaveType.contains(query);
      }).toList();
    }

    setState(() {
      _filteredRequests = filtered;
      _currentPage = 0;
    });
  }

  /// Get paginated requests
  List<Map<String, dynamic>> get _paginatedRequests {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return _filteredRequests.length > startIndex
        ? _filteredRequests.sublist(
      startIndex,
      endIndex > _filteredRequests.length
          ? _filteredRequests.length
          : endIndex,
    )
        : [];
  }

  /// Get total pages
  int get _totalPages => (_filteredRequests.length / _itemsPerPage).ceil();

  /// Approve request
  Future<void> _approveRequest(int index) async {
    final req = _paginatedRequests[index];
    await FirebaseFirestore.instance
        .collection('users')
        .doc(req['userId'])
        .collection('leave_application')
        .doc(req['leaveId'])
        .update({
      'status': 'Approved',
      'approvedAt': FieldValue.serverTimestamp(), // ADDED: Track approval time
    });

    if (mounted) {
      await _loadLeaveRequests();
      _filterRequests();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${req['name']}'s leave request has been approved"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Reject request - FIXED: Now properly sets rejectedAt timestamp
  Future<void> _rejectRequest(int index) async {
    final TextEditingController reasonController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Decline Leave Request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Please provide a reason for declining this leave request:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for decline',
                  border: OutlineInputBorder(),
                  hintText: 'Enter the reason for declining this request...',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () =>
                  Navigator.pop(context, reasonController.text.trim()),
              child: const Text('Decline Request'),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      final req = _paginatedRequests[index];

      // FIXED: Properly set rejectedAt with server timestamp
      await FirebaseFirestore.instance
          .collection('users')
          .doc(req['userId'])
          .collection('leave_application')
          .doc(req['leaveId'])
          .update({
        'status': 'Rejected',
        'rejectionReason': result,
        'rejectedAt': FieldValue.serverTimestamp(), // This will set the current server time
      });

      if (mounted) {
        await _loadLeaveRequests();
        _filterRequests();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${req['name']}'s leave request has been declined. It will be automatically deleted after 5 days."),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Show action menu (3 dots)
  void _showActionMenu(BuildContext context, int index) {
    final request = _paginatedRequests[index];
    final status = request['status'] ?? 'Pending';

    if (status != 'Pending') return;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Approve Leave Request'),
                onTap: () {
                  Navigator.pop(context);
                  _approveRequest(index);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: const Text('Decline Leave Request'),
                onTap: () {
                  Navigator.pop(context);
                  _rejectRequest(index);
                },
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildMainContent(),
    );
  }

  /// Main content with search, filter, and list
  Widget _buildMainContent() {
    return Column(
      children: [
        _buildSearchFilterSection(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '${_filteredRequests.length} leave request${_filteredRequests.length != 1 ? 's' : ''} found',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _filteredRequests.isEmpty
              ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No leave requests found',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          )
              : _buildResponsiveLayout(),
        ),
        if (_totalPages > 1) _buildPagination(),
      ],
    );
  }

  /// Search and Filter Section
  Widget _buildSearchFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        children: [
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _filterRequests();
            },
            decoration: InputDecoration(
              hintText: 'Search by name, role, employee ID...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _statusOptions.length,
              itemBuilder: (context, index) {
                final status = _statusOptions[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(status),
                    selected: _statusFilter == status,
                    onSelected: (selected) {
                      setState(() {
                        _statusFilter = status;
                      });
                      _filterRequests();
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Pagination Controls
  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 0
                ? () {
              setState(() {
                _currentPage--;
              });
            }
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            'Page ${_currentPage + 1} of $_totalPages',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          IconButton(
            onPressed: _currentPage < _totalPages - 1
                ? () {
              setState(() {
                _currentPage++;
              });
            }
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  /// Responsive layout based on screen size
  Widget _buildResponsiveLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        if (screenWidth < 600) {
          return _buildMobileNotificationView();
        } else if (screenWidth < 900) {
          return _buildTabletView(columns: 2);
        } else if (screenWidth < 1200) {
          return _buildTabletView(columns: 3);
        } else {
          return _buildDesktopView();
        }
      },
    );
  }

  /// Mobile View - Notification Style
  Widget _buildMobileNotificationView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _paginatedRequests.length,
      itemBuilder: (context, index) =>
          _buildNotificationTile(_paginatedRequests[index], index),
    );
  }

  /// Tablet View
  Widget _buildTabletView({required int columns}) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3,
      ),
      itemCount: _paginatedRequests.length,
      itemBuilder: (context, index) =>
          _buildLeaveTile(_paginatedRequests[index], index),
    );
  }

  /// Desktop View
  Widget _buildDesktopView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3,
      ),
      itemCount: _paginatedRequests.length,
      itemBuilder: (context, index) =>
          _buildLeaveTile(_paginatedRequests[index], index),
    );
  }

  /// Mobile Notification Style Tile
  Widget _buildNotificationTile(Map<String, dynamic> request, int index) {
    final status = request['status'] ?? 'Pending';
    final leaveType = request['leaveType'] ?? '';
    final reason = request['reason'] ?? 'No reason provided';
    final days = _calculateDays(request['startDate'], request['endDate']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: _getStatusBorderColor(status), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '$days days',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    if (status == 'Pending') ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.more_vert, size: 20),
                        onPressed: () => _showActionMenu(context, index),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      request['name'] ?? 'Unknown User',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${request['role'] ?? 'No role'} • ID: ${request['employeeId'] ?? 'N/A'}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Applied for $leaveType',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _getLeaveTypeColor(leaveType),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${_formatDate(request['startDate'])} - ${_formatDate(request['endDate'])}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (reason.isNotEmpty) ...[
                  const Text(
                    'REASON:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(
                      maxHeight: 60,
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        reason,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (status != 'Pending') ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _showDetailsDialog(request),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue),
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                        ),
                      ),
                      child: const Text(
                        'VIEW DETAILS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Original Tile for Tablet/Desktop
  Widget _buildLeaveTile(Map<String, dynamic> request, int index) {
    final status = request['status'] ?? 'Pending';
    final leaveType = request['leaveType'] ?? '';
    final reason = request['reason'] ?? 'No reason provided';

    return Container(
      constraints: const BoxConstraints(
        maxHeight: 260,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: _getStatusBorderColor(status), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 65,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getStatusHeaderColor(status),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.white,
                  child: Text(
                    request['name']?.toString().isNotEmpty == true
                        ? request['name']
                        .toString()
                        .substring(0, 1)
                        .toUpperCase()
                        : 'U',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: _getStatusTextColor(status),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        request['name'] ?? 'Unknown User',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: _getStatusTextColor(status),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${request['role'] ?? 'No role'} • ID: ${request['employeeId'] ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 9,
                          color: _getStatusTextColor(status).withOpacity(0.8),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                          color: _getStatusColor(status),
                        ),
                      ),
                    ),
                    if (status == 'Pending') ...[
                      const SizedBox(width: 2),
                      IconButton(
                        icon: const Icon(
                          Icons.more_vert,
                          size: 14,
                        ),
                        padding: const EdgeInsets.all(2),
                        onPressed: () => _showActionMenu(context, index),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 11,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                leaveType,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 11,
                                  color: _getLeaveTypeColor(leaveType),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${_calculateDays(request['startDate'], request['endDate'])} days',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 35,
                    width: double.infinity,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'FROM',
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _formatDate(request['startDate']),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.arrow_forward,
                          size: 12,
                          color: Colors.grey[400],
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'TO',
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _formatDate(request['endDate']),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'REASON',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          reason,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show details dialog for mobile
  void _showDetailsDialog(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Leave Details - ${request['name']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Employee ID', request['employeeId'] ?? 'N/A'),
              _buildDetailRow('Role', request['role'] ?? 'No role'),
              _buildDetailRow('Status', request['status'] ?? 'Pending'),
              _buildDetailRow('Leave Type', request['leaveType'] ?? ''),
              _buildDetailRow('Start Date', _formatDate(request['startDate'])),
              _buildDetailRow('End Date', _formatDate(request['endDate'])),
              _buildDetailRow(
                'Duration',
                '${_calculateDays(request['startDate'], request['endDate'])} days',
              ),
              _buildDetailRow(
                'Reason',
                request['reason'] ?? 'No reason provided',
              ),
              if (request['rejectionReason'] != null)
                _buildDetailRow('Rejection Reason', request['rejectionReason']),
              if (request['rejectedAt'] != null)
                _buildDetailRow(
                  'Rejected On',
                  _formatDate(request['rejectedAt']),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  /// Helper methods
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Color _getStatusHeaderColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green.shade50;
      case 'Rejected':
        return Colors.red.shade50;
      default:
        return Colors.orange.shade50;
    }
  }

  Color _getStatusBorderColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green.shade200;
      case 'Rejected':
        return Colors.red.shade200;
      default:
        return Colors.orange.shade200;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green.shade800;
      case 'Rejected':
        return Colors.red.shade800;
      default:
        return Colors.orange.shade800;
    }
  }

  Color _getLeaveTypeColor(String leaveType) {
    switch (leaveType.toLowerCase()) {
      case 'sick leave':
        return Colors.red.shade700;
      case 'vacation leave':
        return Colors.blue.shade700;
      case 'emergency':
        return Colors.orange.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  int _calculateDays(dynamic startTimestamp, dynamic endTimestamp) {
    try {
      if (startTimestamp is Timestamp && endTimestamp is Timestamp) {
        final start = startTimestamp.toDate();
        final end = endTimestamp.toDate();
        return end.difference(start).inDays + 1;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }
    return timestamp.toString();
  }
}