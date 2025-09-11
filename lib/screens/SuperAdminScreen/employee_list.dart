import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  final CollectionReference employeesCollection = FirebaseFirestore.instance
      .collection('employees');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee List Management'),
        backgroundColor: const Color(0xFF1565C0),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    _showAddEmployeeDialog(context);
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Account'),
                ),
                // You can add Deactivate and Edit functionality similarly later
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: employeesCollection.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Employees List'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final employeeDocs = snapshot.data!.docs;

                if (employeeDocs.isEmpty) {
                  return const Center(child: Text('No employees found'));
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 16,
                      headingRowColor: MaterialStateProperty.all(
                        Colors.blue[50],
                      ),
                      columns: const [
                        DataColumn(label: Text("Employee's Name")),
                        DataColumn(label: Text('Joining Date')),
                        DataColumn(label: Text('Email')),
                        DataColumn(label: Text('Status')),
                      ],
                      rows: employeeDocs.map((doc) {
                        final emp = doc.data()! as Map<String, dynamic>;
                        return DataRow(
                          cells: [
                            DataCell(Text(emp['name'] ?? '')),
                            DataCell(Text(emp['joining'] ?? '')),
                            DataCell(Text(emp['email'] ?? '')),
                            DataCell(Text(emp['status'] ?? '')),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEmployeeDialog(BuildContext context) {
    final nameController = TextEditingController();
    final joiningController = TextEditingController();
    final emailController = TextEditingController();
    final statusController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Employee'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: joiningController,
                decoration: const InputDecoration(labelText: 'Joining Date'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: statusController,
                decoration: const InputDecoration(labelText: 'Status'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newEmployee = {
                'name': nameController.text.trim(),
                'joining': joiningController.text.trim(),
                'email': emailController.text.trim(),
                'status': statusController.text.trim(),
              };
              await employeesCollection.add(newEmployee);
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
