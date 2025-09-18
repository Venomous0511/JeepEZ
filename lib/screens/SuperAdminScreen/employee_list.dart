import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/app_user.dart';

class EmployeeListScreen extends StatefulWidget {
  final AppUser user;
  const EmployeeListScreen({super.key, required this.user});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final employeeIdCtrl = TextEditingController();
  String role = 'conductor';
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee List Management'),
        backgroundColor: const Color(0xFF0D2364),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ---------------- LIST ----------------
            const Text(
              'Existing Users',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D2364),
              ),
            ),
            const SizedBox(height: 8),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Text('No users yet.');
                }

                final employeeDocs = snap.data!.docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return data['status'] == true;
                }).toList();

                // ✅ Wrap DataTable in horizontal scroll
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 16,
                    headingRowColor: WidgetStateProperty.all(Colors.blue[50]),
                    columns: const [
                      DataColumn(label: Text("ID Number")),
                      DataColumn(label: Text("Status")),
                      DataColumn(label: Text("Name")),
                      DataColumn(label: Text("Email")),
                      DataColumn(label: Text("Role")),
                      DataColumn(label: Text("Actions")),
                    ],
                    rows: employeeDocs.map((d) {
                      final data = d.data() as Map<String, dynamic>;

                      return DataRow(
                        cells: [
                          DataCell(Text(data['employee_id'].toString() ?? '')),
                          DataCell(
                              Text(
                                  data['status'] == true
                                      ? "Active"
                                      : "Inactive",
                                  style: TextStyle(
                                    color: data['status'] == true
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                              ),
                          ),
                          DataCell(Text(data['name'] ?? '')),
                          DataCell(Text(data['email'] ?? '')),
                          DataCell(Text(data['role'] ?? '')),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () => _editUser(d.id, data),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _deleteUser(d.id, data),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// ---------------- UPDATE USER FUNCTION ----------------
  Future<void> _editUser(String docId, Map<String, dynamic> data) async {
    final employeeIdCtrl = TextEditingController(text: data['employee_id']?.toString());
    final nameCtrl = TextEditingController(text: data['name']);
    final emailCtrl = TextEditingController(text: data['email']);
    String role = data['role'] ?? "conductor";

    final updated = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Update User"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: employeeIdCtrl,
                decoration: const InputDecoration(labelText: "Employee ID"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: role,
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('admin')),
                  DropdownMenuItem(
                    value: 'legal_officer',
                    child: Text('legal_officer'),
                  ),
                  DropdownMenuItem(value: 'driver', child: Text('driver')),
                  DropdownMenuItem(
                    value: 'conductor',
                    child: Text('conductor'),
                  ),
                  DropdownMenuItem(
                    value: 'inspector',
                    child: Text('inspector'),
                  ),
                ],
                onChanged: (v) => setState(() => role = v ?? 'conductor'),
                decoration: const InputDecoration(labelText: 'Role'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Update"),
            ),
          ],
        ),
      ),
    );

    if (updated == true) {
      await FirebaseFirestore.instance.collection('users').doc(docId).update({
        "employee_id": employeeIdCtrl.text.trim(),
        "name": nameCtrl.text.trim(),
        "email": emailCtrl.text.trim(),
        "role": role,
      });
    }
  }

  /// ---------------- DELETE USER ----------------
  Future<void> _deleteUser(String docId, Map<String, dynamic> data) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Deactivate User"),
        content: Text("Are you sure you want to Deactivate ${data['email']}? " "This will remove their info but keep the account as inactive"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('users').doc(docId).update({
        "employee_id": "",
        "name": "",
        "email": "",
        "role": "",
        "status": "false",
      });
    }
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    nameCtrl.dispose();
    super.dispose();
  }
}
