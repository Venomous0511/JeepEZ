import 'package:flutter/material.dart';
import '../../models/app_user.dart';

class IncidentReportManagementScreen extends StatefulWidget {
  const IncidentReportManagementScreen({super.key, required this.user});

  final AppUser user;

  @override
  State<IncidentReportManagementScreen> createState() =>
      _IncidentReportManagementScreenState();
}

class _IncidentReportManagementScreenState
    extends State<IncidentReportManagementScreen> {
  String _selectedFilter = 'All';

  // Sample incident data
  final List<Map<String, dynamic>> incidents = const [
    {
      'unit': 'INC-001',
      'date': '2025-09-01',
      'type': 'Traffic Violation',
      'reporter': 'Juan Dela Cruz',
      'status': 'Open',
      'priority': 'High',
    },
    {
      'unit': 'INC-002',
      'date': '2025-09-02',
      'type': 'Passenger Misconduct',
      'reporter': 'Maria Lopez',
      'status': 'Under Investigation',
      'priority': 'Medium',
    },
    {
      'unit': 'INC-003',
      'date': '2025-09-03',
      'type': 'Overloading',
      'reporter': 'Pedro Santos',
      'status': 'Resolved',
      'priority': 'Low',
    },
    {
      'unit': 'INC-004',
      'date': '2025-09-04',
      'type': 'No Valid ID',
      'reporter': 'Ana Reyes',
      'status': 'Closed',
      'priority': 'Medium',
    },
    {
      'unit': 'INC-005',
      'date': '2025-09-05',
      'type': 'Smoking in Vehicle',
      'reporter': 'Carlos Gomez',
      'status': 'Open',
      'priority': 'Low',
    },
  ];

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
            'Incident Report Management',
            style: TextStyle(color: Colors.white, fontSize: isMobile ? 16 : 20),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search incidents...',
                hintStyle: TextStyle(fontSize: isMobile ? 14 : 16),
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: isMobile ? 12 : 16,
                  horizontal: 16,
                ),
              ),
              onChanged: (value) {
                // Implement search functionality
              },
            ),
            SizedBox(height: isMobile ? 12 : 16),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', isMobile),
                  SizedBox(width: isMobile ? 6 : 8),
                  _buildFilterChip('Open', isMobile),
                  SizedBox(width: isMobile ? 6 : 8),
                  _buildFilterChip('Under Investigation', isMobile),
                  SizedBox(width: isMobile ? 6 : 8),
                  _buildFilterChip('Resolved', isMobile),
                  SizedBox(width: isMobile ? 6 : 8),
                  _buildFilterChip('Closed', isMobile),
                ],
              ),
            ),
            SizedBox(height: isMobile ? 12 : 16),

            // Statistics Cards
            if (isMobile)
              _buildMobileStats()
            else if (isTablet)
              _buildTabletStats()
            else
              _buildDesktopStats(),

            SizedBox(height: isMobile ? 12 : 16),

            // Incidents List/Table
            Expanded(
              child: isMobile
                  ? _buildIncidentCards()
                  : _buildIncidentTable(isTablet),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add new incident functionality
        },
        backgroundColor: const Color(0xFF0D2364),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isMobile) {
    final isSelected = _selectedFilter == label;

    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: isMobile ? 11 : 13)),
      selected: isSelected,
      selectedColor: const Color(0xFF0D2364).withOpacity(0.2),
      checkmarkColor: const Color(0xFF0D2364),
      onSelected: (bool value) {
        setState(() {
          _selectedFilter = label;
        });
      },
    );
  }

  // Mobile: Vertical stacked stats
  Widget _buildMobileStats() {
    return Column(
      children: const [
        Row(
          children: [
            Expanded(
              child: _StatCard(title: 'Total Incidents', value: '24'),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _StatCard(title: 'Open Cases', value: '8'),
            ),
          ],
        ),
        SizedBox(height: 8),
        _StatCard(title: 'Resolved', value: '12'),
      ],
    );
  }

  // Tablet: Three columns
  Widget _buildTabletStats() {
    return const Row(
      children: [
        Expanded(
          child: _StatCard(title: 'Total Incidents', value: '24'),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _StatCard(title: 'Open Cases', value: '8'),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _StatCard(title: 'Resolved', value: '12'),
        ),
      ],
    );
  }

  // Desktop: Three columns with more spacing
  Widget _buildDesktopStats() {
    return const Row(
      children: [
        Expanded(
          child: _StatCard(title: 'Total Incidents', value: '24'),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _StatCard(title: 'Open Cases', value: '8'),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _StatCard(title: 'Resolved', value: '12'),
        ),
      ],
    );
  }

  // Mobile card view
  Widget _buildIncidentCards() {
    return ListView.builder(
      itemCount: incidents.length,
      itemBuilder: (context, index) {
        final incident = incidents[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: InkWell(
            onTap: () => _showIncidentDetails(context, incident),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with unit and status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          incident['unit'] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D2364),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            incident['status'] as String,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getStatusColor(
                              incident['status'] as String,
                            ),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          incident['status'] as String,
                          style: TextStyle(
                            color: _getStatusColor(
                              incident['status'] as String,
                            ),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Incident details
                  _buildCardInfoRow(
                    Icons.calendar_today,
                    'Date',
                    incident['date'] as String,
                  ),
                  const SizedBox(height: 8),
                  _buildCardInfoRow(
                    Icons.report_problem,
                    'Type',
                    incident['type'] as String,
                  ),
                  const SizedBox(height: 8),
                  _buildCardInfoRow(
                    Icons.person,
                    'Reporter',
                    incident['reporter'] as String,
                  ),
                  const SizedBox(height: 8),
                  _buildCardInfoRow(
                    Icons.priority_high,
                    'Priority',
                    incident['priority'] as String,
                  ),
                  const SizedBox(height: 12),

                  // Action button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _showIncidentDetails(context, incident),
                      icon: const Icon(Icons.more_horiz, size: 18),
                      label: const Text('View Details'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF0D2364),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Tablet/Desktop table view
  Widget _buildIncidentTable(bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width - (isTablet ? 24 : 32),
          ),
          child: DataTable(
            columnSpacing: isTablet ? 16 : 20,
            horizontalMargin: isTablet ? 12 : 16,
            dataRowMinHeight: 48,
            dataRowMaxHeight: 56,
            headingRowColor: WidgetStateProperty.all(Colors.grey.shade200),
            headingTextStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isTablet ? 13 : 14,
              color: Colors.black87,
            ),
            dataTextStyle: TextStyle(fontSize: isTablet ? 12 : 14),
            columns: const [
              DataColumn(label: Text('UNIT')),
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('Type')),
              DataColumn(label: Text('Reporter')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Actions')),
            ],
            rows: incidents.map((incident) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      incident['unit'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataCell(Text(incident['date'] as String)),
                  DataCell(
                    Text(
                      incident['type'] as String,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DataCell(
                    Text(
                      incident['reporter'] as String,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          incident['status'] as String,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _getStatusColor(incident['status'] as String),
                        ),
                      ),
                      child: Text(
                        incident['status'] as String,
                        style: TextStyle(
                          color: _getStatusColor(incident['status'] as String),
                          fontWeight: FontWeight.bold,
                          fontSize: isTablet ? 11 : 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  DataCell(
                    IconButton(
                      icon: Icon(
                        Icons.more_vert,
                        size: isTablet ? 18 : 20,
                        color: const Color(0xFF0D2364),
                      ),
                      onPressed: () => _showIncidentDetails(context, incident),
                      tooltip: 'View Details',
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

  static Color _getStatusColor(String status) {
    switch (status) {
      case 'Open':
        return Colors.blue;
      case 'Under Investigation':
        return Colors.orange;
      case 'Resolved':
        return Colors.green;
      case 'Closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  void _showIncidentDetails(
    BuildContext context,
    Map<String, dynamic> incident,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Incident Details - ${incident['unit']}',
            style: TextStyle(fontSize: isMobile ? 16 : 18),
          ),
          content: SizedBox(
            width: isMobile ? double.maxFinite : 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow(title: 'UNIT:', value: incident['unit'] as String),
                  _DetailRow(title: 'Date:', value: incident['date'] as String),
                  _DetailRow(title: 'Type:', value: incident['type'] as String),
                  _DetailRow(
                    title: 'Reporter:',
                    value: incident['reporter'] as String,
                  ),
                  _DetailRow(
                    title: 'Priority:',
                    value: incident['priority'] as String,
                  ),
                  _DetailRow(
                    title: 'Status:',
                    value: incident['status'] as String,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                // Edit incident functionality
                Navigator.pop(context);
              },
              child: const Text('Edit'),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: isMobile ? 12 : 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: isMobile ? 4 : 8),
            Text(
              value,
              style: TextStyle(
                fontSize: isMobile ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0D2364),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isMobile ? 80 : 100,
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 13 : 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: isMobile ? 13 : 14)),
          ),
        ],
      ),
    );
  }
}
