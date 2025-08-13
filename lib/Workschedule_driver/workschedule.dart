import 'package:flutter/material.dart';

void main() => runApp(const WorkScheduleApp());

class WorkScheduleApp extends StatelessWidget {
  const WorkScheduleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Work Schedule',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const WorkScheduleScreen(),
    );
  }
}

class WorkScheduleScreen extends StatelessWidget {
  const WorkScheduleScreen({super.key});
  final List<Map<String, String>> scheduleData = const [
    {'day': 'MON', 'time': '7:00 AM - 10:00 PM', 'unit': 'UNIT 20'},
    {'day': 'TUES', 'time': '7:00 AM - 10:00 PM', 'unit': 'UNIT 20'},
    {'day': 'WED', 'time': '7:00 AM - 10:00 PM', 'unit': 'UNIT 20'},
    {'day': 'THU', 'time': '7:00 AM - 10:00 PM', 'unit': 'UNIT 20'},
    {'day': 'FRI', 'time': '7:00 AM - 10:00 PM', 'unit': 'UNIT 20'},
    {'day': 'SAT', 'time': '7:00 AM - 10:00 PM', 'unit': 'UNIT 20'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Work Schedule'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Schedule',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            _buildShiftBadge('Regular work shift'),
            const SizedBox(height: 24),
            _buildScheduleTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildScheduleTable() {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300, width: 1),
      columnWidths: const {0: FlexColumnWidth(1.2), 1: FlexColumnWidth(2)},
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.blue[50]),
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'DAY',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'SCHEDULE',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
        ...scheduleData.map((entry) {
          return TableRow(
            decoration: const BoxDecoration(color: Colors.white),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                child: Center(
                  child: Text(
                    entry['day']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                child: Center(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      children: [
                        TextSpan(
                          text: '${entry['time']!}\n',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        TextSpan(
                          text: entry['unit']!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }
}
