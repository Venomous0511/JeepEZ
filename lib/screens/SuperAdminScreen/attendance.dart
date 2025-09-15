import 'package:flutter/material.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final List<Map<String, String>> attendanceData = const [
    {'name': '', 'unit': '', 'in': '', 'out': ''},
    {'name': '', 'unit': '', 'in': '', 'out': ''},
    {'name': '', 'unit': '', 'in': '', 'out': ''},
    {'name': '', 'unit': '', 'in': '', 'out': ''},
    {'name': '', 'unit': '', 'in': '', 'out': ''},
    {'name': '', 'unit': '', 'in': '', 'out': ''},
    {'name': '', 'unit': '', 'in': '', 'out': ''},
    {'name': '', 'unit': '', 'in': '', 'out': ''},
    {'name': '', 'unit': '', 'in': '', 'out': ''},
    {'name': '', 'unit': '', 'in': '', 'out': ''},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Record'),
        backgroundColor: const Color(0xFF1565C0),
      ),
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          // Swipe functionality - you can add navigation logic here if needed
          if (details.primaryVelocity! > 0) {
            // Swipe right
            print('Swiped right');
          } else if (details.primaryVelocity! < 0) {
            // Swipe left
            print('Swiped left');
          }
        },
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Table(
              border: TableBorder.all(color: Colors.grey.shade300, width: 1.0),
              defaultColumnWidth: const IntrinsicColumnWidth(),
              children: [
                // Table Header
                TableRow(
                  decoration: BoxDecoration(color: Colors.blue[50]),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text(
                        "Employee's Name",
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text(
                        'Vehicle Unit',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text(
                        'Time In',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text(
                        'Time Out',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                // Table Rows
                ...attendanceData.map((record) {
                  return TableRow(
                    decoration: BoxDecoration(
                      color: attendanceData.indexOf(record) % 2 == 0
                          ? Colors.white
                          : Colors.grey[50],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          record['name'] ?? '',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          record['unit'] ?? '',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          record['in'] ?? '',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          record['out'] ?? '',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
