import 'dart:async';
import 'dart:ui';

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
  final ScrollController _reportTableScrollController = ScrollController();

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
    _reportTableScrollController.dispose();
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

  void _showTicketInspectionDetails(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // Extract ticket inspection data
    final ticketInspection =
        data['ticketInspection'] as Map<String, dynamic>? ?? {};
    final List<String> denominations = ['20', '15', '10', '5', '2', '1'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isMobile ? double.infinity : 600,
            ),
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.receipt_long, color: Color(0xFF0D2364)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ticket Inspection Details',
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D2364),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: isMobile ? 20 : 24),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDetailRow(
                          'Trip No',
                          data['noOfTrips']?.toString() ?? 'N/A',
                          isMobile,
                        ),
                        _buildDetailRow(
                          'Unit Number',
                          data['unitNumber']?.toString() ?? 'N/A',
                          isMobile,
                        ),
                        _buildDetailRow(
                          'Driver',
                          data['driverName']?.toString() ?? 'N/A',
                          isMobile,
                        ),
                        _buildDetailRow(
                          'Conductor',
                          data['conductorName']?.toString() ?? 'N/A',
                          isMobile,
                        ),
                        _buildDetailRow(
                          'Location',
                          data['location']?.toString() ?? 'N/A',
                          isMobile,
                        ),
                        _buildDetailRow(
                          'Inspection Time',
                          data['inspectionTime']?.toString() ?? 'N/A',
                          isMobile,
                        ),
                        _buildDetailRow(
                          'Passengers',
                          data['noOfPass']?.toString() ?? 'N/A',
                          isMobile,
                        ),

                        SizedBox(height: 20),

                        // Ticket Inspection Table
                        if (ticketInspection.isNotEmpty) ...[
                          Text(
                            'Ticket Inspection Breakdown',
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D2364),
                            ),
                          ),
                          SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                // Header
                                Container(
                                  padding: EdgeInsets.all(isMobile ? 8 : 12),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF0D2364),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(7),
                                      topRight: Radius.circular(7),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Fare',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: isMobile ? 12 : 14,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          'Ticket Number',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: isMobile ? 12 : 14,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Rows
                                ...denominations.map((denom) {
                                  final ticketNumber =
                                      ticketInspection[denom]?.toString() ??
                                      'N/A';
                                  final index = denominations.indexOf(denom);

                                  return Container(
                                    padding: EdgeInsets.all(isMobile ? 8 : 12),
                                    decoration: BoxDecoration(
                                      color: index.isEven
                                          ? Colors.grey[50]
                                          : Colors.white,
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey[300]!,
                                          width: 0.5,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            denom,
                                            style: TextStyle(
                                              fontSize: isMobile ? 12 : 14,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF0D2364),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            ticketNumber,
                                            style: TextStyle(
                                              fontSize: isMobile ? 12 : 14,
                                              color: Colors.black87,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                          SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Close',
                      style: TextStyle(fontSize: isMobile ? 14 : 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
                fontSize: isMobile ? 12 : 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: Colors.black87,
                fontSize: isMobile ? 12 : 14,
              ),
            ),
          ),
        ],
      ),
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
                    IconButton(
                      icon: const Icon(
                        Icons.visibility,
                        color: Color(0xFF0D2364),
                      ),
                      onPressed: () =>
                          _showTicketInspectionDetails(context, data),
                      tooltip: 'View Ticket Details',
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
    final isDesktop = screenWidth >= 1024;

    return Scrollbar(
      controller: _reportTableScrollController,
      thumbVisibility: isDesktop || isTablet,
      child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
            },
            scrollbars: true,
          ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            constraints: BoxConstraints(minWidth: isTablet ? 800 : 900),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                const Color(0xFF0D2364),
              ), // Blue color for header
              headingTextStyle: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white, // White text for better contrast
                fontSize: isTablet ? 12 : 13,
              ),
              dataTextStyle: TextStyle(
                fontSize: isTablet ? 11 : 12,
                color: Colors.black87,
              ),
              dataRowColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.selected)) {
                  return Theme.of(context).colorScheme.primary.withAlpha(8);
                }
                return Colors.white;
              }),
              columnSpacing: 60,
              horizontalMargin: 0,
              dataRowMinHeight: 50,
              dataRowMaxHeight: 50,
              columns: [
                DataColumn(
                  label: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Trip No',
                      style: TextStyle(
                        color: Colors.white, // White text for header
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                DataColumn(
                  label: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Inspector Name',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                DataColumn(
                  label: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Date',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                DataColumn(
                  label: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Unit Number',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                DataColumn(
                  label: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Driver Name',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                DataColumn(
                  label: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Conductor Name',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                DataColumn(
                  label: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Ticket Time',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                DataColumn(
                  label: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Passengers',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                DataColumn(
                  label: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Location',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                DataColumn(
                  label: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Action',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
              rows: trips.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
                final inspectorUid = data['uid']?.toString() ?? '';
                final noOfTrips = data['noOfTrips']?.toString() ?? doc.id;

                return DataRow(
                  cells: [
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          noOfTrips,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        width: 100,
                        child: FutureBuilder<String>(
                          future: _getInspectorName(inspectorUid),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Text(
                                'Loading...',
                                overflow: TextOverflow.ellipsis,
                              );
                            }
                            return Text(
                              snapshot.data ?? 'Unknown',
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          timestamp != null
                              ? '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}'
                              : 'N/A',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          data['unitNumber']?.toString() ?? 'N/A',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        width: 100,
                        child: Text(
                          data['driverName']?.toString() ?? 'N/A',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        width: 100,
                        child: Text(
                          data['conductorName']?.toString() ?? 'N/A',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          data['inspectionTime']?.toString() ?? 'N/A',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          data['noOfPass']?.toString() ?? 'N/A',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          data['location']?.toString() ?? 'N/A',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: IconButton(
                          icon: const Icon(
                            Icons.visibility,
                            size: 18,
                            color: Color(0xFF0D2364),
                          ),
                          onPressed: () =>
                              _showTicketInspectionDetails(context, data),
                          tooltip: 'View Ticket Details',
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
