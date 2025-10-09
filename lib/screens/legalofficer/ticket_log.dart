import 'package:flutter/material.dart';

class TicketTable extends StatefulWidget {
  const TicketTable({super.key});

  @override
  State<TicketTable> createState() => _TicketTableState();
}

class _TicketTableState extends State<TicketTable> {
  final List<TicketData> _allTickets = [
    TicketData(
      tripNo: '001',
      vehicle: 'PUJ-23',
      conductorName: 'Juan Dela Cruz',
      date: DateTime(2025, 10, 7),
      openingTicketNo: 125,
      closingTicketNo: 172,
      passengers: 48,
      submittedBy: 'Juan Dela Cruz',
    ),
    TicketData(
      tripNo: '002',
      vehicle: 'PUJ-23',
      conductorName: 'Maria Santos',
      date: DateTime(2025, 10, 7),
      openingTicketNo: 173,
      closingTicketNo: 220,
      passengers: 47,
      submittedBy: 'Maria Santos',
    ),
    TicketData(
      tripNo: '003',
      vehicle: 'PUJ-23',
      conductorName: 'Pedro Reyes',
      date: DateTime(2025, 10, 7),
      openingTicketNo: 221,
      closingTicketNo: 342,
      passengers: 33,
      submittedBy: 'Pedro Reyes',
    ),
    TicketData(
      tripNo: '004',
      vehicle: 'PUJ-24',
      conductorName: 'Ana Lopez',
      date: DateTime(2025, 10, 7),
      openingTicketNo: 343,
      closingTicketNo: 390,
      passengers: 47,
      submittedBy: 'Ana Lopez',
    ),
    TicketData(
      tripNo: '005',
      vehicle: 'PUJ-23',
      conductorName: 'Juan Dela Cruz',
      date: DateTime(2025, 10, 8),
      openingTicketNo: 391,
      closingTicketNo: 438,
      passengers: 47,
      submittedBy: 'Juan Dela Cruz',
    ),
    TicketData(
      tripNo: '006',
      vehicle: 'PUJ-25',
      conductorName: 'Carlos Garcia',
      date: DateTime(2025, 10, 8),
      openingTicketNo: 439,
      closingTicketNo: 486,
      passengers: 47,
      submittedBy: 'Carlos Garcia',
    ),
  ];

  List<TicketData> _filteredTickets = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedVehicle = 'All';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _filteredTickets = _allTickets;
  }

  void _applyFilters() {
    setState(() {
      _filteredTickets = _allTickets.where((ticket) {
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
    });
  }

  List<String> get _vehicleOptions {
    final vehicles = _allTickets
        .map((ticket) => ticket.vehicle)
        .toSet()
        .toList();
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
        _applyFilters();
      });
    }
  }

  String _formatTicketNumber(int number) {
    return number.toString().padLeft(6, '0');
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
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
                      _buildDetailRow(
                        'Conductor',
                        ticket.conductorName,
                        isMobile,
                      ),
                      _buildDetailRow(
                        'Date',
                        _formatDate(ticket.date),
                        isMobile,
                      ),
                      _buildDetailRow(
                        'Opening Ticket No.',
                        _formatTicketNumber(ticket.openingTicketNo),
                        isMobile,
                      ),
                      _buildDetailRow(
                        'Closing Ticket No.',
                        _formatTicketNumber(ticket.closingTicketNo),
                        isMobile,
                      ),
                      _buildDetailRow(
                        'Passenger Count',
                        ticket.passengers.toString(),
                        isMobile,
                      ),
                      _buildDetailRow(
                        'Submitted By',
                        ticket.submittedBy,
                        isMobile,
                      ),
                      SizedBox(height: 16),
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
                              (ticket.closingTicketNo -
                                      ticket.openingTicketNo +
                                      1)
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
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
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

  Widget _buildDesktopTable() {
    return Column(
      children: [
        // Table Header
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

        // Table Body
        Expanded(
          child: _filteredTickets.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: _filteredTickets.length,
                  itemBuilder: (context, index) {
                    final ticket = _filteredTickets[index];
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
                                  ticket.passengers.toString(),
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

  Widget _buildMobileList() {
    return Expanded(
      child: _filteredTickets.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              itemCount: _filteredTickets.length,
              itemBuilder: (context, index) {
                final ticket = _filteredTickets[index];
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
                                color: Color(0xFF0D2364).withOpacity(0.1),
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
            ),
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

  Widget _buildSearchAndFilterSection(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Bar
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
            onChanged: (value) => _applyFilters(),
          ),
          SizedBox(height: isMobile ? 8 : 12),
          if (isMobile)
            Column(
              children: [
                // Vehicle Filter - Mobile
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
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.grey,
                      ),
                      items: _vehicleOptions.map((String vehicle) {
                        return DropdownMenuItem<String>(
                          value: vehicle,
                          child: Text(vehicle, style: TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          _selectedVehicle = value!;
                          _applyFilters();
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(height: 8),
                // Date Filter - Mobile
                InkWell(
                  onTap: () => _selectDate(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
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
                            color: _selectedDate == null
                                ? Colors.grey
                                : Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                        Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                // Vehicle Filter - Desktop
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
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.grey,
                        ),
                        items: _vehicleOptions.map((String vehicle) {
                          return DropdownMenuItem<String>(
                            value: vehicle,
                            child: Text(
                              vehicle,
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          setState(() {
                            _selectedVehicle = value!;
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                // Date Filter - Desktop
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
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
                              color: _selectedDate == null
                                  ? Colors.grey
                                  : Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                          Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: Colors.grey[600],
                          ),
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
                    _applyFilters();
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

  Widget _buildResultsFooter(bool isMobile) {
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
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing ${_filteredTickets.length} of ${_allTickets.length} tickets',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: isMobile ? 10 : 12,
            ),
          ),
          if (_filteredTickets.isNotEmpty)
            Text(
              'Total Passengers: ${_filteredTickets.fold(0, (sum, ticket) => sum + ticket.passengers)}',
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
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
          child: Column(
            children: [
              // Search and Filter Section
              _buildSearchAndFilterSection(isMobile),
              SizedBox(height: isMobile ? 12 : 16),
              // Table/List Section
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: isMobile
                            ? _buildMobileList()
                            : _buildDesktopTable(),
                      ),
                      _buildResultsFooter(isMobile),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
  final DateTime date;
  final int openingTicketNo;
  final int closingTicketNo;
  final int passengers;
  final String submittedBy;

  TicketData({
    required this.tripNo,
    required this.vehicle,
    required this.conductorName,
    required this.date,
    required this.openingTicketNo,
    required this.closingTicketNo,
    required this.passengers,
    required this.submittedBy,
  });
}
