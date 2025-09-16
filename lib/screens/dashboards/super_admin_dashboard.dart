import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../SuperAdminScreen/employee_list.dart';
import '../SuperAdminScreen/attendance.dart';
import '../SuperAdminScreen/add_account.dart';

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
    _screens = [
      _buildHomeScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// ---------------- HOME SCREEN ----------------
  Widget _buildHomeScreen() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [

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
                          // Navigate to Add Account screen
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
                      // Attendance
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
                              builder: (context) =>
                                  AttendanceScreen(user: widget.user),
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
      // Tinanggal na ang BottomNavigationBar
    );
  }
}
