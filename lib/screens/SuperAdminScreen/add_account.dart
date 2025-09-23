import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';
import '../../models/app_user.dart';

class AddAccountScreen extends StatefulWidget {
  final AppUser user;
  const AddAccountScreen({super.key, required this.user});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController employeeIDCtrl = TextEditingController();

  bool loading = false;
  String role = "conductor";

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

  /// ----------- GENERATE EMPLOYEE ID FUNCTION -----------
  Future<String> _generateEmployeeId(String role) async {
    final Map<String, String> rolePrefixes = {
      'admin': '10',
      'legal_officer': '20',
      'driver': '30',
      'conductor': '40',
      'inspector': '50',
    };

    final prefix = rolePrefixes[role] ?? '99';

    // Find the last employee_id with this prefix
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('employeeId', isGreaterThanOrEqualTo: prefix)
        .where('employeeId', isLessThan: '${prefix}999999')
        .orderBy('employeeId', descending: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      // First ID for this role
      return '${prefix}001';
    } else {
      final lastId = query.docs.first['employeeId'] as String;
      final lastNum = int.tryParse(lastId) ?? int.parse('${prefix}000');
      return (lastNum + 1).toString().padLeft(5, '0');
    }
  }

  /// ----------- Called when role changes -----------
  Future<void> _updateEmployeeId(String newRole) async {
    final newId = await _generateEmployeeId(newRole);
    setState(() {
      role = newRole;
      employeeIDCtrl.text = newId;
    });
  }

  /// ----------- CREATE FUNCTION -----------
  Future<void> _createUser() async {
    if (emailCtrl.text.trim().isEmpty || passCtrl.text.trim().length < 8) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter email and 8+ char password')),
        );
      }
      return;
    }

    if (employeeIDCtrl.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Employee ID not generated')),
        );
      }
      return;
    }

    setState(() => loading = true);

    try {
      final email = emailCtrl.text.trim();
      final password = passCtrl.text.trim();
      final employeeId = employeeIDCtrl.text.trim();

      // Create User In Secondary Auth Instance
      final secondaryApp = await _getOrCreateSecondaryApp();
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final newCred = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final newUid = newCred.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(newUid).set({
        'uid': newUid,
        'email': email,
        'employeeId': employeeId,
        'name': nameCtrl.text.trim(),
        'employment_type'
                'role':
            role,
        'status': true,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': widget.user.email,
      });

      await FirebaseFirestore.instance.collection('notifications').add({
        'title': 'New Account Created',
        'message': '${nameCtrl.text.trim()} has been added as $role',
        'time': FieldValue.serverTimestamp(),
        'dismissed': false,
        'type': 'updates',
        'createdBy': widget.user.email,
      });

      await secondaryAuth.signOut();

      final createdRole = role;

      emailCtrl.clear();
      passCtrl.clear();
      nameCtrl.clear();
      employeeIDCtrl.clear();
      if (mounted) {
        setState(() => role = 'conductor');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User created as $createdRole with ID $employeeId'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Generate initial ID for default role
    _updateEmployeeId(role);
  }

  /// ----------- SCREEN VIEW -----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Account'),
        backgroundColor: const Color(0xFF0D2364),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // Bordered Create User Form with Box Shadow
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(128),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.grey.withAlpha(128),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create User',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D2364),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: employeeIDCtrl,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Employee ID (auto-generated)',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: role,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: "admin", child: Text("Admin")),
                      DropdownMenuItem(
                        value: "legal_officer",
                        child: Text("Legal Officer"),
                      ),
                      DropdownMenuItem(value: "driver", child: Text("Driver")),
                      DropdownMenuItem(
                        value: "conductor",
                        child: Text("Conductor"),
                      ),
                      DropdownMenuItem(
                        value: "inspector",
                        child: Text("Inspector"),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        _updateEmployeeId(value);
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity, // full width
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D2364),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: loading ? null : _createUser,
                      child: loading
                          ? const CircularProgressIndicator()
                          : const Text(
                              "Create User",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
