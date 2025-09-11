import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../Personaldetailed/driver.dart'; // Import the PersonalDetails screen
import '../inspectorreportform/inspector_RForm.dart';
import '../inspectortrip/inspector_trip_report.dart';

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
      _placeholder('Schedule'),
      _buildTripScreen(),
      _buildInspectorReportScreen(),
      _placeholder('Leave'),
    ];
  }

  Widget _buildHomeScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            color: const Color(0xFF0D2364),
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                const Icon(Icons.directions_bus, size: 40, color: Colors.white),
                const SizedBox(height: 8),
                const Text(
                  'JeepEZ',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
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
              ),
            ),
          ),
          const SizedBox(height: 20),
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
    return const InspectorTripReportScreen();
  }

  Widget _buildInspectorReportScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Violations')),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.assignment),
          label: const Text('Open Report/Remarks'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const InspectorReportScreen(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _placeholder(String title) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title screen coming soon')),
    );
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
