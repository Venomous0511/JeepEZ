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
  final TextEditingController _unitNumberController = TextEditingController();
  final TextEditingController _conductorNameController = TextEditingController();

  bool isLoading = false;
  String noOfPass = '0';
  String inspectionTime = '';
  String conductorName = '';
  String driverName = '';
  String location = '';
  String unitNumber = '';
  List<String> ticketHeaders = ['20', '15', '10', '5', '2', '1'];
  List<List<String>> ticketData = [];
  bool showTicketTable = false;

  @override
  void dispose() {
    _unitNumberController.dispose();
    _conductorNameController.dispose();
    super.dispose();
  }

  Stream<List<TicketData>> _getTicketsStream() {
    return _firestore.collection('ticket_report').snapshots().asyncMap((ticketSnapshot) async {
      // Get inspector trips for passenger count
      final inspectorSnapshot = await _firestore.collection('inspector_trip').get();
      Map<String, int> inspectorData = {}; // key: date-unit-conductor, value: passengers

      for (var doc in inspectorSnapshot.docs) {
        final data = doc.data();
        if (data['timestamp'] != null && data['noOfPass'] != null) {
          final timestamp = (data['timestamp'] as Timestamp).toDate();
          final dateKey = DateFormat('yyyy-MM-dd').format(timestamp);
          final unitNumber = data['unitNumber']?.toString() ?? '';
          final conductorName = data['conductorName'] ?? '';
          final passengers = int.tryParse(data['noOfPass'].toString()) ?? 0;

          final key = '$dateKey-$unitNumber-$conductorName';
          inspectorData[key] = passengers;
        }
      }

      List<TicketData> tickets = [];

      for (var doc in ticketSnapshot.docs) {
        final data = doc.data();

        // Skip if required fields are null
        if (data['timestamp'] == null) {
          debugPrint('Skipping document ${doc.id}: missing timestamp');
          continue;
        }

        final timestamp = (data['timestamp'] as Timestamp).toDate();
        final dateKey = DateFormat('yyyy-MM-dd').format(timestamp);
        final unitNumber = data['unitNumber']?.toString() ?? 'Unknown';
        final conductorName = data['conductorName'] ?? 'Unknown';
        final employeeId = data['employeeId'] ?? '';

        // Get opening and closing tickets
        final openingTickets = data['openingTickets'] as List<dynamic>? ?? [];
        final closingTickets = data['closingTickets'] as List<dynamic>? ?? [];

        debugPrint('Processing doc ${doc.id}: unit=$unitNumber, conductor=$conductorName');
        debugPrint('Opening tickets: ${openingTickets.length}, Closing tickets: ${closingTickets.length}');

        // Process each row (each row is a trip)
        int maxRows = openingTickets.length > closingTickets.length
            ? openingTickets.length
            : closingTickets.length;

        for (int rowIndex = 0; rowIndex < maxRows; rowIndex++) {
          final openingMap = rowIndex < openingTickets.length
              ? openingTickets[rowIndex] as Map<String, dynamic>? ?? {}
              : {};
          final closingMap = rowIndex < closingTickets.length
              ? closingTickets[rowIndex] as Map<String, dynamic>? ?? {}
              : {};

          // Denominations to process
          List<String> denominations = ['20', '15', '10', '5', '2', '1'];

          int totalPassengers = 0;
          int? firstOpeningTicket;
          int? firstClosingTicket;
          bool hasData = false;
          Map<String, DenominationData> denominationBreakdown = {};

          // Calculate passengers for each denomination and sum them up
          for (String denom in denominations) {
            final openingStr = openingMap[denom]?.toString();
            final closingStr = closingMap[denom]?.toString();

            if (openingStr != null && openingStr.isNotEmpty) {
              hasData = true;
              final opening = int.tryParse(openingStr.replaceAll('"', '')) ?? 0;

              // Store the first opening ticket for display
              if (firstOpeningTicket == null) {
                firstOpeningTicket = opening;
              }

              int? closing;
              int passengersForDenom = 0;

              if (closingStr != null && closingStr.isNotEmpty) {
                closing = int.tryParse(closingStr.replaceAll('"', '')) ?? 0;

                // Store the first closing ticket for display
                if (firstClosingTicket == null) {
                  firstClosingTicket = closing;
                }

                // Calculate passengers for this denomination
                passengersForDenom = (closing - opening).abs();
                totalPassengers += passengersForDenom;

                debugPrint('Row ${rowIndex + 1}, ₱$denom: Opening=$opening, Closing=$closing, Passengers=$passengersForDenom');
              }

              // Store denomination breakdown
              denominationBreakdown[denom] = DenominationData(
                opening: opening,
                closing: closing,
                passengers: passengersForDenom,
              );
            }
          }

          // Skip if no valid data found
          if (!hasData || firstOpeningTicket == null) {
            debugPrint('Skipping row $rowIndex: no valid ticket data');
            continue;
          }

          // Create a ticket entry for this trip
          tickets.add(TicketData(
            tripNo: '${rowIndex + 1}',
            vehicle: unitNumber,
            conductorName: conductorName,
            employeeId: employeeId,
            date: timestamp,
            openingTicketNo: firstOpeningTicket,
            closingTicketNo: firstClosingTicket,
            passengers: totalPassengers,
            submittedBy: conductorName,
            openingTimestamp: timestamp,
            closingTimestamp: firstClosingTicket != null ? timestamp : null,
            denominationBreakdown: denominationBreakdown,
          ));

          debugPrint('Added Trip ${rowIndex + 1}: unit=$unitNumber, Total Passengers=$totalPassengers');
        }
      }

      // Sort by date descending, then by trip number
      tickets.sort((a, b) {
        final dateCompare = b.date.compareTo(a.date);
        if (dateCompare != 0) return dateCompare;

        // Extract numeric part of trip number for sorting
        final aNum = int.tryParse(a.tripNo) ?? 0;
        final bNum = int.tryParse(b.tripNo) ?? 0;
        return aNum.compareTo(bNum);
      });

      debugPrint('Total trips found: ${tickets.length}');
      return tickets;
    });
  }

  Future<void> _fetchInspectorTripData() async {
    if (_unitNumberController.text.isEmpty ||
        _conductorNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both Unit Number and Conductor Name'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('inspector_trip')
          .where('unitNumber', isEqualTo: _unitNumberController.text.trim())
          .where('conductorName', isEqualTo: _conductorNameController.text.trim())
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        QuerySnapshot alternativeQuery = await _firestore
            .collection('inspector_trip')
            .where('unitNumber', isEqualTo: _unitNumberController.text.trim())
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        if (alternativeQuery.docs.isNotEmpty) {
          querySnapshot = alternativeQuery;
        }
      }

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot doc = querySnapshot.docs.first;
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        List<dynamic> ticketSalesDataRaw = data['ticketSalesData'] ?? [];

        setState(() {
          ticketData.clear();

          for (var row in ticketSalesDataRaw) {
            if (row is Map) {
              List<String> rowData = [];
              for (String header in ticketHeaders) {
                String value = row[header]?.toString() ?? '0';
                rowData.add(value);
              }
              ticketData.add(rowData);
            } else if (row is List) {
              ticketData.add(List<String>.from(row.map((e) => e.toString())));
            }
          }

          noOfPass = data['noOfPass']?.toString() ?? '0';
          inspectionTime = data['inspectionTime']?.toString() ?? '';
          conductorName = data['conductorName']?.toString() ?? '';
          driverName = data['driverName']?.toString() ?? '';
          location = data['location']?.toString() ?? '';
          unitNumber = data['unitNumber']?.toString() ?? '';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data loaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          ticketData.clear();
          noOfPass = '0';
          inspectionTime = '';
          conductorName = '';
          driverName = '';
          location = '';
          unitNumber = '';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No data found for this Unit Number'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  List<TicketData> _applyFilters(List<TicketData> tickets) {
    return tickets;
  }

  List<String> _getVehicleOptions(List<TicketData> tickets) {
    return ['All'];
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
                        'Trip Details - Trip ${ticket.tripNo}',
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
                        _buildDetailRow('Trip No.', ticket.tripNo, isMobile),
                        _buildDetailRow('Vehicle Unit', ticket.vehicle, isMobile),
                        _buildDetailRow('Conductor', ticket.conductorName, isMobile),
                        _buildDetailRow('Employee ID', ticket.employeeId, isMobile),
                        _buildDetailRow('Date', _formatDate(ticket.date), isMobile),
                        _buildDetailRow(
                          'Opening Time',
                          _formatTime(ticket.openingTimestamp),
                          isMobile,
                        ),
                        _buildDetailRow(
                          'Closing Time',
                          _formatTime(ticket.closingTimestamp),
                          isMobile,
                        ),
                        _buildDetailRow('Submitted By', ticket.submittedBy, isMobile),

                        SizedBox(height: 20),

                        // Denomination Breakdown Section
                        if (ticket.denominationBreakdown.isNotEmpty) ...[
                          Text(
                            'Ticket Breakdown by Denomination',
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
                                        flex: 2,
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
                                        flex: 2,
                                        child: Text(
                                          'Opening',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: isMobile ? 12 : 14,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Closing',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: isMobile ? 12 : 14,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Passengers',
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
                                ...ticket.denominationBreakdown.entries.map((entry) {
                                  final denom = entry.key;
                                  final data = entry.value;
                                  final index = ticket.denominationBreakdown.keys.toList().indexOf(denom);

                                  return Container(
                                    padding: EdgeInsets.all(isMobile ? 8 : 12),
                                    decoration: BoxDecoration(
                                      color: index.isEven ? Colors.grey[50] : Colors.white,
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
                                          flex: 2,
                                          child: Text(
                                            '₱$denom',
                                            style: TextStyle(
                                              fontSize: isMobile ? 12 : 14,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF0D2364),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            _formatTicketNumber(data.opening),
                                            style: TextStyle(
                                              fontSize: isMobile ? 12 : 14,
                                              color: Colors.black87,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            _formatTicketNumber(data.closing),
                                            style: TextStyle(
                                              fontSize: isMobile ? 12 : 14,
                                              color: Colors.black87,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            data.passengers.toString(),
                                            style: TextStyle(
                                              fontSize: isMobile ? 12 : 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.green[700],
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                          SizedBox(height: 16),
                        ],

                        // Total Summary
                        Container(
                          padding: EdgeInsets.all(isMobile ? 12 : 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Color(0xFF0D2364), width: 2),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Passengers:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                  fontSize: isMobile ? 14 : 16,
                                ),
                              ),
                              Text(
                                ticket.passengers.toString(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 18 : 20,
                                  color: Color(0xFF0D2364),
                                ),
                              ),
                            ],
                          ),
                        ),
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
                        color: Color(0xFF0D2364).withAlpha(25),
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
    Color customBlueColor = const Color(0xFF0D2364);

    return Column(
      children: [
        // Search Section
        Container(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha(50),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Search Ticket Data',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: customBlueColor,
                ),
              ),
              const SizedBox(height: 15),
              _buildSearchField(
                'Unit Number',
                _unitNumberController,
                'Enter unit number',
                isMobile,
              ),
              const SizedBox(height: 12),
              _buildSearchField(
                'Conductor Name',
                _conductorNameController,
                'Enter conductor name',
                isMobile,
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _fetchInspectorTripData,
                  icon: const Icon(Icons.search),
                  label: const Text('Search'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: customBlueColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        if (isLoading)
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Center(child: CircularProgressIndicator()),
          ),

        // Ticket Report Summary
        if (unitNumber.isNotEmpty) ...[
          SizedBox(height: isMobile ? 12 : 16),
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(50),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ticket Report Summary',
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildInfoRow('Unit Number:', unitNumber, isMobile),
                  _buildInfoRow('Driver:', driverName, isMobile),
                  _buildInfoRow('Conductor:', conductorName, isMobile),
                  _buildInfoRow('Location:', location, isMobile),
                  const SizedBox(height: 10),
                  Text(
                    'Total passenger from latest ticket inspection:',
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[50],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$noOfPass passengers',
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 16,
                              fontWeight: FontWeight.w600,
                              color: customBlueColor,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            inspectionTime.isNotEmpty ? inspectionTime : '--:--',
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 16,
                              fontWeight: FontWeight.w600,
                              color: customBlueColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (ticketData.isNotEmpty) ...[
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            showTicketTable = !showTicketTable;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: customBlueColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          showTicketTable ? 'Hide Ticket Table' : 'Show Ticket Table',
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (showTicketTable && ticketData.isNotEmpty) ...[
                    const SizedBox(height: 15),
                    _buildTicketTable(isMobile),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSearchField(
      String label,
      TextEditingController controller,
      String hint,
      bool isSmallScreen,
      ) {
    Color customBlueColor = const Color(0xFF0D2364);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: customBlueColor),
            ),
            contentPadding: EdgeInsets.all(isSmallScreen ? 12 : 14),
          ),
          style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, bool isSmallScreen) {
    Color customBlueColor = const Color(0xFF0D2364);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: customBlueColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketTable(bool isSmallScreen) {
    Color customBlueColor = const Color(0xFF0D2364);
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: 300,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[400]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: isSmallScreen ? 500 : 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    vertical: isSmallScreen ? 8 : 10,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: customBlueColor,
                    border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: isSmallScreen ? 50 : 60,
                        child: Text(
                          '#',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 12 : 14,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      for (String header in ticketHeaders)
                        SizedBox(
                          width: isSmallScreen ? 80 : 100,
                          child: Text(
                            header,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallScreen ? 12 : 14,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
                for (int rowIndex = 0; rowIndex < ticketData.length; rowIndex++)
                  Container(
                    padding: EdgeInsets.symmetric(
                      vertical: isSmallScreen ? 8 : 10,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: rowIndex % 2 == 0 ? Colors.grey[50] : Colors.white,
                      border: Border(
                        bottom: rowIndex == ticketData.length - 1
                            ? BorderSide.none
                            : BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: isSmallScreen ? 50 : 60,
                          child: Text(
                            '${rowIndex + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: isSmallScreen ? 12 : 14,
                              color: customBlueColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        for (int colIndex = 0;
                        colIndex < ticketData[rowIndex].length;
                        colIndex++)
                          SizedBox(
                            width: isSmallScreen ? 80 : 100,
                            child: Text(
                              ticketData[rowIndex][colIndex],
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 14,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<int> _calculateTotalPassengersFromTicketReport() async {
    try {
      final querySnapshot = await _firestore.collection('ticket_report').get();

      int totalPassengers = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();

        final openingTickets = data['openingTickets'] as List<dynamic>? ?? [];
        final closingTickets = data['closingTickets'] as List<dynamic>? ?? [];

        for (int i = 0; i < openingTickets.length && i < closingTickets.length; i++) {
          final openingMap = openingTickets[i] as Map<String, dynamic>? ?? {};
          final closingMap = closingTickets[i] as Map<String, dynamic>? ?? {};

          for (String denomination in ['1', '2', '5', '10', '15', '20']) {
            final openingStr = openingMap[denomination]?.toString() ?? '0';
            final closingStr = closingMap[denomination]?.toString() ?? '0';

            final opening = int.tryParse(openingStr.replaceAll('"', '')) ?? 0;
            final closing = int.tryParse(closingStr.replaceAll('"', '')) ?? 0;

            final ticketsUsed = (closing - opening).abs();
            totalPassengers += ticketsUsed;
          }
        }
      }

      return totalPassengers;
    } catch (e) {
      debugPrint('Error calculating total passengers: $e');
      return 0;
    }
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
            color: Colors.grey.withAlpha(50),
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
            FutureBuilder<int>(
              future: _calculateTotalPassengersFromTicketReport(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }

                final totalPassengers = snapshot.data ?? 0;

                return Text(
                  'Total Passengers: $totalPassengers',
                  style: TextStyle(
                    color: const Color(0xFF0D2364),
                    fontSize: isMobile ? 10 : 12,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
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

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
                      child: Column(
                        children: [
                          _buildSearchAndFilterSection(isMobile, vehicleOptions),
                          SizedBox(height: isMobile ? 12 : 16),
                          Container(
                            constraints: BoxConstraints(
                              minHeight: 400,
                              maxHeight: MediaQuery.of(context).size.height * 0.6,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withAlpha(50),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: isMobile
                                ? _buildMobileList(filteredTickets)
                                : _buildDesktopTable(filteredTickets),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildResultsFooter(filteredTickets, allTickets.length, isMobile),
              ],
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
  final Map<String, DenominationData> denominationBreakdown;

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
    this.denominationBreakdown = const {},
  });
}

class DenominationData {
  final int opening;
  final int? closing;
  final int passengers;

  DenominationData({
    required this.opening,
    this.closing,
    required this.passengers,
  });
}