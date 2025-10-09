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
  final bool _isEditing = false;
  final Map<String, dynamic> _editingIncident = {};

  // Sample incident data - using mutable list for demo
  List<Map<String, dynamic>> incidents = [
    {
      'unit': 'INC-001',
      'date': '2025-09-01',
      'type': 'Traffic Violation',
      'reporter': 'Juan Dela Cruz',
      'status': 'In Progress',
      'priority': 'High',
    },
    {
      'unit': 'INC-002',
      'date': '2025-09-02',
      'type': 'Passenger Misconduct',
      'reporter': 'Maria Lopez',
      'status': 'In Progress',
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
      'status': 'In Progress',
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
                  _buildFilterChip('New', isMobile),
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
    );
  }

  Widget _buildFilterChip(String label, bool isMobile) {
    final isSelected = _selectedFilter == label;

    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: isMobile ? 11 : 13)),
      selected: isSelected,
      selectedColor: const Color(0xFF0D2364),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
      onSelected: (bool value) {
        setState(() {
          _selectedFilter = label;
        });
      },
    );
  }

  // Mobile: Vertical stacked stats
  Widget _buildMobileStats() {
    final inProgressCount = incidents
        .where((incident) => incident['status'] == 'In Progress')
        .length;
    final resolvedCount = incidents
        .where((incident) => incident['status'] == 'Resolved')
        .length;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'New',
                value: incidents.length.toString(),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                title: 'In Progress',
                value: inProgressCount.toString(),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        _StatCard(title: 'Resolved', value: resolvedCount.toString()),
      ],
    );
  }

  // Tablet: Three columns
  Widget _buildTabletStats() {
    final inProgressCount = incidents
        .where((incident) => incident['status'] == 'In Progress')
        .length;
    final resolvedCount = incidents
        .where((incident) => incident['status'] == 'Resolved')
        .length;

    return Row(
      children: [
        Expanded(
          child: _StatCard(title: 'New', value: incidents.length.toString()),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            title: 'In Progress',
            value: inProgressCount.toString(),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _StatCard(title: 'Resolved', value: resolvedCount.toString()),
        ),
      ],
    );
  }

  // Desktop: Three columns with more spacing
  Widget _buildDesktopStats() {
    final inProgressCount = incidents
        .where((incident) => incident['status'] == 'In Progress')
        .length;
    final resolvedCount = incidents
        .where((incident) => incident['status'] == 'Resolved')
        .length;

    return Row(
      children: [
        Expanded(
          child: _StatCard(title: 'New', value: incidents.length.toString()),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'In Progress',
            value: inProgressCount.toString(),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _StatCard(title: 'Resolved', value: resolvedCount.toString()),
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
            onTap: () => _showIncidentDetails(context, incident, index),
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
                      onPressed: () =>
                          _showIncidentDetails(context, incident, index),
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
            rows: incidents.asMap().entries.map((entry) {
              final index = entry.key;
              final incident = entry.value;
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
                      onPressed: () =>
                          _showIncidentDetails(context, incident, index),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'In Progress':
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
    int index,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Incident Details - ${incident['unit']}',
                style: TextStyle(fontSize: isMobile ? 16 : 18),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: 20,
              ),
            ],
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
            if (incident['status'] != 'Closed')
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close details dialog
                  _showEditIncidentDialog(context, incident, index);
                },
                child: const Text('Edit'),
              ),
          ],
        );
      },
    );
  }

  void _showEditIncidentDialog(
    BuildContext context,
    Map<String, dynamic> incident,
    int index,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // Create editable copies of the fields
    TextEditingController unitController = TextEditingController(
      text: incident['unit'],
    );
    TextEditingController dateController = TextEditingController(
      text: incident['date'],
    );
    TextEditingController typeController = TextEditingController(
      text: incident['type'],
    );
    TextEditingController reporterController = TextEditingController(
      text: incident['reporter'],
    );
    String selectedPriority = incident['priority'];
    String selectedStatus = incident['status'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Edit Incident - ${incident['unit']}',
                style: TextStyle(fontSize: isMobile ? 16 : 18),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: 20,
              ),
            ],
          ),
          content: SizedBox(
            width: isMobile ? double.maxFinite : 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEditField('UNIT', unitController),
                  const SizedBox(height: 12),
                  _buildEditField('Date', dateController),
                  const SizedBox(height: 12),
                  _buildEditField('Type', typeController),
                  const SizedBox(height: 12),
                  _buildEditField('Reporter', reporterController),
                  const SizedBox(height: 12),

                  // Priority Dropdown
                  Text(
                    'Priority:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 13 : 14,
                    ),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: selectedPriority,
                    items: ['High', 'Medium', 'Low'].map((String priority) {
                      return DropdownMenuItem<String>(
                        value: priority,
                        child: Text(priority),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      selectedPriority = newValue!;
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Status Dropdown
                  Text(
                    'Status:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 13 : 14,
                    ),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: selectedStatus,
                    items: ['In Progress', 'Resolved', 'Closed'].map((
                      String status,
                    ) {
                      return DropdownMenuItem<String>(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      selectedStatus = newValue!;
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),

                  if (selectedStatus == 'Closed')
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Note: This incident will be moved to ARCHIVED.',
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _saveIncidentChanges(
                  index,
                  unitController.text,
                  dateController.text,
                  typeController.text,
                  reporterController.text,
                  selectedPriority,
                  selectedStatus,
                );
                Navigator.pop(context);

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Incident ${unitController.text} has been saved',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEditField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  void _saveIncidentChanges(
    int index,
    String unit,
    String date,
    String type,
    String reporter,
    String priority,
    String status,
  ) {
    setState(() {
      incidents[index] = {
        'unit': unit,
        'date': date,
        'type': type,
        'reporter': reporter,
        'priority': priority,
        'status': status,
      };

      // If status is 'Closed', move to archived (in real app, this would be a database operation)
      if (status == 'Closed') {
        // Here you would move the incident to your archived database
        print('Moving incident $unit to ARCHIVED database');
        // In a real app, you would remove it from the active list and add to archived
      }
    });
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
