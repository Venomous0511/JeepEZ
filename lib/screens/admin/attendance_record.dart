import 'package:flutter/material.dart';

class AttendanceScreen extends StatelessWidget {
  final VoidCallback onBackPressed;

  const AttendanceScreen({super.key, required this.onBackPressed});

  final List<Map<String, String>> attendanceData = const [
    {'name': 'John Doe', 'unit': 'UNIT 20', 'in': '8:00 AM', 'out': '5:00 PM'},
    {
      'name': 'Jane Smith',
      'unit': 'UNIT 21',
      'in': '8:15 AM',
      'out': '4:45 PM',
    },
    {
      'name': 'Robert Johnson',
      'unit': 'UNIT 02',
      'in': '7:45 AM',
      'out': '5:30 PM',
    },
    {
      'name': 'Sarah Williams',
      'unit': 'UNIT 05',
      'in': '8:30 AM',
      'out': '5:15 PM',
    },
    {
      'name': 'Michael Brown',
      'unit': 'UNIT 10',
      'in': '8:05 AM',
      'out': '4:50 PM',
    },
    {
      'name': 'Emily Davis',
      'unit': 'UNIT 20',
      'in': '8:10 AM',
      'out': '5:10 PM',
    },
    {
      'name': 'David Miller',
      'unit': 'UNIT 21',
      'in': '8:20 AM',
      'out': '5:05 PM',
    },
    {
      'name': 'Jessica Wilson',
      'unit': 'UNIT 02',
      'in': '7:55 AM',
      'out': '5:25 PM',
    },
    {
      'name': 'Daniel Taylor',
      'unit': 'UNIT 05',
      'in': '8:25 AM',
      'out': '5:20 PM',
    },
    {
      'name': 'Jennifer Anderson',
      'unit': 'UNIT 10',
      'in': '8:15 AM',
      'out': '4:55 PM',
    },
    {
      'name': 'Christopher Thomas',
      'unit': 'UNIT 20',
      'in': '8:00 AM',
      'out': '5:00 PM',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: onBackPressed,
        ),
        title: const Text(
          'Attendance Record',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0D2364),
        automaticallyImplyLeading:
            false, // This hides the drawer/hamburger icon
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  columnSpacing: 16,
                  headingRowColor: WidgetStateProperty.all(Colors.blue[50]),
                  columns: const [
                    DataColumn(label: Text("Employee's Name")),
                    DataColumn(label: Text('Vehicle Unit')),
                    DataColumn(label: Text('Time In')),
                    DataColumn(label: Text('Time Out')),
                  ],
                  rows: attendanceData.map((record) {
                    return DataRow(
                      cells: [
                        DataCell(Text(record['name'] ?? '')),
                        DataCell(Text(record['unit'] ?? '')),
                        DataCell(Text(record['in'] ?? '')),
                        DataCell(Text(record['out'] ?? '')),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
