import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../firebase_options.dart';
import '../../models/app_user.dart';
import '../SuperAdminScreen/monitor.dart';
import '../SuperAdminScreen/employee_list.dart';
import '../SuperAdminScreen/attendance.dart';
import '../SuperAdminScreen/leave_management.dart';

class SuperAdminDashboard extends StatefulWidget {
  final AppUser user;
  const SuperAdminDashboard({super.key, required this.user});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  String role = 'driver';
  bool loading = false;
  int _selectedIndex = 0;

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _screens.add(_buildHomeScreen());
    _screens.add(MonitorScreen(user: widget.user));
    _screens.add(_buildSettingsScreen());
  }

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
      setState(() => role);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('User created as $role')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildHomeScreen() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          const Text(
            'Create User',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D2364),
            ),
          ),
          const SizedBox(height: 12),
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
              'legalofficer',
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
                  label: const Text('Create User'),
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
                return const Text('No users yet.');
              }
              return Column(
                children: snap.data!.docs.map((d) {
                  final data = d.data() as Map<String, dynamic>;
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
                      trailing: const Icon(
                        Icons.person,
                        color: Color(0xFF0D2364),
                      ),
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
    try {
      await FirebaseAuth.instance.signOut();
      // Navigate to login screen or root
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Dashboard'),
        backgroundColor: const Color(0xFF0D2364),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const DrawerHeader(
                    decoration: BoxDecoration(color: Color(0xFF0D2364)),
                    child: Text(
                      'Super Admin Menu',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.home, color: Color(0xFF0D2364)),
                    title: const Text('Home'),
                    selected: _selectedIndex == 0,
                    onTap: () {
                      _onItemTapped(0);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.people, color: Color(0xFF0D2364)),
                    title: const Text('Employee List'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EmployeeListScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.check_circle,
                      color: Color(0xFF0D2364),
                    ),
                    title: const Text('Attendance'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AttendanceScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.event_busy,
                      color: Color(0xFF0D2364),
                    ),
                    title: const Text('Leave Management'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LeaveManagementScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.route, color: Colors.blue),
                    title: const Text('Route Playback'),
                    onTap: () {
                      Navigator.pop(context);
                      //Route Playback screen
                    },
                  ),
                ],
              ),
            ),
            // Logout button at the bottom with spacing
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Color(0xFF0D2364)),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Color(0xFF0D2364)),
                ),
                onTap: _signOut,
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
        selectedItemColor: Color(0xFF0D2364),
        onTap: _onItemTapped,
      ),
    );
  }
}
