import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../legalofficer/inspector_report_history.dart';
import '../legalofficer/violation_report_management.dart';
import '../legalofficer/employee_list_view.dart';
import '../legalofficer/inspector_report_management.dart';
import '../legalofficer/hiring_management.dart';

class LegalOfficerDashboardScreen extends StatefulWidget {
  const LegalOfficerDashboardScreen({super.key, required this.user});

  final AppUser user;

  @override
  State<LegalOfficerDashboardScreen> createState() =>
      _LegalOfficerDashboardScreenState();
}

class _LegalOfficerDashboardScreenState
    extends State<LegalOfficerDashboardScreen> {
  bool _isLoggingOut = false;
  int _selectedIndex = 0;

  Stream<List<Map<String, dynamic>>> getInspectorsStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'inspector')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<List<Map<String, dynamic>>> getIncidentReportsStream() async* {
    final incidentSnapshot =
    await FirebaseFirestore.instance.collection('incident_report').get();

    // Extract all unique createdById
    final userIds = incidentSnapshot.docs
        .map((doc) => doc.data()['createdById'] as String)
        .toSet()
        .toList();

    // Fetch users in batch
    final userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, whereIn: userIds)
        .get();

    // Map userId to name
    final userMap = {for (var doc in userSnapshot.docs) doc.id: doc.data()['name']};

    // Build list of incidents with user name
    final incidentsWithNames = incidentSnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'type': data['type'] ?? '',
        'description': data['description'] ?? '',
        'location': data['location'] ?? '',
        'persons': data['persons'] ?? '',
        'timestamp': data['timestamp'],
        'employeeName': userMap[data['createdById']] ?? 'Unknown',
      };
    }).toList();

    yield incidentsWithNames;
  }

  Stream<Map<String, int>> getViolationCountsStream() {
    return FirebaseFirestore.instance
        .collection('incident_report')
        .snapshots()
        .map((snapshot) {
      final Map<String, int> counts = {};
      for (var doc in snapshot.docs) {
        final type = doc['type'] ?? 'Unknown';
        counts[type] = (counts[type] ?? 0) + 1;
      }
      return counts;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// ---------------- NOTIFICATION FUNCTIONS  ----------------
  Stream<QuerySnapshot<Map<String, dynamic>>> getNotificationsStream(String role,) {
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

  /// ---------------- SIGN OUT  ----------------
  Future<void> _signOut() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);

    try {
      // If you actually want to wait (e.g., show spinner), keep the delay. Otherwise remove.
      await Future.delayed(const Duration(seconds: 1));
      await AuthService().logout();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to sign out: $e')));
      setState(() => _isLoggingOut = false);
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
                    final type = (data['type'] ?? 'updates') as String;
                    final message = (data['message'] ?? 'No message') as String;
                    // Safe check for 'read' field
                    final isRead = (data['read'] ?? false) as bool;

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
                                    _formatTimestampSafe(data['time']),
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

  String _formatTimestampSafe(dynamic ts) {
    try {
      if (ts is Timestamp) {
        final dt = ts.toDate();
        return DateFormat('MMM d, y hh:mm a').format(dt);
      } else if (ts is DateTime) {
        return DateFormat('MMM d, y hh:mm a').format(ts);
      } else {
        return ts?.toString() ?? '';
      }
    } catch (_) {
      return ts?.toString() ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Legal Officer Dashboard',
            style: TextStyle(fontSize: screenWidth < 360 ? 16 : 20),
          ),
        ),
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
      drawer: _buildResponsiveDrawer(),
      body: _getSelectedScreen(),
    );
  }

  Widget _buildResponsiveDrawer() {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF0D2364)),
            accountName: Text(
              widget.user.name ?? 'Legal Officer',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(
              "Employee ID: ${widget.user.employeeId}",
              style: const TextStyle(fontSize: 14),
            ),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.gavel, color: Color(0xFF0D2364), size: 32),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.home,
                  title: 'Home',
                  isSelected: _selectedIndex == 0,
                  onTap: () {
                    _onItemTapped(0);
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.history,
                  title: 'Inspector Report History',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            InspectorReportHistoryScreen(user: widget.user),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.report_problem,
                  title: 'Violation Report Management',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ViolationReportHistoryScreen(user: widget.user),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.warning,
                  title: 'Incident Report Management',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            IncidentReportManagementScreen(user: widget.user),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.people,
                  title: 'Employee List View',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EmployeeListViewScreen(user: widget.user),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.work,
                  title: 'Hiring Management',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HiringManagementScreen(),
                      ),
                    );
                  },
                ),
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
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF0D2364)),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onTap: onTap,
    );
  }

  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return _buildNotificationScreen();
      default:
        return _buildHomeContent();
    }
  }

  /// ---------------- NOTIFICATION SCREEN  ----------------
  Widget _buildNotificationScreen() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notifications',
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0D2364),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: getNotificationsStream(widget.user.role),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No notifications',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                        leading: Icon(
                          _getIconForType((data['type'] ?? '') as String),
                          color: _getColorForType((data['type'] ?? '') as String),
                          size: isMobile ? 20 : 24,
                        ),
                        title: Text(
                          (data['title'] ?? 'Notification') as String,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 14 : 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              (data['message'] ?? '') as String,
                              style: TextStyle(fontSize: isMobile ? 12 : 14),
                            ),
                            const SizedBox(height: 4),
                            if (data['time'] != null)
                              Text(
                                _formatTimestampSafe(data['time']),
                                style: TextStyle(
                                  fontSize: isMobile ? 11 : 12,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.close, size: isMobile ? 16 : 18),
                          onPressed: () async {
                            await docs[index].reference.update({
                              'dismissed': true,
                            });
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// ---------------- HOME SCREEN  ----------------
  Widget _buildHomeContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isMobile = screenWidth < 600;
        final isTablet = screenWidth >= 600 && screenWidth < 1024;
        final isDesktop = screenWidth >= 1024;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isMobile)
                _buildMobileLayout()
              else if (isTablet)
                _buildTabletLayout()
              else
                _buildDesktopLayout(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Inspector View'),
        const SizedBox(height: 8),
        _buildInspectorCards(),
        const SizedBox(height: 24),
        _sectionTitle('Incident Tracking'),
        const SizedBox(height: 8),
        _buildIncidentCards(),
        const SizedBox(height: 24),
        _sectionTitle('Violations by Type'),
        const SizedBox(height: 8),
        _styledCard(_buildViolationChart()),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Column(
      children: [
        _sectionTitle('Inspector Leaderboard'),
        const SizedBox(height: 8),
        _buildInspectorTableWithScroll(),
        const SizedBox(height: 24),
        _sectionTitle('Incident Tracking'),
        const SizedBox(height: 8),
        _buildIncidentTable(),
        const SizedBox(height: 24),
        _sectionTitle('Violations by Type'),
        const SizedBox(height: 8),
        _styledCard(_buildViolationChart()),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Inspector Leaderboard'),
                  const SizedBox(height: 8),
                  _buildInspectorTableWithScroll(),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Incident Tracking'),
                  const SizedBox(height: 8),
                  _buildIncidentTable(),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _sectionTitle('Violations by Type'),
        const SizedBox(height: 8),
        _styledCard(_buildViolationChart()),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: isMobile ? 16 : 20,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _styledCard(Widget child) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2364),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white),
        child: child,
      ),
    );
  }

  // Mobile Card Views for Inspector and Incidents
  Widget _buildInspectorCards() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: getInspectorsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No inspectors found'));
        }

        final inspectors = snapshot.data!;

        return Column(
          children: inspectors.map((inspector) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D2364),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inspector['name'] ?? 'No Name',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow('Area', inspector['area'] ?? ''),
                    _buildInfoRow(
                      'Employee ID',
                      inspector['employeeId'] ?? '',
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildIncidentCards() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: getIncidentReportsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No incidents found'));
        }

        final incidents = snapshot.data!;

        // Sort incidents by timestamp (optional)
        final sortedIncidents = List<Map<String, dynamic>>.from(incidents)
          ..sort((a, b) {
            final t1 = a['timestamp'] as Timestamp?;
            final t2 = b['timestamp'] as Timestamp?;
            if (t1 == null || t2 == null) return 0;
            return t1.compareTo(t2);
          });

        return Column(
          children: sortedIncidents.asMap().entries.map((entry) {
            final index = entry.key;
            final incident = entry.value;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // <-- GENERATED INCIDENT ID
                        Text(
                          'INC-${(index + 1).toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Date',
                      incident['timestamp'] != null
                          ? DateFormat('MMM d, y hh:mm a')
                          .format((incident['timestamp'] as Timestamp).toDate())
                          : '',
                      isDark: false,
                    ),
                    _buildInfoRow(
                      'Assigned',
                      incident['employeeName'] ?? incident['createdById'] ?? '',
                      isDark: false,
                    ),
                    _buildInfoRow(
                      'Type',
                      incident['type'] ?? '',
                      isDark: false,
                    ),
                    _buildInfoRow(
                      'Location',
                      incident['location'] ?? '',
                      isDark: false,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isDark = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspectorTableWithScroll() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: getInspectorsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No inspectors found'));
        }

        final inspectors = snapshot.data!;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: isTablet ? 600 : 700),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFF0D2364)),
              dataRowColor: WidgetStateProperty.all(const Color(0xFF0D2364)),
              headingTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              dataTextStyle: const TextStyle(color: Colors.white),
              columns: [
                DataColumn(
                  label: Text(
                    'Inspector Name',
                    style: TextStyle(fontSize: isTablet ? 12 : 14),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Area Assigned',
                    style: TextStyle(fontSize: isTablet ? 12 : 14),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Employee ID',
                    style: TextStyle(fontSize: isTablet ? 12 : 14),
                  ),
                ),
              ],
              rows: inspectors.map((i) {
                return DataRow(
                  cells: [
                    DataCell(Text(i['name'] ?? '')),
                    DataCell(Text(i['area'] ?? '')),
                    DataCell(Text(i['employeeId'] ?? '')),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  // FIXED INCIDENT TABLE - HINDI NA SCROLLABLE
  Widget _buildIncidentTable() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: getIncidentReportsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final incidents = snapshot.data!;

        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance.collection('users').get(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) return const CircularProgressIndicator();

            // Map userId -> name
            final userMap = {
              for (var doc in userSnapshot.data!.docs)
                doc.id: (doc.data() as Map<String, dynamic>)['name']
            };

            final sortedIncidents = List<Map<String, dynamic>>.from(incidents)
              ..sort((a, b) {
                final t1 = a['timestamp'] as Timestamp?;
                final t2 = b['timestamp'] as Timestamp?;
                if (t1 == null || t2 == null) return 0;
                return t1.compareTo(t2);
              });

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Assigned')),
                  DataColumn(label: Text('Type')),
                ],
                rows: sortedIncidents.asMap().entries.map((entry) {
                  final index = entry.key;
                  final incident = entry.value;
                  final assignedName = userMap[incident['createdById']] ?? '';

                  return DataRow(
                    cells: [
                      DataCell(Text('INC-${(index + 1).toString().padLeft(2, '0')}')),
                      DataCell(Text(incident['timestamp'] != null
                          ? DateFormat('MMM d, y hh:mm a')
                          .format((incident['timestamp'] as Timestamp).toDate())
                          : '')),
                      DataCell(Text(assignedName)),
                      DataCell(Text(incident['type'] ?? '')),
                    ],
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildViolationChart() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return StreamBuilder<Map<String, int>>(
      stream: getViolationCountsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();

        final counts = snapshot.data!;
        if (counts.isEmpty) return const Text('No violations found');

        // Get the most common violation type
        final mostCommon = counts.entries
            .reduce((a, b) => a.value >= b.value ? a : b)
            .key;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Most Common Violation Type: $mostCommon',
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            ...counts.entries.map((e) => Padding(
              padding: EdgeInsets.only(bottom: isMobile ? 8 : 12),
              child: _buildViolationItem(e.key, e.value),
            )),
          ],
        );
      },
    );
  }

  Widget _buildViolationItem(String label, int count) {
    final total = 100; // Or calculate total from counts if you want %
    final percentage = (count / total * 100).clamp(0, 100).toInt();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 400;

        return Row(
          children: [
            SizedBox(
              width: isSmallScreen ? 100 : 150,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: Colors.white.withAlpha(5),
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getColorForViolationType(label),
                ),
                minHeight: isSmallScreen ? 16 : 20,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: isSmallScreen ? 35 : 40,
              child: Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getColorForViolationType(String type) {
    switch (type) {
      case '':
        return Colors.red;
      case 'Traffic Violation':
        return Colors.blue;
      case 'Passenger Misconduct':
        return Colors.green;
      case 'Fare / Ticket Issue':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
