import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../SuperAdminScreen/monitor.dart';
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
      MonitorScreen(user: widget.user),
      _buildSettingsScreen(),
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
                  color: Colors.grey.withAlpha(2),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
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
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    'admin',
                    'legal_officer',
                    'driver',
                    'conductor',
                    'inspector',
                  ].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (value) => setState(() => role = value ?? "driver"),
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

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),
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
                return const Text("No users yet.");
              }

              return Column(
                children: snap.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(
                        data['email'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${data['name'] ?? ''} • ${data['role'] ?? ''}',
                      ),
                      trailing: const Icon(Icons.person, color: Color(0xFF0D2364)),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsScreen() {
    return const Center(
      child: Text('Settings Screen', style: TextStyle(fontSize: 24)),
    );
  }

  Future<void> _signOut() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);

    try {
      await AuthService().logout();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign out: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
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
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF0D2364)),
              child: Text(
                'Super Admin Menu',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
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
                  ExpansionTile(
                    leading: const Icon(Icons.people, color: Color(0xFF0D2364)),
                    title: const Text('User Management'),
                    initiallyExpanded: showUserManagementOptions,
                    onExpansionChanged: (expanded) =>
                        setState(() => showUserManagementOptions = expanded),
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person_add, color: Color(0xFF0D2364)),
                        title: const Text('Add Account'),
                        onTap: () {
                          Navigator.pop(context);
                          _onItemTapped(0);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.list, color: Color(0xFF0D2364)),
                        title: const Text('Employee List'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EmployeeListScreen(user: widget.user),
                            ),
                          );
                        },
                      ),
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
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: ListTile(
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
            ),
          ],
        ),
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Monitor'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF0D2364),
        onTap: _onItemTapped,
      ),
    );
  }
}
