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
        return const Color(0xFF0D2364);
    }
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

  /// ---------------- SIGN OUT  ----------------
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
                        contentPadding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                        leading: Icon(
                          _getIconForType(data['type'] ?? ''),
                          color: _getColorForType(data['type'] ?? ''),
                          size: isMobile ? 20 : 24,
                        ),
                        title: Text(
                          data['title'] ?? 'Notification',
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
                              data['message'] ?? '',
                              style: TextStyle(fontSize: isMobile ? 12 : 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat(
                                'MMM d, y hh:mm a',
                              ).format((data['time'] as Timestamp).toDate()),
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
        _sectionTitle('Inspector Leaderboard'),
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
        _buildIncidentTableWithScroll(),
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
                  _buildIncidentTableWithScroll(),
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
                  inspector['name'] as String,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                _buildInfoRow('Area', inspector['area'] as String),
                _buildInfoRow(
                  'Inspections',
                  inspector['inspections'].toString(),
                ),
                _buildInfoRow('Reports', inspector['reports'].toString()),
                _buildInfoRow('Score', inspector['score'] as String),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIncidentCards() {
    return Column(
      children: incidents.map((incident) {
        Color priorityColor = Colors.black;
        switch (incident['priority']) {
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
                    Text(
                      incident['id'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: priorityColor),
                      ),
                      child: Text(
                        incident['priority'] as String,
                        style: TextStyle(
                          color: priorityColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  'Date',
                  incident['date'] as String,
                  isDark: false,
                ),
                _buildInfoRow(
                  'Assigned',
                  incident['assigned'] as String,
                  isDark: false,
                ),
                _buildInfoRow(
                  'Type',
                  incident['type'] as String,
                  isDark: false,
                ),
                _buildInfoRow(
                  'Status',
                  incident['status'] as String,
                  isDark: false,
                ),
              ],
            ),
          ),
        );
      }).toList(),
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

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2364),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: isTablet ? 600 : 700),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFF0D2364)),
            dataRowMinHeight: 48,
            dataRowMaxHeight: 64,
            columns: [
              DataColumn(
                label: Text(
                  'Inspector Name',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: isTablet ? 12 : 14,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Area Assigned',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: isTablet ? 12 : 14,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Inspections',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: isTablet ? 12 : 14,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Reports',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: isTablet ? 12 : 14,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Score',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: isTablet ? 12 : 14,
                  ),
                ),
              ),
            ],
            rows: inspectors.map((i) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      i['name'] as String,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 12 : 14,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      i['area'] as String,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 12 : 14,
                      ),
                    ),
                  ),
                  DataCell(
                    Center(
                      child: Text(
                        i['inspections'].toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTablet ? 12 : 14,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Center(
                      child: Text(
                        i['reports'].toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTablet ? 12 : 14,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Center(
                      child: Text(
                        i['score'] as String,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTablet ? 12 : 14,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildIncidentTableWithScroll() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

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
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: isTablet ? 700 : 800),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.grey.shade300),
            columnSpacing: isTablet ? 12 : 20,
            dataRowMinHeight: 48,
            dataRowMaxHeight: 64,
            columns: [
              DataColumn(
                label: Text(
                  'ID',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: isTablet ? 12 : 14,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Date',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: isTablet ? 12 : 14,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Assigned',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: isTablet ? 12 : 14,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Incident Type',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: isTablet ? 12 : 14,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Priority',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: isTablet ? 12 : 14,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Status',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: isTablet ? 12 : 14,
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
                  DataCell(
                    Text(
                      i['id'] as String,
                      style: TextStyle(fontSize: isTablet ? 12 : 14),
                    ),
                  ),
                  DataCell(
                    Text(
                      i['date'] as String,
                      style: TextStyle(fontSize: isTablet ? 12 : 14),
                    ),
                  ),
                  DataCell(
                    Text(
                      i['assigned'] as String,
                      style: TextStyle(fontSize: isTablet ? 12 : 14),
                    ),
                  ),
                  DataCell(
                    Text(
                      i['type'] as String,
                      style: TextStyle(fontSize: isTablet ? 12 : 14),
                    ),
                  ),
                  DataCell(
                    Text(
                      i['priority'] as String,
                      style: TextStyle(
                        color: priorityColor,
                        fontWeight: FontWeight.bold,
                        fontSize: isTablet ? 12 : 14,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      i['status'] as String,
                      style: TextStyle(fontSize: isTablet ? 12 : 14),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildViolationChart() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Most Common Violation Type: Traffic Violation',
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        SizedBox(height: isMobile ? 8 : 12),
        _buildViolationItem('Overloading', 30),
        SizedBox(height: isMobile ? 8 : 12),
        _buildViolationItem('Other Violations', 20),
        SizedBox(height: isMobile ? 12 : 16),
        Wrap(
          alignment: WrapAlignment.spaceEvenly,
          spacing: isMobile ? 6 : 8,
          runSpacing: isMobile ? 6 : 8,
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
                backgroundColor: Colors.white.withOpacity(0.5),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isMobile ? 10 : 12,
          height: isMobile ? 10 : 12,
          color: color,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(fontSize: isMobile ? 10 : 12, color: Colors.white),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
