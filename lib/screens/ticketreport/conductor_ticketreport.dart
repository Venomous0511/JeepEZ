import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/app_user.dart';

void main() {
  runApp(const TicketReportApp());
}

class TicketReportApp extends StatelessWidget {
  const TicketReportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ticket Report',
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
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      setState(() {
        user = AppUser.fromMap(uid, doc.data()!);
      });
    }
  }

  bool showTicketTable = false;
  bool isLoading = false;

  final TextEditingController _openingTicketController = TextEditingController();
  final TextEditingController _closingTicketController = TextEditingController();
  final TextEditingController _unitNumberController = TextEditingController();
  final TextEditingController _conductorNameController = TextEditingController();

  Color customBlueColor = const Color(0xFF0D2364);

  List<String> ticketHeaders = ['20', '15', '10', '5', '2', '1'];
  List<List<String>> ticketData = [];

  String noOfPass = '0';
  String inspectionTime = '';
  String conductorName = '';
  String driverName = '';
  String location = '';
  String unitNumber = '';

  @override
  void dispose() {
    _openingTicketController.dispose();
    _closingTicketController.dispose();
    _unitNumberController.dispose();
    _conductorNameController.dispose();
    super.dispose();
  }

  Future<void> _fetchInspectorTripData() async {
    if (_unitNumberController.text.isEmpty || _conductorNameController.text.isEmpty) {
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
          .where('conductorName', isEqualTo: _conductorNameController.text.trim())
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

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
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No data found for this Unit Number and Conductor'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: const Color(0xFF0D2364)),
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
                    Container(
                      margin: EdgeInsets.only(bottom: isSmallScreen ? 20 : 30),
                      child: _buildTitle(isSmallScreen),
                    ),

                    // Search Section
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
                      child: _buildTicketReportForm(isSmallScreen),
                    ),

                    Container(
                      margin: EdgeInsets.only(bottom: isSmallScreen ? 15 : 20),
                      child: _buildTicketButton(isSmallScreen),
                    ),

                    if (showTicketTable && ticketData.isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(bottom: isSmallScreen ? 20 : 30),
                        child: _buildTicketTable(isSmallScreen),
                      ),

                    if (showTicketTable && ticketData.isEmpty)
                      Container(
                        margin: EdgeInsets.only(bottom: isSmallScreen ? 20 : 30),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Center(
                          child: Text(
                            'No ticket data available. Please search for a unit and conductor.',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                    Container(
                      margin: EdgeInsets.only(bottom: isSmallScreen ? 15 : 20),
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
                      child: _buildOpeningTicketField(isSmallScreen),
                    ),

                    Container(
                      margin: EdgeInsets.only(bottom: isSmallScreen ? 15 : 20),
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
                      child: _buildClosingTicketField(isSmallScreen),
                    ),

                    Container(
                      margin: EdgeInsets.only(bottom: isSmallScreen ? 10 : 15),
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

  Widget _buildTitle(bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: BoxDecoration(
        color: customBlueColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Ticket Report',
        style: TextStyle(
          fontSize: isSmallScreen ? 24 : 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
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

        if (unitNumber.isNotEmpty) ...[
          _buildInfoRow('Unit Number:', unitNumber, isSmallScreen),
          _buildInfoRow('Driver:', driverName, isSmallScreen),
          _buildInfoRow('Conductor:', conductorName, isSmallScreen),
          _buildInfoRow('Location:', location, isSmallScreen),
          const SizedBox(height: 10),
        ],

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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!),
                  ),
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
                      for (int colIndex = 0; colIndex < ticketData[rowIndex].length; colIndex++)
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

  Widget _buildOpeningTicketField(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Opening Ticket:',
          style: TextStyle(
            fontSize: isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[400]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _openingTicketController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: InputDecoration(
              hintText: 'Enter opening ticket number (1-99999)...',
              hintStyle: TextStyle(color: Colors.grey[600]),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              counterText: "",
            ),
            style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
            onChanged: (value) {
              if (value.isNotEmpty) {
                final filtered = value.replaceAll(RegExp(r'[^0-9]'), '');
                if (filtered != value) {
                  _openingTicketController.value = TextEditingValue(
                    text: filtered,
                    selection: TextSelection.collapsed(offset: filtered.length),
                  );
                }
                if (filtered.isNotEmpty) {
                  final number = int.tryParse(filtered);
                  if (number != null && number > 99999) {
                    _openingTicketController.value = TextEditingValue(
                      text: '99999',
                      selection: TextSelection.collapsed(offset: 4),
                    );
                  }
                }
              }
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_openingTicketController.text.length}/6',
                style: TextStyle(
                  fontSize: 12,
                  color: _openingTicketController.text.length > 6
                      ? Colors.red
                      : Colors.grey[600],
                ),
              ),
              if (_openingTicketController.text.isNotEmpty)
                Text(
                  'Range: 1-99999',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClosingTicketField(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Closing Ticket:',
          style: TextStyle(
            fontSize: isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[400]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _closingTicketController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: InputDecoration(
              hintText: 'Enter closing ticket number (1-99999)...',
              hintStyle: TextStyle(color: Colors.grey[600]),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              counterText: "",
            ),
            style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
            onChanged: (value) {
              if (value.isNotEmpty) {
                final filtered = value.replaceAll(RegExp(r'[^0-9]'), '');
                if (filtered != value) {
                  _closingTicketController.value = TextEditingValue(
                    text: filtered,
                    selection: TextSelection.collapsed(offset: filtered.length),
                  );
                }
                if (filtered.isNotEmpty) {
                  final number = int.tryParse(filtered);
                  if (number != null && number > 99999) {
                    _closingTicketController.value = TextEditingValue(
                      text: '99999',
                      selection: TextSelection.collapsed(offset: 4),
                    );
                  }
                }
              }
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_closingTicketController.text.length}/6',
                style: TextStyle(
                  fontSize: 12,
                  color: _closingTicketController.text.length > 6
                      ? Colors.red
                      : Colors.grey[600],
                ),
              ),
              if (_closingTicketController.text.isNotEmpty)
                Text(
                  'Range: 1-99999',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
            ],
          ),
        ),
      ],
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Submit Opening Ticket', style: TextStyle(fontSize: 16)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Submit Closing Ticket', style: TextStyle(fontSize: 16)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Submit Opening Ticket', style: TextStyle(fontSize: 16)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Submit Closing Ticket', style: TextStyle(fontSize: 16)),
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

    if (ticketNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter ${type == 'opening' ? 'opening' : 'closing'} ticket number'),
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
      'unitNumber': user?.assignedVehicle,
      'conductorName': user?.name,
      'employeeId': user?.employeeId,
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance.collection('ticket_report').add(ticketDataToSave);

      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${type == 'opening' ? 'Opening' : 'Closing'} Ticket $ticketNumber saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      }

      if (type == 'opening') {
        _openingTicketController.clear();
      } else {
        _closingTicketController.clear();
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