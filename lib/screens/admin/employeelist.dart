import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../firebase_options.dart';
import '../../models/app_user.dart';

class EmployeeListScreen extends StatefulWidget {
  final AppUser user;
  const EmployeeListScreen({super.key, required this.user});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  /// ----------- GET AND CREATE SECONDARY FUNCTION -----------
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

      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              // ---------------- SEARCH BAR ----------------
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withAlpha(40),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search employees...',
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 12.0,
                        horizontal: 16.0,
                      ),
                    ),
                    onChanged: (_) {
                      setState(() {}); // rebuild when typing
                    },
                  ),
                ),
              ),

              // ---------------- LIST ----------------
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    width: constraints.maxWidth,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withAlpha(30),
                          spreadRadius: 2,
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (!snap.hasData || snap.data!.docs.isEmpty) {
                          return const Center(child: Text('No users yet.'));
                        }

                        // get docs
                        var employeeDocs = snap.data!.docs.where((d) {
                          final data = d.data() as Map<String, dynamic>;
                          return data['status'] == true;
                        }).toList();

                        // apply search filter
                        final query = searchController.text.toLowerCase();
                        if (query.isNotEmpty) {
                          employeeDocs = employeeDocs.where((d) {
                            final data = d.data() as Map<String, dynamic>;
                            final name = (data['name'] ?? '')
                                .toString()
                                .toLowerCase();
                            final email = (data['email'] ?? '')
                                .toString()
                                .toLowerCase();
                            final empId = (data['employeeId'] ?? '')
                                .toString()
                                .toLowerCase();
                            return name.contains(query) ||
                                email.contains(query) ||
                                empId.contains(query);
                          }).toList();
                        }

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columnSpacing: 20,
                            headingRowColor: WidgetStateProperty.all(
                              const Color(0xFFF5F7FA),
                            ),
                            columns: const [
                              DataColumn(label: Text("Employee ID")),
                              DataColumn(label: Text("Employee Name")),
                              DataColumn(label: Text("Status")),
                              DataColumn(label: Text("Email")),
                              DataColumn(label: Text("Role")),
                              DataColumn(label: Text("Actions")),
                            ],
                            rows: employeeDocs.map((d) {
                              final data = d.data() as Map<String, dynamic>;

                              return DataRow(
                                cells: [
                                  DataCell(Text(data['employeeId'].toString())),
                                  DataCell(Text(data['name'] ?? '')),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: data['status'] == true
                                            ? Colors.green.withAlpha(1)
                                            : Colors.red.withAlpha(1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
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
                                  ),
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
                                          onPressed: () =>
                                              _editUser(d.id, data),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () =>
                                              _deleteUser(d.id, data),
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
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),

      // ---------------- ADD BUTTON ----------------
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        backgroundColor: const Color(0xFF0D2364),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// ---------------- ADD NEW USER ----------------
  Future<void> _showAddUserDialog() async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final employeeIdCtrl = TextEditingController();
    String role = "conductor";
    String? employmentType;
    bool loading = false;

    // Move helper outside async gaps (no underscore inside method)
    Future<String> generateEmployeeId(String role) async {
      final Map<String, String> rolePrefixes = {
        'legal_officer': '20',
        'driver': '30',
        'conductor': '40',
        'inspector': '50',
      };

      final prefix = rolePrefixes[role] ?? '99';

      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('employeeId', isGreaterThanOrEqualTo: prefix)
          .where('employeeId', isLessThan: '${prefix}999999')
          .orderBy('employeeId', descending: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return '${prefix}001';
      } else {
        final lastId = query.docs.first['employeeId'] as String;
        final lastNum = int.tryParse(lastId) ?? int.parse('${prefix}000');
        return (lastNum + 1).toString().padLeft(5, '0');
      }
    }

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Add New User"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: "Full Name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: "Password",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: employeeIdCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: "Employee ID (auto-generated)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: role,
                      items: const [
                        DropdownMenuItem(
                          value: "legal_officer",
                          child: Text("Legal Officer"),
                        ),
                        DropdownMenuItem(
                          value: "driver",
                          child: Text("Driver"),
                        ),
                        DropdownMenuItem(
                          value: "conductor",
                          child: Text("Conductor"),
                        ),
                        DropdownMenuItem(
                          value: "inspector",
                          child: Text("Inspector"),
                        ),
                      ],
                      onChanged: (value) async {
                        if (value != null) {
                          final newId = await generateEmployeeId(value);
                          setState(() {
                            role = value;
                            employeeIdCtrl.text = newId;
                            employmentType = null;
                          });
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: "Role",
                        border: OutlineInputBorder(),
                      ),
                    ),

                    if (role == "driver" ||
                        role == "conductor" ||
                        role == "inspector") ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: employmentType,
                        items: const [
                          DropdownMenuItem(
                            value: "full_time",
                            child: Text("Full-Time"),
                          ),
                          DropdownMenuItem(
                            value: "part_time",
                            child: Text("Part-Time"),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            employmentType = value;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: "Employment Type",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                          if (emailCtrl.text.isEmpty ||
                              passCtrl.text.length < 8) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Enter email and 8+ char password",
                                  ),
                                ),
                              );
                            }
                            return;
                          }

                          if (employeeIdCtrl.text.isEmpty) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Employee ID not generated"),
                                ),
                              );
                            }
                            return;
                          }

                          setState(() => loading = true);

                          try {
                            final secondaryApp = await _getOrCreateSecondaryApp();
                            final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

                            final email = emailCtrl.text.trim();
                            final password = passCtrl.text.trim();
                            final employeeId = employeeIdCtrl.text.trim();

                            final newCred = await secondaryAuth.createUserWithEmailAndPassword(
                              email: email,
                              password: password,
                            );
                            final newUid = newCred.user!.uid;

                            final newUser = {
                              'uid': newUid,
                              "employeeId": employeeId,
                              "name": nameCtrl.text.trim(),
                              "email": emailCtrl.text.trim(),
                              "role": role,
                              "status": true,
                              if (employmentType != null)
                                "employmentType": employmentType,
                              "createdAt": FieldValue.serverTimestamp(),
                              "createdBy": widget.user.email,
                            };

                            await FirebaseFirestore.instance
                                .collection("users")
                                .doc(newUid)
                                .set(newUser);

                            await FirebaseFirestore.instance
                                .collection("notifications")
                                .add({
                                  "title": "New Account",
                                  "message":
                                  "Added account for ${nameCtrl.text.trim()} as $role",
                                  "time": FieldValue.serverTimestamp(),
                                  "dismissed": false,
                                  "type": "updates",
                                  "createdBy": widget.user.email,
                                });

                            await secondaryAuth.signOut();

                            final createdRole = role;

                            emailCtrl.clear();
                            passCtrl.clear();
                            nameCtrl.clear();
                            employeeIdCtrl.clear();
                            if (mounted) {
                              setState(() => role = 'conductor');
                            }

                            if (context.mounted) {
                              Navigator.pop(dialogCtx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('User created as $createdRole with ID $employeeId'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error: $e")),
                              );
                            }
                          } finally {
                            setState(() => loading = false);
                          }
                        },
                  child: loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Create"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// ---------------- UPDATE USER ----------------
  Future<void> _editUser(String docId, Map<String, dynamic> data) async {
    final nameCtrl = TextEditingController(text: data['name']);
    final emailCtrl = TextEditingController(text: data['email']);

    String? employmentType = data['employmentType'];
    final String role = data['role'] ?? '';

    final updated = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update User"),
        content: SingleChildScrollView(
          child: Column(
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
              if (role == 'driver' || role == 'conductor' || role == 'inspector')
                DropdownButtonFormField<String>(
                  value: employmentType,
                  items: const [
                    DropdownMenuItem(value: "full_time", child: Text("Full-Time")),
                    DropdownMenuItem(value: "part_time", child: Text("Part-Time")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      employmentType = value;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: "Employment Type",
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Update"),
          ),
        ],
      ),
    );

    if (updated == true) {
      final updateData = {
        "name": nameCtrl.text.trim(),
        "email": emailCtrl.text.trim(),
        "updatedAt": FieldValue.serverTimestamp(),
      };

      if (role == 'driver' || role == 'conductor' || role == 'inspector') {
        updateData["employmentType"] = (employmentType as Object?)!;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(docId) // ✅ FIXED HERE
          .update(updateData);

      await FirebaseFirestore.instance.collection('notifications').add({
        'title': 'Updated Account',
        'message': 'Updated account for ${nameCtrl.text.trim()}',
        'time': FieldValue.serverTimestamp(),
        'dismissed': false,
        'type': 'updates',
        'createdBy': widget.user.email,
      });
    }

    nameCtrl.dispose();
    emailCtrl.dispose();
  }

  /// ---------------- DELETE USER ----------------
  Future<void> _deleteUser(String docId, Map<String, dynamic> data) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Deactivate User"),
        content: Text(
          "Deactivate ${data['email']}? This will archive and free the slot.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Deactivate",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final userRef = FirebaseFirestore.instance.collection('users').doc(docId);
      final snap = await userRef.get();
      if (!snap.exists) return;

      final userData = snap.data()!;

      // Archive the user
      await FirebaseFirestore.instance
          .collection('archived_users')
          .doc(docId)
          .set({
            ...userData,
            "archivedAt": FieldValue.serverTimestamp(),
            "archivedBy": widget.user.email,
            "status": false,
          });

      // Update the original user record to reflect deactivation
      await userRef.update({
        "status": false,
        "updatedAt": FieldValue.serverTimestamp(),
      });

      // Create a notification
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': 'Deactivated Account',
        'message': 'Deactivated account for ${data['email']}',
        'time': FieldValue.serverTimestamp(),
        'dismissed': false,
        'type': 'updates',
        'createdBy': widget.user.email,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("User ${data['email']} deactivated successfully"),
        ),
      );
    }
  }
}
