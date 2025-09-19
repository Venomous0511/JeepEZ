import 'package:flutter/material.dart';
import '../../models/app_user.dart';

class ViolationReportHistoryScreen extends StatelessWidget {
  const ViolationReportHistoryScreen({super.key, required this.user});

  final AppUser user;

  // User data based on the screenshot
  final List<Map<String, String>> userList = const [
    {
      'name': 'James Arthur',
      'email': 'jamesarthur@gmail.com',
      'position': 'Driver',
    },
    {
      'name': 'Robert Valio',
      'email': 'robertvalio@mail.com',
      'position': 'Inspector',
    },
    {
      'name': 'Hanna Masalan',
      'email': 'hannamasalan@mail.com',
      'position': 'Conductor',
    },
    {
      'name': 'Jack Harper',
      'email': 'jackharper@mail.com',
      'position': 'Driver',
    },
    {
      'name': 'George Toen',
      'email': 'georgetoen@mail.com',
      'position': 'Inspector',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF0D2364),
        title: const Text('User Reports'),
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
                  flex: 2,
                  child: Text(
                    'User',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Position',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: SizedBox(), // Empty space for the three dots
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),

            // Users List
            Expanded(
              child: ListView(
                children: userList
                    .map(
                      (userData) => _UserItem(
                        name: userData['name']!,
                        email: userData['email']!,
                        position: userData['position']!,
                      ),
                    )
                    .toList(),
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
    required this.email,
    required this.position,
  });

  final String name;
  final String email;
  final String position;

  void _showViolationReport(BuildContext context) {
    // Sample violation data for the selected user
    final List<Map<String, String>> violations = [
      {
        'date': '2024-02-19',
        'violation': 'Traffic Violation',
        'severity': 'High',
      },
      {'date': '2024-01-05', 'violation': 'Misconduct', 'severity': 'Medium'},
      {
        'date': '2023-12-15',
        'violation': 'Traffic Violation',
        'severity': 'Low',
      },
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('VIOLATION REPORT - $name'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Violations Summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem(
                      'VIOLATIONS',
                      violations.length.toString(),
                    ),
                    _buildSummaryItem('TYPE', '2'),
                  ],
                ),
                const SizedBox(height: 16),

                // Table Header
                const Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Date & TIME',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Violation Committed',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Severity',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const Divider(),

                // Violations List
                ...violations.map(
                  (violation) => Column(
                    children: [
                      Row(
                        children: [
                          Expanded(flex: 2, child: Text(violation['date']!)),
                          Expanded(
                            flex: 2,
                            child: Text(violation['violation']!),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(violation['severity']!),
                          ),
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
              child: const Text('Close'),
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
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D2364),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    email,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Expanded(flex: 2, child: Text(position)),
            Expanded(
              flex: 1,
              child: IconButton(
                icon: const Icon(Icons.more_vert, size: 20),
                onPressed: () => _showViolationReport(context),
              ),
            ),
          ],
        ),
        const Divider(),
      ],
    );
  }
}
