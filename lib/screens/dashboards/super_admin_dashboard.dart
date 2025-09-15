import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
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
  int _selectedIndex = 0;
  bool _isLoggingOut = false;

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _screens.add(_buildHomeScreen());
    _screens.add(MonitorScreen(user: widget.user));
    _screens.add(_buildSettingsScreen());
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
      await Future.delayed(const Duration(milliseconds: 3000));

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
                          builder: (context) => EmployeeListScreen(user: widget.user),
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
                          builder: (context) => AttendanceScreen(user: widget.user),
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
                          builder: (context) => LeaveManagementScreen(user: widget.user),
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
        selectedItemColor: Color(0xFF0D2364),
        onTap: _onItemTapped,
      ),
    );
  }
}
