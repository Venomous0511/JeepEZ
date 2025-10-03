import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LeaveManagementScreen extends StatefulWidget {
  const LeaveManagementScreen({super.key});

  @override
  State<LeaveManagementScreen> createState() => _LeaveManagementScreenState();
}

class _LeaveManagementScreenState extends State<LeaveManagementScreen> {
  List<Map<String, dynamic>> _leaveRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaveRequests();
  }

  /// Load all leave applications from Firestore
  Future<void> _loadLeaveRequests() async {
    try {
      final data = await _fetchAllLeaveApplications();
      if (mounted) {
        setState(() {
          _leaveRequests = data;
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

    final usersSnapshot = await firestore.collection('users').get();
    for (var userDoc in usersSnapshot.docs) {
      final userId = userDoc.id;

      final leaveSnapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('leave_application')
          .orderBy('submittedAt', descending: true)
          .get();

      for (var leaveDoc in leaveSnapshot.docs) {
        final data = leaveDoc.data();
        allLeaves.add({
          ...data,
          'userId': userId,
          'leaveId': leaveDoc.id,
          'name': userDoc.data()['name'] ?? 'Unknown',
          'email': userDoc.data()['email'] ?? 'N/A',
          'role': userDoc.data()['role'] ?? '',
        });
      }
    }

    return allLeaves;
  }

  /// Approve request
  Future<void> _approveRequest(int index) async {
    final req = _leaveRequests[index];
    await FirebaseFirestore.instance
        .collection('users')
        .doc(req['userId'])
        .collection('leave_application')
        .doc(req['leaveId'])
        .update({'status': 'Approved'});

    if (mounted) {
      setState(() => _leaveRequests[index]['status'] = 'Approved');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${req['name']}'s leave approved"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Reject request
  Future<void> _rejectRequest(int index) async {
    final TextEditingController reasonController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reject Leave'),
          content: TextField(
            controller: reasonController,
            decoration: const InputDecoration(
              labelText: 'Reason for rejection',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
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
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      final req = _leaveRequests[index];
      await FirebaseFirestore.instance
          .collection('users')
          .doc(req['userId'])
          .collection('leave_application')
          .doc(req['leaveId'])
          .update({
            'status': 'Rejected',
            'rejectionReason': result,
            'rejectedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        setState(() => _leaveRequests[index]['status'] = 'Rejected');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${req['name']}'s leave rejected"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Leave Management',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0D2364),
        foregroundColor: const Color(0xFFFFFFFF),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _leaveRequests.isEmpty
          ? const Center(child: Text('No leave applications found'))
          : _buildLeaveList(),
    );
  }

  /// Card List View for mobile
  Widget _buildLeaveList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _leaveRequests.length,
      itemBuilder: (context, index) {
        final request = _leaveRequests[index];
        final status = request['status'] ?? 'Pending';
        final leaveType = request['leaveType'] ?? '';
        final reason = request['reason'] ?? 'No reason provided';
        final rejectionReason = request['rejectionReason'];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: status == 'Approved'
              ? Colors.green.shade50
              : status == 'Rejected'
              ? Colors.red.shade50
              : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Name & Type
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      request['name'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      leaveType,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                /// Dates
                Text(
                  'From: ${_formatDate(request['startDate'])} → To: ${_formatDate(request['endDate'])}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),

                /// Reason
                Text('Reason: $reason', style: const TextStyle(fontSize: 14)),

                /// Rejection Reason
                if (status == 'Rejected' && rejectionReason != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Rejection Reason: $rejectionReason',
                    style: const TextStyle(fontSize: 14, color: Colors.red),
                  ),
                ],

                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatusChip(status),
                    if (status == 'Pending')
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => _rejectRequest(index),
                            child: const Text(
                              'Reject',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _approveRequest(index),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: const Text(
                              'Approve',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Status chip
  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'Approved':
        color = Colors.green;
        break;
      case 'Rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// Format Firestore Timestamp
  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.month}/${date.day}/${date.year}';
    }
    return timestamp.toString();
  }
}
