import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../Personaldetailed/conductor.dart';
import '../workSchedule/conductor_workschedule.dart';
import '../incidentreport/driver_incidentreport.dart';
import '../ticketreport/conductor_ticketreport.dart';
import '../leaveapplication/driverleaveapp.dart';

class ConductorDashboard extends StatefulWidget {
  final AppUser user;
  const ConductorDashboard({super.key, required this.user});

  @override
  State<ConductorDashboard> createState() => _ConductorDashboardState();
}

class _ConductorDashboardState extends State<ConductorDashboard> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      _buildHomeScreen(),
      const WorkScheduleScreen(),
      const IncidentReportScreen(),
      const TicketReportScreen(),
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
            Container(
              width: double.infinity,
              color: const Color(0xFF0D2364),
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: const Center(
                child: Icon(
                  Icons.directions_bus,
                  size: 60,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),

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
                widget.user.name ?? "Conductor",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),

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
                  "View More",
                  style: TextStyle(
                    color: Color(0xFF0D2364),
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D2364),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      "Passenger Count",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
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
            icon: Icon(Icons.calendar_today),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_problem),
            label: 'Incident',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number),
            label: 'Tickets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.beach_access),
            label: 'Leave',
          ),
        ],
      ),
    );
  }
}

class PlaceholderWidget extends StatelessWidget {
  final String title;
  const PlaceholderWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title feature is coming soon!')),
    );
  }
}
