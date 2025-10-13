import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
  dynamic user;
  bool hasSubmittedOpeningToday = false;
  bool hasSubmittedClosingToday = false;
  String? todayOpeningDocId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();

    // Start with only one row for each section
    openingTicketRows = [
      List.generate(6, (index) => TextEditingController(text: '0')),
    ];
    closingTicketRows = [
      List.generate(6, (index) => TextEditingController(text: '0')),
    ];
  }

  Future<void> _loadCurrentUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      setState(() {
        user = doc.data();
        user?['uid'] = uid;
      });
      await _checkTodaySubmissions();
    }
  }

  Future<void> _checkTodaySubmissions() async {
    if (user == null) return;

    final firestore = FirebaseFirestore.instance;
    final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final unit = (user['assignedVehicle'] ?? 'N/A').toString();
    final conductor = (user['name'] ?? '').toString().toLowerCase().trim();
    final docId = '${dateKey}_${unit}_$conductor'.replaceAll(' ', '_');

    try {
      final doc = await firestore.collection('ticket_report').doc(docId).get();

      if (doc.exists) {
        final data = doc.data()!;
        final opening = data['openingTickets'] as List?;
        final closing = data['closingTickets'] as List?;

        setState(() {
          hasSubmittedOpeningToday = opening != null && opening.isNotEmpty;
          hasSubmittedClosingToday = closing != null && closing.isNotEmpty;
        });
      } else {
        setState(() {
          hasSubmittedOpeningToday = false;
          hasSubmittedClosingToday = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking today submissions: $e');
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
        .where('employeeId', isEqualTo: user?['employeeId'])
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      List<TicketReportData> allReports = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();

        final timestamp = (data['timestamp'] as Timestamp).toDate();
        final openingTickets = (data['openingTickets'] as List?) ?? [];
        final closingTickets = (data['closingTickets'] as List?) ?? [];

        // ✅ Create a record for opening if available
        if (openingTickets.isNotEmpty) {
          allReports.add(
            TicketReportData(
              timestamp: timestamp,
              openingTickets: List<Map<String, dynamic>>.from(openingTickets),
              closingTickets: [],
              type: 'opening',
            ),
          );
        }

        // ✅ Create a record for closing if available
        if (closingTickets.isNotEmpty) {
          allReports.add(
            TicketReportData(
              timestamp: timestamp,
              openingTickets: [],
              closingTickets: List<Map<String, dynamic>>.from(closingTickets),
              type: 'closing',
            ),
          );
        }
      }

      // Sort so most recent comes first
      allReports.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return allReports;
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
                          return _buildHistoryCard(report, index);
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

  Widget _buildHistoryCard(TicketReportData report, int index) {
    final tickets = report.type == 'opening'
        ? report.openingTickets
        : report.closingTickets;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: report.type == 'opening'
                ? Colors.green[100]
                : Colors.red[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            report.type == 'opening' ? Icons.play_arrow : Icons.stop,
            color: report.type == 'opening'
                ? Colors.green[800]
                : Colors.red[800],
          ),
        ),
        title: Text(
          '${report.type.toUpperCase()} Ticket Report',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: customBlueColor,
          ),
        ),
        subtitle: Text(
          _formatDate(report.timestamp),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ticket Report:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: customBlueColor,
                  ),
                ),
                const SizedBox(height: 8),
                ...tickets.asMap().entries.map((entry) {
                  Map<String, dynamic> ticket = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            _buildTicketDetail('20', ticket['20'] ?? '0'),
                            _buildTicketDetail('15', ticket['15'] ?? '0'),
                            _buildTicketDetail('10', ticket['10'] ?? '0'),
                            _buildTicketDetail('5', ticket['5'] ?? '0'),
                            _buildTicketDetail('2', ticket['2'] ?? '0'),
                            _buildTicketDetail('1', ticket['1'] ?? '0'),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketDetail(String label, String value) {
    return Text(
      '$label: $value',
      style: const TextStyle(fontSize: 12),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ticket Report',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (user != null)
              Text(
                'Unit No: ${user['assignedVehicle'] ?? 'N/A'}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
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
                    // Unit Number Display Card
                    Container(
                      margin: EdgeInsets.only(bottom: isSmallScreen ? 15 : 20),
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            customBlueColor,
                            customBlueColor.withOpacity(0.8)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: customBlueColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.directions_bus,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Vehicle Unit Number',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user?['assignedVehicle'].toString() ?? 'Not Assigned',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Status Indicators
                    Container(
                      margin: EdgeInsets.only(bottom: isSmallScreen ? 15 : 20),
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatusIndicator(
                              'Opening Ticket',
                              hasSubmittedOpeningToday,
                              Colors.green,
                              Icons.check_circle,
                              Icons.radio_button_unchecked,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.grey[300],
                          ),
                          Expanded(
                            child: _buildStatusIndicator(
                              'Closing Ticket',
                              hasSubmittedClosingToday,
                              Colors.red,
                              Icons.check_circle,
                              Icons.radio_button_unchecked,
                            ),
                          ),
                        ],
                      ),
                    ),

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
                      child: Column(
                        children: [
                          _buildTicketSection(
                            'Opening Ticket',
                            openingTicketRows,
                            _addOpeningTicketRow,
                            _removeOpeningTicketRow,
                            isSmallScreen,
                            Colors.green,
                            Icons.play_arrow,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: hasSubmittedOpeningToday
                                  ? null
                                  : () => _submitOpeningTickets(),
                              icon: Icon(
                                hasSubmittedOpeningToday
                                    ? Icons.check_circle
                                    : Icons.send,
                              ),
                              label: Text(
                                hasSubmittedOpeningToday
                                    ? 'Opening Submitted Today'
                                    : 'Submit Opening Tickets',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: hasSubmittedOpeningToday
                                    ? Colors.grey
                                    : Colors.green,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  vertical: isSmallScreen ? 12 : 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
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
                      child: Column(
                        children: [
                          _buildTicketSection(
                            'Closing Ticket',
                            closingTicketRows,
                            _addClosingTicketRow,
                            _removeClosingTicketRow,
                            isSmallScreen,
                            Colors.red,
                            Icons.stop,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: !hasSubmittedOpeningToday
                                  ? null
                                  : hasSubmittedClosingToday
                                  ? null
                                  : () => _submitClosingTickets(),
                              icon: Icon(
                                hasSubmittedClosingToday
                                    ? Icons.check_circle
                                    : Icons.send,
                              ),
                              label: Text(
                                hasSubmittedClosingToday
                                    ? 'Closing Submitted Today'
                                    : !hasSubmittedOpeningToday
                                    ? 'Submit Opening First'
                                    : 'Submit Closing Tickets',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: hasSubmittedClosingToday
                                    ? Colors.grey
                                    : !hasSubmittedOpeningToday
                                    ? Colors.grey
                                    : Colors.red,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  vertical: isSmallScreen ? 12 : 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          if (!hasSubmittedOpeningToday)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '⚠️ Please submit opening tickets first',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
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
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(
      String label,
      bool isSubmitted,
      Color color,
      IconData iconSubmitted,
      IconData iconPending,
      ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isSubmitted ? iconSubmitted : iconPending,
          color: isSubmitted ? color : Colors.grey,
          size: 20,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            Text(
              isSubmitted ? 'Submitted' : 'Pending',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSubmitted ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ],
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

  Future<void> _submitOpeningTickets() async {
    try {
      if (user == null) return;

      final firestore = FirebaseFirestore.instance;

      // Unique ID: date + unit + conductor
      final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final unit = (user['assignedVehicle'] ?? 'N/A').toString();
      final conductor = (user['name'] ?? '').toString().toLowerCase().trim();
      final docId = '${dateKey}_${unit}_$conductor'.replaceAll(' ', '_');

      // Prepare ticket rows
      List<Map<String, dynamic>> ticketData = openingTicketRows.map((row) {
        Map<String, dynamic> ticket = {};
        for (int i = 0; i < ticketHeaders.length; i++) {
          ticket[ticketHeaders[i]] = row[i].text.trim();
        }
        return ticket;
      }).toList();

      // Save or merge into same doc
      await firestore.collection('ticket_report').doc(docId).set({
        'employeeId': user['employeeId'],
        'conductorName': user['name'],
        'unitNumber': user['assignedVehicle'] ?? 'N/A',
        'type': 'opening',
        'timestamp': FieldValue.serverTimestamp(),
        'openingTickets': ticketData,
      }, SetOptions(merge: true));

      setState(() => hasSubmittedOpeningToday = true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening tickets submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error submitting opening tickets: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit opening tickets: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitClosingTickets() async {
    try {
      if (user == null) return;

      final firestore = FirebaseFirestore.instance;

      // Same docId logic as opening
      final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final unit = (user['assignedVehicle'] ?? 'N/A').toString();
      final conductor = (user['name'] ?? '').toString().toLowerCase().trim();
      final docId = '${dateKey}_${unit}_$conductor'.replaceAll(' ', '_');

      // Prepare ticket rows
      List<Map<String, dynamic>> ticketData = closingTicketRows.map((row) {
        Map<String, dynamic> ticket = {};
        for (int i = 0; i < ticketHeaders.length; i++) {
          ticket[ticketHeaders[i]] = row[i].text.trim();
        }
        return ticket;
      }).toList();

      // Merge the closing data into same doc
      await firestore.collection('ticket_report').doc(docId).set({
        'type': 'closing',
        'timestamp': FieldValue.serverTimestamp(),
        'closingTickets': ticketData,
      }, SetOptions(merge: true));

      setState(() => hasSubmittedClosingToday = true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Closing tickets submitted successfully!'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error submitting closing tickets: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit closing tickets: $e'),
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
  final String type;

  TicketReportData({
    required this.timestamp,
    required this.openingTickets,
    required this.closingTickets,
    required this.type,
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
      type: data['type'],
    );
  }
}