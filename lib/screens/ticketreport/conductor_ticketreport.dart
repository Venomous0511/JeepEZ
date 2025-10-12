import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../models/app_user.dart';

void main() {
  runApp(const TicketReportApp());
}

class TicketReportApp extends StatelessWidget {
  const TicketReportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const TicketReportScreen(),
    );
  }
}

class TicketReportScreen extends StatefulWidget {
  const TicketReportScreen({super.key});

  @override
  State<TicketReportScreen> createState() => _TicketReportScreenState();
}

class _TicketReportScreenState extends State<TicketReportScreen> {
  AppUser? user;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      setState(() {
        user = AppUser.fromMap(uid, doc.data()!);
      });
    }
  }

  bool showTicketTable = false;
  bool isLoading = false;

  final TextEditingController _openingTicketController =
      TextEditingController();
  final TextEditingController _closingTicketController =
      TextEditingController();
  final TextEditingController _unitNumberController = TextEditingController();
  final TextEditingController _conductorNameController =
      TextEditingController();

  Color customBlueColor = const Color(0xFF0D2364);

  List<String> ticketHeaders = ['20', '15', '10', '5', '2', '1'];
  List<List<String>> ticketData = [];

  String noOfPass = '0';
  String inspectionTime = '';
  String conductorName = '';
  String driverName = '';
  String location = '';
  String unitNumber = '';

  // Time controllers
  final TextEditingController _openingTimeController = TextEditingController();
  final TextEditingController _closingTimeController = TextEditingController();

  @override
  void dispose() {
    _openingTicketController.dispose();
    _closingTicketController.dispose();
    _unitNumberController.dispose();
    _conductorNameController.dispose();
    _openingTimeController.dispose();
    _closingTimeController.dispose();
    super.dispose();
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
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('inspector_trip')
          .where('unitNumber', isEqualTo: _unitNumberController.text.trim())
          .where(
            'conductorName',
            isEqualTo: _conductorNameController.text.trim(),
          )
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        QuerySnapshot alternativeQuery = await FirebaseFirestore.instance
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
              // Extract the values in the correct order based on ticketHeaders
              List<String> rowData = [];
              for (String header in ticketHeaders) {
                String value = row[header]?.toString() ?? '0';
                rowData.add(value);
              }
              ticketData.add(rowData);
            } else if (row is List) {
              // Keep the existing logic for backward compatibility
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

  Future<void> _selectTime(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      final formattedTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      controller.text = formattedTime;
    }
  }

  void _showReportHistory() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ticket Report History',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: customBlueColor,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('ticket_report')
                        .where('employeeId', isEqualTo: user?.employeeId)
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'No report history found',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        );
                      }
                      final docs = snapshot.data!.docs;
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data =
                              docs[index].data() as Map<String, dynamic>;
                          final timestamp = data['timestamp'] as Timestamp?;
                          final type = data['type']?.toString() ?? 'N/A';
                          final ticketNumber =
                              data['ticketNumber']?.toString() ?? 'N/A';
                          final time = data['time']?.toString() ?? '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${type.toUpperCase()} TICKET',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: type == 'opening'
                                            ? Colors.green
                                            : Colors.blue,
                                      ),
                                    ),
                                    Text(
                                      '#$ticketNumber',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('Unit: ${data['unitNumber'] ?? 'N/A'}'),
                                Text(
                                  'Conductor: ${data['conductorName'] ?? 'N/A'}',
                                ),
                                if (time.isNotEmpty) Text('Time: $time'),
                                if (timestamp != null)
                                  Text(
                                    'Submitted: ${_formatTimestamp(timestamp)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 15),
                Center(
                  child: SizedBox(
                    width: 120,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: customBlueColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Close'),
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

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('MM/dd/yyyy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2364),
        title: const Text(''),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isSmallScreen = constraints.maxWidth < 600;

            return SingleChildScrollView(
              padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Section - WALANG TICKET REPORT TITLE
                    Container(
                      margin: EdgeInsets.only(bottom: isSmallScreen ? 20 : 30),
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
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
                      child: _buildSearchSection(isSmallScreen),
                    ),

                    if (isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),

                    // Ticket Report Summary
                    if (unitNumber.isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(
                          bottom: isSmallScreen ? 20 : 30,
                        ),
                        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
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
                        child: _buildTicketReportForm(isSmallScreen),
                      ),

                    // Show/Hide Ticket Table Button
                    if (ticketData.isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(
                          bottom: isSmallScreen ? 15 : 20,
                        ),
                        child: _buildTicketButton(isSmallScreen),
                      ),

                    // Ticket Table
                    if (showTicketTable && ticketData.isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(
                          bottom: isSmallScreen ? 20 : 30,
                        ),
                        child: _buildTicketTable(isSmallScreen),
                      ),

                    // TICKET LOGS SECTION
                    Container(
                      margin: EdgeInsets.only(bottom: isSmallScreen ? 20 : 30),
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
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
                          // Header with History Button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'TICKET LOGS',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 18 : 20,
                                  fontWeight: FontWeight.bold,
                                  color: customBlueColor,
                                ),
                              ),
                              IconButton(
                                onPressed: _showReportHistory,
                                icon: const Icon(Icons.history, size: 24),
                                tooltip: 'View Report History',
                                style: IconButton.styleFrom(
                                  backgroundColor: customBlueColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.all(8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),

                          // Opening Ticket Row
                          _buildTicketLogRow(
                            'Opening Ticket',
                            _openingTicketController,
                            _openingTimeController,
                            isSmallScreen,
                            Icons.play_arrow,
                            Colors.green,
                          ),
                          const SizedBox(height: 15),

                          // Closing Ticket Row
                          _buildTicketLogRow(
                            'Closing Ticket',
                            _closingTicketController,
                            _closingTimeController,
                            isSmallScreen,
                            Icons.stop,
                            Colors.red,
                          ),
                        ],
                      ),
                    ),

                    // Submit Buttons
                    Container(
                      margin: EdgeInsets.only(bottom: isSmallScreen ? 10 : 15),
                      child: _buildSubmitButtons(isSmallScreen),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchSection(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search Ticket Data',
          style: TextStyle(
            fontSize: isSmallScreen ? 18 : 20,
            fontWeight: FontWeight.bold,
            color: customBlueColor,
          ),
        ),
        const SizedBox(height: 15),

        _buildSearchField(
          'Unit Number',
          _unitNumberController,
          'Enter unit number',
          isSmallScreen,
        ),
        const SizedBox(height: 12),

        _buildSearchField(
          'Conductor Name',
          _conductorNameController,
          'Enter conductor name',
          isSmallScreen,
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
              padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField(
    String label,
    TextEditingController controller,
    String hint,
    bool isSmallScreen,
  ) {
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

  Widget _buildTicketReportForm(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ticket Report Summary',
          style: TextStyle(
            fontSize: isSmallScreen ? 18 : 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 15),

        _buildInfoRow('Unit Number:', unitNumber, isSmallScreen),
        _buildInfoRow('Driver:', driverName, isSmallScreen),
        _buildInfoRow('Conductor:', conductorName, isSmallScreen),
        _buildInfoRow('Location:', location, isSmallScreen),
        const SizedBox(height: 10),

        Text(
          'Total passenger from latest ticket inspection:',
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
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
                    fontSize: isSmallScreen ? 14 : 16,
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
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    color: customBlueColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, bool isSmallScreen) {
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

  Widget _buildTicketButton(bool isSmallScreen) {
    return SizedBox(
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
          padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          showTicketTable ? 'Hide Ticket Table' : 'Show Ticket Table',
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTicketTable(bool isSmallScreen) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[400]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: isSmallScreen ? 500 : 600),
          child: Column(
            children: [
              // Header Row
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
                          '₱$header',
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

              // Data Rows
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
                      for (
                        int colIndex = 0;
                        colIndex < ticketData[rowIndex].length;
                        colIndex++
                      )
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
    );
  }

  Widget _buildTicketLogRow(
    String label,
    TextEditingController ticketController,
    TextEditingController timeController,
    bool isSmallScreen,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[50],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ticket Number:',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: TextField(
                          controller: ticketController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: InputDecoration(
                            hintText: 'Enter ticket number (1-99999)...',
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(
                              isSmallScreen ? 12 : 14,
                            ),
                            counterText: "",
                          ),
                          style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              final filtered = value.replaceAll(
                                RegExp(r'[^0-9]'),
                                '',
                              );
                              if (filtered != value) {
                                ticketController.value = TextEditingValue(
                                  text: filtered,
                                  selection: TextSelection.collapsed(
                                    offset: filtered.length,
                                  ),
                                );
                              }
                              if (filtered.isNotEmpty) {
                                final number = int.tryParse(filtered);
                                if (number != null && number > 99999) {
                                  ticketController.value = TextEditingValue(
                                    text: '99999',
                                    selection: TextSelection.collapsed(
                                      offset: 4,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Time:',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => _selectTime(context, timeController),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[400]!),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  timeController.text.isEmpty
                                      ? 'Select time'
                                      : timeController.text,
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 16,
                                    color: timeController.text.isEmpty
                                        ? Colors.grey[600]
                                        : Colors.black,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.access_time,
                                color: customBlueColor,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButtons(bool isSmallScreen) {
    if (isSmallScreen) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _submitTicket('opening'),
              style: ElevatedButton.styleFrom(
                backgroundColor: customBlueColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Submit Opening Ticket',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _submitTicket('closing'),
              style: ElevatedButton.styleFrom(
                backgroundColor: customBlueColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Submit Closing Ticket',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _submitTicket('opening'),
              style: ElevatedButton.styleFrom(
                backgroundColor: customBlueColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Submit Opening Ticket',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _submitTicket('closing'),
              style: ElevatedButton.styleFrom(
                backgroundColor: customBlueColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Submit Closing Ticket',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      );
    }
  }

  Future<void> _submitTicket(String type) async {
    String ticketNumber = type == 'opening'
        ? _openingTicketController.text.trim()
        : _closingTicketController.text.trim();

    String time = type == 'opening'
        ? _openingTimeController.text.trim()
        : _closingTimeController.text.trim();

    if (ticketNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter ${type == 'opening' ? 'opening' : 'closing'} ticket number',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (time.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select ${type == 'opening' ? 'opening' : 'closing'} time',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final number = int.tryParse(ticketNumber);
    if (number == null || number < 1 || number > 99999) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid number between 1-99999'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Save ticket using logged-in user's data
    Map<String, dynamic> ticketDataToSave = {
      'type': type,
      'ticketNumber': number,
      'time': time,
      'unitNumber': user?.assignedVehicle ?? _unitNumberController.text.trim(),
      'conductorName': user?.name ?? _conductorNameController.text.trim(),
      'employeeId': user?.employeeId,
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('ticket_report')
          .add(ticketDataToSave);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${type == 'opening' ? 'Opening' : 'Closing'} Ticket $ticketNumber saved successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      if (type == 'opening') {
        _openingTicketController.clear();
        _openingTimeController.clear();
      } else {
        _closingTicketController.clear();
        _closingTimeController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
