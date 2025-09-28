import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../Personaldetailed/driver.dart';
import '../violationReport/inspector_violation_report.dart';
import '../inspectorTrip/inspector_trip_report.dart';
import '../workSchedule/inspector.dart';
import '../leaveapplication/inspector_leaveapp.dart';

class InspectorDashboard extends StatefulWidget {
  final AppUser user;
  const InspectorDashboard({super.key, required this.user});

  @override
  State<InspectorDashboard> createState() => _InspectorDashboardState();
}

class _InspectorDashboardState extends State<InspectorDashboard> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      _buildHomeScreen(),
      const WorkScheduleScreen(),
      _buildTripScreen(),
      _buildViolationReportForm(),
      const LeaveApplicationScreen(),
    ];
  }

  Widget _buildHomeScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo section with notification bell - same design as driver dashboard but with bell
            Container(
              width: double.infinity,
              color: const Color(0xFF0D2364),
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(
                      Icons.directions_bus,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  Positioned(
                    right: 20,
                    top: 0,
                    bottom: 0,
                    child: IconButton(
                      icon: const Icon(
                        Icons.notifications,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: () {
                        // Add notification functionality here
                        _showNotifications();
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // User Profile Section - maintained from original inspector dashboard
            Center(
              child: IconButton(
                icon: const Icon(Icons.person, color: Colors.black, size: 40),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PersonalDetails(user: widget.user),
                    ),
                  );
                },
              ),
            ),
            Center(
              child: Text(
                widget.user.name ?? 'Ashanti Dadivo',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Date Container - maintained from original inspector dashboard
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D2364),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Today | Monday | 06/06/06',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Route Preview Map Placeholder - maintained from original inspector dashboard
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Route Preview (Map Placeholder)',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  void _showNotifications() {
    // Temporary notification dialog - you can replace this with your actual notification screen
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Notifications'),
          content: const Text('No new notifications'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTripScreen() {
    return InspectorTripScreen();
  }

  Widget _buildViolationReportForm() {
    return ViolationReportForm();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_walk),
            label: 'Trip',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning),
            label: 'Violations',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.event_busy), label: 'Leave'),
        ],
      ),
    );
  }
}
