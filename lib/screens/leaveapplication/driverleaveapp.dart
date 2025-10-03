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
  String? _selectedLeaveType;
  final TextEditingController _reasonController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  final List<String> _leaveTypes = [
    'Sick Leave',
    'Vacation Leave',
  ];

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a date range.')),
        );
        return;
      }

      try {
        // Get current user UID
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not logged in.')),
          );
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
          'status': 'Pending', // can be Approved / Rejected later
          'submittedAt': FieldValue.serverTimestamp(),
        };

        // Save inside user's subcollection
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('leave_application')
            .add(leaveData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Leave application submitted successfully!')),
          );
        }

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
        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] ?? '';
          final rejectedAt = (data['rejectedAt'] as Timestamp?)?.toDate();

          // If it's rejected and older than 5 days → mark for deletion
          if (status == 'Rejected' && rejectedAt != null) {
            final diff = now.difference(rejectedAt).inDays;
            if (diff >= 5) {
              // Schedule deletion in the background (non-blocking)
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('leave_application')
                  .doc(doc.id)
                  .delete();
              return false; // Don't show it
            }
          }

          return true;
        }).toList();

        if (docs.isEmpty) {
          return const Text(
            'No leave applications to show.',
            style: TextStyle(color: Colors.grey),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Submitted Leave Applications',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D2364),
              ),
            ),
            const SizedBox(height: 8),
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final leaveType = data['leaveType'] ?? 'N/A';
              final startDate = (data['startDate'] as Timestamp?)?.toDate();
              final endDate = (data['endDate'] as Timestamp?)?.toDate();
              final status = data['status'] ?? 'Pending';
              final reason = data['reason'] ?? 'No reason provided';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
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
                  ],
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime(2026),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (BuildContext context, Widget? child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;

        final double popupWidth = screenWidth > 500 ? 420 : screenWidth * 0.9;
        final double popupHeight = screenHeight > 600 ? 520 : screenHeight * 0.8;

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

  int _calculateNumberOfDays() {
    if (_startDate == null || _endDate == null) return 0;
    return _endDate!.difference(_startDate!).inDays + 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(backgroundColor: const Color(0xFF0D2364)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isWide = constraints.maxWidth > 600;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWide ? 600 : double.infinity,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildFormCard(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2364),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Leave Application",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Easily file your leave request with automatic details.",
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(30),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade300, width: 1.0),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Leave Application Form',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D2364),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Show Submitted Application
            _buildSubmittedApplications(),

            const SizedBox(height: 20),

            // Type of Leave
            _buildFormSection(
              label: 'Type of Leave',
              child: DropdownButtonFormField<String>(
                value: _selectedLeaveType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                ),
                items: _leaveTypes.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedLeaveType = newValue;
                  });
                },
                validator: (value) =>
                value == null ? 'Please select leave type' : null,
              ),
            ),
            const SizedBox(height: 16),

            // Date Range Picker
            _buildFormSection(
              label: 'Select Leave Date Range',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OutlinedButton(
                    onPressed: () => _selectDateRange(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF0D2364)),
                    ),
                    child: const Text(
                      'Pick Date Range from Calendar',
                      style: TextStyle(
                        color: Color(0xFF0D2364),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_startDate != null && _endDate != null)
                    Text(
                      '${_formatDate(_startDate!)} - ${_formatDate(_endDate!)} '
                          '(${_calculateNumberOfDays()} days)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Reason
            _buildFormSection(
              label: 'Reason for requesting leave:',
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.shade400,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: TextFormField(
                  controller: _reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Enter reason for leave',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(12.0),
                  ),
                  validator: (value) =>
                  value!.isEmpty ? 'Required' : null,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D2364),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: const Text(
                  'Submit Leave Application',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSection({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
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
