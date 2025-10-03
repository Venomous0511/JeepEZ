import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/app_user.dart';
import '../Personaldetailed/conductor.dart';
import '../workSchedule/conductor_workschedule.dart';
import '../ticketreport/conductor_ticketreport.dart';
import '../incidentreport/conductor_incidentreport.dart';
import '../leaveapplication/conductorleaveapp.dart';

class ConductorDashboard extends StatefulWidget {
  final AppUser user;
  const ConductorDashboard({super.key, required this.user});

  @override
  State<ConductorDashboard> createState() => _ConductorDashboardState();
}

class _ConductorDashboardState extends State<ConductorDashboard> {
  int _currentIndex = 0;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize screens here where context is available
    _screens = [
      _buildHomeScreen(),
      const WorkScheduleScreen(),
      const TicketReportScreen(),
      const IncidentReportScreen(),
      const LeaveApplicationScreen(),
    ];
  }

  /// ---------------- FETCH NOTIFICATIONS ----------------
  Stream<QuerySnapshot<Map<String, dynamic>>> getNotificationsStream(
    String role,
  ) {
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

  /// ---------------- ICON TYPE ----------------
  IconData _getIconForType(String type) {
    switch (type) {
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

  /// ---------------- COLOR TYPE ----------------
  Color _getColorForType(String type) {
    switch (type) {
      case 'system':
        return Colors.blue;
      case 'security':
        return Colors.red;
      case 'updates':
        return Colors.green;
      default:
        return const Color(0xFF0D2364);
    }
  }

  Widget _buildHomeScreen() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo section at the top
              Container(
                width: double.infinity,
                color: const Color(0xFF0D2364),
                padding: EdgeInsets.symmetric(vertical: isMobile ? 20 : 30),
                child: const Center(
                  child: Icon(
                    Icons.directions_bus,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: isMobile ? 20 : 30),

              // Profile Section with notification
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16.0 : 24.0,
                ),
                child: Row(
                  children: [
                    // Person Icon (clickable)
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PersonalDetails(user: widget.user),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D2364).withAlpha(1),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Icon(
                          Icons.person,
                          color: const Color(0xFF0D2364),
                          size: isMobile ? 40 : 50,
                        ),
                      ),
                    ),
                    SizedBox(width: isMobile ? 12 : 16),

                    // Name and Employee ID
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.user.name ?? "Conductor",
                            style: TextStyle(
                              fontSize: isMobile ? 18 : 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Employee ID: ${widget.user.employeeId}",
                            style: TextStyle(
                              fontSize: isMobile ? 13 : 15,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Notification Icon
                    IconButton(
                      icon: Icon(
                        Icons.notifications_outlined,
                        color: const Color(0xFF0D2364),
                        size: isMobile ? 28 : 32,
                      ),
                      onPressed: () {
                        _showNotifications();
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: isMobile ? 24 : 32),

              // Welcome message instead of tracking status
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16.0 : 24.0,
                  ),
                  child: Text(
                    '👋 Welcome, ${widget.user.name ?? "Conductor"}!',
                    style: const TextStyle(fontSize: 16, color: Colors.green),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // View More Button
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16.0 : 24.0,
                ),
                child: InkWell(
                  onTap: () {
                    // Add navigation or action here
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isMobile ? 16 : 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF0D2364),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "View More",
                          style: TextStyle(
                            color: const Color(0xFF0D2364),
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Color(0xFF0D2364),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: isMobile ? 16 : 20),

              // Time Logs Card
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16.0 : 24.0,
                ),
                child: InkWell(
                  onTap: () {
                    // Add navigation to time logs
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isMobile ? 16 : 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D2364),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: Colors.white,
                          size: isMobile ? 24 : 28,
                        ),
                        SizedBox(width: isMobile ? 12 : 16),
                        Text(
                          "Time Logs",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: isMobile ? 24 : 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 600;

        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.notifications, color: Color(0xFF0D2364)),
              const SizedBox(width: 8),
              Text(
                'Notifications',
                style: TextStyle(fontSize: isMobile ? 16 : 18),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: getNotificationsStream(widget.user.role),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Text('Failed to load notifications.');
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Text('No new notifications');
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final title = data['title'] ?? 'No title';
                    final message = data['message'] ?? '';
                    final type = data['type'] ?? 'system';

                    return ListTile(
                      leading: Icon(
                        _getIconForType(type),
                        color: _getColorForType(type),
                      ),
                      title: Text(title),
                      subtitle: Text(message),
                    );
                  },
                );
              },
            ),
          ),
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

  @override
  Widget build(BuildContext context) {
    // Check if screens are initialized, if not show loading
    if (_screens.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0D2364),
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number),
            label: 'Ticket Report',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_problem),
            label: 'Incident',
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
