import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../admin/employeelist.dart';
import '../admin/attendance_record.dart';
import '../admin/leavemanagement.dart';
import '../admin/hiringmanagement.dart';
import 'dart:developer';

class AdminDashboard extends StatefulWidget {
  final AppUser user;
  const AdminDashboard({super.key, required this.user});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _screens.add(_buildHomeScreen());
    _screens.add(const EmployeeListScreen());
    _screens.add(const AttendanceScreen());
    _screens.add(const LeaveManagementScreen());
    _screens.add(_buildRoutePlaybackScreen());
    _screens.add(const HiringManagementScreen());
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildHomeScreen() {
    return const HomeScreen();
  }

  Widget _buildRoutePlaybackScreen() {
    return const Center(
      child: Text('Route Playback Screen', style: TextStyle(fontSize: 24)),
    );
  }

  // Add this missing method
  Future<void> _signOut() async {
    try {
      // Navigate to login screen or root
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } catch (e) {
      log('Error signing out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: const Color(0xFF0D2364),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF0D2364)),
              child: Center(
                child: Text(
                  'ADMIN MENU',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildMenuListItem(Icons.home, 'Home', 0),
                  _buildMenuListItem(Icons.people, 'Employee List', 1),
                  _buildMenuListItem(Icons.calendar_today, 'Attendance', 2),
                  _buildMenuListItem(Icons.event_busy, 'Leave Management', 3),
                  _buildMenuListItem(Icons.directions, 'Route Playback', 4),
                  _buildMenuListItem(Icons.work, 'Hiring Management', 5),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: _signOut,
              ),
            ),
          ],
        ),
      ),
      body: _screens[_selectedIndex],
    );
  }

  Widget _buildMenuListItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.black87, // Changed to always use the same color
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black87, // Changed to always use the same color
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        _onItemTapped(index);
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Welcome to Admin Dashboard', style: TextStyle(fontSize: 24)),
    );
  }
}
