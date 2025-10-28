import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LeaveApplicationScreen extends StatefulWidget {
  const LeaveApplicationScreen({super.key});

  @override
  State<LeaveApplicationScreen> createState() => _LeaveApplicationScreenState();
}

class _LeaveApplicationScreenState extends State<LeaveApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _vehicleId;
  String? _selectedLeaveType;
  final TextEditingController _reasonController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _hasSubmittedToday = false;
  bool _isCheckingSubmission = true;

  final List<String> _leaveTypes = ['Sick Leave', 'Vacation Leave'];

  @override
  void initState() {
    super.initState();
    _checkTodaySubmission();
    _fetchAssignedVehicle();
  }

  Future<void> _fetchAssignedVehicle() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      final assignedVehicleId =
          userData['assignedVehicle']?.toString() ?? 'N/A';
      setState(() {
        _vehicleId = assignedVehicleId;
      });
    } catch (e) {
      debugPrint('Error fetching assigned vehicle: $e');
    }
  }

  Future<void> _checkTodaySubmission() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Check for any pending applications
      final pendingSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('leave_application')
          .where('status', isEqualTo: 'Pending')
          .get();

      // Check for approved applications in the current month
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final approvedThisMonthSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('leave_application')
          .where('status', isEqualTo: 'Approved')
          .where('approvedAt', isGreaterThanOrEqualTo: startOfMonth)
          .where('approvedAt', isLessThanOrEqualTo: endOfMonth)
          .get();

      setState(() {
        _hasSubmittedToday =
            pendingSnapshot.docs.isNotEmpty ||
            approvedThisMonthSnapshot.docs.isNotEmpty;
        _isCheckingSubmission = false;
      });
    } catch (e) {
      debugPrint('Error checking submission: $e');
      setState(() {
        _isCheckingSubmission = false;
      });
    }
  }

  // ADD THIS FUNCTION - Send notification ONLY to Legal Officer
  Future<void> _sendLeaveNotificationToLegalOfficer() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get user data to include in notification
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDoc.data();
      final userName = userData?['name'] ?? 'Unknown User';
      final userRole = userData?['role'] ?? 'Unknown Role';
      final employeeId = userData?['employeeId'] ?? 'Unknown ID';

      // Create notification ONLY for Legal Officer
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': 'New Leave Application',
        'message':
            '$userName ($employeeId - $userRole) has submitted a ${_selectedLeaveType?.toLowerCase() ?? 'leave'} application',
        'type': 'leave_application',
        'category': 'leave',
        'relatedUserId': user.uid,
        'employeeId': employeeId,
        'employeeName': userName,
        'employeeRole': userRole,
        'leaveType': _selectedLeaveType,
        'startDate': _startDate,
        'endDate': _endDate,
        'reason': _reasonController.text.trim(),
        'status': 'pending',
        'time': FieldValue.serverTimestamp(),
        'read': false,
        'dismissed': false,
        'targetRole': 'legal_officer',
      });

      debugPrint('Leave notification sent to Legal Officer only');
    } catch (e) {
      debugPrint('Error sending leave notification: $e');
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a date range.')),
        );
        return;
      }

      if (_reasonController.text.length > 100) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reason must not exceed 100 characters.'),
          ),
        );
        return;
      }

      if (_hasSubmittedToday) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'You already have a pending request or approved leave this month. \n'
              'You can submit again next month or after your current request is resolved.',
            ),
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('User not logged in.')));
          return;
        }

        final String uid = user.uid;

        // Prepare leave data
        final leaveData = {
          'leaveType': _selectedLeaveType,
          'startDate': _startDate,
          'endDate': _endDate,
          'numberOfDays': _calculateNumberOfDays(),
          'reason': _reasonController.text.trim(),
          'status': 'Pending',
          'submittedAt': FieldValue.serverTimestamp(),
        };

        // Save inside user's subcollection
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('leave_application')
            .add(leaveData);

        // ADD THIS LINE - Send notification to Legal Officer
        await _sendLeaveNotificationToLegalOfficer();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Leave application submitted successfully!'),
            ),
          );
        }

        // Update submission status
        setState(() {
          _hasSubmittedToday = true;
        });

        // Clear form after submission
        if (mounted) {
          setState(() {
            _selectedLeaveType = null;
            _startDate = null;
            _endDate = null;
            _reasonController.clear();
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error submitting application: $e')),
          );
        }
      }
    }
  }

  // IMPROVED: Better auto-cleanup with proper error handling
  Widget _buildSubmittedApplications() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Text('Log in to view your applications.');
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('leave_application')
          .orderBy('submittedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text(
            'No leave applications submitted yet.',
            style: TextStyle(color: Colors.grey),
          );
        }

        final now = DateTime.now();
        final List<DocumentSnapshot> validDocs = [];

        for (final doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] ?? '';
          final rejectedAt = (data['rejectedAt'] as Timestamp?)?.toDate();
          final endDate = (data['endDate'] as Timestamp?)?.toDate();

          bool shouldDelete = false;
          String deleteReason = '';

          // Delete rejected applications after 5 days
          if (status == 'Rejected' && rejectedAt != null) {
            final daysSinceRejection = now.difference(rejectedAt).inDays;
            if (daysSinceRejection >= 5) {
              shouldDelete = true;
              deleteReason = 'Rejected $daysSinceRejection days ago';
            }
          }

          if (status == 'Approved' && endDate != null) {
            final daysAfterEndDate = now.difference(endDate).inDays;
            if (daysAfterEndDate >= 3) {
              shouldDelete = true;
              deleteReason =
                  'Leave ended ${_formatDate(endDate)} - archived after 3 days';
            }
          }

          // Delete completed leave applications (end date has passed)
          if (endDate != null && endDate.isBefore(now)) {
            shouldDelete = true;
            deleteReason = 'Leave period ended on ${_formatDate(endDate)}';
          }

          if (shouldDelete) {
            // Delete asynchronously
            FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('leave_application')
                .doc(doc.id)
                .delete()
                .then((_) {
                  debugPrint(
                    'Auto-deleted leave application: ${doc.id} - $deleteReason',
                  );
                })
                .catchError((error) {
                  debugPrint(
                    'Error deleting leave application ${doc.id}: $error',
                  );
                });
            continue; // Skip this document
          }

          validDocs.add(doc);
        }

        if (validDocs.isEmpty) {
          return const Text(
            'No active leave applications to show.',
            style: TextStyle(color: Colors.grey),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Active Leave Applications',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D2364),
              ),
            ),
            const SizedBox(height: 12),
            ...validDocs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final leaveType = data['leaveType'] ?? 'N/A';
              final startDate = (data['startDate'] as Timestamp?)?.toDate();
              final endDate = (data['endDate'] as Timestamp?)?.toDate();
              final status = data['status'] ?? 'Pending';
              final reason = data['reason'] ?? 'No reason provided';
              final submittedAt = (data['submittedAt'] as Timestamp?)?.toDate();
              final rejectedAt = (data['rejectedAt'] as Timestamp?)?.toDate();
              final rejectionReason = data['rejectionReason'];

              // Calculate days until deletion for rejected applications
              String deletionInfo = '';
              if (status == 'Rejected' && rejectedAt != null) {
                final daysSinceRejection = now.difference(rejectedAt).inDays;
                final daysRemaining = 5 - daysSinceRejection;
                if (daysRemaining > 0) {
                  deletionInfo =
                      'Will be removed in $daysRemaining day${daysRemaining > 1 ? 's' : ''}';
                }
              }

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          leaveType,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          status,
                          style: TextStyle(
                            color: status == 'Approved'
                                ? Colors.green
                                : status == 'Rejected'
                                ? Colors.red
                                : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    if (startDate != null && endDate != null)
                      Text(
                        'Date: ${_formatDate(startDate)} - ${_formatDate(endDate)}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Reason: $reason',
                      style: const TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                    // Show rejection reason if rejected
                    if (status == 'Rejected' && rejectionReason != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Rejection Reason:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              rejectionReason,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (submittedAt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Submitted: ${_formatDateTime(submittedAt)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),

                    // Show deletion countdown for rejected applications
                    if (deletionInfo.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          deletionInfo,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2026),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (BuildContext context, Widget? child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;

        final double popupWidth = screenWidth > 500 ? 500 : screenWidth * 0.9;
        final double popupHeight = screenHeight > 600
            ? 520
            : screenHeight * 0.8;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: popupWidth,
              maxHeight: popupHeight,
            ),
            child: Material(
              elevation: 12,
              borderRadius: BorderRadius.circular(16),
              color: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Dialog(
                  insetPadding: EdgeInsets.zero,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: child!,
                ),
              ),
            ),
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  int _calculateNumberOfDays() {
    if (_startDate == null || _endDate == null) return 0;
    return _endDate!.difference(_startDate!).inDays + 1;
  }

  bool get _canSubmit {
    return _reasonController.text.length <= 100 &&
        !_hasSubmittedToday &&
        !_isCheckingSubmission &&
        _selectedLeaveType != null &&
        _startDate != null &&
        _endDate != null;
  }

  String get _submitButtonText {
    if (_isCheckingSubmission) return 'Checking...';
    if (_vehicleId == 'N/A' || _vehicleId == null) return 'No Vehicle Assigned';
    if (_hasSubmittedToday) return 'Request Limit Reached';
    return 'Submit Leave Application';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.zero,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              children: [
                // Header Section
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isMobile ? 20.0 : 24.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D2364),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Leave Application",
                        style: TextStyle(
                          fontSize: isMobile ? 22 : 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Easily file your leave request with details.",
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          color: Colors.white70,
                        ),
                      ),
                      if (_hasSubmittedToday)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'You have a pending request or approved leave this month',
                              style: TextStyle(
                                fontSize: isMobile ? 12 : 13,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Form Section
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isMobile ? 20.0 : 24.0),
                  decoration: const BoxDecoration(color: Colors.white),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Leave Application Form',
                          style: TextStyle(
                            fontSize: isMobile ? 18 : 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0D2364),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Show Submitted Application
                        _buildSubmittedApplications(),

                        const SizedBox(height: 24),

                        // Type of Leave
                        _buildFormSection(
                          label: 'Type of Leave',
                          isMobile: isMobile,
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedLeaveType,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: isMobile ? 16 : 18,
                              ),
                            ),
                            items: _leaveTypes.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value,
                                  style: TextStyle(
                                    fontSize: isMobile ? 14 : 16,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: _hasSubmittedToday
                                ? null
                                : (newValue) {
                                    setState(() {
                                      _selectedLeaveType = newValue;
                                    });
                                  },
                            validator: (value) => value == null
                                ? 'Please select leave type'
                                : null,
                          ),
                        ),
                        SizedBox(height: isMobile ? 16 : 20),

                        // Date Range Picker
                        _buildFormSection(
                          label: 'Select Leave Date Range',
                          isMobile: isMobile,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: _hasSubmittedToday
                                      ? null
                                      : () => _selectDateRange(context),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: _hasSubmittedToday
                                          ? Colors.grey
                                          : const Color(0xFF0D2364),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isMobile ? 16 : 24,
                                      vertical: isMobile ? 12 : 16,
                                    ),
                                  ),
                                  child: Text(
                                    'Pick Date Range from Calendar',
                                    style: TextStyle(
                                      fontSize: isMobile ? 14 : 16,
                                      color: _hasSubmittedToday
                                          ? Colors.grey
                                          : const Color(0xFF0D2364),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (_startDate != null && _endDate != null)
                                Text(
                                  '${_formatDate(_startDate!)} - ${_formatDate(_endDate!)} '
                                  '(${_calculateNumberOfDays()} days)',
                                  style: TextStyle(
                                    fontSize: isMobile ? 14 : 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(height: isMobile ? 16 : 20),

                        _buildFormSection(
                          label: 'Reason for requesting leave:',
                          isMobile: isMobile,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _hasSubmittedToday
                                        ? Colors.grey
                                        : Colors.grey.shade400,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Column(
                                  children: [
                                    TextFormField(
                                      controller: _reasonController,
                                      maxLength: 100,
                                      maxLines: 3,
                                      enabled: !_hasSubmittedToday,
                                      // Removed the setState listener for stable typing
                                      style: TextStyle(
                                        fontSize: isMobile ? 14 : 16,
                                        color: _hasSubmittedToday
                                            ? Colors.grey
                                            : Colors.black,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Enter reason for leave',
                                        hintStyle: TextStyle(
                                          fontSize: isMobile ? 14 : 16,
                                          color: _hasSubmittedToday
                                              ? Colors.grey
                                              : Colors.grey.shade500,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.all(
                                          16.0,
                                        ),
                                        counterText: "",
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Required';
                                        }
                                        if (value.length > 100) {
                                          return 'Reason must not exceed 100 characters';
                                        }
                                        return null;
                                      },
                                    ),
                                    // Character counter - only updates when needed
                                    if (_reasonController.text.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 12.0,
                                          bottom: 8.0,
                                        ),
                                        child: Text(
                                          '${_reasonController.text.length}/100',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                _reasonController.text.length >
                                                    100
                                                ? Colors.red
                                                : Colors.grey.shade600,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (_reasonController.text.length > 100)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Character limit exceeded!',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(height: isMobile ? 24 : 32),

                        // Submit Button
                        if (_isCheckingSubmission)
                          const Center(child: CircularProgressIndicator())
                        else
                          SizedBox(
                            width: double.infinity,
                            height: isMobile ? 50 : 56,
                            child: ElevatedButton(
                              onPressed: _canSubmit ? _submitForm : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _canSubmit
                                    ? const Color(0xFF0D2364)
                                    : Colors.grey,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              child: Text(
                                _submitButtonText,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isMobile ? 16 : 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        if (_vehicleId == 'N/A' || _vehicleId == null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              '⚠️ No vehicle assigned. Please contact admin to submit leave applications.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.red[700],
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection({
    required String label,
    required bool isMobile,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 16 : 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }
}
