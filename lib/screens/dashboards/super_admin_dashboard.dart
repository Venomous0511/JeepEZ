import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../SuperAdminScreen/employee_list.dart';
import '../SuperAdminScreen/deactivated_account.dart';
import '../SuperAdminScreen/add_account.dart';
import '../SuperAdminScreen/system_management.dart';

class SuperAdminDashboard extends StatefulWidget {
  final AppUser user;
  const SuperAdminDashboard({super.key, required this.user});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  int _selectedIndex = 0;
  bool _isLoggingOut = false;
  bool showUserManagementOptions = false;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [_buildHomeScreen()];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showAddNotificationDialog() {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String selectedType = 'system';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Add Notification"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: "Title",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: messageController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Message",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: "Type",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'system', child: Text('System')),
                      DropdownMenuItem(
                        value: 'security',
                        child: Text('Security'),
                      ),
                      DropdownMenuItem(
                        value: 'updates',
                        child: Text('Updates'),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedType = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D2364),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final message = messageController.text.trim();

                    if (title.isEmpty || message.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please fill in all fields"),
                        ),
                      );
                      return;
                    }

                    await FirebaseFirestore.instance
                        .collection('notifications')
                        .add({
                          'title': title,
                          'message': message,
                          'time': FieldValue.serverTimestamp(),
                          'dismissed': false,
                          'type': selectedType,
                          'createdBy': widget.user.role,
                        });

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Notification added successfully!"),
                        ),
                      );
                    }
                  },
                  child: const Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );
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

  String _getTypeLabel(String type) {
    switch (type) {
      case 'system':
        return 'SYSTEM';
      case 'security':
        return 'SECURITY';
      case 'updates':
        return 'UPDATES';
      default:
        return 'NOTICE';
    }
  }

  Widget _buildHomeScreen() {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < 768;

          return Stack(
            children: [
              Padding(
                padding: isMobile
                    ? const EdgeInsets.all(12.0)
                    : const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: isMobile ? 24 : 32,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0D2364),
                          ),
                        ),
                        StreamBuilder<QuerySnapshot>(
                          stream: getNotificationsStream(widget.user.role),
                          builder: (context, snapshot) {
                            final count = snapshot.hasData
                                ? snapshot.data!.docs.length
                                : 0;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D2364),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 14 : 16,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Notifications Content
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: getNotificationsStream(widget.user.role),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.notifications_off_outlined,
                                    size: isMobile ? 60 : 80,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No notifications',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: isMobile ? 18 : 20,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final docs = snapshot.data!.docs;

                          if (isMobile) {
                            return _buildMobileNotificationsList(docs);
                          } else {
                            return _buildDesktopNotificationsGrid(docs);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Floating Action Button - positioned differently for mobile
              Positioned(
                bottom: isMobile ? 16 : 24,
                right: isMobile ? 16 : 24,
                child: FloatingActionButton(
                  onPressed: _showAddNotificationDialog,
                  backgroundColor: const Color(0xFF0D2364),
                  foregroundColor: Colors.white,
                  tooltip: 'Add Notification',
                  child: Icon(Icons.add, size: isMobile ? 24 : 28),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Mobile View - Vertical List
  Widget _buildMobileNotificationsList(List<QueryDocumentSnapshot> docs) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80), // Space for FAB
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final data = docs[index].data() as Map<String, dynamic>;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: MobileNotificationTile(
            data: data,
            docReference: docs[index].reference,
            getIconForType: _getIconForType,
            getColorForType: _getColorForType,
            getTypeLabel: _getTypeLabel,
          ),
        );
      },
    );
  }

  /// Desktop View - Responsive Grid
  Widget _buildDesktopNotificationsGrid(List<QueryDocumentSnapshot> docs) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        final int crossAxisCount = availableWidth > 1200
            ? 4
            : availableWidth > 800
            ? 3
            : 2;

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1.0,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          padding: const EdgeInsets.only(bottom: 80), // Space for FAB
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return DesktopNotificationTile(
              data: data,
              docReference: docs[index].reference,
              getIconForType: _getIconForType,
              getColorForType: _getColorForType,
              getTypeLabel: _getTypeLabel,
            );
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> getNotificationsStream(String role) {
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

  Future<void> _signOut() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);

    try {
      await Future.delayed(const Duration(seconds: 3));
      await AuthService().logout();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to sign out: $e')));
      setState(() => _isLoggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Super Admin Dashboard',
          style: TextStyle(fontSize: 20),
        ),
        backgroundColor: const Color(0xFF0D2364),
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF0D2364)),
              accountName: Text(
                widget.user.name ?? 'Super Admin',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              accountEmail: Text(
                "Employee ID: ${widget.user.employeeId}",
                style: const TextStyle(fontSize: 16),
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.admin_panel_settings,
                  color: Color(0xFF0D2364),
                  size: 40,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.home,
                      color: Color(0xFF0D2364),
                      size: 28,
                    ),
                    title: const Text('Home', style: TextStyle(fontSize: 16)),
                    selected: _selectedIndex == 0,
                    onTap: () {
                      _onItemTapped(0);
                      Navigator.pop(context);
                    },
                  ),
                  ExpansionTile(
                    leading: const Icon(
                      Icons.people,
                      color: Color(0xFF0D2364),
                      size: 28,
                    ),
                    title: const Text(
                      'User Management',
                      style: TextStyle(fontSize: 16),
                    ),
                    initiallyExpanded: showUserManagementOptions,
                    onExpansionChanged: (expanded) =>
                        setState(() => showUserManagementOptions = expanded),
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.person_add,
                          color: Color(0xFF0D2364),
                          size: 24,
                        ),
                        title: const Text(
                          'Add Account',
                          style: TextStyle(fontSize: 15),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AddAccountScreen(user: widget.user),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.list,
                          color: Color(0xFF0D2364),
                          size: 24,
                        ),
                        title: const Text(
                          'Employee List',
                          style: TextStyle(fontSize: 15),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EmployeeListScreen(user: widget.user),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.person_off,
                          color: Color(0xFF0D2364),
                          size: 24,
                        ),
                        title: const Text(
                          'Deactivated Account',
                          style: TextStyle(fontSize: 15),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DeactivatedAccountScreen(user: widget.user),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.settings,
                      color: Color(0xFF0D2364),
                      size: 28,
                    ),
                    title: const Text(
                      'System Management',
                      style: TextStyle(fontSize: 16),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SystemManagementScreen(user: widget.user),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.logout,
                color: Color(0xFF0D2364),
                size: 28,
              ),
              title: Text(
                _isLoggingOut ? 'Logging out...' : 'Logout',
                style: const TextStyle(color: Color(0xFF0D2364), fontSize: 16),
              ),
              trailing: _isLoggingOut
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  : null,
              onTap: _isLoggingOut ? null : _signOut,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      body: _screens[_selectedIndex],
    );
  }
}

// Mobile Notification Tile - Optimized for small screens
class MobileNotificationTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final DocumentReference docReference;
  final IconData Function(String) getIconForType;
  final Color Function(String) getColorForType;
  final String Function(String) getTypeLabel;

  const MobileNotificationTile({
    super.key,
    required this.data,
    required this.docReference,
    required this.getIconForType,
    required this.getColorForType,
    required this.getTypeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final type = data['type'] ?? '';
    final color = getColorForType(type);
    final icon = getIconForType(type);
    final title = data['title'] ?? 'No Title';
    final message = data['message'] ?? '';
    final timestamp = data['time'] as Timestamp?;

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D2364),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              message,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withAlpha(1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    getTypeLabel(type),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  timestamp != null
                      ? DateFormat('MMM d').format(timestamp.toDate())
                      : '',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        onTap: () => _showNotificationDialog(
          context,
          title,
          message,
          icon,
          color,
          timestamp,
        ),
        onLongPress: () => _dismissNotification(context),
      ),
    );
  }

  void _showNotificationDialog(
    BuildContext context,
    String title,
    String message,
    IconData icon,
    Color color,
    Timestamp? timestamp,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            if (timestamp != null)
              Text(
                DateFormat('MMM d, yyyy - hh:mm a').format(timestamp.toDate()),
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              _dismissNotification(context);
              Navigator.pop(context);
            },
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  void _dismissNotification(BuildContext context) async {
    await docReference.update({'dismissed': true});
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification dismissed'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

// Desktop Notification Tile - Optimized for larger screens
class DesktopNotificationTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final DocumentReference docReference;
  final IconData Function(String) getIconForType;
  final Color Function(String) getColorForType;
  final String Function(String) getTypeLabel;

  const DesktopNotificationTile({
    super.key,
    required this.data,
    required this.docReference,
    required this.getIconForType,
    required this.getColorForType,
    required this.getTypeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final type = data['type'] ?? '';
    final color = getColorForType(type);
    final icon = getIconForType(type);
    final title = data['title'] ?? 'No Title';
    final message = data['message'] ?? '';
    final timestamp = data['time'] as Timestamp?;

    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () => _showNotificationDialog(
          context,
          title,
          message,
          icon,
          color,
          timestamp,
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withAlpha(1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, size: 18, color: Colors.grey),
                    onPressed: () => _dismissNotification(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Type Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withAlpha(1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  getTypeLabel(type),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D2364),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Message
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),

              // Footer
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    timestamp != null
                        ? DateFormat('MMM d, yyyy').format(timestamp.toDate())
                        : '',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationDialog(
    BuildContext context,
    String title,
    String message,
    IconData icon,
    Color color,
    Timestamp? timestamp,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 20))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            if (timestamp != null)
              Text(
                DateFormat('MMM d, yyyy - hh:mm a').format(timestamp.toDate()),
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              _dismissNotification(context);
              Navigator.pop(context);
            },
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  void _dismissNotification(BuildContext context) async {
    await docReference.update({'dismissed': true});
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification dismissed'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

// Utility Functions (unchanged)
Future<void> createSystemNotification(
  String title,
  String message,
  String role,
) async {
  final userQuery = await FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: role)
      .limit(1)
      .get();

  if (userQuery.docs.isNotEmpty && role == 'super_admin') {
    await FirebaseFirestore.instance.collection('notifications').add({
      'title': title,
      'message': message,
      'time': FieldValue.serverTimestamp(),
      'dismissed': false,
      'type': 'system',
      'createdBy': role,
    });
  } else {
    throw Exception('Not authorized to create system notifications');
  }
}

Future<void> addEmployee(String name, String email) async {
  final usersRef = FirebaseFirestore.instance.collection('users');

  await usersRef.add({
    'name': name,
    'email': email,
    'role': 'employee',
    'createdAt': FieldValue.serverTimestamp(),
    'createdBy': name,
  });

  await FirebaseFirestore.instance.collection('notifications').add({
    'title': 'New Employee Registered',
    'message': '$name has been added to the system',
    'time': FieldValue.serverTimestamp(),
    'dismissed': false,
    'type': 'system',
    'createdBy': 'system',
  });
}

Future<void> logSecurityWarning(String message) async {
  await FirebaseFirestore.instance.collection('notifications').add({
    'title': 'Security Warning',
    'message': message,
    'time': FieldValue.serverTimestamp(),
    'dismissed': false,
    'type': 'security',
    'createdBy': 'system',
  });
}
