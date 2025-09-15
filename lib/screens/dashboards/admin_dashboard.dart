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
        color: _selectedIndex == index
            ? const Color(0xFF0D2364)
            : const Color(0xFF0D2364),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: _selectedIndex == index
              ? FontWeight.bold
              : FontWeight.normal,
          color: _selectedIndex == index
              ? const Color(0xFF0D2364)
              : Colors.black87,
        ),
      ),
      selected: _selectedIndex == index,
      selectedTileColor: const Color(0xFF0D2364),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome, Admin',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Dashboard Overview',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Moved grid calculation to build method to avoid MediaQuery error
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;

              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  StatCard(
                    icon: Icons.people,
                    value: '50',
                    label: 'Employees',
                    description: 'Total active employees',
                  ),
                  StatCard(
                    icon: Icons.calendar_today,
                    value: '98%',
                    label: 'Attendance',
                    description: 'Today\'s attendance rate',
                  ),
                  StatCard(
                    icon: Icons.event_busy,
                    value: '8',
                    label: 'Leave Requests',
                    description: 'Pending approval',
                  ),
                  StatCard(
                    icon: Icons.work,
                    value: '5',
                    label: 'Open Positions',
                    description: 'Currently hiring',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          const RecentActivity(),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String description;

  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: const Color(0xFF0D2364)),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class RecentActivity extends StatelessWidget {
  const RecentActivity({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildActivityItem(
              Icons.person_add,
              'New employee added',
              'John Doe joined the team',
            ),
            _buildActivityItem(
              Icons.description,
              'Leave request submitted',
              'Jane Smith requested time off',
            ),
            _buildActivityItem(
              Icons.check_circle,
              'Attendance marked',
              '95% of employees checked in today',
            ),
            _buildActivityItem(
              Icons.directions,
              'Route completed',
              'Delivery route #245 finished',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: const Color(0xFF0D2364), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
