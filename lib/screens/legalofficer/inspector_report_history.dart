import 'package:flutter/material.dart';
import '../../models/app_user.dart';

class InspectorReportHistoryScreen extends StatelessWidget {
  const InspectorReportHistoryScreen({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Color(0xFF0D2364),
        title: const Text('Inspector Report History'),
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
                    Navigator.pushReplacementNamed(context, '/legal-dashboard');
                  }),
                  _drawerItem(context, 'Inspector Report History', () {}),
                  _drawerItem(context, 'Violation Report Management', () {
                    Navigator.pushNamed(context, '/violation-management');
                  }),
                  _drawerItem(context, 'Incident Report Management', () {
                    Navigator.pushNamed(context, '/incident-management');
                  }),
                  _drawerItem(context, 'Employee List View', () {
                    Navigator.pushNamed(context, '/employee-list');
                  }),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text(
                  'Logout',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
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
            // Metrics Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMetricCard(
                  context,
                  title: 'Reports Filed',
                  value: '32',
                  onTap: () =>
                      _showMetricDetails(context, 'Reports Filed', '32'),
                ),
                _buildMetricCard(
                  context,
                  title: 'Total Inspections Conducted',
                  value: '113',
                  onTap: () =>
                      _showMetricDetails(context, 'Total Inspections', '113'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Report History Section
            _sectionTitle('Report History'),
            _styledCardWhite(_buildReportTable()),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.4,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFF0D2364),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMetricDetails(BuildContext context, String title, String value) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text('Total: $value'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
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
          const Icon(Icons.directions_bus, size: 32, color: Colors.indigo),
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
        style: TextStyle(
          color: title == 'Inspector Report History'
              ? Color(0xFF0D2364)
              : Colors.black87,
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
          color: Colors.black87,
        ),
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
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }

  Widget _buildReportTable() {
    // Sample report data - in a real app, this would come from your data source
    final List<Map<String, dynamic>> reports = [
      {
        'id': 'RPT-2023-001',
        'date': '2023-09-10',
        'inspector': 'Juan Dela Cruz',
        'violations': 3,
        'status': 'Approved',
      },
      {
        'id': 'RPT-2023-002',
        'date': '2023-09-09',
        'inspector': 'Maria Lopez',
        'violations': 2,
        'status': 'Pending',
      },
      {
        'id': 'RPT-2023-003',
        'date': '2023-09-08',
        'inspector': 'Pedro Santos',
        'violations': 5,
        'status': 'Rejected',
      },
      {
        'id': 'RPT-2023-004',
        'date': '2023-09-07',
        'inspector': 'Juan Dela Cruz',
        'violations': 1,
        'status': 'Approved',
      },
      {
        'id': 'RPT-2023-005',
        'date': '2023-09-06',
        'inspector': 'Maria Lopez',
        'violations': 4,
        'status': 'Approved',
      },
    ];

    return DataTable(
      headingRowColor: WidgetStateProperty.all(Colors.grey.shade300),
      columnSpacing: 12,
      columns: const [
        DataColumn(
          label: Text(
            'Report ID',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        DataColumn(
          label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataColumn(
          label: Text(
            'Inspector',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        DataColumn(
          label: Text(
            'Violations',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        DataColumn(
          label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataColumn(
          label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
      rows: reports.map((report) {
        return DataRow(
          cells: [
            DataCell(Text(report['id'])),
            DataCell(Text(report['date'])),
            DataCell(Text(report['inspector'])),
            DataCell(Text(report['violations'].toString())),
            DataCell(
              Text(
                report['status'],
                style: TextStyle(
                  color: _getStatusColor(report['status']),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataCell(
              IconButton(
                icon: const Icon(Icons.visibility, size: 20),
                onPressed: () {
                  // Navigate to report details
                },
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
