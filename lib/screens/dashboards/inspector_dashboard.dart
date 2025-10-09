import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/app_user.dart';
import '../Personaldetailed/driver.dart';
import '../violationReport/inspector_violation_report.dart';
import '../inspectorTrip/inspector_trip_report.dart';
import '../leaveapplication/inspector_leaveapp.dart';

class InspectorDashboard extends StatefulWidget {
  final AppUser user;
  const InspectorDashboard({super.key, required this.user});

  @override
  State<InspectorDashboard> createState() => _InspectorDashboardState();
}

class _InspectorDashboardState extends State<InspectorDashboard> {
  int _currentIndex = 0;
  late List<Widget> _screens;
  bool _hasShownPasswordReminder = false;

  @override
  void initState() {
    super.initState();
    _screens = [];
    _checkIfNewAccount();

    /// Location Stream
    _vehicleLocationsStream = _firestore
        .collection('vehicles_locations')
        .snapshots();
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
      _buildTripScreen(),
      _buildViolationReportForm(),
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

  /// ---------------- MARK ALL AS READ ----------------
  Future<void> _markAllAsRead() async {
    final query = await FirebaseFirestore.instance
        .collection('notifications')
        .where('dismissed', isEqualTo: false)
        .get();

    final batch = FirebaseFirestore.instance.batch();

    for (var doc in query.docs) {
      final data = doc.data();
      if (!data.containsKey('read')) {
        batch.update(doc.reference, {'read': true});
      } else if (data['read'] == false) {
        batch.update(doc.reference, {'read': true});
      }
    }

    await batch.commit();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All notifications marked as read")),
      );
    }
  }

  /// ---------------- SHOW NOTIFICATIONS POPUP ----------------
  void _showNotifications() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Notifications'),
          content: SizedBox(
            width: double.maxFinite,
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: getNotificationsStream(widget.user.role),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No notifications"));
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final type = data['type'] ?? 'updates';
                    final message = data['message'] ?? 'No message';
                    // Safe check for 'read' field
                    final isRead = data['read'] ?? false;

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isRead
                            ? Colors.white
                            : Colors.blue.shade50, // highlight unread
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withAlpha(1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            _getIconForType(type),
                            color: _getColorForType(type),
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                if (data['time'] != null)
                                  Text(
                                    (data['time'] as Timestamp)
                                        .toDate()
                                        .toString()
                                        .substring(0, 16),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark all as read',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D2364),
                ),
              ),
            ),
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

  /// Google Map related
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final Stream<QuerySnapshot<Map<String, dynamic>>>
  _vehicleLocationsStream;
  GoogleMapController? mapController;

  @override
  void dispose() {
    mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  /// Build markers from query snapshot docs
  Set<Marker> _buildMarkersFromDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return docs.map((doc) {
      final data = doc.data();
      final vehicleId = data['vehicleId']?.toString() ?? 'Unknown';
      final lat = data['lat'] as double;
      final lng = data['lng'] as double;

      return Marker(
        markerId: MarkerId(vehicleId),
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(
          title: 'Jeepney #$vehicleId',
          snippet: 'Speed: ${data['speed']} km/h',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      );
    }).toSet();
  }

  /// Fit all markers into view
  Future<void> _fitAllMarkers(Set<Marker> markers) async {
    if (markers.isEmpty || mapController == null) return;

    LatLngBounds bounds;
    if (markers.length == 1) {
      final m = markers.first.position;
      bounds = LatLngBounds(
        southwest: LatLng(m.latitude - 0.01, m.longitude - 0.01),
        northeast: LatLng(m.latitude + 0.01, m.longitude + 0.01),
      );
    } else {
      final latitudes = markers.map((m) => m.position.latitude).toList();
      final longitudes = markers.map((m) => m.position.longitude).toList();
      bounds = LatLngBounds(
        southwest: LatLng(
          latitudes.reduce((a, b) => a < b ? a : b),
          longitudes.reduce((a, b) => a < b ? a : b),
        ),
        northeast: LatLng(
          latitudes.reduce((a, b) => a > b ? a : b),
          longitudes.reduce((a, b) => a > b ? a : b),
        ),
      );
    }

    await mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
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
                            widget.user.name ?? "Inspector",
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
                    '👋 Welcome, ${widget.user.name ?? "Inspector"}!',
                    style: const TextStyle(fontSize: 16, color: Colors.green),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Date Container - maintained from original inspector dashboard
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16.0 : 24.0,
                ),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isMobile ? 16 : 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D2364),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getCurrentDate(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(height: isMobile ? 16 : 20),

              // Route Preview Map Placeholder - maintained from original inspector dashboard
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 10.0 : 24.0,
                ),
                child: SizedBox(
                  height: 300, // fixed container height
                  width: double.infinity,
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _vehicleLocationsStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text('No vehicle locations available'),
                        );
                      }

                      final markers = _buildMarkersFromDocs(
                        snapshot.data!.docs,
                      );

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _fitAllMarkers(markers);
                      });

                      // Use SizedBox to fix the map size
                      return SizedBox(
                        height: double.infinity,
                        width: double.infinity,
                        child: GoogleMap(
                          onMapCreated: _onMapCreated,
                          initialCameraPosition: const CameraPosition(
                            target: LatLng(14.8287, 121.0549),
                            zoom: 13,
                          ),
                          markers: markers,
                          mapType: MapType.normal,
                          myLocationEnabled: false,
                          zoomGesturesEnabled: true,
                          scrollGesturesEnabled: true,
                          rotateGesturesEnabled: true,
                          tiltGesturesEnabled: true,
                          gestureRecognizers:
                              <Factory<OneSequenceGestureRecognizer>>{
                                Factory<OneSequenceGestureRecognizer>(
                                  () => EagerGestureRecognizer(),
                                ),
                              },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    final days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    final dayName = days[now.weekday];
    final formattedDate =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    return 'Today | $dayName | $formattedDate';
  }

  Widget _buildTripScreen() {
    return const InspectorTripScreen();
  }

  Widget _buildViolationReportForm() {
    return const ViolationReportForm();
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
