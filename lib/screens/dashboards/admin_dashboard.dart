import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../admin/employeelist.dart';
import '../admin/attendance_record.dart';
import '../admin/leavemanagement.dart';
import '../admin/driver_and_conductor_management.dart';
import '../admin/maintenance.dart';
import '../admin/route_history.dart';

class AdminDashboard extends StatefulWidget {
  final AppUser user;
  const AdminDashboard({super.key, required this.user});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _isLoggingOut = false;

  /// ---------------- SING OUT FUNCTION ----------------
  Future<void> _signOut() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);

    try {
      await Future.delayed(const Duration(milliseconds: 3000));
      await AuthService().logout();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign out: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
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

  /// ---------------- GET TODAY DATE ----------------
  String getTodayAbbrev() {
    final now = DateTime.now();
    const days = {
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun',
    };
    return days[now.weekday]!;
  }

  /// ---------------- GET TODAY VEHICLE ASSIGN ----------------
  Stream<List<Map<String, dynamic>>> getTodayVehicleAssignments() {
    final today = getTodayAbbrev();

    return FirebaseFirestore.instance
        .collection('users')
        .where('status', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                final data = doc.data();
                return {
                  'name': data['name'],
                  'assignedVehicle': data['assignedVehicle'],
                  'schedule': data['schedule'],
                  'role': data['role'],
                };
              })
              .where((user) {
                final schedule = user['schedule'] as String? ?? '';
                final role = user['role'] as String? ?? '';
                return role == 'driver' && schedule.contains(today);
              })
              .toList();
        });
  }

  /// Fetch and process attendance logs from backend
  Future<List<Map<String, dynamic>>> fetchAttendance(
    DateTime targetDate,
  ) async {
    final response = await http.get(
      Uri.parse("https://jeepez-attendance.onrender.com/api/logs"),
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);

      final filterDate = DateFormat('yyyy-MM-dd').format(targetDate);

      // Group logs by name and date
      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (var log in data) {
        final logDate = DateFormat(
          'yyyy-MM-dd',
        ).format(DateTime.parse(log['timestamp']).toLocal());

        if (logDate == filterDate) {
          final key = "${log['name']}_$logDate";
          grouped.putIfAbsent(key, () => []).add(log);
        }
      }

      final List<Map<String, dynamic>> attendance = [];

      grouped.forEach((key, logs) {
        logs.sort(
          (a, b) => DateTime.parse(
            a['timestamp'],
          ).compareTo(DateTime.parse(b['timestamp'])),
        );

        String name = logs.first['name'];
        String date = logs.first['date'];
        int inCount = 0, outCount = 0;

        Map<String, dynamic>? currentIn;

        for (var log in logs) {
          if (log['type'] == 'tap-in' && inCount < 4) {
            currentIn = log;
            inCount++;
          } else if (log['type'] == 'tap-out' &&
              currentIn != null &&
              outCount < 4) {
            attendance.add({
              "name": name,
              "date": date,
              "timeIn": currentIn['timestamp'],
              "timeOut": log['timestamp'],
              "unit": log["unit"] ?? "",
            });
            outCount++;
            currentIn = null;
          }
        }

        // If ended with tap-in without tap-out
        if (currentIn != null && inCount <= 4) {
          attendance.add({
            "name": name,
            "date": date,
            "timeIn": currentIn['timestamp'],
            "timeOut": null,
            "unit": currentIn["unit"] ?? "",
          });
        }
      });

      return attendance;
    } else {
      throw Exception("Failed to load attendance");
    }
  }

  /// ---------------- DRAWER ITEM ----------------
  Widget _drawerItem(BuildContext context, String title, VoidCallback onTap) {
    return ListTile(
      leading: _getIconForTitle(title),
      title: Text(title),
      onTap: onTap,
    );
  }

  Icon _getIconForTitle(String title) {
    switch (title) {
      case 'Home':
        return const Icon(Icons.home, color: Color(0xFF0D2364));
      case 'Employee List':
        return const Icon(Icons.people, color: Color(0xFF0D2364));
      case 'Attendance':
        return const Icon(Icons.calendar_today, color: Color(0xFF0D2364));
      case 'Leave Management':
        return const Icon(Icons.event_busy, color: Color(0xFF0D2364));
      case 'Driver & Conductor Management':
        return const Icon(Icons.directions_car, color: Color(0xFF0D2364));
      case 'Maintenance':
        return const Icon(Icons.build, color: Color(0xFF0D2364));
      case 'Route Playback':
        return const Icon(Icons.map, color: Color(0xFF0D2364));
      default:
        return const Icon(Icons.menu, color: Color(0xFF0D2364));
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
        actions: [
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: getNotificationsStream(widget.user.role),
            builder: (context, snapshot) {
              int unreadCount = 0;
              if (snapshot.hasData) {
                unreadCount = snapshot.data!.docs.where((doc) {
                  final data = doc.data();
                  return (data['read'] != true);
                }).length;
              }

              return SizedBox(
                width: 50,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications),
                      onPressed: _showNotifications,
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8, // smaller font to prevent overflow
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF0D2364)),
              accountName: Text(
                widget.user.name ?? 'Admin',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              accountEmail: Text(
                widget.user.email,
                style: const TextStyle(fontSize: 14),
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.admin_panel_settings,
                  color: Color(0xFF0D2364),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  _drawerItem(context, 'Home', () {
                    Navigator.pop(context);
                  }),
                  _drawerItem(context, 'Employee List', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EmployeeListScreen(user: widget.user),
                      ),
                    );
                  }),
                  _drawerItem(context, 'Attendance', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AttendanceScreen(
                          onBackPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    );
                  }),
                  _drawerItem(context, 'Leave Management', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LeaveManagementScreen(),
                      ),
                    );
                  }),
                  _drawerItem(context, 'Driver & Conductor Management', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const DriverConductorManagementScreen(),
                      ),
                    );
                  }),
                  _drawerItem(context, 'Maintenance', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MaintenanceScreen(),
                      ),
                    );
                  }),
                  _drawerItem(context, 'Route Playback', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RouteHistoryScreen(),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFF0D2364)),
              title: Text(
                _isLoggingOut ? 'Logging out...' : 'Logout',
                style: const TextStyle(color: Color(0xFF0D2364)),
              ),
              trailing: _isLoggingOut
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              onTap: _isLoggingOut ? null : _signOut,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      body: HomeScreen(
        vehicleStream: getTodayVehicleAssignments(),
        attendanceFuture: fetchAttendance(DateTime.now()),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final Stream<List<Map<String, dynamic>>> vehicleStream;
  final Future<List<Map<String, dynamic>>> attendanceFuture;

  const HomeScreen({
    super.key,
    required this.vehicleStream,
    required this.attendanceFuture,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Attendance Stream
  late Stream<List<Map<String, dynamic>>> _attendanceStream;

  /// Firestore Stream
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final Stream<QuerySnapshot<Map<String, dynamic>>>
  _vehicleLocationsStream;

  /// Google Map related
  GoogleMapController? mapController;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();

    /// Attendance Stream
    _attendanceStream = Stream.periodic(
      const Duration(seconds: 5),
    ).asyncMap((_) => fetchAttendanceNow());

    /// Location Stream
    _vehicleLocationsStream = _firestore.collection('vehicles_locations').snapshots();
  }

  @override
  void dispose() {
    mapController?.dispose();
    super.dispose();
  }

  /// Refresh dashboard when user pulls down
  Future<void> _refreshDashboard() async {
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 800));
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

  /// Get the latest attendance
  Future<List<Map<String, dynamic>>> fetchAttendanceNow() {
    return http
        .get(Uri.parse("https://jeepez-attendance.onrender.com/api/logs"))
        .then((response) {
          if (response.statusCode != 200)
            throw Exception("Failed to load attendance");
          final List data = json.decode(response.body);
          final filterDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

          final Map<String, List<Map<String, dynamic>>> grouped = {};
          for (var log in data) {
            final logDate = DateFormat(
              'yyyy-MM-dd',
            ).format(DateTime.parse(log['timestamp']).toLocal());
            if (logDate == filterDate) {
              final key = "${log['name']}_$logDate";
              grouped.putIfAbsent(key, () => []).add(log);
            }
          }

          final List<Map<String, dynamic>> attendance = [];
          grouped.forEach((key, logs) {
            logs.sort(
              (a, b) => DateTime.parse(
                a['timestamp'],
              ).compareTo(DateTime.parse(b['timestamp'])),
            );

            String name = logs.first['name'];
            String date = logs.first['date'];
            int inCount = 0, outCount = 0;
            Map<String, dynamic>? currentIn;

            for (var log in logs) {
              if (log['type'] == 'tap-in' && inCount < 4) {
                currentIn = log;
                inCount++;
              } else if (log['type'] == 'tap-out' &&
                  currentIn != null &&
                  outCount < 4) {
                attendance.add({
                  "name": name,
                  "date": date,
                  "timeIn": currentIn['timestamp'],
                  "timeOut": log['timestamp'],
                  "unit": log["unit"] ?? "",
                });
                outCount++;
                currentIn = null;
              }
            }

            if (currentIn != null && inCount <= 4) {
              attendance.add({
                "name": name,
                "date": date,
                "timeIn": currentIn['timestamp'],
                "timeOut": null,
                "unit": currentIn["unit"] ?? "",
              });
            }
          });

          return attendance;
        });
  }

  /// Get today's label
  String getTodayLabel() {
    final now = DateTime.now();
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return 'Today | ${weekdays[now.weekday - 1]}';
  }

  TableRow _buildEmployeeRow(String name, String time) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              const Icon(Icons.email, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              const Icon(Icons.access_time, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                time,
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: Column(
        children: [
          const SizedBox(height: 10),

          const Text(
            'Welcome to Admin Dashboard',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          /// --- MAP SECTION ---
          SizedBox(
            height: 550,
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _vehicleLocationsStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(child: Text('No vehicle locations available'));
                        }

                        final markers = _buildMarkersFromDocs(
                          snapshot.data!.docs,
                        );

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _fitAllMarkers(markers);
                        });

                        return _mapReady
                            ? GoogleMap(
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

                          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                            Factory<OneSequenceGestureRecognizer>(
                                  () => EagerGestureRecognizer(),
                            ),
                          },
                        );
                      },
                    ),

                    /// Floating Action Button — Recenter
                    Positioned(
                      top: 12,
                      right: 12,
                      child: FloatingActionButton(
                        backgroundColor: const Color(0xFF0D2364),
                        foregroundColor: Colors.white,
                        onPressed: () async {
                          final snap = await _firestore
                              .collection('vehicles_locations')
                              .get();
                          final markers = _buildMarkersFromDocs(snap.docs);
                          await _fitAllMarkers(markers);
                        },
                        child: const Icon(Icons.center_focus_strong),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          /// --- CONTENT SECTION ---
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// --- Vehicle Schedule ---
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Vehicle Schedule',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D2364),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            getTodayLabel(),
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const Divider(),
                          const SizedBox(height: 8),
                          StreamBuilder<List<Map<String, dynamic>>>(
                            stream: widget.vehicleStream,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }

                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return const Text(
                                  'No vehicle schedules for today',
                                  style: TextStyle(color: Colors.grey),
                                );
                              }

                        final assignments = snapshot.data!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: assignments.map((item) {
                            final vehicleId =
                                item['assignedVehicle']?.toString() ?? 'Unknown';
                            final driverName =
                                item['name'] ?? 'Unknown Driver';
                            return Text('$driverName — UNIT $vehicleId');
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

                  const SizedBox(height: 20),

                  /// --- Employee Tracking ---
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D2364),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Employee Tracking',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              getTodayLabel(),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 12),
                            StreamBuilder<List<Map<String, dynamic>>>(
                              stream: _attendanceStream,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const SizedBox(
                                    height: 120,
                                    child: Center(
                                      child: CircularProgressIndicator(color: Colors.white),
                                    ),
                                  );
                                }

                                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                  return const SizedBox(
                                    height: 120,
                                    child: Center(
                                      child: Text(
                                        "No tap-in records yet",
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                  );
                                }

                          final attendance = snapshot.data!;
                          return SizedBox(
                            height: 150,
                            child: SingleChildScrollView(
                              child: Table(
                                columnWidths: const {
                                  0: FlexColumnWidth(2),
                                  1: FlexColumnWidth(1),
                                },
                                children: attendance.map((log) {
                                  final name = log['name'] ?? '';
                                  final timeIn = DateTime.parse(
                                    log['timeIn'],
                                  ).toLocal();
                                  final formattedTime =
                                  TimeOfDay.fromDateTime(timeIn)
                                      .format(context);
                                  return _buildEmployeeRow(
                                      name, formattedTime);
                                }).toList(),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
