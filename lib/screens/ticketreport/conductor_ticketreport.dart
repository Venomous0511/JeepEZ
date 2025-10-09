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

  // Exact blue color na sinabi mo
  Color customBlueColor = const Color(0xFF0D2364);

  // Ticket data based on the image content
  List<List<String>> ticketData = [
    ['20', '15', '10', '5', '2', '1'],
    ['NO.123', 'NO.123', 'NO.123', 'NO.123', 'NO.123', 'NO.123'],
    ['44', '44', '44', '44', '44', '44'],
    ['10', '10', '10', '10', '10', '10'],
    ['02', '02', '02', '02', '02', '02'],
    ['05', '05', '05', '05', '05', '05'],
    ['02', '02', '02', '02', '02', '02'],
  ];

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
    String message = type == 'opening'
        ? 'Opening Ticket submitted successfully!'
        : 'Closing Ticket submitted successfully!';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }
}
