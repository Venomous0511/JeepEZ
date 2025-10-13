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
    _addOpeningTicketRow();
    _addClosingTicketRow();
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

  Color customBlueColor = const Color(0xFF0D2364);

  List<String> ticketHeaders = ['20', '15', '10', '5', '2', '1'];

  // Opening ticket rows
  List<List<TextEditingController>> openingTicketRows = [];
  // Closing ticket rows
  List<List<TextEditingController>> closingTicketRows = [];

  void _addOpeningTicketRow() {
    if (openingTicketRows.length < 4) {
      setState(() {
        openingTicketRows.add(
          List.generate(6, (index) => TextEditingController(text: '0')),
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 4 rows allowed for opening tickets'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _removeOpeningTicketRow(int rowIndex) {
    if (openingTicketRows.length > 1) {
      setState(() {
        for (var controller in openingTicketRows[rowIndex]) {
          controller.dispose();
        }
        openingTicketRows.removeAt(rowIndex);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least one row is required'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _addClosingTicketRow() {
    if (closingTicketRows.length < 4) {
      setState(() {
        closingTicketRows.add(
          List.generate(6, (index) => TextEditingController(text: '0')),
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 4 rows allowed for closing tickets'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _removeClosingTicketRow(int rowIndex) {
    if (closingTicketRows.length > 1) {
      setState(() {
        for (var controller in closingTicketRows[rowIndex]) {
          controller.dispose();
        }
        closingTicketRows.removeAt(rowIndex);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least one row is required'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  void dispose() {
    for (var row in openingTicketRows) {
      for (var controller in row) {
        controller.dispose();
      }
    }
    for (var row in closingTicketRows) {
      for (var controller in row) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  Stream<List<TicketReportData>> _getTicketReportsStream() {
    return FirebaseFirestore.instance
        .collection('ticket_report')
        .where('employeeId', isEqualTo: user?.employeeId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return TicketReportData.fromMap(data);
      }).toList();
    });
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
                  child: StreamBuilder<List<TicketReportData>>(
                    stream: _getTicketReportsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text(
                            'No report history found',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        );
                      }
                      final reports = snapshot.data!;
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: reports.length,
                        itemBuilder: (context, index) {
                          final report = reports[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
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
                                      'Submission #${index + 1}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: customBlueColor,
                                      ),
                                    ),
                                    Text(
                                      _formatDate(report.timestamp),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Opening: ${report.openingTickets.length} trip(s)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'Closing: ${report.closingTickets.length} trip(s)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w500,
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

  String _formatDate(DateTime date) {
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
                    // OPENING TICKET SECTION
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
                      child: _buildTicketSection(
                        'Opening Ticket',
                        openingTicketRows,
                        _addOpeningTicketRow,
                        _removeOpeningTicketRow,
                        isSmallScreen,
                        Colors.green,
                        Icons.play_arrow,
                      ),
                    ),

                    // CLOSING TICKET SECTION
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
                      child: _buildTicketSection(
                        'Closing Ticket',
                        closingTicketRows,
                        _addClosingTicketRow,
                        _removeClosingTicketRow,
                        isSmallScreen,
                        Colors.red,
                        Icons.stop,
                      ),
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
                      child: Row(
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
                    ),

                    // Submit Button
                    Container(
                      margin: EdgeInsets.only(bottom: isSmallScreen ? 10 : 15),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitTickets,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: customBlueColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: isSmallScreen ? 12 : 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Save & Submit',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.bold,
                            ),
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
      ),
    );
  }

  Widget _buildTicketSection(
      String title,
      List<List<TextEditingController>> ticketRows,
      VoidCallback onAddRow,
      Function(int) onRemoveRow,
      bool isSmallScreen,
      Color iconColor,
      IconData icon,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: customBlueColor,
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: onAddRow,
              icon: const Icon(
                Icons.add_circle,
                color: Color(0xFF0D2364),
              ),
              tooltip: 'Add Row',
            ),
          ],
        ),
        const SizedBox(height: 15),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                // Header Row
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: customBlueColor,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[400]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 60,
                        child: Center(
                          child: Text(
                            '#',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      for (String header in ticketHeaders)
                        SizedBox(
                          width: 80,
                          child: Center(
                            child: Text(
                              header,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      SizedBox(
                        width: 60,
                        child: Center(
                          child: Icon(
                            Icons.delete,
                            color: Colors.white,
                            size: isSmallScreen ? 16 : 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Data Rows
                for (int rowIndex = 0; rowIndex < ticketRows.length; rowIndex++)
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: rowIndex == ticketRows.length - 1
                            ? BorderSide.none
                            : BorderSide(color: Colors.grey[400]!),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 60,
                          child: Center(
                            child: Text(
                              '${rowIndex + 1}',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 14,
                                fontWeight: FontWeight.bold,
                                color: customBlueColor,
                              ),
                            ),
                          ),
                        ),
                        for (int colIndex = 0;
                        colIndex < ticketRows[rowIndex].length;
                        colIndex++)
                          Container(
                            width: 80,
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(
                                  color: Colors.grey[400]!,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 12,
                              ),
                              child: TextField(
                                controller:
                                ticketRows[rowIndex][colIndex],
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  isDense: true,
                                  hintText: '0',
                                ),
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 12 : 14,
                                  color: Colors.black,
                                ),
                                onChanged: (value) {
                                  if (value.isNotEmpty &&
                                      !RegExp(r'^[0-9]*$')
                                          .hasMatch(value)) {
                                    ticketRows[rowIndex][colIndex]
                                        .text = value.replaceAll(
                                      RegExp(r'[^0-9]'),
                                      '',
                                    );
                                    ticketRows[rowIndex][colIndex]
                                        .selection =
                                        TextSelection.fromPosition(
                                          TextPosition(
                                            offset: ticketRows[rowIndex]
                                            [colIndex]
                                                .text
                                                .length,
                                          ),
                                        );
                                  }
                                },
                              ),
                            ),
                          ),
                        SizedBox(
                          width: 60,
                          child: IconButton(
                            onPressed: () => onRemoveRow(rowIndex),
                            icon: Icon(
                              Icons.delete_outline,
                              color: Colors.red[700],
                              size: isSmallScreen ? 16 : 20,
                            ),
                            tooltip: 'Remove Row',
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitTickets() async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not logged in'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Convert opening ticket rows
      List<Map<String, dynamic>> openingTicketData = [];
      for (int i = 0; i < openingTicketRows.length; i++) {
        Map<String, dynamic> rowData = {
          'row': i + 1,
          '20': openingTicketRows[i][0].text,
          '15': openingTicketRows[i][1].text,
          '10': openingTicketRows[i][2].text,
          '5': openingTicketRows[i][3].text,
          '2': openingTicketRows[i][4].text,
          '1': openingTicketRows[i][5].text,
        };
        openingTicketData.add(rowData);
      }

      // Convert closing ticket rows
      List<Map<String, dynamic>> closingTicketData = [];
      for (int i = 0; i < closingTicketRows.length; i++) {
        Map<String, dynamic> rowData = {
          'row': i + 1,
          '20': closingTicketRows[i][0].text,
          '15': closingTicketRows[i][1].text,
          '10': closingTicketRows[i][2].text,
          '5': closingTicketRows[i][3].text,
          '2': closingTicketRows[i][4].text,
          '1': closingTicketRows[i][5].text,
        };
        closingTicketData.add(rowData);
      }

      Map<String, dynamic> ticketData = {
        'type': 'both',
        'openingTickets': openingTicketData,
        'closingTickets': closingTicketData,
        'employeeId': user?.employeeId,
        'conductorName': user?.name,
        'unitNumber': user?.assignedVehicle,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('ticket_report')
          .add(ticketData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ticket report saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Reset all rows
      setState(() {
        for (var row in openingTicketRows) {
          for (var controller in row) {
            controller.dispose();
          }
        }
        for (var row in closingTicketRows) {
          for (var controller in row) {
            controller.dispose();
          }
        }
        openingTicketRows.clear();
        closingTicketRows.clear();
        _addOpeningTicketRow();
        _addClosingTicketRow();
      });
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

class TicketReportData {
  final DateTime timestamp;
  final List<Map<String, dynamic>> openingTickets;
  final List<Map<String, dynamic>> closingTickets;

  TicketReportData({
    required this.timestamp,
    required this.openingTickets,
    required this.closingTickets,
  });

  factory TicketReportData.fromMap(Map<String, dynamic> data) {
    List<Map<String, dynamic>> openingTickets = [];
    List<Map<String, dynamic>> closingTickets = [];

    if (data['openingTickets'] is List) {
      openingTickets = List<Map<String, dynamic>>.from(data['openingTickets']);
    }

    if (data['closingTickets'] is List) {
      closingTickets = List<Map<String, dynamic>>.from(data['closingTickets']);
    }

    return TicketReportData(
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      openingTickets: openingTickets,
      closingTickets: closingTickets,
    );
  }
}