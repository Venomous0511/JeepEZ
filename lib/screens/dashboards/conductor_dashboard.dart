import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
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

  int latestPassengerCount = 0;
  String latestTripTime = '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _screens = [];
    _fetchLatestPassengerCount();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screens = [
      _buildHomeScreen(),
      const WorkScheduleScreen(),
      TicketReportScreen(),
      const IncidentReportScreen(),
      const LeaveApplicationScreen(),
    ];
  }

  // ----------------- FETCH PASSENGER COUNT -----------------
  Future<void> _fetchLatestPassengerCount() async {
    dynamic assignedVehicle = widget.user.assignedVehicle;
    int vehicleNumber;

    if (assignedVehicle is int) {
      vehicleNumber = assignedVehicle;
    } else if (assignedVehicle is String) {
      vehicleNumber = int.tryParse(assignedVehicle) ?? 0;
    } else {
      vehicleNumber = 0;
    }

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('inspector_trip')
          .where('unitNumber', isEqualTo: vehicleNumber.toString())
          .where('conductorName', isEqualTo: widget.user.name?.trim())
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .where('timestamp', isLessThanOrEqualTo: endOfDay)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty && mounted) {
        final data = snapshot.docs.first.data();
        final timestamp = data['timestamp'] as Timestamp?;

        setState(() {
          latestPassengerCount =
              int.tryParse(data['noOfPass']?.toString() ?? '0') ?? 0;
          latestTripTime = timestamp != null
              ? "${timestamp.toDate().hour % 12 == 0 ? 12 : timestamp.toDate().hour % 12}:${timestamp.toDate().minute.toString().padLeft(2, '0')} ${timestamp.toDate().hour >= 12 ? 'PM' : 'AM'}"
              : '';
        });
      }
    } catch (e) {
      debugPrint('Error fetching latest passenger count: $e');
    }
  }

  // ----------------- STREAM FOR LIVE PASSENGER COUNT -----------------
  Stream<DocumentSnapshot<Map<String, dynamic>>?> latestTripStream() {
    dynamic assignedVehicle = widget.user.assignedVehicle;
    int vehicleNumber;

    if (assignedVehicle is int) {
      vehicleNumber = assignedVehicle;
    } else if (assignedVehicle is String) {
      vehicleNumber = int.tryParse(assignedVehicle) ?? 0;
    } else {
      vehicleNumber = 0;
    }
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return FirebaseFirestore.instance
        .collection('inspector_trip')
        .where('unitNumber', isEqualTo: vehicleNumber.toString())
        .where('conductorName', isEqualTo: widget.user.name?.trim())
        .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
        .where('timestamp', isLessThanOrEqualTo: endOfDay)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.isNotEmpty ? snapshot.docs.first : null,
        );
  }

  // ----------------- NOTIFICATIONS -----------------
  Stream<QuerySnapshot<Map<String, dynamic>>> getNotificationsStream(
    String role,
  ) {
    final collection = FirebaseFirestore.instance.collection('notifications');
    if (role == 'super_admin' || role == 'admin') {
      return collection
          .where('dismissed', isEqualTo: false)
          .orderBy('time', descending: true)
          .snapshots();
    }
    return collection
        .where('dismissed', isEqualTo: false)
        .where('type', isEqualTo: 'system')
        .orderBy('time', descending: true)
        .snapshots();
  }

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

  // ----------------- HOME SCREEN -----------------
  Widget _buildHomeScreen() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final now = DateTime.now();
    final dayOfWeek = DateFormat('EEEE').format(now);
    final formattedDate = DateFormat('MM/dd/yy').format(now);

    final todayString = 'Today | $dayOfWeek | $formattedDate';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo - UPDATED WITH YOUR SPECIFIC JPG FILE
              Container(
                width: double.infinity,
                color: const Color(0xFF0D2364),
                padding: EdgeInsets.symmetric(vertical: isMobile ? 20 : 30),
                child: Column(
                  children: [
                    // Your specific logo file
                    Image.asset(
                      'assets/images/a47c2721-58f7-4dc7-a395-082ab4b753e0.jpg',
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback if image fails to load
                        return Column(
                          children: [
                            Icon(
                              Icons.directions_bus,
                              size: 60,
                              color: Colors.white,
                            ),
                            SizedBox(height: 5),
                            Text(
                              'JeepEZ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
              SizedBox(height: isMobile ? 20 : 30),

              // Profile & Notifications
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PersonalDetails(user: widget.user),
                        ),
                      ),
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
                    IconButton(
                      icon: Icon(
                        Icons.notifications_outlined,
                        color: const Color(0xFF0D2364),
                        size: isMobile ? 28 : 32,
                      ),
                      onPressed: _showNotifications,
                    ),
                  ],
                ),
              ),
              SizedBox(height: isMobile ? 24 : 32),

              // Welcome message
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
                  child: Text(
                    '👋 Welcome, ${widget.user.name ?? "Conductor"}!',
                    style: const TextStyle(fontSize: 16, color: Colors.green),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Passenger Count Card
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
                child: InkWell(
                  onTap: () {},
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Text(
                          todayString,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 14 : 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'UNIT ${widget.user.assignedVehicle}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 20 : 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Passenger Count",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Total passenger from latest ticket inspection:",
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // StreamBuilder for live count
                        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
                          stream: latestTripStream(),
                          builder: (context, snapshot) {
                            int passengerCount = latestPassengerCount;
                            String tripTime = "N/A";

                            if (snapshot.hasData &&
                                snapshot.data != null &&
                                snapshot.data!.exists) {
                              final data = snapshot.data!.data()!;
                              passengerCount =
                                  int.tryParse(data['noOfPass'] ?? '0') ?? 0;
                              final timestamp = data['timestamp'] as Timestamp?;
                              if (timestamp != null) {
                                final time = timestamp.toDate();
                                tripTime =
                                    "${time.hour % 12 == 0 ? 12 : time.hour % 12}:${time.minute.toString().padLeft(2, '0')} ${time.hour >= 12 ? 'PM' : 'AM'}";
                              }
                            } else if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white.withAlpha(1),
                                ),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildCountBox(passengerCount, isMobile),
                                  _buildCountBox(tripTime, isMobile),
                                ],
                              ),
                            );
                          },
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

  Widget _buildCountBox(dynamic value, bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2364),
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        value is int ? '$value Passengers' : value,
        style: TextStyle(
          fontSize: isMobile ? 14 : 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  // ----------------- NOTIFICATIONS -----------------
  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) {
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
                if (docs.isEmpty) return const Text('No new notifications');

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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
