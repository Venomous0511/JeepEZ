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
        title: const Text(
          'Inspector Report History',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
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
            _styledCardWhite(_buildReportTable(context)),
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

  Widget _buildReportTable(BuildContext context) {
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
          headingTextStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          dataRowColor: WidgetStateProperty.resolveWith<Color>((
            Set<WidgetState> states,
          ) {
            if (states.contains(WidgetState.selected)) {
              return Theme.of(context).colorScheme.primary.withOpacity(0.08);
            }
            return Colors.white;
          }),
          columnSpacing: 20,
          horizontalMargin: 12,
          columns: const [
            DataColumn(
              label: SizedBox(
                width: 120,
                child: Text('Report ID', overflow: TextOverflow.ellipsis),
              ),
            ),
            DataColumn(
              label: SizedBox(
                width: 100,
                child: Text('Date', overflow: TextOverflow.ellipsis),
              ),
            ),
            DataColumn(
              label: SizedBox(
                width: 120,
                child: Text('Inspector', overflow: TextOverflow.ellipsis),
              ),
            ),
            DataColumn(
              label: SizedBox(
                width: 80,
                child: Text('Violations', overflow: TextOverflow.ellipsis),
              ),
            ),
            DataColumn(
              label: SizedBox(
                width: 100,
                child: Text('Status', overflow: TextOverflow.ellipsis),
              ),
            ),
            DataColumn(
              label: SizedBox(
                width: 80,
                child: Text('Actions', overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          rows: reports.map((report) {
            return DataRow(
              cells: [
                DataCell(
                  SizedBox(
                    width: 120,
                    child: Text(report['id'], overflow: TextOverflow.ellipsis),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 100,
                    child: Text(
                      report['date'],
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 120,
                    child: Text(
                      report['inspector'],
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 80,
                    child: Text(
                      report['violations'].toString(),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 100,
                    child: Text(
                      report['status'],
                      style: TextStyle(
                        color: _getStatusColor(report['status']),
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 80,
                    child: IconButton(
                      icon: const Icon(Icons.visibility, size: 20),
                      onPressed: () {
                        // Navigate to report details
                      },
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
