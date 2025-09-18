import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../SuperAdminScreen/employee_list.dart';
import '../SuperAdminScreen/deactivated_account.dart';
import '../SuperAdminScreen/add_account.dart';
import '../SuperAdminScreen/system_management.dart';

// Main SuperAdminDashboard Class
class SuperAdminDashboard extends StatefulWidget {
  final AppUser user;
  const SuperAdminDashboard({super.key, required this.user});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  int _selectedIndex = 0;
  bool _isLoggingOut = false;

  // For dropdown in drawer
  bool showUserManagementOptions = false;

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [_buildHomeScreen()];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// ---------------- HOME SCREEN ----------------

  IconData _getIconForType(String type) {
    switch (type){
      case 'system':
        return Icons.system_update_alt;
      case 'security':
        return Icons.warning;
      case 'updates':
        return Icons.notifications_on;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'system':
        return Colors.blue;
      case 'security':
        return Colors.red;
      case 'updates':
        return Colors.green;
      default:
        return Color(0xFF0D2364);
    }
  }

  Widget _buildHomeScreen() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notifications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D2364),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
                stream: getNotificationsStream(widget.user.role),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No notifications',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),

                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),

                          leading: Icon(
                              _getIconForType(data['type'] ?? ''),
                              color: _getColorForType(data['type'] ?? ''),
                          ),

                          title: Text(
                            data['title'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),

                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),

                              Text(data['message']),

                              const SizedBox(height: 4),

                              Text(
                                DateFormat('MMM d, y hh:mm a').format((data['time'] as Timestamp).toDate()),

                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),

                          trailing: IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () async {
                              await docs[index].reference.update({'dismissed': true});
                            },
                          ),
                        ),
                      );
                    },
                  );
                })
          ),
        ],
      ),
    );
  }

  /// ---------------- FETCH FOR NOTIFICATION  ----------------
  Stream<QuerySnapshot> getNotificationsStream(String role) {
    final collection = FirebaseFirestore.instance.collection('notifications');

    if (role == 'super_admin' || role == 'admin') {
      // Super_Admin & Admin → See ALL (system + security)
      return collection
          .where('dismissed', isEqualTo: false)
          .orderBy('time', descending: true)
          .snapshots();
    } else {
      // Others → See only system notifications
      return collection
          .where('dismissed', isEqualTo: false)
          .where('type', isEqualTo: 'system')
          .orderBy('time', descending: true)
          .snapshots();
    }
  }

  /// ---------------- SIGN OUT  ----------------
  Future<void> _signOut() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);

    try {
      // show loading for 3 seconds before signing out
      await Future.delayed(const Duration(seconds: 3));
      await AuthService()
          .logout();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to sign out: $e')));
      setState(() => _isLoggingOut = false);
    }
  }

  /// ---------------- SIDEBAR  ----------------
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
              decoration: const BoxDecoration(color: Color(0xFF0D2364)),
              accountName: Text(
                widget.user.name ?? 'Super Admin',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              accountEmail: Text(
                widget.user.email,
                style: const TextStyle(fontSize: 14),
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.admin_panel_settings,
                  color: Color(0xFF0D2364),
                ),
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
                      ListTile(
                        leading: const Icon(
                          Icons.person_add,
                          color: Color(0xFF0D2364),
                        ),
                        title: const Text('Add Account'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AddAccountScreen(user: widget.user),
                            ),
                          );
                        },
                      ),
                      // Employee List
                      ListTile(
                        leading: const Icon(
                          Icons.list,
                          color: Color(0xFF0D2364),
                        ),
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
                      // Deactivated Account
                      ListTile(
                        leading: const Icon(
                          Icons.person_off,
                          color: Color(0xFF0D2364),
                        ),
                        title: const Text('Deactivated Account'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AttendanceScreen(user: widget.user),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  // System Management Button
                  ListTile(
                    leading: const Icon(
                      Icons.settings,
                      color: Color(0xFF0D2364),
                    ),
                    title: const Text('System Management'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SystemManagementScreen(user: widget.user),
                        ),
                      );
                    },
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

  /// ---------------- MANUAL NOTIFICATION  ----------------
  Future<void> createSystemNotification(String title, String message, String role) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(role).get();

    if (userDoc.exists && userDoc['role'] == 'super_admin') {
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': title,
        'message': message,
        'time': FieldValue.serverTimestamp(),
        'dismissed': false,
        'type': 'system',
        'createdBy': role
      });
    } else {
      SnackBar(content: Text('Not authorized to create system notifications'));
    }
  }

  /// ---------------- AUTOMATIC NOTIFICATION  ----------------
  Future<void> addEmployee(String name, String email) async {
    final usersRef = FirebaseFirestore.instance.collection('users');

    // Create employee
    await usersRef.add({
      'name': name,
      'email': email,
      'role': 'employee',
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': name
    });

    // Create system notification
    await FirebaseFirestore.instance.collection('notifications').add({
      'title': 'New Employee Registered',
      'message': '$name has been added to the system',
      'time': FieldValue.serverTimestamp(),
      'dismissed': false,
      'type': 'system',
      'createdBy': 'system',
    });
  }

  /// ---------------- AUTOMATIC SECURITY NOTIFICATION  ----------------
  Future<void> logSecurityWarning(String message) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'title': 'Security Warning',
      'message': message,
      'time': FieldValue.serverTimestamp(),
      'dismissed': false,
      'type': 'security',
      'createdBy': 'system',
    });
  }
