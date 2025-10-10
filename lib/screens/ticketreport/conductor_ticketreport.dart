import 'package:flutter/material.dart';

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
  bool showTicketTable = false;

  // Text controllers for the new fields
  final TextEditingController _openingTicketController =
      TextEditingController();
  final TextEditingController _closingTicketController =
      TextEditingController();

  // Exact blue color na sinabi mo
  Color customBlueColor = const Color(0xFF0D2364);

  // Ticket data based on the image content
  List<List<String>> ticketData = [
    ['20', '15', '10', '5', '2', '1'],
    ['44', '44', '44', '44', '44', '44'],
    ['10', '10', '10', '10', '10', '10'],
    ['02', '02', '02', '02', '02', '02'],
    ['05', '05', '05', '05', '05', '05'],
    ['02', '02', '02', '02', '02', '02'],
  ];

  @override
  void dispose() {
    _openingTicketController.dispose();
    _closingTicketController.dispose();
    super.dispose();
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
                    // Container para sa Title
                    Container(
                      margin: EdgeInsets.only(bottom: isSmallScreen ? 20 : 30),
                      child: _buildTitle(isSmallScreen),
                    ),

                    // Container para sa Ticket Report Form
                    Container(
                      margin: EdgeInsets.only(bottom: isSmallScreen ? 20 : 30),
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withAlpha(1),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _buildTicketReportForm(isSmallScreen),
                    ),

                    // Container para sa Ticket Button
                    Container(
                      margin: EdgeInsets.only(bottom: isSmallScreen ? 15 : 20),
                      child: _buildTicketButton(isSmallScreen),
                    ),

                    // Container para sa Table (shown when button is pressed)
                    if (showTicketTable)
                      Container(
                        margin: EdgeInsets.only(
                          bottom: isSmallScreen ? 20 : 30,
                        ),
                        child: _buildTicketTable(isSmallScreen),
                      ),

                    // Container para sa Opening Ticket Field
                    Container(
                      margin: EdgeInsets.only(bottom: isSmallScreen ? 15 : 20),
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withAlpha(1),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _buildOpeningTicketField(isSmallScreen),
                    ),

                    // Container para sa Closing Ticket Field
                    Container(
                      margin: EdgeInsets.only(bottom: isSmallScreen ? 15 : 20),
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withAlpha(1),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _buildClosingTicketField(isSmallScreen),
                    ),

                    // Container para sa Submit Buttons
                    Container(
                      margin: EdgeInsets.only(bottom: isSmallScreen ? 10 : 15),
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withAlpha(1),
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
        color: customBlueColor, // Exact blue color
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

  Widget _buildTicketReportForm(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(bottom: isSmallScreen ? 10 : 15),
          child: Text(
            'Ticket Report Form',
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),

        Container(
          margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 10),
          child: Text(
            'Total passenger from latest ticket inspection:',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ),

        // Text box with passenger count and time side by side
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
              // 20 passengers
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
                  '20 passengers',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    color: customBlueColor, // Exact blue color
                  ),
                ),
              ),

              // 9:00 AM
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
                  '9:00 AM',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    color: customBlueColor, // Exact blue color
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
          backgroundColor: customBlueColor, // Exact blue color
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
              // Table Rows - Exactly matching your image data
              ...ticketData.asMap().entries.map((entry) {
                int rowIndex = entry.key;
                List<String> rowData = entry.value;
                bool isFirstRow = rowIndex == 0; // 20 to 1 row

                return Container(
                  padding: EdgeInsets.symmetric(
                    vertical: isSmallScreen ? 8 : 10,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isFirstRow
                        ? customBlueColor
                        : Colors.transparent, // Exact blue color
                    border: Border(
                      bottom: rowIndex == ticketData.length - 1
                          ? BorderSide.none
                          : BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      for (int i = 0; i < rowData.length; i++)
                        SizedBox(
                          width: isSmallScreen ? 80 : 100,
                          child: Text(
                            rowData[i],
                            style: TextStyle(
                              fontWeight: isFirstRow
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: isSmallScreen ? 12 : 14,
                              color: isFirstRow ? Colors.white : Colors.black87,
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
      ),
    );
  }

  Widget _buildOpeningTicketField(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 10),
          child: Text(
            'Opening Ticket:',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[400]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _openingTicketController,
            keyboardType: TextInputType.number, // Number keyboard only
            maxLength: 4, // Limit to 4 characters (up to 1000)
            decoration: InputDecoration(
              hintText: 'Enter opening ticket number (1-1000)...',
              hintStyle: TextStyle(color: Colors.grey[600]),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              counterText: "", // Hide character counter
            ),
            style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
            onChanged: (value) {
              // Filter out non-numeric characters
              if (value.isNotEmpty) {
                final filtered = value.replaceAll(RegExp(r'[^0-9]'), '');
                if (filtered != value) {
                  _openingTicketController.value = TextEditingValue(
                    text: filtered,
                    selection: TextSelection.collapsed(offset: filtered.length),
                  );
                }

                // Validate range (1-1000)
                if (filtered.isNotEmpty) {
                  final number = int.tryParse(filtered);
                  if (number != null && number > 1000) {
                    _openingTicketController.value = TextEditingValue(
                      text: '1000',
                      selection: TextSelection.collapsed(offset: 4),
                    );
                  }
                }
              }
            },
          ),
        ),
        // Character count and validation message
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_openingTicketController.text.length}/4',
                style: TextStyle(
                  fontSize: 12,
                  color: _openingTicketController.text.length > 4
                      ? Colors.red
                      : Colors.grey[600],
                ),
              ),
              if (_openingTicketController.text.isNotEmpty)
                Text(
                  'Range: 1-1000',
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
        Container(
          margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 10),
          child: Text(
            'Closing Ticket:',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[400]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _closingTicketController,
            keyboardType: TextInputType.number, // Number keyboard only
            maxLength: 4, // Limit to 4 characters (up to 1000)
            decoration: InputDecoration(
              hintText: 'Enter closing ticket number (1-1000)...',
              hintStyle: TextStyle(color: Colors.grey[600]),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              counterText: "", // Hide character counter
            ),
            style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
            onChanged: (value) {
              // Filter out non-numeric characters
              if (value.isNotEmpty) {
                final filtered = value.replaceAll(RegExp(r'[^0-9]'), '');
                if (filtered != value) {
                  _closingTicketController.value = TextEditingValue(
                    text: filtered,
                    selection: TextSelection.collapsed(offset: filtered.length),
                  );
                }

                // Validate range (1-1000)
                if (filtered.isNotEmpty) {
                  final number = int.tryParse(filtered);
                  if (number != null && number > 1000) {
                    _closingTicketController.value = TextEditingValue(
                      text: '1000',
                      selection: TextSelection.collapsed(offset: 4),
                    );
                  }
                }
              }
            },
          ),
        ),
        // Character count and validation message
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_closingTicketController.text.length}/4',
                style: TextStyle(
                  fontSize: 12,
                  color: _closingTicketController.text.length > 4
                      ? Colors.red
                      : Colors.grey[600],
                ),
              ),
              if (_closingTicketController.text.isNotEmpty)
                Text(
                  'Range: 1-1000',
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
      // Vertical layout for small screens
      return Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            child: ElevatedButton(
              onPressed: () => _submitTicket('opening'),
              style: ElevatedButton.styleFrom(
                backgroundColor: customBlueColor, // Exact blue color
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _submitTicket('closing'),
              style: ElevatedButton.styleFrom(
                backgroundColor: customBlueColor, // Exact blue color
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
      // Horizontal layout for larger screens
      return SizedBox(
        child: Row(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                child: ElevatedButton(
                  onPressed: () => _submitTicket('opening'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: customBlueColor, // Exact blue color
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
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(left: 6),
                child: ElevatedButton(
                  onPressed: () => _submitTicket('closing'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: customBlueColor, // Exact blue color
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
            ),
          ],
        ),
      );
    }
  }

  void _submitTicket(String type) {
    String ticketNumber = '';
    String message = '';

    if (type == 'opening') {
      ticketNumber = _openingTicketController.text.trim();
      if (ticketNumber.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter opening ticket number'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final number = int.tryParse(ticketNumber);
      if (number == null || number < 1 || number > 1000) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid number between 1-1000'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      message = 'Opening Ticket $ticketNumber submitted successfully!';
    } else {
      ticketNumber = _closingTicketController.text.trim();
      if (ticketNumber.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter closing ticket number'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final number = int.tryParse(ticketNumber);
      if (number == null || number < 1 || number > 1000) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid number between 1-1000'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      message = 'Closing Ticket $ticketNumber submitted successfully!';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );

    // Clear the field after submission
    if (type == 'opening') {
      _openingTicketController.clear();
    } else {
      _closingTicketController.clear();
    }
  }
}
