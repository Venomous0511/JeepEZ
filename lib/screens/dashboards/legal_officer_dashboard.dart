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

  final List<Map<String, dynamic>> inspectors = const [
    {
      'name': 'Juan Dela Cruz',
      'area': 'Area A (North)',
      'inspections': 45,
      'reports': 12,
      'score': '20/25',
    },
    {
      'name': 'Maria Lopez',
      'area': 'Area B (East)',
      'inspections': 38,
      'reports': 9,
      'score': '20/25',
    },
    {
      'name': 'Pedro Santos',
      'area': 'Area C (West)',
      'inspections': 25,
      'reports': 6,
      'score': '20/25',
    },
  ];

  final List<Map<String, dynamic>> incidents = const [
    {
      'id': 'INC-001',
      'date': '2025-09-01',
      'assigned': 'Juan Dela Cruz',
      'type': 'Accident / Collision',
      'priority': 'Critical',
      'status': 'Open',
    },
    {
      'id': 'INC-002',
      'date': '2025-09-02',
      'assigned': 'Pedro Santos',
      'type': 'Traffic Violation',
      'priority': 'Medium',
      'status': 'Under Investigation',
    },
    {
      'id': 'INC-003',
      'date': '2025-09-03',
      'assigned': 'Maria Lopez',
      'type': 'Passenger Misconduct',
      'priority': 'Low',
      'status': 'Closed',
    },
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// ---------------- NOTIFICATION FUNCTIONS  ----------------
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
        return Color(0xFF0D2364);
    }
  }

  Stream<QuerySnapshot> getNotificationsStream(String role) {
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

  /// ---------------- SIGN OUT  ----------------
  Future<void> _signOut() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);

    try {
      // show loading for 3 seconds before signing out
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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Legal Officer Dashboard'),
        backgroundColor: const Color(0xFF0D2364),
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF0D2364)),
              accountName: Text(
                widget.user.name ?? 'Legal Officer',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              accountEmail: Text(
                "Employee ID: ${widget.user.employeeId}",
                style: const TextStyle(fontSize: 14),
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.gavel, color: Color(0xFF0D2364)),
              ),
            ),

            // Expanded ListView for menu items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(Icons.home, color: Color(0xFF0D2364)),
                    title: const Text('Home'),
                    selected: _selectedIndex == 0,
                    onTap: () {
                      _onItemTapped(0);
                      Navigator.pop(context);
                    },
                  ),

                  // Notification Bill
                  ListTile(
                    leading: const Icon(
                      Icons.notifications,
                      color: Color(0xFF0D2364),
                    ),
                    title: const Text('Notifications'),
                    selected: _selectedIndex == 1,
                    onTap: () {
                      _onItemTapped(1);
                      Navigator.pop(context);
                    },
                  ),

                  // Inspector Report History
                  ListTile(
                    leading: const Icon(
                      Icons.history,
                      color: Color(0xFF0D2364),
                    ),
                    title: const Text('Inspector Report History'),
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

                  // Violation Report Management
                  ListTile(
                    leading: const Icon(
                      Icons.report_problem,
                      color: Color(0xFF0D2364),
                    ),
                    title: const Text('Violation Report Management'),
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

                  // Incident Report Management
                  ListTile(
                    leading: const Icon(
                      Icons.warning,
                      color: Color(0xFF0D2364),
                    ),
                    title: const Text('Incident Report Management'),
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

                  // Employee List View
                  ListTile(
                    leading: const Icon(Icons.people, color: Color(0xFF0D2364)),
                    title: const Text('Employee List View'),
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

                  // Hiring Management
                  ListTile(
                    leading: const Icon(Icons.work, color: Color(0xFF0D2364)),
                    title: const Text('Hiring Management'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HiringManagementScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Logout pinned at bottom
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
            const SizedBox(height: 12), // spacing at bottom
          ],
        ),
      ),
      body: _getSelectedScreen(),
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
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D2364),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
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
                        final data = docs[index].data() as Map<String, dynamic>;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Icon(
                              _getIconForType(data['type'] ?? ''),
                              color: _getColorForType(data['type'] ?? ''),
                            ),
                            title: Text(
                              data['title'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(data['message']),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('MMM d, y hh:mm a').format(
                                    (data['time'] as Timestamp).toDate(),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.close, size: 18),
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
        ),
      ],
    );
  }

  /// ---------------- HOME SCREEN  ----------------
  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Inspector Leaderboard'),
          _buildInspectorTableWithScroll(),
          const SizedBox(height: 24),
          _sectionTitle('Incident Tracking'),
          _buildIncidentTableWithScroll(),
          const SizedBox(height: 24),
          _sectionTitle('Violations by Type'),
          _styledCard(_buildViolationChart()),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _styledCard(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF0D2364),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.white, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white),
        child: child,
      ),
    );
  }

  Widget _buildInspectorTableWithScroll() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF0D2364),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Color(0xFF0D2364)),
          columns: const [
            DataColumn(
              label: Text(
                'Inspector Name',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Area Assigned',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Inspections',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Reports',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            DataColumn(
              label: SizedBox(
                width: 60,
                child: Center(
                  child: Text(
                    '',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
          rows: inspectors.map((i) {
            return DataRow(
              cells: [
                DataCell(
                  Text(i['name'], style: TextStyle(color: Colors.white)),
                ),
                DataCell(
                  Text(i['area'], style: TextStyle(color: Colors.white)),
                ),
                DataCell(
                  Center(
                    child: Text(
                      i['inspections'].toString(),
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                DataCell(
                  Center(
                    child: Text(
                      i['reports'].toString(),
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                DataCell(
                  Center(
                    child: Text(
                      i['score'],
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildIncidentTableWithScroll() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.grey, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey.shade300),
          columnSpacing: 20,
          columns: const [
            DataColumn(
              label: Text(
                'ID',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Date',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Assigned',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Incident Type',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Priority',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Status',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ],
          rows: incidents.map((i) {
            Color priorityColor = Colors.black;
            switch (i['priority']) {
              case 'Critical':
                priorityColor = Colors.red;
                break;
              case 'Medium':
                priorityColor = Colors.orange;
                break;
              case 'Low':
                priorityColor = Colors.green;
                break;
            }

            return DataRow(
              cells: [
                DataCell(Text(i['id'])),
                DataCell(Text(i['date'])),
                DataCell(Text(i['assigned'])),
                DataCell(Text(i['type'])),
                DataCell(
                  Text(
                    i['priority'],
                    style: TextStyle(
                      color: priorityColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataCell(Text(i['status'])),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildViolationChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Most Common Violation Type: Traffic Violation',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        _buildViolationItem('Traffic Violation', 70),
        const SizedBox(height: 12),
        _buildViolationItem('Passenger Misconduct', 40),
        const SizedBox(height: 12),
        _buildViolationItem('Overloading', 30),
        const SizedBox(height: 12),
        _buildViolationItem('Other Violations', 20),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.spaceEvenly,
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildChartLegend(Colors.blue, 'Traffic Violation'),
            _buildChartLegend(Colors.green, 'Passenger Misconduct'),
            _buildChartLegend(Colors.orange, 'Overloading'),
            _buildChartLegend(Colors.red, 'Other Violations'),
          ],
        ),
      ],
    );
  }

  Widget _buildViolationItem(String label, int percentage) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmallScreen = constraints.maxWidth < 400;

        return Row(
          children: [
            SizedBox(
              width: isSmallScreen ? 120 : 150,
              child: Text(
                label,
                style: const TextStyle(fontSize: 14, color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: Colors.white.withAlpha(128),
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getColorForViolationType(label),
                ),
                minHeight: 20,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 40,
              child: Text(
                '$percentage%',
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getColorForViolationType(String type) {
    switch (type) {
      case 'Traffic Violation':
        return Colors.blue;
      case 'Passenger Misconduct':
        return Colors.green;
      case 'Overloading':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  Widget _buildChartLegend(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: Colors.white),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
