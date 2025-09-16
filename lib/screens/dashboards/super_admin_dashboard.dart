import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../SuperAdminScreen/employee_list.dart';
import '../SuperAdminScreen/attendance.dart';

class SuperAdminDashboard extends StatefulWidget {
  final AppUser user;
  const SuperAdminDashboard({super.key, required this.user});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  int _selectedIndex = 0;
  bool _isLoggingOut = false;

  // Form Controllers
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  String role = "driver";
  bool loading = false;

  // For dropdown in drawer
  bool showUserManagementOptions = false;

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      _buildHomeScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// ---------------- CREATE USER FUNCTION ----------------
  Future<void> _createUser() async {
    if (emailCtrl.text.isEmpty || passCtrl.text.length < 6) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter email and password (6+ chars)")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final newUser = {
        "name": nameCtrl.text.trim(),
        "email": emailCtrl.text.trim(),
        "role": role,
        "createdAt": FieldValue.serverTimestamp(),
        "createdBy": widget.user.email,
      };

      await FirebaseFirestore.instance.collection("users").add(newUser);

      if (!mounted) return; // ✅ prevent invalid context

      nameCtrl.clear();
      emailCtrl.clear();
      passCtrl.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User created successfully")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  /// ---------------- HOME SCREEN ----------------
  Widget _buildHomeScreen() {
    return Padding(
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
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
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
                  items:
                      const [
                        'admin',
                        'legal_officer',
                        'driver',
                        'conductor',
                        'inspector',
                      ].map((String role) {
                        return DropdownMenuItem<String>(
                          value: role,
                          child: Text(role),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      role = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 20),
                loading
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _createUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D2364),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Create User',
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
    );
  }

  Future<void> _signOut() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);

    try {
      // show loading for 3 seconds before signing out
      await Future.delayed(const Duration(seconds: 3));

      await AuthService().logout(); // triggers authStateChanges -> back to login
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign out: $e')),
      );
      setState(() => _isLoggingOut = false); // reset only if error
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Dashboard'),
        backgroundColor: const Color(0xFF0D2364),
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF0D2364)),
              accountName: Text(
                widget.user.name ?? 'Super Admin',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(
                widget.user.email,
                style: TextStyle(fontSize: 14),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.admin_panel_settings, color: Color(0xFF0D2364)),
              ),
            ),

            // Expanded ListView for menu items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(Icons.home, color: Color(0xFF0D2364)),
                    title: const Text('Home'),
                    selected: _selectedIndex == 0,
                    onTap: () {
                      _onItemTapped(0);
                      Navigator.pop(context);
                    },
                  ),
                  // User Management Expansion Tile
                  ExpansionTile(
                    leading: const Icon(Icons.people, color: Color(0xFF0D2364)),
                    title: const Text('User Management'),
                    initiallyExpanded: showUserManagementOptions,
                    onExpansionChanged: (expanded) =>
                        setState(() => showUserManagementOptions = expanded),
                    children: [
                      // Add Account
                      // ListTile(
                      //   leading: const Icon(Icons.person_add, color: Color(0xFF0D2364)),
                      //   title: const Text('Add Account'),
                      //   onTap: () {
                      //     Navigator.pop(context);
                      //     // Navigate to Add Account screen
                      //     Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //         builder: (context) => Scaffold(
                      //           appBar: AppBar(
                      //             title: const Text('Add Account'),
                      //             backgroundColor: const Color(0xFF0D2364),
                      //             foregroundColor: Colors.white,
                      //           ),
                      //           body: _buildAddAccountScreen(),
                      //         ),
                      //       ),
                      //     );
                      //   },
                      // ),
                      // Employee List
                      ListTile(
                        leading: const Icon(Icons.list, color: Color(0xFF0D2364)),
                        title: const Text('Employee List'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EmployeeListScreen(user: widget.user),
                            ),
                          );
                        },
                      ),
                      // Attendance
                      ListTile(
                        leading: const Icon(Icons.check_circle, color: Color(0xFF0D2364)),
                        title: const Text('Attendance'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AttendanceScreen(user: widget.user),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Logout pinned at bottom
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFF0D2364)),
              title: Text(
                _isLoggingOut ? 'Logging out...' : 'Logout',
                style: const TextStyle(color: Color(0xFF0D2364)),
              ),
              trailing: _isLoggingOut
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : null,
              onTap: _isLoggingOut ? null : _signOut,
            ),
            const SizedBox(height: 12), // spacing at bottom
          ],
        ),
      ),
      body: _screens[_selectedIndex],
    );
  }
}
