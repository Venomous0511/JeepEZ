import 'package:flutter/material.dart';
import '../../models/app_user.dart';

class AttendanceScreen extends StatefulWidget {
  final AppUser user;
  const AttendanceScreen({super.key, required this.user});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final List<Map<String, String>> attendanceData = const [
    {
      'name': 'Juan Dela Cruz',
      'unit': 'Jeep 101',
      'in': '08:00 AM',
      'out': '05:00 PM',
    },
    {
      'name': 'Maria Santos',
      'unit': 'Jeep 102',
      'in': '09:00 AM',
      'out': '06:00 PM',
    },
    {
      'name': 'Pedro Lopez',
      'unit': 'Jeep 103',
      'in': '07:30 AM',
      'out': '04:30 PM',
    },
    {
      'name': 'Ana Reyes',
      'unit': 'Jeep 104',
      'in': '08:15 AM',
      'out': '05:15 PM',
    },
    {
      'name': 'Jose Garcia',
      'unit': 'Jeep 105',
      'in': '07:45 AM',
      'out': '04:45 PM',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Record'),
        backgroundColor: const Color(0xFF0D2364),
      ),
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          // Swipe functionality - optional for navigation
          if (details.primaryVelocity! > 0) {
            debugPrint('Swiped right');
          } else if (details.primaryVelocity! < 0) {
            debugPrint('Swiped left');
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
                  int index = attendanceData.indexOf(record);
                  return TableRow(
                    decoration: BoxDecoration(
                      color: index % 2 == 0 ? Colors.white : Colors.grey[50],
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
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
