import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TicketTable extends StatefulWidget {
  const TicketTable({super.key});

  @override
  State<TicketTable> createState() => _TicketTableState();
}

class _TicketTableState extends State<TicketTable> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _selectedVehicle = 'All';
  DateTime? _selectedDate;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<List<TicketData>> _getTicketsStream() {
    return _firestore.collection('ticket_report').snapshots().asyncMap((ticketSnapshot) async {

      // Get inspector trips for passenger count
      final inspectorSnapshot = await _firestore.collection('inspector_trip').get();
      Map<String, Map<String, int>> inspectorData = {}; // key: date-unit-conductor-tripNo, value: passengers

      for (var doc in inspectorSnapshot.docs) {
        final data = doc.data();
        if (data['timestamp'] != null && data['noOfPass'] != null) {
          final timestamp = (data['timestamp'] as Timestamp).toDate();
          final dateKey = DateFormat('yyyy-MM-dd').format(timestamp);
          final unitNumber = data['unitNumber']?.toString() ?? '';
          final conductorName = data['conductorName'] ?? '';
          final tripNo = data['noOfTrips']?.toString() ?? '1';
          final passengers = int.tryParse(data['noOfPass'].toString()) ?? 0;

          final key = '$dateKey-$unitNumber-$conductorName-$tripNo';
          if (!inspectorData.containsKey(key)) {
            inspectorData[key] = {};
          }
          inspectorData[key]![tripNo] = passengers;
        }
      }

      // Group tickets by date, vehicle, and conductor
      Map<String, List<Map<String, dynamic>>> groupedTickets = {};

      for (var doc in ticketSnapshot.docs) {
        final data = doc.data();

        // Skip if timestamp is null
        if (data['timestamp'] == null) {
          continue;
        }

        final timestamp = (data['timestamp'] as Timestamp).toDate();
        final dateKey = DateFormat('yyyy-MM-dd').format(timestamp);
        final unitNumber = data['unitNumber']?.toString() ?? 'Unknown';
        final conductorName = data['conductorName'] ?? 'Unknown';

        final key = '$dateKey-$unitNumber-$conductorName';

        if (!groupedTickets.containsKey(key)) {
          groupedTickets[key] = [];
        }
        groupedTickets[key]!.add({
          'type': data['type'] ?? 'opening',
          'ticketNumber': data['ticketNumber'] ?? 0,
          'timestamp': timestamp,
          'conductorName': conductorName,
          'employeeId': data['employeeId'] ?? '',
          'unitNumber': unitNumber,
        });
      }

      // Process grouped tickets into trips
      List<TicketData> tickets = [];

      groupedTickets.forEach((key, ticketList) {

        // Sort by timestamp
        ticketList.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));

        // Separate opening and closing tickets
        List<Map<String, dynamic>> openings = ticketList.where((t) => t['type'] == 'opening').toList();
        List<Map<String, dynamic>> closings = ticketList.where((t) => t['type'] == 'closing').toList();

        // Parse the key: format is yyyy-MM-dd-unitNumber-conductorName
        // We need to extract date (first 10 chars), then split the rest
        final dateStr = key.substring(0, 10); // yyyy-MM-dd
        final remaining = key.substring(11); // everything after date
        final remainingParts = remaining.split('-');

        DateTime date;
        try {
          date = DateTime.parse(dateStr);
        } catch (e) {
          return;
        }

        final unitNumber = remainingParts.isNotEmpty ? remainingParts[0] : 'Unknown';
        final conductorName = remainingParts.length > 1 ? remainingParts.sublist(1).join('-') : 'Unknown';

        // Create trips (max 4 per day)
        int maxTrips = openings.length > 4 ? 4 : openings.length;

        for (int i = 0; i < maxTrips; i++) {
          final opening = openings[i];
          final closing = i < closings.length ? closings[i] : null;
          final tripNo = '${i + 1}';

          // Look up passenger count from inspector data
          final inspectorKey = '$dateStr-$unitNumber-$conductorName-$tripNo';
          final passengers = inspectorData[inspectorKey]?[tripNo] ?? 0;

          tickets.add(TicketData(
            tripNo: tripNo,
            vehicle: unitNumber,
            conductorName: conductorName,
            employeeId: opening['employeeId'] ?? '',
            date: date,
            openingTicketNo: opening['ticketNumber'],
            closingTicketNo: closing?['ticketNumber'],
            passengers: passengers,
            submittedBy: conductorName,
            openingTimestamp: opening['timestamp'],
            closingTimestamp: closing?['timestamp'],
          ));
        }
      });

      // Sort by date descending
      tickets.sort((a, b) => b.date.compareTo(a.date));

      return tickets;
    });
  }

  List<TicketData> _applyFilters(List<TicketData> tickets) {
    return tickets.where((ticket) {
      final matchesSearch =
          _searchController.text.isEmpty ||
              ticket.tripNo.toLowerCase().contains(
                _searchController.text.toLowerCase(),
              ) ||
              ticket.vehicle.toLowerCase().contains(
                _searchController.text.toLowerCase(),
              ) ||
              ticket.conductorName.toLowerCase().contains(
                _searchController.text.toLowerCase(),
              );

      final matchesVehicle =
          _selectedVehicle == 'All' || ticket.vehicle == _selectedVehicle;

      final matchesDate =
          _selectedDate == null ||
              (ticket.date.year == _selectedDate!.year &&
                  ticket.date.month == _selectedDate!.month &&
                  ticket.date.day == _selectedDate!.day);

      return matchesSearch && matchesVehicle && matchesDate;
    }).toList();
  }

  List<String> _getVehicleOptions(List<TicketData> tickets) {
    final vehicles = tickets.map((ticket) => ticket.vehicle).toSet().toList();
    vehicles.sort();
    return ['All', ...vehicles];
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2026),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _formatTicketNumber(int? number) {
    if (number == null) return 'N/A';
    return number.toString().padLeft(6, '0');
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  String _formatTime(DateTime? timestamp) {
    if (timestamp == null) return 'N/A';
    return DateFormat('h:mm a').format(timestamp);
  }

  void _showTicketDetails(TicketData ticket) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isMobile ? double.infinity : 500,
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
                        'Trip Details - ${ticket.tripNo}',
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
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDetailRow('Trip No.', ticket.tripNo, isMobile),
                      _buildDetailRow('Vehicle Unit', ticket.vehicle, isMobile),
                      _buildDetailRow('Conductor', ticket.conductorName, isMobile),
                      _buildDetailRow('Employee ID', ticket.employeeId, isMobile),
                      _buildDetailRow('Date', _formatDate(ticket.date), isMobile),
                      _buildDetailRow(
                        'Opening Ticket No.',
                        _formatTicketNumber(ticket.openingTicketNo),
                        isMobile,
                      ),
                      _buildDetailRow(
                        'Opening Time',
                        _formatTime(ticket.openingTimestamp),
                        isMobile,
                      ),
                      _buildDetailRow(
                        'Closing Ticket No.',
                        _formatTicketNumber(ticket.closingTicketNo),
                        isMobile,
                      ),
                      _buildDetailRow(
                        'Closing Time',
                        _formatTime(ticket.closingTimestamp),
                        isMobile,
                      ),
                      _buildDetailRow(
                        'Passenger Count',
                        ticket.passengers.toString(),
                        isMobile,
                      ),
                      _buildDetailRow('Submitted By', ticket.submittedBy, isMobile),
                      SizedBox(height: 16),
                      if (ticket.closingTicketNo != null)
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Tickets Used:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                  fontSize: isMobile ? 12 : 14,
                                ),
                              ),
                              Text(
                                ((ticket.closingTicketNo! - ticket.openingTicketNo).abs() + 1)
                                    .toString(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 14 : 16,
                                  color: Color(0xFF0D2364),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
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

  Widget _buildDesktopTable(List<TicketData> tickets) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D2364),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(flex: 2, child: _TableHeaderText('Trip No.')),
                Expanded(flex: 3, child: _TableHeaderText('Vehicle Unit')),
                Expanded(flex: 4, child: _TableHeaderText('Conductor')),
                Expanded(flex: 3, child: _TableHeaderText('Date')),
                Expanded(flex: 3, child: _TableHeaderText('Opening')),
                Expanded(flex: 3, child: _TableHeaderText('Closing')),
                Expanded(
                  flex: 3,
                  child: Center(child: _TableHeaderText('Passengers')),
                ),
                Expanded(
                  flex: 2,
                  child: Center(child: _TableHeaderText('Action')),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: tickets.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              return Container(
                decoration: BoxDecoration(
                  color: index.isEven ? Colors.white : Colors.grey[50],
                  border: const Border(
                    bottom: BorderSide(color: Colors.grey, width: 0.5),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _TableDataText(ticket.tripNo),
                      ),
                      Expanded(
                        flex: 3,
                        child: _TableDataText(ticket.vehicle),
                      ),
                      Expanded(
                        flex: 4,
                        child: _TableDataText(ticket.conductorName),
                      ),
                      Expanded(
                        flex: 3,
                        child: _TableDataText(_formatDate(ticket.date)),
                      ),
                      Expanded(
                        flex: 3,
                        child: _TableDataText(
                          _formatTicketNumber(ticket.openingTicketNo),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: _TableDataText(
                          _formatTicketNumber(ticket.closingTicketNo),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: _TableDataText(
                            ticket.closingTicketNo != null
                                ? ticket.passengers.toString()
                                : 'N/A',
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: IconButton(
                            icon: Icon(
                              Icons.visibility,
                              color: Color(0xFF0D2364),
                              size: 18,
                            ),
                            onPressed: () => _showTicketDetails(ticket),
                            tooltip: 'View Details',
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMobileList(List<TicketData> tickets) {
    return tickets.isEmpty
        ? _buildEmptyState()
        : ListView.builder(
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        return Card(
          margin: EdgeInsets.fromLTRB(8, 4, 8, 4),
          elevation: 1,
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Trip ${ticket.tripNo}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF0D2364),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFF0D2364).withAlpha(1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        ticket.vehicle,
                        style: TextStyle(
                          color: Color(0xFF0D2364),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                _buildMobileInfoRow('Conductor', ticket.conductorName),
                _buildMobileInfoRow('Date', _formatDate(ticket.date)),
                Row(
                  children: [
                    Expanded(
                      child: _buildMobileInfoRow(
                        'Opening',
                        _formatTicketNumber(ticket.openingTicketNo),
                      ),
                    ),
                    Expanded(
                      child: _buildMobileInfoRow(
                        'Closing',
                        _formatTicketNumber(ticket.closingTicketNo),
                      ),
                    ),
                    Expanded(
                      child: _buildMobileInfoRow(
                        'Passengers',
                        ticket.passengers.toString(),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: Icon(
                      Icons.visibility,
                      size: 16,
                      color: Color(0xFF0D2364),
                    ),
                    label: Text(
                      'View Details',
                      style: TextStyle(
                        color: Color(0xFF0D2364),
                        fontSize: 12,
                      ),
                    ),
                    onPressed: () => _showTicketDetails(ticket),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
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

  Widget _buildMobileInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'No tickets found',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterSection(bool isMobile, List<String> vehicleOptions) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: isMobile
                  ? 'Search tickets...'
                  : 'Search by Trip No, Vehicle, or Conductor...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: isMobile ? 12 : 14,
              ),
            ),
            onChanged: (value) => setState(() {}),
          ),
          SizedBox(height: isMobile ? 8 : 12),
          if (isMobile)
            Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedVehicle,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      items: vehicleOptions.map((String vehicle) {
                        return DropdownMenuItem<String>(
                          value: vehicle,
                          child: Text(vehicle, style: TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          _selectedVehicle = value!;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(height: 8),
                InkWell(
                  onTap: () => _selectDate(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedDate == null
                              ? 'Select Date'
                              : _formatDate(_selectedDate!),
                          style: TextStyle(
                            color: _selectedDate == null ? Colors.grey : Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                        Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
                      ],
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedVehicle,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        items: vehicleOptions.map((String vehicle) {
                          return DropdownMenuItem<String>(
                            value: vehicle,
                            child: Text(vehicle, style: const TextStyle(fontSize: 14)),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          setState(() {
                            _selectedVehicle = value!;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedDate == null
                                ? 'Select Date'
                                : _formatDate(_selectedDate!),
                            style: TextStyle(
                              color: _selectedDate == null ? Colors.grey : Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                          Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          SizedBox(height: isMobile ? 8 : 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _selectedVehicle = 'All';
                    _selectedDate = null;
                  });
                },
                child: Text(
                  'Clear Filters',
                  style: TextStyle(fontSize: isMobile ? 12 : 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultsFooter(List<TicketData> tickets, int totalTickets, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing ${tickets.length} of $totalTickets tickets',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: isMobile ? 10 : 12,
            ),
          ),
          if (tickets.isNotEmpty)
            Text(
              'Total Passengers: ${tickets.fold(0, (total, ticket) => total + ticket.passengers)}',
              style: TextStyle(
                color: const Color(0xFF0D2364),
                fontSize: isMobile ? 10 : 12,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: StreamBuilder<List<TicketData>>(
          stream: _getTicketsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            final allTickets = snapshot.data ?? [];
            final filteredTickets = _applyFilters(allTickets);
            final vehicleOptions = _getVehicleOptions(allTickets);

            return Padding(
              padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
              child: Column(
                children: [
                  _buildSearchAndFilterSection(isMobile, vehicleOptions),
                  SizedBox(height: isMobile ? 12 : 16),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withAlpha(1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: isMobile
                                ? _buildMobileList(filteredTickets)
                                : _buildDesktopTable(filteredTickets),
                          ),
                          _buildResultsFooter(filteredTickets, allTickets.length, isMobile),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TableHeaderText extends StatelessWidget {
  final String text;

  const _TableHeaderText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _TableDataText extends StatelessWidget {
  final String text;

  const _TableDataText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, color: Colors.black87),
      overflow: TextOverflow.ellipsis,
    );
  }
}

class TicketData {
  final String tripNo;
  final String vehicle;
  final String conductorName;
  final String employeeId;
  final DateTime date;
  final int openingTicketNo;
  final int? closingTicketNo;
  final int passengers;
  final String submittedBy;
  final DateTime openingTimestamp;
  final DateTime? closingTimestamp;

  TicketData({
    required this.tripNo,
    required this.vehicle,
    required this.conductorName,
    required this.employeeId,
    required this.date,
    required this.openingTicketNo,
    this.closingTicketNo,
    required this.passengers,
    required this.submittedBy,
    required this.openingTimestamp,
    this.closingTimestamp,
  });
}