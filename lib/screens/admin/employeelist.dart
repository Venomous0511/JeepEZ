import 'package:flutter/material.dart';

class EmployeeListScreen extends StatelessWidget {
  const EmployeeListScreen({super.key});

  final List<Map<String, String>> employees = const [
    {'name': '', 'joining': '', 'dob': '', 'email': '', 'status': ''},
    {'name': '', 'joining': '', 'dob': '', 'email': '', 'status': ''},
    {'name': '', 'joining': '', 'dob': '', 'email': '', 'status': ''},
    {'name': '', 'joining': '', 'dob': '', 'email': '', 'status': ''},
    {'name': '', 'joining': '', 'dob': '', 'email': '', 'status': ''},
    {'name': '', 'joining': '', 'dob': '', 'email': '', 'status': ''},
    {'name': '', 'joining': '', 'dob': '', 'email': '', 'status': ''},
    {'name': '', 'joining': '', 'dob': '', 'email': '', 'status': ''},
    {'name': '', 'joining': '', 'dob': '', 'email': '', 'status': ''},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee List Management'),
        backgroundColor: const Color(0xFF1565C0),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.person_add),
                      label: const Text('Add Account'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.person_off),
                      label: const Text('Deactivate Account'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                      ),
                      child: DataTable(
                        columnSpacing: 16,
                        headingRowColor: MaterialStateProperty.all(
                          Colors.blue[50],
                        ),
                        columns: const [
                          DataColumn(label: Text("Employee's Name")),
                          DataColumn(label: Text('Joining Date')),
                          DataColumn(label: Text('Date of Birth')),
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Status')),
                        ],
                        rows: employees.map((emp) {
                          return DataRow(
                            cells: [
                              DataCell(Text(emp['name'] ?? '')),
                              DataCell(Text(emp['joining'] ?? '')),
                              DataCell(Text(emp['dob'] ?? '')),
                              DataCell(Text(emp['email'] ?? '')),
                              DataCell(Text(emp['status'] ?? '')),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
