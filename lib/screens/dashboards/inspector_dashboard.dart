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
      body: Column(
        children: [
          // JeepEZ Header with full width blue background
          Container(
            width: double.infinity,
            color: const Color(0xFF0D2364),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.directions_bus, size: 32, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  'JeepEZ',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // User Profile Section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                // Make the person icon clickable
                IconButton(
                  icon: const Icon(Icons.person, size: 50, color: Colors.black),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PersonalDetails(user: widget.user),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  widget.user.name ?? 'Ashanti Dadivo',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Date Container
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

          // Route Preview Map Placeholder
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
        ],
      ),
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
