import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/app_user.dart';
import '../../models/incident_report.dart'; // Import the model we created

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
  String _searchQuery = '';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
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
                  _buildFilterChip('In Progress', isMobile),
                  SizedBox(width: isMobile ? 6 : 8),
                  _buildFilterChip('Resolved', isMobile),
                  SizedBox(width: isMobile ? 6 : 8),
                  _buildFilterChip('Closed', isMobile),
                ],
              ),
            ),
            SizedBox(height: isMobile ? 12 : 16),

            // Statistics Cards with StreamBuilder
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('incident_report').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final incidents = snapshot.data!.docs
                    .map((doc) => IncidentReport.fromFirestore(doc))
                    .toList();

                if (isMobile) {
                  return _buildMobileStats(incidents);
                } else if (isTablet) {
                  return _buildTabletStats(incidents);
                } else {
                  return _buildDesktopStats(incidents);
                }
              },
            ),

            SizedBox(height: isMobile ? 12 : 16),

            // Incidents List/Table with StreamBuilder
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('incident_report')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No incidents found'));
                  }

                  var incidents = snapshot.data!.docs
                      .map((doc) => IncidentReport.fromFirestore(doc))
                      .toList();

                  // Apply filters
                  incidents = _applyFilters(incidents);

                  if (incidents.isEmpty) {
                    return const Center(
                      child: Text('No incidents match your search'),
                    );
                  }

                  return isMobile
                      ? _buildIncidentCards(incidents)
                      : _buildIncidentTable(incidents, isTablet);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<IncidentReport> _applyFilters(List<IncidentReport> incidents) {
    // Filter by status
    if (_selectedFilter != 'All') {
      incidents = incidents
          .where((incident) => incident.status == _selectedFilter)
          .toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      incidents = incidents.where((incident) {
        return incident.type.toLowerCase().contains(_searchQuery) ||
            incident.createdBy.toLowerCase().contains(_searchQuery) ||
            incident.assignedVehicleId.toLowerCase().contains(_searchQuery) ||
            incident.description.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    return incidents;
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
  Widget _buildMobileStats(List<IncidentReport> incidents) {
    final inProgressCount = incidents
        .where((i) => i.status == 'In Progress')
        .length;
    final resolvedCount = incidents.where((i) => i.status == 'Resolved').length;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Total',
                value: incidents.length.toString(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                title: 'In Progress',
                value: inProgressCount.toString(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _StatCard(title: 'Resolved', value: resolvedCount.toString()),
      ],
    );
  }

  // Tablet: Three columns
  Widget _buildTabletStats(List<IncidentReport> incidents) {
    final inProgressCount = incidents
        .where((i) => i.status == 'In Progress')
        .length;
    final resolvedCount = incidents.where((i) => i.status == 'Resolved').length;

    return Row(
      children: [
        Expanded(
          child: _StatCard(title: 'Total', value: incidents.length.toString()),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            title: 'In Progress',
            value: inProgressCount.toString(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(title: 'Resolved', value: resolvedCount.toString()),
        ),
      ],
    );
  }

  // Desktop: Three columns with more spacing
  Widget _buildDesktopStats(List<IncidentReport> incidents) {
    final inProgressCount = incidents
        .where((i) => i.status == 'In Progress')
        .length;
    final resolvedCount = incidents.where((i) => i.status == 'Resolved').length;

    return Row(
      children: [
        Expanded(
          child: _StatCard(title: 'Total', value: incidents.length.toString()),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'In Progress',
            value: inProgressCount.toString(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(title: 'Resolved', value: resolvedCount.toString()),
        ),
      ],
    );
  }

  // Mobile card view
  Widget _buildIncidentCards(List<IncidentReport> incidents) {
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
                          'Vehicle: ${incident.assignedVehicleId}',
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
                          color: _getStatusColor(incident.status).withAlpha(1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getStatusColor(incident.status),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          incident.status,
                          style: TextStyle(
                            color: _getStatusColor(incident.status),
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
                    _formatDate(incident.timestamp),
                  ),
                  const SizedBox(height: 8),
                  _buildCardInfoRow(
                    Icons.report_problem,
                    'Type',
                    incident.type,
                  ),
                  const SizedBox(height: 8),
                  _buildCardInfoRow(
                    Icons.person,
                    'Reporter',
                    incident.createdBy,
                  ),
                  const SizedBox(height: 8),
                  _buildCardInfoRow(
                    Icons.location_on,
                    'Location',
                    incident.location,
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
  Widget _buildIncidentTable(List<IncidentReport> incidents, bool isTablet) {
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
              DataColumn(label: Text('Vehicle')),
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
                      incident.assignedVehicleId,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataCell(Text(_formatDate(incident.timestamp))),
                  DataCell(
                    Text(incident.type, overflow: TextOverflow.ellipsis),
                  ),
                  DataCell(
                    Text(incident.createdBy, overflow: TextOverflow.ellipsis),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(incident.status).withAlpha(1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _getStatusColor(incident.status),
                        ),
                      ),
                      child: Text(
                        incident.status,
                        style: TextStyle(
                          color: _getStatusColor(incident.status),
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

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
        return Colors.blue;
    }
  }

  void _showIncidentDetails(BuildContext context, IncidentReport incident) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Incident Details',
                  style: TextStyle(fontSize: isMobile ? 16 : 18),
                ),
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
                  _DetailRow(
                    title: 'Vehicle ID:',
                    value: incident.assignedVehicleId,
                  ),
                  _DetailRow(
                    title: 'Date:',
                    value: _formatDate(incident.timestamp),
                  ),
                  _DetailRow(title: 'Type:', value: incident.type),
                  _DetailRow(title: 'Reporter:', value: incident.createdBy),
                  _DetailRow(title: 'Location:', value: incident.location),
                  _DetailRow(
                    title: 'Persons Involved:',
                    value: incident.persons,
                  ),
                  _DetailRow(title: 'Status:', value: incident.status),
                  const SizedBox(height: 8),
                  const Text(
                    'Description:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(incident.description),
                ],
              ),
            ),
          ),
          actions: [
            if (incident.status != 'Closed')
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showEditIncidentDialog(context, incident);
                },
                child: const Text('Edit Status'),
              ),
          ],
        );
      },
    );
  }

  void _showEditIncidentDialog(BuildContext context, IncidentReport incident) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    String selectedStatus = incident.status;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Edit Incident Status',
                      style: TextStyle(fontSize: isMobile ? 16 : 18),
                    ),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 13 : 14,
                      ),
                    ),
                    const SizedBox(height: 8),
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
                        setDialogState(() {
                          selectedStatus = newValue!;
                        });
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
                        padding: EdgeInsets.only(top: 12.0),
                        child: Text(
                          'Note: Closed incidents will be archived.',
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    try {
                      // Update Firestore
                      await _firestore
                          .collection('incident_report')
                          .doc(incident.id)
                          .update({'status': selectedStatus});

                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Incident status updated successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error updating status: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
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
            width: isMobile ? 110 : 130,
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
