import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';
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
  String role = 'driver';
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee List Management'),
        backgroundColor: const Color(0xFF1565C0),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ---------------- FORM ----------------
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: passCtrl,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: role,
              items: const [
                'admin',
                'legal_officer',
                'driver',
                'conductor',
                'inspector',
              ].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (v) => setState(() => role = v ?? 'driver'),
              decoration: const InputDecoration(labelText: 'Role'),
            ),
            const SizedBox(height: 16),
            loading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
              onPressed: _createUser,
              icon: const Icon(Icons.person_add),
              label: const Text('Add Account'),
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),

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

                final employeeDocs = snap.data!.docs;

                // ✅ Wrap DataTable in horizontal scroll
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 16,
                    headingRowColor:
                    WidgetStateProperty.all(Colors.blue[50]),
                    columns: const [
                      DataColumn(label: Text("Name")),
                      DataColumn(label: Text("Email")),
                      DataColumn(label: Text("Role")),
                      DataColumn(label: Text("Actions")),
                    ],
                    rows: employeeDocs.map((d) {
                      final data = d.data() as Map<String, dynamic>;

                      return DataRow(cells: [
                        DataCell(Text(data['name'] ?? '')),
                        DataCell(Text(data['email'] ?? '')),
                        DataCell(Text(data['role'] ?? '')),
                        DataCell(Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editUser(d.id, data),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteUser(d.id, data),
                            ),
                          ],
                        )),
                      ]);
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

  /// ---------------- CREATE USER ----------------
  Future<FirebaseApp> _getOrCreateSecondaryApp() async {
    try {
      return Firebase.app('adminSecondary');
    } catch (_) {
      return await Firebase.initializeApp(
        name: 'adminSecondary',
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }

  Future<void> _createUser() async {
    if (emailCtrl.text.trim().isEmpty || passCtrl.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter email and 6+ char password')),
      );
      return;
    }

    setState(() => loading = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final secondaryApp = await _getOrCreateSecondaryApp();
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final newCred = await secondaryAuth.createUserWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
      );

      final newUid = newCred.user!.uid;
      await FirebaseFirestore.instance.collection('users').doc(newUid).set({
        'uid': newUid,
        'email': emailCtrl.text.trim(),
        'name': nameCtrl.text.trim(),
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': widget.user.email,
      });

      await secondaryAuth.signOut();

      emailCtrl.clear();
      passCtrl.clear();
      nameCtrl.clear();

      messenger.showSnackBar(
        SnackBar(content: Text('User created as $role')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  /// ---------------- UPDATE USER ----------------
  Future<void> _editUser(String docId, Map<String, dynamic> data) async {
    final nameCtrl = TextEditingController(text: data['name']);
    String role = data['role'] ?? "driver";

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
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: role,
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('admin')),
                  DropdownMenuItem(value: 'legal_officer', child: Text('legal_officer')),
                  DropdownMenuItem(value: 'driver', child: Text('driver')),
                  DropdownMenuItem(value: 'conductor', child: Text('conductor')),
                  DropdownMenuItem(value: 'inspector', child: Text('inspector')),
                ],
                onChanged: (v) => setState(() => role = v ?? 'driver'),
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
        "name": nameCtrl.text.trim(),
        "role": role,
      });
    }
  }

  /// ---------------- DELETE USER ----------------
  Future<void> _deleteUser(String docId, Map<String, dynamic> data) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete User"),
        content: Text("Are you sure you want to delete ${data['email']}?"),
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
      await FirebaseFirestore.instance.collection('users').doc(docId).delete();
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
