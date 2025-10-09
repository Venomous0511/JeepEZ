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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Metrics Section - Only Total Inspections Conducted
            if (isMobile)
              _buildMobileMetrics(context)
            else if (isTablet)
              _buildTabletMetrics(context)
            else
              _buildDesktopMetrics(context),

            SizedBox(height: isMobile ? 16 : 24),

            // Search and Filter Section
            _buildSearchFilterSection(isMobile),
            SizedBox(height: isMobile ? 16 : 24),

            // Report History Section
            _sectionTitle('Violation Reports', isMobile),
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

  // Mobile: Single metric card for Total Inspections
  Widget _buildMobileMetrics(BuildContext context) {
    return _buildMetricCard(
      context,
      title: 'Total Inspections Conducted',
      value: '113',
      onTap: () => _showMetricDetails(context, 'Total Inspections', '113'),
      width: double.infinity,
    );
  }

  // Tablet: Single metric card for Total Inspections
  Widget _buildTabletMetrics(BuildContext context) {
    return _buildMetricCard(
      context,
      title: 'Total Inspections Conducted',
      value: '113',
      onTap: () => _showMetricDetails(context, 'Total Inspections', '113'),
      width: null,
    );
  }

  // Desktop: Single metric card for Total Inspections
  Widget _buildDesktopMetrics(BuildContext context) {
    return _buildMetricCard(
      context,
      title: 'Total Inspections Conducted',
      value: '113',
      onTap: () => _showMetricDetails(context, 'Total Inspections', '113'),
      width: MediaQuery.of(context).size.width * 0.35,
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

  Widget _buildSearchFilterSection(bool isMobile) {
    return _styledCardWhite(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search Reports',
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Search Field
          TextField(
            decoration: InputDecoration(
              hintText:
                  'Search by Trip No, Inspector Name, Unit Number, or Driver Name...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Filter Row
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              // Date Filter
              _buildFilterChip('Today', Icons.today),
              _buildFilterChip('This Week', Icons.calendar_view_week),
              _buildFilterChip('This Month', Icons.calendar_month),
              _buildFilterChip('All Time', Icons.all_inclusive),
            ],
          ),
        ],
      ),
      isMobile,
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    return FilterChip(
      label: Text(label),
      avatar: Icon(icon, size: 16),
      onSelected: (bool value) {
        // Handle filter selection
      },
      backgroundColor: Colors.grey[200],
      selectedColor: const Color(0xFF0D2364),
      labelStyle: const TextStyle(color: Colors.black87),
      selected: label == 'All Time', // Default selection
      checkmarkColor: Colors.white,
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with Trip No
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'TRIP NO: ${report['tripNo']}',
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
                        color: _getViolationsColor(
                          report['violations'] as int,
                        ).withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getViolationsColor(
                            report['violations'] as int,
                          ),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        '${report['violations']} Violation${report['violations'] == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: _getViolationsColor(
                            report['violations'] as int,
                          ),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Report details in required arrangement
                _buildInfoRow(
                  'Inspector Name',
                  report['inspector'] as String,
                  Icons.person,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Date',
                  report['date'] as String,
                  Icons.calendar_today,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Unit Number',
                  report['unitNumber'] as String,
                  Icons.confirmation_number,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Driver Name',
                  report['driverName'] as String,
                  Icons.person_outline,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Conductor Name',
                  report['conductorName'] as String,
                  Icons.people_outline,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Ticket Inspection Time',
                  report['inspectionTime'] as String,
                  Icons.access_time,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Number of Passengers',
                  report['passengerCount'].toString(),
                  Icons.people,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Location',
                  report['location'] as String,
                  Icons.location_on,
                ),
              ],
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        constraints: BoxConstraints(minWidth: isTablet ? 1000 : 1200),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
          headingTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontSize: isTablet ? 12 : 14,
          ),
          dataTextStyle: TextStyle(
            fontSize: isTablet ? 11 : 13,
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
          columnSpacing: isTablet ? 16 : 20,
          horizontalMargin: isTablet ? 16 : 20,
          dataRowMinHeight: 60,
          dataRowMaxHeight: 60,
          columns: [
            DataColumn(
              label: SizedBox(
                width: isTablet ? 100 : 120,
                child: const Text('Trip No', overflow: TextOverflow.ellipsis),
              ),
            ),
            DataColumn(
              label: SizedBox(
                width: isTablet ? 120 : 140,
                child: const Text(
                  'Inspector Name',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            DataColumn(
              label: SizedBox(
                width: isTablet ? 90 : 110,
                child: const Text('Date', overflow: TextOverflow.ellipsis),
              ),
            ),
            DataColumn(
              label: SizedBox(
                width: isTablet ? 100 : 120,
                child: const Text(
                  'Unit Number',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            DataColumn(
              label: SizedBox(
                width: isTablet ? 120 : 140,
                child: const Text(
                  'Driver Name',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            DataColumn(
              label: SizedBox(
                width: isTablet ? 120 : 140,
                child: const Text(
                  'Conductor Name',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            DataColumn(
              label: SizedBox(
                width: isTablet ? 120 : 140,
                child: const Text(
                  'Ticket Inspection Time',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            DataColumn(
              label: SizedBox(
                width: isTablet ? 100 : 120,
                child: const Text(
                  'Passengers',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            DataColumn(
              label: SizedBox(
                width: isTablet ? 120 : 140,
                child: const Text('Location', overflow: TextOverflow.ellipsis),
              ),
            ),
            DataColumn(
              label: SizedBox(
                width: isTablet ? 80 : 100,
                child: const Text(
                  'Violations',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          rows: reports.map((report) {
            return DataRow(
              cells: [
                DataCell(
                  SizedBox(
                    width: isTablet ? 100 : 120,
                    child: Text(
                      report['tripNo'] as String,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
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
                    width: isTablet ? 90 : 110,
                    child: Text(
                      report['date'] as String,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: isTablet ? 100 : 120,
                    child: Text(
                      report['unitNumber'] as String,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: isTablet ? 120 : 140,
                    child: Text(
                      report['driverName'] as String,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: isTablet ? 120 : 140,
                    child: Text(
                      report['conductorName'] as String,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: isTablet ? 120 : 140,
                    child: Text(
                      report['inspectionTime'] as String,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: isTablet ? 100 : 120,
                    child: Center(
                      child: Text(
                        report['passengerCount'].toString(),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: isTablet ? 120 : 140,
                    child: Text(
                      report['location'] as String,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: isTablet ? 80 : 100,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getViolationsColor(
                            report['violations'] as int,
                          ).withAlpha(30),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _getViolationsColor(
                              report['violations'] as int,
                            ),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          '${report['violations']}',
                          style: TextStyle(
                            color: _getViolationsColor(
                              report['violations'] as int,
                            ),
                            fontWeight: FontWeight.bold,
                            fontSize: isTablet ? 11 : 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
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

  List<Map<String, dynamic>> _getSampleReports() {
    return [
      {
        'tripNo': 'TRIP-2023-001',
        'inspector': 'Juan Dela Cruz',
        'date': '2023-09-10',
        'unitNumber': 'UNIT-001',
        'driverName': 'Rodrigo Santos',
        'conductorName': 'Maria Clara',
        'inspectionTime': '08:30 AM',
        'passengerCount': 45,
        'location': 'Main Highway - KM 25',
        'violations': 3,
      },
      {
        'tripNo': 'TRIP-2023-002',
        'inspector': 'Maria Lopez',
        'date': '2023-09-09',
        'unitNumber': 'UNIT-078',
        'driverName': 'Carlos Reyes',
        'conductorName': 'Lorna Dimagiba',
        'inspectionTime': '02:15 PM',
        'passengerCount': 32,
        'location': 'City Center - Terminal A',
        'violations': 2,
      },
      {
        'tripNo': 'TRIP-2023-003',
        'inspector': 'Pedro Santos',
        'date': '2023-09-08',
        'unitNumber': 'UNIT-156',
        'driverName': 'Antonio Cruz',
        'conductorName': 'Josefina Luna',
        'inspectionTime': '11:45 AM',
        'passengerCount': 28,
        'location': 'North Expressway',
        'violations': 5,
      },
      {
        'tripNo': 'TRIP-2023-004',
        'inspector': 'Juan Dela Cruz',
        'date': '2023-09-07',
        'unitNumber': 'UNIT-045',
        'driverName': 'Roberto Garcia',
        'conductorName': 'Sofia Mendoza',
        'inspectionTime': '04:20 PM',
        'passengerCount': 38,
        'location': 'South Terminal',
        'violations': 1,
      },
      {
        'tripNo': 'TRIP-2023-005',
        'inspector': 'Maria Lopez',
        'date': '2023-09-06',
        'unitNumber': 'UNIT-189',
        'driverName': 'Miguel Torres',
        'conductorName': 'Elena Rodriguez',
        'inspectionTime': '09:10 AM',
        'passengerCount': 41,
        'location': 'Coastal Road',
        'violations': 4,
      },
    ];
  }

  Color _getViolationsColor(int violations) {
    if (violations == 0) {
      return Colors.green;
    } else if (violations <= 2) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
