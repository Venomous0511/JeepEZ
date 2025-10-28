import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

class AdminDashboard extends StatefulWidget {
  final AppUser user;
  const AdminDashboard({super.key, required this.user});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _isLoggingOut = false;
  int _currentScreenIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Password change variables
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isChangingPassword = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  // List of all available screens
  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    // Initialize screens
    _screens.addAll([
      HomeScreen(
        vehicleStream: getTodayVehicleAssignments(),
        attendanceFuture: fetchAttendance(DateTime.now()),
      ),
      EmployeeListScreen(user: widget.user),
      AttendanceScreen(onBackPressed: () => _navigateToScreen(0)),
      const LeaveManagementScreen(),
      const DriverConductorManagementScreen(),
      const MaintenanceScreen(),
    ]);
  }

  void _navigateToScreen(int index) {
    setState(() {
      _currentScreenIndex = index;
    });
    // Close drawer if open
    if (_scaffoldKey.currentState!.isDrawerOpen) {
      _scaffoldKey.currentState!.openEndDrawer();
    }
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'Admin Dashboard';
      case 1:
        return 'Employee Account Management';
      case 2:
        return 'Attendance Records';
      case 3:
        return 'Leave Management';
      case 4:
        return 'Schedule Management';
      case 5:
        return 'Vehicle Maintenance';
      default:
        return 'Admin Dashboard';
    }
  }

  Future<void> _signOut() async {
    if (_isLoggingOut) return;

    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout Confirmation'),
        content: const Text('Are you sure you want to log-out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D2364),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    // If user cancels, return
    if (shouldLogout != true) return;

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

  /// ---------------- CHANGE PASSWORD FUNCTIONALITY ----------------
  Future<void> _changePassword() async {
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final user = _auth.currentUser;

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("New passwords do not match")),
      );
      return;
    }

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password must be at least 6 characters")),
      );
      return;
    }

    setState(() => _isChangingPassword = true);

    try {
      // Re-authenticate user with current password
      final cred = EmailAuthProvider.credential(
        email: user!.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(cred);

      // Update password
      await user.updatePassword(newPassword);

      // Update a flag in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'lastPasswordChange': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password changed successfully!")),
      );

      // Clear fields and close dialog
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      String message = "Password change failed";
      if (e.code == 'wrong-password') {
        message = "Current password is incorrect";
      } else if (e.code == 'weak-password') {
        message = "New password is too weak";
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isChangingPassword = false);
    }
  }

  /// ---------------- CHANGE PASSWORD DIALOG ----------------
  Future<void> _showChangePasswordDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Change Password'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPasswordField(
                      controller: _currentPasswordController,
                      label: "Current Password",
                      showPassword: _showCurrentPassword,
                      onToggle: () {
                        setState(() {
                          _showCurrentPassword = !_showCurrentPassword;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildPasswordField(
                      controller: _newPasswordController,
                      label: "New Password",
                      showPassword: _showNewPassword,
                      onToggle: () {
                        setState(() {
                          _showNewPassword = !_showNewPassword;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildPasswordField(
                      controller: _confirmPasswordController,
                      label: "Confirm New Password",
                      showPassword: _showConfirmPassword,
                      onToggle: () {
                        setState(() {
                          _showConfirmPassword = !_showConfirmPassword;
                        });
                      },
                    ),
                    if (_isChangingPassword)
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isChangingPassword
                      ? null
                      : () {
                          _currentPasswordController.clear();
                          _newPasswordController.clear();
                          _confirmPasswordController.clear();
                          Navigator.of(context).pop();
                        },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isChangingPassword ? null : _changePassword,
                  child: const Text('Change Password'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Password field widget with show/hide functionality
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool showPassword,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: !showPassword,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        suffixIcon: IconButton(
          icon: Icon(
            showPassword ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getNotificationsStream(
    String role,
  ) {
    final collection = FirebaseFirestore.instance.collection('notifications');

    if (role == 'super_admin' || role == 'admin') {
      return collection
          .where('dismissed', isEqualTo: false)
          .orderBy('time', descending: true)
          .snapshots();
    } else {
      return collection
          .where('dismissed', isEqualTo: false)
          .where('type', isEqualTo: 'system')
          .orderBy('time', descending: true)
          .snapshots();
    }
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

  Future<void> _dismissNotification(String docId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(docId)
        .update({'dismissed': true});
  }

  void _showNotifications() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: true,
      builder: (BuildContext context) {
        final isMobile = MediaQuery.of(context).size.width < 600;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          insetPadding: isMobile
              ? const EdgeInsets.symmetric(horizontal: 20, vertical: 40)
              : const EdgeInsets.all(40),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isMobile
                  ? MediaQuery.of(context).size.width * 0.9
                  : 400,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header - NO X BUTTON HERE
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0D2364),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.notifications,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Notifications',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),

                // Notifications List
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: getNotificationsStream(widget.user.role),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              "No notifications",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        );
                      }

                      final docs = snapshot.data!.docs;

                      return Column(
                        children: [
                          // Mark all as read button
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${docs.length} notification${docs.length > 1 ? 's' : ''}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: _markAllAsRead,
                                  icon: const Icon(Icons.checklist, size: 16),
                                  label: const Text(
                                    'Mark all as read',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0D2364),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Notifications list
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              itemCount: docs.length,
                              itemBuilder: (context, index) {
                                final doc = docs[index];
                                final data = doc.data();
                                final type = data['type'] ?? 'updates';
                                final message = data['message'] ?? 'No message';
                                final isRead = data['read'] ?? false;
                                final timestamp = data['time'] as Timestamp?;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isRead
                                        ? Colors.white
                                        : Colors.blue.shade50,
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withAlpha(1),
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: _getColorForType(
                                            type,
                                          ).withAlpha(1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          _getIconForType(type),
                                          color: _getColorForType(type),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              message,
                                              style: TextStyle(
                                                fontWeight: isRead
                                                    ? FontWeight.normal
                                                    : FontWeight.bold,
                                                fontSize: 14,
                                                color: Colors.grey.shade800,
                                              ),
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (timestamp != null)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 4,
                                                ),
                                                child: Text(
                                                  _formatTimestamp(timestamp),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // X button for individual notification - ONLY THIS HAS X
                                      IconButton(
                                        icon: const Icon(Icons.close, size: 16),
                                        color: Colors.grey.shade500,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                          minWidth: 24,
                                          minHeight: 24,
                                        ),
                                        onPressed: () =>
                                            _dismissNotification(doc.id),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // Footer - CLOSE BUTTON HERE AGAIN
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Close',
                          style: TextStyle(color: Color(0xFF0D2364)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

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
        })
        .asBroadcastStream();
  }

  Future<List<Map<String, dynamic>>> fetchAttendance(
    DateTime targetDate,
  ) async {
    final response = await http.get(
      Uri.parse("https://jeepez-attendance.onrender.com/api/logs"),
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      final filterDate = DateFormat('yyyy-MM-dd').format(targetDate);

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
              "status": "Completed",
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
            "status": "Active",
          });
        }
      });

      return attendance;
    } else {
      throw Exception("Failed to load attendance");
    }
  }

  Widget _drawerItem(String title, int index, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF0D2364)),
      title: Text(title),
      tileColor: _currentScreenIndex == index ? Colors.blue[50] : null,
      onTap: () => _navigateToScreen(index),
    );
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_getAppBarTitle(_currentScreenIndex)),
        backgroundColor: const Color(0xFF0D2364),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState!.openDrawer(),
        ),
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
                              fontSize: 8,
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
                  _drawerItem('Home', 0, Icons.home),
                  _drawerItem('Employee Account Management', 1, Icons.people),
                  _drawerItem('Attendance Records', 2, Icons.calendar_today),
                  _drawerItem('Leave Management', 3, Icons.event_busy),
                  _drawerItem('Schedule Management', 4, Icons.directions_car),
                  _drawerItem('Vehicle Maintenance', 5, Icons.build),
                ],
              ),
            ),
            const Divider(height: 1),
            // CHANGE PASSWORD BUTTON
            ListTile(
              leading: const Icon(Icons.lock, color: Color(0xFF0D2364)),
              title: const Text(
                'Change Password',
                style: TextStyle(color: Color(0xFF0D2364)),
              ),
              onTap: _showChangePasswordDialog,
            ),
            // LOGOUT BUTTON
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
      body: _screens[_currentScreenIndex],
    );
  }
}

class LiveMapWidget extends StatefulWidget {
  const LiveMapWidget({super.key});

  @override
  State<LiveMapWidget> createState() => _LiveMapWidgetState();
}

class _LiveMapWidgetState extends State<LiveMapWidget> {
  GoogleMapController? mapController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final Stream<QuerySnapshot<Map<String, dynamic>>>
  _vehicleLocationsStream;

  @override
  void initState() {
    super.initState();
    _vehicleLocationsStream = _firestore
        .collection('vehicles_locations')
        .snapshots()
        .asBroadcastStream();
  }

  @override
  void dispose() {
    mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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

                final markers = _buildMarkersFromDocs(snapshot.data!.docs);

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _fitAllMarkers(markers);
                });

                return GoogleMap(
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
            Positioned(
              top: 12,
              right: 12,
              child: FloatingActionButton(
                backgroundColor: const Color(0xFF0D2364),
                foregroundColor: Colors.white,
                mini: true,
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

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  late Stream<List<Map<String, dynamic>>> _attendanceStream;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    // FIXED: Convert to broadcast stream for multiple listeners
    _attendanceStream = Stream.periodic(
      const Duration(seconds: 5),
    ).asyncMap((_) => _fetchAttendanceNow()).asBroadcastStream();
  }

  Future<void> _refreshDashboard() async {
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 800));
  }

  Future<List<Map<String, dynamic>>> _fetchAttendanceNow() {
    return http
        .get(Uri.parse("https://jeepez-attendance.onrender.com/api/logs"))
        .then((response) {
          if (response.statusCode != 200) {
            throw Exception("Failed to load attendance");
          }
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
                  "status": "Completed",
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
                "status": "Active",
              });
            }
          });

          return attendance;
        });
  }

  String _getTodayLabel() {
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return RefreshIndicator(
          onRefresh: _refreshDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to Admin Dashboard',
                  style: TextStyle(
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Responsive 50/50 Layout
                if (isMobile) _buildMobileLayout() else _buildDesktopLayout(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Map - Full width on mobile
        SizedBox(height: 300, child: _buildMapSection()),
        const SizedBox(height: 16),
        // Cards stacked vertically on mobile
        Column(
          children: [
            SizedBox(height: 200, child: _buildVehicleScheduleCard()),
            const SizedBox(height: 16),
            SizedBox(height: 200, child: _buildEmployeeTrackingCard()),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Map - 50% width
          Expanded(flex: 1, child: _buildMapSection()),
          const SizedBox(width: 16),
          // Cards Section - 50% width
          Expanded(
            flex: 1,
            child: Column(
              children: [
                // Vehicle Schedule Card
                Expanded(flex: 1, child: _buildVehicleScheduleCard()),
                const SizedBox(height: 16),
                // Employee Tracking Card
                Expanded(flex: 1, child: _buildEmployeeTrackingCard()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleScheduleCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vehicle Schedule',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D2364),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getTodayLabel(),
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const Divider(),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: widget.vehicleStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        'No vehicle schedules for today',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  final assignments = snapshot.data!;
                  return ListView.builder(
                    itemCount: assignments.length,
                    itemBuilder: (context, index) {
                      final item = assignments[index];
                      final vehicleId =
                          item['assignedVehicle']?.toString() ?? 'Unknown';
                      final driverName = item['name'] ?? 'Unknown Driver';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.directions_car,
                              color: const Color(0xFF0D2364),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$driverName — UNIT $vehicleId',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
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
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeTrackingCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              Text(
                'Employee Tracking',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getTodayLabel(),
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              // Table Header
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Employee',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Tap In',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Tap Out',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _attendanceStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          "No attendance records yet",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      );
                    }

                    final attendance = snapshot.data!;
                    return ListView.builder(
                      itemCount: attendance.length,
                      itemBuilder: (context, index) {
                        final log = attendance[index];
                        final name = log['name'] ?? 'Unknown';
                        final timeIn = log['timeIn'] != null
                            ? DateTime.parse(log['timeIn']).toLocal()
                            : null;
                        final timeOut = log['timeOut'] != null
                            ? DateTime.parse(log['timeOut']).toLocal()
                            : null;

                        final tapInTime = timeIn != null
                            ? TimeOfDay.fromDateTime(timeIn).format(context)
                            : '--:--';

                        final tapOutTime = timeOut != null
                            ? TimeOfDay.fromDateTime(timeOut).format(context)
                            : '--:--';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              // Employee Name
                              Expanded(
                                flex: 2,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Tap In Time
                              Expanded(
                                flex: 1,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.login,
                                      color: Colors.green[300],
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      tapInTime,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: timeIn != null
                                            ? Colors.green[300]
                                            : Colors.grey,
                                        fontWeight: timeIn != null
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Tap Out Time
                              Expanded(
                                flex: 1,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.logout,
                                      color: Colors.red[300],
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      tapOutTime,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: timeOut != null
                                            ? Colors.red[300]
                                            : Colors.grey,
                                        fontWeight: timeOut != null
                                            ? FontWeight.bold
                                            : FontWeight.normal,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapSection() {
    return const LiveMapWidget();
  }
}
