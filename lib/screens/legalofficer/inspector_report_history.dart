import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/app_user.dart';

class InspectorReportHistoryScreen extends StatefulWidget {
  const InspectorReportHistoryScreen({super.key, required this.user});

  final AppUser user;

  @override
  State<InspectorReportHistoryScreen> createState() =>
      _InspectorReportHistoryScreenState();
}

class _InspectorReportHistoryScreenState
    extends State<InspectorReportHistoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';
  String _selectedFilter = 'All Time';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getInspectorTripsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final trips = snapshot.data?.docs ?? [];
          final filteredTrips = _filterTrips(trips);

          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search and Filter Section - moved to top
                _buildSearchFilterSection(isMobile),
                SizedBox(height: isMobile ? 16 : 24),

                // Report History Section
                _sectionTitle('Action Reports', isMobile),
                const SizedBox(height: 8),

                if (filteredTrips.isEmpty)
                  _styledCardWhite(
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text(
                          'No inspection reports found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    ),
                    isMobile,
                  )
                else if (isMobile)
                  _buildReportCards(context, filteredTrips)
                else
                  _styledCardWhite(
                    _buildReportTable(context, filteredTrips),
                    isMobile,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Stream<QuerySnapshot> _getInspectorTripsStream() {
    return _firestore
        .collection('inspector_trip')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  List<DocumentSnapshot> _filterTrips(List<DocumentSnapshot> trips) {
    var filtered = trips;

    // Apply date filter
    if (_selectedFilter != 'All Time') {
      final now = DateTime.now();
      filtered = trips.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
        if (timestamp == null) return false;

        switch (_selectedFilter) {
          case 'Today':
            return timestamp.year == now.year &&
                timestamp.month == now.month &&
                timestamp.day == now.day;
          case 'This Week':
            final weekAgo = now.subtract(const Duration(days: 7));
            return timestamp.isAfter(weekAgo);
          case 'This Month':
            return timestamp.year == now.year && timestamp.month == now.month;
          default:
            return true;
        }
      }).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final query = _searchQuery.toLowerCase();

        return (data['unitNumber']?.toString().toLowerCase().contains(query) ??
                false) ||
            (data['driverName']?.toString().toLowerCase().contains(query) ??
                false) ||
            (data['conductorName']?.toString().toLowerCase().contains(query) ??
                false) ||
            (doc.id.toLowerCase().contains(query));
      }).toList();
    }

    return filtered;
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
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by Trip No, Unit Number, or Driver Name...',
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
        setState(() {
          _selectedFilter = label;
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: const Color(0xFF0D2364),
      labelStyle: TextStyle(
        color: _selectedFilter == label ? Colors.white : Colors.black87,
      ),
      selected: label == _selectedFilter,
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

  Widget _buildReportCards(BuildContext context, List<DocumentSnapshot> trips) {
    return Column(
      children: trips.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
        final inspectorUid = data['uid']?.toString() ?? '';

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
                        'TRIP NO: ${data['noOfTrips']?.toString() ?? doc.id}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D2364),
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {},
                      itemBuilder: (BuildContext context) => [],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                FutureBuilder<String>(
                  future: _getInspectorName(inspectorUid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildInfoRow(
                        'Inspector Name',
                        'Loading...',
                        Icons.person,
                      );
                    }
                    if (snapshot.hasError) {
                      return _buildInfoRow(
                        'Inspector Name',
                        'Error',
                        Icons.person,
                      );
                    }
                    return _buildInfoRow(
                      'Inspector Name',
                      snapshot.data ?? 'Unknown',
                      Icons.person,
                    );
                  },
                ),

                const SizedBox(height: 12),

                _buildInfoRow(
                  'Date',
                  timestamp != null
                      ? '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}'
                      : 'N/A',
                  Icons.calendar_today,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Unit Number',
                  data['unitNumber']?.toString() ?? 'N/A',
                  Icons.confirmation_number,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Driver Name',
                  data['driverName']?.toString() ?? 'N/A',
                  Icons.person_outline,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Conductor Name',
                  data['conductorName']?.toString() ?? 'N/A',
                  Icons.people_outline,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Ticket Inspection Time',
                  data['inspectionTime']?.toString() ?? 'N/A',
                  Icons.access_time,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Number of Passengers',
                  data['noOfPass']?.toString() ?? 'N/A',
                  Icons.people,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Location',
                  data['location']?.toString() ?? 'N/A',
                  Icons.location_on,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<String> _getInspectorName(String inspectorUid) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(inspectorUid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        return data['name']?.toString() ?? 'Unknown Inspector';
      } else {
        return 'Unknown Inspector';
      }
    } catch (e) {
      debugPrint('Error fetching inspector name: $e');
      return 'Unknown Inspector';
    }
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

  Widget _buildReportTable(BuildContext context, List<DocumentSnapshot> trips) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        constraints: BoxConstraints(minWidth: isTablet ? 900 : 1100),
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
          dataRowColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) {
              return Theme.of(context).colorScheme.primary.withAlpha(8);
            }
            return Colors.white;
          }),
          columnSpacing: isTablet ? 16 : 20,
          horizontalMargin: isTablet ? 16 : 20,
          dataRowMinHeight: 60,
          dataRowMaxHeight: 60,
          columns: const [
            DataColumn(label: Text('Trip No')),
            DataColumn(label: Text('Inspector Name')),
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Unit Number')),
            DataColumn(label: Text('Driver Name')),
            DataColumn(label: Text('Conductor Name')),
            DataColumn(label: Text('Ticket Inspection Time')),
            DataColumn(label: Text('Passengers')),
            DataColumn(label: Text('Location')),
            DataColumn(label: Text('Action')),
          ],
          rows: trips.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
            final inspectorUid = data['uid']?.toString() ?? '';

            return DataRow(
              cells: [
                DataCell(
                  Text(
                    doc.id,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: isTablet ? 120 : 140,
                    child: FutureBuilder<String>(
                      future: _getInspectorName(inspectorUid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Text('Loading...');
                        }
                        return Text(snapshot.data ?? 'Unknown');
                      },
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    timestamp != null
                        ? '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}'
                        : 'N/A',
                  ),
                ),
                DataCell(Text(data['unitNumber']?.toString() ?? 'N/A')),
                DataCell(Text(data['driverName']?.toString() ?? 'N/A')),
                DataCell(Text(data['conductorName']?.toString() ?? 'N/A')),
                DataCell(Text(data['inspectionTime']?.toString() ?? 'N/A')),
                DataCell(Text(data['noOfPass']?.toString() ?? 'N/A')),
                DataCell(Text(data['location']?.toString() ?? 'N/A')),
                DataCell(
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (value) {},
                    itemBuilder: (BuildContext context) => [],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
