import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../legalofficer/inspector_report_history.dart';
import '../legalofficer/violation_report_management.dart';
import '../legalofficer/employee_list_view.dart';
import '../legalofficer/inspector_report_management.dart';

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
      'inspector': 'Juan Dela Cruz',
      'type': 'Traffic Violation',
      'priority': 'Critical',
      'status': 'Open',
    },
    {
      'id': 'INC-002',
      'date': '2025-09-02',
      'assigned': 'Pedro Santos',
      'inspector': 'Pedro Santos',
      'type': 'Traffic Violation',
      'priority': 'Medium',
      'status': 'Under Investigation',
    },
    {
      'id': 'INC-003',
      'date': '2025-09-03',
      'assigned': 'Maria Lopez',
      'inspector': 'Maria Lopez',
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
        title: const Text('JeepEZ Dashboard'),
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
                    // Already on home, just close drawer
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
                        builder: (context) =>
                            EmployeeListViewScreen(user: user),
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
            _styledCard(_buildInspectorTable()),
            const SizedBox(height: 24),
            _sectionTitle('Incident Tracking'),
            _styledCardWhite(_buildIncidentTable()),
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

  Widget _styledCardWhite(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.white, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInspectorTable() {
    return DataTable(
      headingRowColor: MaterialStateProperty.all(Color(0xFF0D2364)),
      columns: const [
        DataColumn(
          label: Text(
            'Inspector Name',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        DataColumn(
          label: Text(
            'Area Assigned',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        DataColumn(
          label: Text(
            'Inspections Conducted',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        DataColumn(
          label: Text(
            'Reports Filed',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        DataColumn(
          label: Text(
            'Score',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ],
      rows: inspectors.map((i) {
        return DataRow(
          cells: [
            DataCell(Text(i['name'])),
            DataCell(Text(i['area'])),
            DataCell(Text(i['inspections'].toString())),
            DataCell(Text(i['reports'].toString())),
            DataCell(Text(i['score'])),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildIncidentTable() {
    return DataTable(
      headingRowColor: MaterialStateProperty.all(Colors.grey.shade300),
      columnSpacing: 12,
      columns: const [
        DataColumn(
          label: Text(
            'ID',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
        DataColumn(
          label: Text(
            'Date',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
        DataColumn(
          label: Text(
            'Assigned',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
        DataColumn(
          label: Text(
            'Inspector',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
        DataColumn(
          label: Text(
            'Type',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
        DataColumn(
          label: Text(
            'Priority',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
        DataColumn(
          label: Text(
            'Status',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
      ],
      rows: incidents.map((i) {
        return DataRow(
          cells: [
            DataCell(Text(i['id'])),
            DataCell(Text(i['date'])),
            DataCell(Text(i['assigned'])),
            DataCell(Text(i['inspector'])),
            DataCell(Text(i['type'])),
            DataCell(Text(i['priority'])),
            DataCell(Text(i['status'])),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildViolationChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Most Common Violation Type: Traffic Violation',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _buildChartBar('Traffic Violation', 0.7),
              const SizedBox(height: 12),
              _buildChartBar('Passenger Misconduct', 0.4),
              const SizedBox(height: 12),
              _buildChartBar('Overloading', 0.3),
              const SizedBox(height: 12),
              _buildChartBar('Other Violations', 0.2),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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

  Widget _buildChartBar(String label, double percentage) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: const TextStyle(fontSize: 14)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
              _getColorForViolationType(label),
            ),
            minHeight: 20,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(percentage * 100).toInt()}%',
          style: const TextStyle(fontSize: 14),
        ),
      ],
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
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
