import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../../models/app_user.dart';
import '../Personaldetailed/driver.dart';
import '../workSchedule/driver_workschedule.dart';
import '../incidentreport/driver_incidentreport.dart';
import '../vehiclechecklist/driver_vehicle_checklist.dart';
import '../leaveapplication/driverleaveapp.dart';
import 'package:http/http.dart' as http;

class DriverDashboard extends StatefulWidget {
  final AppUser user;
  const DriverDashboard({super.key, required this.user});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class TrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<Position>? _positionSubscription;

  /// Start live GPS tracking
  Future<void> startTracking() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Get user data
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (!userDoc.exists) return;

    final data = userDoc.data();
    final vehicleId = data?['assignedVehicle']?.toString();
    final employeeId = data?['employeeId']?.toString();

    if (vehicleId == null || employeeId == null) return;

    // Location settings
    final locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 5,
    );

    // Start position stream
    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (position) async {
            await _firestore
                .collection('vehicles_locations')
                .doc(employeeId)
                .set({
                  'vehicleId': vehicleId,
                  'driverId': employeeId,
                  'lat': position.latitude,
                  'lng': position.longitude,
                  'speed': position.speed * 3.6,
                  'updatedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));
          },
          onError: (error) {
            debugPrint('Tracking error: $error');
          },
        );

    debugPrint('Tracking started for $employeeId | Vehicle $vehicleId');
  }

  /// Stop live GPS tracking
  Future<void> stopTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    debugPrint('Tracking stopped');
  }

  /// Remove location marker only (no logout)
  Future<void> removeLocationMarker() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final employeeId = userDoc.data()?['employeeId']?.toString();

      // Remove driver location from Firestore
      if (employeeId != null && employeeId.isNotEmpty) {
        await _firestore
            .collection('vehicles_locations')
            .doc(employeeId)
            .delete()
            .then((_) {
              debugPrint('Location removed for $employeeId');
            })
            .catchError((error) {
              debugPrint('Error removing location: $error');
            });
      } else {
        debugPrint('Employee ID is null or empty');
      }
    } catch (e) {
      debugPrint('Error removing location marker: $e');
    }
  }
}

class _DriverDashboardState extends State<DriverDashboard>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  late List<Widget> _screens;

  final TrackingService trackingService = TrackingService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _screens = [];
    _initializeTracking();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize screens here where context is available
    _screens = [
      _buildHomeScreen(),
      const WorkScheduleScreen(),
      const IncidentReportScreen(),
      const VehicleChecklistScreen(),
      const LeaveApplicationScreen(),
    ];
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Stop tracking when app goes into background
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      trackingService.stopTracking();
    } else if (state == AppLifecycleState.resumed) {
      _initializeTracking();
    }
  }

  Future<void> _initializeTracking() async {
    try {
      await handleLocationPermission();

      // Ensure location service is enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        return;
      }

      // Start tracking after checks
      await trackingService.startTracking();
      _showErrorSnackBar('Tracking started successfully.');
    } catch (e) {
      _showErrorSnackBar('Failed to start tracking: $e');
    }
  }

  Future<void> handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location service is enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return Future.error('Location services are disabled.');
    }

    // Check permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    trackingService.stopTracking();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
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

  Future<List<Map<String, dynamic>>> _fetchTodayTimeLogs() async {
    try {
      final response = await http.get(
        Uri.parse("https://jeepez-attendance.onrender.com/api/logs"),
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);

        // Get today's date
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

        // Filter logs for current user and today
        final userLogs = data.where((log) {
          final logDate = DateFormat(
            'yyyy-MM-dd',
          ).format(DateTime.parse(log['timestamp']).toLocal());
          final logName = log['name']?.toString() ?? '';

          return logDate == today && logName == widget.user.name;
        }).toList();

        // Sort by timestamp
        userLogs.sort(
          (a, b) => DateTime.parse(
            a['timestamp'],
          ).compareTo(DateTime.parse(b['timestamp'])),
        );

        // Group into pairs (tap-in, tap-out)
        List<Map<String, dynamic>> timeLogs = [];
        Map<String, dynamic>? currentIn;

        for (var log in userLogs) {
          if (log['type'] == 'tap-in') {
            currentIn = log;
          } else if (log['type'] == 'tap-out' && currentIn != null) {
            timeLogs.add({
              'timeIn': currentIn['timestamp'],
              'timeOut': log['timestamp'],
            });
            currentIn = null;
          }
        }

        // If there's an unpaired tap-in, add it with no tap-out
        if (currentIn != null) {
          timeLogs.add({'timeIn': currentIn['timestamp'], 'timeOut': null});
        }

        return timeLogs;
      } else {
        throw Exception("Failed to load attendance");
      }
    } catch (e) {
      debugPrint('Error fetching time logs: $e');
      return [];
    }
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '--:--';
    try {
      final dateTime = DateTime.parse(timestamp).toLocal();
      return DateFormat('h:mma').format(dateTime).toLowerCase();
    } catch (e) {
      return '--:--';
    }
  }

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
              // Logo section at the top - UPDATED WITH SMALLER PADDING
              Container(
                width: double.infinity,
                color: const Color(0xFF0D2364),
                padding: EdgeInsets.symmetric(
                  vertical: isMobile ? 12 : 20,
                ), // REDUCED PADDING
                child: Column(
                  children: [
                    // Updated with the correct filename
                    Image.asset(
                      'assets/images/a47c2721-58f7-4dc7-a395-082ab4b753e0.jpg',
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 20), // REDUCED FROM 40 TO 20
                  ],
                ),
              ),
              SizedBox(height: isMobile ? 16 : 24), // REDUCED SPACING
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
                            widget.user.name ?? "Driver",
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

                    // Notification Icon only (logout removed)
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
              SizedBox(height: isMobile ? 20 : 28), // REDUCED SPACING
              // Tracking status
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16.0 : 24.0,
                  ),
                  child: const Text(
                    '📍 Tracking in progress...',
                    style: TextStyle(fontSize: 16, color: Colors.green),
                  ),
                ),
              ),

              const SizedBox(height: 24), // REDUCED FROM 32
              // Time Logs Card - UPDATED WITH BLUE CONTAINER AND WHITE TEXT
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
                      color: const Color(0xFF0D2364), // BLUE CONTAINER
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
                        // Header with date - UPDATED WITH WHITE TEXT
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              todayString,
                              style: TextStyle(
                                color: Colors.white, // WHITE TEXT
                                fontSize: isMobile ? 14 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Unit number - UPDATED WITH WHITE TEXT
                        Text(
                          'UNIT ${widget.user.assignedVehicle}',
                          style: TextStyle(
                            color: Colors.white, // WHITE TEXT
                            fontSize: isMobile ? 20 : 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // TIME LOGS SECTION - ADDED
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Time Logs Title
                              Text(
                                "Time Logs",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isMobile ? 16 : 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Tap In Tap Out Headers - ALWAYS VISIBLE
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Time",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isMobile ? 14 : 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    "Status",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isMobile ? 14 : 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Dynamic Time entries
                              FutureBuilder<List<Map<String, dynamic>>>(
                                future: _fetchTodayTimeLogs(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    );
                                  }

                                  if (snapshot.hasError) {
                                    return Text(
                                      "Error loading logs",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: isMobile ? 12 : 14,
                                      ),
                                    );
                                  }

                                  final timeLogs = snapshot.data ?? [];

                                  if (timeLogs.isEmpty) {
                                    return Column(
                                      children: [
                                        // No time logs message
                                        Text(
                                          "No time logs for today",
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.7,
                                            ),
                                            fontSize: isMobile ? 14 : 16,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        // Tap In Tap Out placeholders
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "--:--",
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withOpacity(0.5),
                                                    fontSize: isMobile
                                                        ? 14
                                                        : 16,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  "--:--",
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withOpacity(0.5),
                                                    fontSize: isMobile
                                                        ? 14
                                                        : 16,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  "Tap In",
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withOpacity(0.5),
                                                    fontSize: isMobile
                                                        ? 14
                                                        : 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  "Tap Out",
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withOpacity(0.5),
                                                    fontSize: isMobile
                                                        ? 14
                                                        : 16,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  }

                                  // Display all time log entries
                                  return Column(
                                    children: timeLogs.map((log) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _formatTime(log['timeIn']),
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: isMobile
                                                        ? 14
                                                        : 16,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  _formatTime(log['timeOut']),
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: isMobile
                                                        ? 14
                                                        : 16,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  "Tap In",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: isMobile
                                                        ? 14
                                                        : 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  "Tap Out",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: isMobile
                                                        ? 14
                                                        : 16,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: isMobile ? 20 : 28), // REDUCED SPACING
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
            icon: Icon(Icons.report_problem),
            label: 'Incident',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist),
            label: 'Checklist',
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
