import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/app_user.dart';

class ViolationReportHistoryScreen extends StatelessWidget {
  ViolationReportHistoryScreen({super.key, required this.user});

  final AppUser user;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream to get all violation reports
  Stream<List<Map<String, dynamic>>> getViolationReports() {
    return _firestore
        .collection('violation_report')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Get violations for a specific user
  Future<List<Map<String, dynamic>>> getViolationsByUser(
      String name, String position) async {
    final querySnapshot = await _firestore
        .collection('violation_report')
        .where('name', isEqualTo: name)
        .where('position', isEqualTo: position)
        .get();

    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Fetch reported user's email from `users` collection using employeeId
  Future<String> getReportedUserEmail(String employeeDocId) async {
    final doc = await _firestore.collection('users').doc(employeeDocId).get();
    if (doc.exists) {
      return doc.data()?['email'] ?? 'Unknown';
    }
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2364),
        title: const Text('User Reports', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Table Header
            const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'User',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Position',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: SizedBox(), // Empty for three-dot button
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),

            // Users List
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: getViolationReports(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No violation reports found'));
                  }

                  final reports = snapshot.data!;

                  // Filter only Driver, Conductor, Inspector
                  final filteredReports = reports
                      .where((r) =>
                  r['position'] == 'Driver' ||
                      r['position'] == 'Conductor' ||
                      r['position'] == 'Inspector')
                      .toList();

                  // Get unique users by name + position
                  final users = {
                    for (var report in filteredReports)
                      '${report['name']}-${report['position']}': report
                  }.values.toList();

                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final userData = users[index];
                      return _UserItem(
                        name: userData['name'],
                        employeeId: userData['employeeId'],
                        position: userData['position'],
                        fetchViolations: () => getViolationsByUser(
                            userData['name'], userData['position']),
                        getEmail: () =>
                            getReportedUserEmail(userData['employeeId']),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserItem extends StatelessWidget {
  const _UserItem({
    required this.name,
    required this.employeeId,
    required this.position,
    required this.fetchViolations,
    required this.getEmail,
  });

  final String name;
  final String employeeId;
  final String position;
  final Future<List<Map<String, dynamic>>> Function() fetchViolations;
  final Future<String> Function() getEmail;

  void _showViolationReport(BuildContext context) async {
    final localContext = context;
    final violations = await fetchViolations();

    if (localContext.mounted) {
      showDialog(
        context: localContext,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('VIOLATION REPORT - $name'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem('VIOLATIONS', violations.length.toString()),
                      _buildSummaryItem(
                          'TYPE',
                          violations
                              .map((v) => v['violation'])
                              .toSet()
                              .length
                              .toString()),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Table Header (without Severity)
                  const Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text('Date & TIME',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('Violation Committed',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const Divider(),

                  // Violations List (without Severity)
                  ...violations.map(
                        (violation) => Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                                flex: 2,
                                child: Text(violation['submittedAt'] != null
                                    ? (violation['submittedAt'] as Timestamp)
                                    .toDate()
                                    .toString()
                                    : violation['time'] ?? '')),
                            Expanded(flex: 2, child: Text(violation['violation'] ?? '')),
                          ],
                        ),
                        const Divider(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close')),
            ],
          );
        },
      );
    }
  }

  Widget _buildSummaryItem(String title, String value) {
    return Column(
      children: [
        Text(title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        Text(value,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D2364))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getEmail(),
      builder: (context, snapshot) {
        final reporterEmail = snapshot.data ?? 'Loading...';

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Reported By: $reporterEmail',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
                Expanded(flex: 1, child: Text(position)),
                Expanded(
                  flex: 1,
                  child: IconButton(
                    icon: const Icon(Icons.more_vert, size: 20, color: Color(0xFF0D2364)),
                    onPressed: () => _showViolationReport(context),
                  ),
                ),
              ],
            ),
            const Divider(),
          ],
        );
      },
    );
  }
}