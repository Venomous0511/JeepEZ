import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../legalofficer/inspector_report_history.dart';
import '../legalofficer/violation_report_management.dart';
import '../legalofficer/employee_list_view.dart';
import '../legalofficer/inspector_report_management.dart';
import '../legalofficer/hiring_management.dart';

class LegalOfficerDashboardScreen extends StatelessWidget {
  const LegalOfficerDashboardScreen({super.key, required this.user});

  final AppUser user;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Color(0xFF0D2364),
        title: const Text(
          'Legal Officer',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF0D2364)),
              child: Row(
                children: [
                  _buildJeepEZLogo(),
                  const SizedBox(width: 12),
                  const Text(
                    'Admin (Legal Officer)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  _drawerItem(context, 'Home', () {
                    Navigator.pop(context);
                  }),
                  _drawerItem(context, 'Inspector Report History', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            InspectorReportHistoryScreen(user: user),
                      ),
                    );
                  }),
                  _drawerItem(context, 'Violation Report Management', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ViolationReportHistoryScreen(user: user),
                      ),
                    );
                  }),
                  _drawerItem(context, 'Incident Report Management', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            IncidentReportManagementScreen(user: user),
                      ),
                    );
                  }),
                  _drawerItem(context, 'Employee List View', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EmployeeListViewScreen(
                          user: user,
                        ), // ✅ Correct parameter name
                      ),
                    );
                  }),
                  // ADDED HIRING MANAGEMENT OPTION
                  _drawerItem(context, 'Hiring Management', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HiringManagementScreen(),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Color(0xFF0D2364)),
                title: const Text(
                  'Logout',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
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
      ),
    );
  }

  Widget _buildJeepEZLogo() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.directions_bus, size: 32, color: Color(0xFF0D2364)),
          Positioned(
            bottom: 2,
            child: Text(
              'JeepEZ',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D2364),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(BuildContext context, String title, VoidCallback onTap) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: onTap,
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
