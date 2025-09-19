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
        title: const Text(
          'Employee List Management',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0D2364),
        iconTheme: const IconThemeData(color: Colors.white),
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

                // Wrap DataTable in horizontal scroll
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 16,
                    headingRowColor: WidgetStateProperty.all(Colors.blue[50]),
                    columns: const [
                      DataColumn(label: Text("Employee ID")),
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
                          DataCell(Text(data['employeeId'].toString())),
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
    final employeeIdCtrl = TextEditingController(text: data['employeeId']?.toString());
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
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: "Email"),
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
        "name": nameCtrl.text.trim(),
        "email": emailCtrl.text.trim(),
        "role": role,
      });

      await FirebaseFirestore.instance.collection('notifications').add({
        'title': 'Updated Account',
        'message': 'Update account for ${nameCtrl.text.trim()} with an email of ${emailCtrl.text.trim()}',
        'time': FieldValue.serverTimestamp(),
        'dismissed': false,
        'type': 'updates',
        'createdBy': widget.user.email,
      });
    }

    employeeIdCtrl.dispose();
    nameCtrl.dispose();
    emailCtrl.dispose();
  }

  /// ---------------- DELETE USER ----------------
  Future<void> _deleteUser(String docId, Map<String, dynamic> data) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(docId);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Deactivate User"),
        content: Text(
          "Are you sure you want to deactivate ${data['email']}?\n\n"
              "This will archive their info but keep the account slot reusable.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Deactivate", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final userSnap = await userRef.get();
      if (!userSnap.exists) return;

      final userData = userSnap.data()!;

      await FirebaseFirestore.instance
          .collection('archived_users')
          .doc(docId)
          .set({
        ...userData,
        "archivedAt": FieldValue.serverTimestamp(),
        "archivedBy": widget.user.email,
      });

      await userRef.update({
        "status": false,
        "name": "",
        "updatedAt": FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('notifications').add({
        'title': 'Deactivated Account',
        'message':
        'Deactivated account for ${data['email']}. This slot is now available for reuse.',
        'time': FieldValue.serverTimestamp(),
        'dismissed': false,
        'type': 'updates',
        'createdBy': widget.user.email,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
          Text("User ${data['email']} archived and deactivated successfully"),
        ),
      );
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
