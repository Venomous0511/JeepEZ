import 'package:flutter/material.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

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
    {'name': '', 'unit': '', 'in': '', 'out': ''},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Record'),
        backgroundColor: const Color(0xFF0D2364),
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
