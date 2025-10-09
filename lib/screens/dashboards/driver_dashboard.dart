import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/app_user.dart';
import '../Personaldetailed/driver.dart';
import '../workSchedule/driver_workschedule.dart';
import '../incidentreport/driver_incidentreport.dart';
import '../vehiclechecklist/driver_vehicle_checklist.dart';
import '../leaveapplication/driverleaveapp.dart';

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

  /// Logout user + stop tracking + remove location marker
  Future<void> logout() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final employeeId = userDoc.data()?['employeeId']?.toString();

    // Stop tracking
    await stopTracking();

    // Remove driver location
    if (employeeId != null) {
      await _firestore
          .collection('vehicles_locations')
          .doc(employeeId)
          .delete();
      debugPrint('Location removed for $employeeId');
    }

    // Sign out
    await _auth.signOut();
    debugPrint('User logged out');
  }
}

class _DriverDashboardState extends State<DriverDashboard>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  late List<Widget> _screens;
  bool _hasShownPasswordReminder = false;

  final TrackingService trackingService = TrackingService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _screens = [];
    _initializeTracking();
    _checkIfNewAccount();
  }

  // Check if this is a new account that needs password change
  Future<void> _checkIfNewAccount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Check user creation time - if account was created within the last 24 hours, consider it new
        final userCreationTime = user.metadata.creationTime;
        final now = DateTime.now();

        if (userCreationTime != null) {
          final hoursSinceCreation = now.difference(userCreationTime).inHours;

          // Consider account as "new" if created within last 24 hours AND hasn't shown reminder yet
          final isNewAccount = hoursSinceCreation < 24;

          if (isNewAccount && !_hasShownPasswordReminder) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showPasswordChangeReminder();
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking account status: $e');
    }
  }

  void _showPasswordChangeReminder() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Password Change Required',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'For security reasons, please change your password in the Personal Details section.',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
        backgroundColor: Colors.orange[800],
        duration: Duration(seconds: 6),
        action: SnackBarAction(
          label: 'Change Now',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to Personal Details page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PersonalDetails(user: widget.user),
              ),
            );
          },
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    setState(() {
      _hasShownPasswordReminder = true;
    });
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

              const SizedBox(height: 32),

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
                          color: Colors.black.withOpacity(0.1),
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
                              "Today | Monday | 06/06/06",
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
                          "UNIT20",
                          style: TextStyle(
                            color: Colors.white, // WHITE TEXT
                            fontSize: isMobile ? 20 : 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
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
