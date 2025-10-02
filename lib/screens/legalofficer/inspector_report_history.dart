import 'package:flutter/material.dart';
import '../../models/app_user.dart';

class InspectorReportHistoryScreen extends StatelessWidget {
  const InspectorReportHistoryScreen({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2364),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Inspector Report History',
            style: TextStyle(color: Colors.white, fontSize: isMobile ? 16 : 20),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Metrics Section
            if (isMobile)
              _buildMobileMetrics(context)
            else if (isTablet)
              _buildTabletMetrics(context)
            else
              _buildDesktopMetrics(context),

            SizedBox(height: isMobile ? 16 : 24),

            // Report History Section
            _sectionTitle('Report History', isMobile),
            const SizedBox(height: 8),

            if (isMobile)
              _buildReportCards(context)
            else
              _styledCardWhite(_buildReportTable(context), isMobile),
          ],
        ),
      ),
    );
  }

  // Mobile: Stacked metric cards
  Widget _buildMobileMetrics(BuildContext context) {
    return Column(
      children: [
        _buildMetricCard(
          context,
          title: 'Reports Filed',
          value: '32',
          onTap: () => _showMetricDetails(context, 'Reports Filed', '32'),
          width: double.infinity,
        ),
        const SizedBox(height: 12),
        _buildMetricCard(
          context,
          title: 'Total Inspections Conducted',
          value: '113',
          onTap: () => _showMetricDetails(context, 'Total Inspections', '113'),
          width: double.infinity,
        ),
      ],
    );
  }

  // Tablet: Row with equal width cards
  Widget _buildTabletMetrics(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            context,
            title: 'Reports Filed',
            value: '32',
            onTap: () => _showMetricDetails(context, 'Reports Filed', '32'),
            width: null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            context,
            title: 'Total Inspections Conducted',
            value: '113',
            onTap: () =>
                _showMetricDetails(context, 'Total Inspections', '113'),
            width: null,
          ),
        ),
      ],
    );
  }

  // Desktop: Row with spaced cards
  Widget _buildDesktopMetrics(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildMetricCard(
          context,
          title: 'Reports Filed',
          value: '32',
          onTap: () => _showMetricDetails(context, 'Reports Filed', '32'),
          width: MediaQuery.of(context).size.width * 0.35,
        ),
        _buildMetricCard(
          context,
          title: 'Total Inspections Conducted',
          value: '113',
          onTap: () => _showMetricDetails(context, 'Total Inspections', '113'),
          width: MediaQuery.of(context).size.width * 0.35,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required VoidCallback onTap,
    required double? width,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: EdgeInsets.all(isMobile ? 20.0 : 24.0),
        decoration: BoxDecoration(
          color: const Color(0xFF0D2364),
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
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: isMobile ? 12 : 16),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 32 : 36,
                fontWeight: FontWeight.bold,
                height: 1.0,
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

  Widget _sectionTitle(String title, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: isMobile ? 18 : 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _styledCardWhite(Widget child, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
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

  // Mobile card view for reports
  Widget _buildReportCards(BuildContext context) {
    final List<Map<String, dynamic>> reports = _getSampleReports();

    return Column(
      children: reports.map((report) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: InkWell(
            onTap: () {
              // Navigate to report details
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with ID and status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          report['id'] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D2364),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            report['status'] as String,
                          ).withAlpha(1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getStatusColor(report['status'] as String),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          report['status'] as String,
                          style: TextStyle(
                            color: _getStatusColor(report['status'] as String),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Report details
                  _buildInfoRow(
                    'Date',
                    report['date'] as String,
                    Icons.calendar_today,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    'Inspector',
                    report['inspector'] as String,
                    Icons.person,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    'Violations',
                    report['violations'].toString(),
                    Icons.warning,
                  ),
                  const SizedBox(height: 16),

                  // Action button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        // Navigate to report details
                      },
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('View Details'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF0D2364),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReportTable(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final reports = _getSampleReports();

    return DataTable(
      headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
      headingTextStyle: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.black87,
        fontSize: isTablet ? 14 : 16,
      ),
      dataTextStyle: TextStyle(
        fontSize: isTablet ? 13 : 15,
        color: Colors.black87,
      ),
      dataRowColor: WidgetStateProperty.resolveWith<Color>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.selected)) {
          return Theme.of(context).colorScheme.primary.withAlpha(8);
        }
        return Colors.white;
      }),
      columnSpacing: isTablet ? 20 : 24,
      horizontalMargin: isTablet ? 16 : 20,
      dataRowMinHeight: 60,
      dataRowMaxHeight: 60,
      columns: [
        DataColumn(
          label: SizedBox(
            width: isTablet ? 120 : 140,
            child: const Text('Report ID', overflow: TextOverflow.ellipsis),
          ),
        ),
        DataColumn(
          label: SizedBox(
            width: isTablet ? 100 : 120,
            child: const Text('Date', overflow: TextOverflow.ellipsis),
          ),
        ),
        DataColumn(
          label: SizedBox(
            width: isTablet ? 120 : 140,
            child: const Text('Inspector', overflow: TextOverflow.ellipsis),
          ),
        ),
        DataColumn(
          label: SizedBox(
            width: isTablet ? 80 : 100,
            child: const Text('Violations', overflow: TextOverflow.ellipsis),
          ),
        ),
        DataColumn(
          label: SizedBox(
            width: isTablet ? 100 : 120,
            child: const Text('Status', overflow: TextOverflow.ellipsis),
          ),
        ),
        DataColumn(
          label: SizedBox(
            width: isTablet ? 80 : 100,
            child: const Text('Actions', overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      rows: reports.map((report) {
        return DataRow(
          cells: [
            DataCell(
              SizedBox(
                width: isTablet ? 120 : 140,
                child: Text(
                  report['id'] as String,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            DataCell(
              SizedBox(
                width: isTablet ? 100 : 120,
                child: Text(
                  report['date'] as String,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            DataCell(
              SizedBox(
                width: isTablet ? 120 : 140,
                child: Text(
                  report['inspector'] as String,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            DataCell(
              SizedBox(
                width: isTablet ? 80 : 100,
                child: Center(
                  child: Text(
                    report['violations'].toString(),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: isTablet ? 14 : 16,
                    ),
                  ),
                ),
              ),
            ),
            DataCell(
              SizedBox(
                width: isTablet ? 100 : 120,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      report['status'] as String,
                    ).withAlpha(1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _getStatusColor(report['status'] as String),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    report['status'] as String,
                    style: TextStyle(
                      color: _getStatusColor(report['status'] as String),
                      fontWeight: FontWeight.bold,
                      fontSize: isTablet ? 12 : 13,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            DataCell(
              SizedBox(
                width: isTablet ? 80 : 100,
                child: Center(
                  child: IconButton(
                    icon: Icon(
                      Icons.visibility,
                      size: isTablet ? 20 : 22,
                      color: const Color(0xFF0D2364),
                    ),
                    onPressed: () {
                      // Navigate to report details
                    },
                    tooltip: 'View Details',
                  ),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  List<Map<String, dynamic>> _getSampleReports() {
    return [
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
