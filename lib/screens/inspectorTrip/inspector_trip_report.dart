import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inspector Trip Form',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: InspectorTripScreen(),
    );
  }
}

class InspectorTripScreen extends StatefulWidget {
  const InspectorTripScreen({super.key});

  @override
  InspectorTripScreenState createState() => InspectorTripScreenState();
}

class InspectorTripScreenState extends State<InspectorTripScreen> {
  final TextEditingController unitNumberController = TextEditingController();
  final TextEditingController driverNameController = TextEditingController();
  final TextEditingController conductorNameController = TextEditingController();
  final TextEditingController inspectionTimeController =
      TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController noOfPassController = TextEditingController();
  final TextEditingController noOfTripsController = TextEditingController();

  // List to hold multiple rows of ticket data (max 4 rows)
  List<List<TextEditingController>> ticketRows = [];

  // Ticket denominations (header)
  final List<String> ticketHeaders = ['20', '15', '10', '5', '2', '1'];

  @override
  void initState() {
    super.initState();
    _addTicketRow();
  }

  void _addTicketRow() {
    if (ticketRows.length < 4) {
      setState(() {
        ticketRows.add(
          List.generate(6, (index) => TextEditingController(text: '0')),
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 4 rows allowed'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _removeTicketRow(int rowIndex) {
    if (ticketRows.length > 1) {
      setState(() {
        for (var controller in ticketRows[rowIndex]) {
          controller.dispose();
        }
        ticketRows.removeAt(rowIndex);
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
    for (var row in ticketRows) {
      for (var controller in row) {
        controller.dispose();
      }
    }
    unitNumberController.dispose();
    driverNameController.dispose();
    conductorNameController.dispose();
    inspectionTimeController.dispose();
    locationController.dispose();
    noOfPassController.dispose();
    noOfTripsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: const Color(0xFF0D2364)),
      body: Container(
        color: Colors.grey[100],
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D2364),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Inspector Trip',
                          style: TextStyle(
                            fontSize: constraints.maxWidth < 600 ? 24 : 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Kindly complete the form with accurate and detailed information.',
                          style: TextStyle(
                            fontSize: constraints.maxWidth < 600 ? 14 : 16,
                            color: Colors.white,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Form Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Inspector Trip Form',
                          style: TextStyle(
                            fontSize: constraints.maxWidth < 600 ? 18 : 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0D2364),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Form fields
                        _buildFormField(
                          'Unit number',
                          unitNumberController,
                          'Enter unit number',
                          textColor: const Color(0xFF0D2364),
                        ),
                        const SizedBox(height: 15),

                        _buildFormField(
                          'Name of Driver',
                          driverNameController,
                          'Enter driver name',
                          textColor: const Color(0xFF0D2364),
                        ),
                        const SizedBox(height: 15),

                        _buildFormField(
                          'Name of Conductor',
                          conductorNameController,
                          'Enter conductor name',
                          textColor: const Color(0xFF0D2364),
                        ),
                        const SizedBox(height: 15),

                        _buildTimePickerField(
                          'Ticket inspection time',
                          inspectionTimeController,
                          textColor: const Color(0xFF0D2364),
                        ),
                        const SizedBox(height: 15),

                        _buildFormField(
                          'No. of Pass',
                          noOfPassController,
                          'Enter number of passengers',
                          textColor: const Color(0xFF0D2364),
                        ),
                        const SizedBox(height: 15),

                        _buildFormField(
                          'Location',
                          locationController,
                          'Enter location',
                          textColor: Colors.black,
                        ),
                        const SizedBox(height: 15),

                        _buildFormField(
                          'No. of Trips',
                          noOfTripsController,
                          'Enter number of trips',
                          textColor: Colors.black,
                        ),

                        const SizedBox(height: 20),

                        // TICKET INSPECTION REPORT SECTION
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[400]!),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Ticket Inspection Report (Max 4 inspections)',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0D2364),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _addTicketRow,
                                    icon: const Icon(
                                      Icons.add_circle,
                                      color: Color(0xFF0D2364),
                                    ),
                                    tooltip: 'Add Row',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Ticket Table
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey[400]!,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Column(
                                    children: [
                                      // Header Row (20, 15, 10, 5, 2, 1)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0D2364),
                                          border: Border(
                                            bottom: BorderSide(
                                              color: Colors.grey[400]!,
                                            ),
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
                                                    fontSize: 16,
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
                                                    '₱$header',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Data Rows
                                      for (
                                        int rowIndex = 0;
                                        rowIndex < ticketRows.length;
                                        rowIndex++
                                      )
                                        Container(
                                          decoration: BoxDecoration(
                                            border: Border(
                                              bottom:
                                                  rowIndex ==
                                                      ticketRows.length - 1
                                                  ? BorderSide.none
                                                  : BorderSide(
                                                      color: Colors.grey[400]!,
                                                    ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              // Row number
                                              SizedBox(
                                                width: 60,
                                                child: Center(
                                                  child: Text(
                                                    '${rowIndex + 1}',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: const Color(
                                                        0xFF0D2364,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              // Input fields for each denomination
                                              for (
                                                int colIndex = 0;
                                                colIndex < 6;
                                                colIndex++
                                              )
                                                Container(
                                                  width: 80,
                                                  decoration: BoxDecoration(
                                                    border: Border(
                                                      right: BorderSide(
                                                        color:
                                                            Colors.grey[400]!,
                                                      ),
                                                    ),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 12,
                                                        ),
                                                    child: TextField(
                                                      controller:
                                                          ticketRows[rowIndex][colIndex],
                                                      textAlign:
                                                          TextAlign.center,
                                                      keyboardType:
                                                          TextInputType.number,
                                                      decoration:
                                                          const InputDecoration(
                                                            border: InputBorder
                                                                .none,
                                                            contentPadding:
                                                                EdgeInsets.zero,
                                                            isDense: true,
                                                            hintText: '0',
                                                          ),
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.black,
                                                      ),
                                                      onChanged: (value) {
                                                        if (value.isNotEmpty &&
                                                            !RegExp(
                                                              r'^[0-9]*$',
                                                            ).hasMatch(value)) {
                                                          ticketRows[rowIndex][colIndex]
                                                              .text = value
                                                              .replaceAll(
                                                                RegExp(
                                                                  r'[^0-9]',
                                                                ),
                                                                '',
                                                              );
                                                          ticketRows[rowIndex][colIndex]
                                                                  .selection =
                                                              TextSelection.fromPosition(
                                                                TextPosition(
                                                                  offset:
                                                                      ticketRows[rowIndex][colIndex]
                                                                          .text
                                                                          .length,
                                                                ),
                                                              );
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              // Delete button
                                              SizedBox(
                                                width: 60,
                                                child: IconButton(
                                                  onPressed: () =>
                                                      _removeTicketRow(
                                                        rowIndex,
                                                      ),
                                                  icon: Icon(
                                                    Icons.delete_outline,
                                                    color: Colors.red[700],
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
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Buttons Row
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                child: ElevatedButton(
                                  onPressed: _showHistory,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF0D2364),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                  ),
                                  child: const Text(
                                    'History',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.only(left: 8),
                                child: ElevatedButton(
                                  onPressed: _saveAndSubmit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0D2364),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                  ),
                                  child: const Text(
                                    'Save & Submit',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildTimePickerField(
    String label,
    TextEditingController controller, {
    Color textColor = Colors.black,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D2364),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            TimeOfDay? pickedTime = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );
            if (pickedTime != null) {
              controller.text = pickedTime.format(context);
            }
          },
          child: AbsorbPointer(
            child: TextField(
              controller: controller,
              style: TextStyle(color: textColor, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Select time',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[400]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF0D2364)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 15,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormField(
    String label,
    TextEditingController controller,
    String hintText, {
    Color textColor = Colors.black,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D2364),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: onChanged,
          style: TextStyle(color: textColor, fontSize: 16),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF0D2364)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 15,
            ),
          ),
        ),
      ],
    );
  }

  void _showHistory() {
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
                const Text(
                  'Submission History',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D2364),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('inspector_trip')
                        .where(
                          'uid',
                          isEqualTo: FirebaseAuth.instance.currentUser?.uid,
                        )
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'No submission history found',
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
                                Text(
                                  'Unit: ${data['unitNumber'] ?? 'N/A'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text('Driver: ${data['driverName'] ?? 'N/A'}'),
                                Text(
                                  'Conductor: ${data['conductorName'] ?? 'N/A'}',
                                ),
                                Text(
                                  'Time: ${data['inspectionTime'] ?? 'N/A'}',
                                ),
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
                        backgroundColor: const Color(0xFF0D2364),
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
    return '${date.month}/${date.day}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _saveAndSubmit() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not logged in'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (unitNumberController.text.isEmpty ||
        driverNameController.text.isEmpty ||
        conductorNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Convert ticket rows to List<Map<String, dynamic>>
    List<Map<String, dynamic>> ticketSalesData = [];
    for (int i = 0; i < ticketRows.length; i++) {
      Map<String, dynamic> rowData = {
        'row': i + 1,
        '20': ticketRows[i][0].text,
        '15': ticketRows[i][1].text,
        '10': ticketRows[i][2].text,
        '5': ticketRows[i][3].text,
        '2': ticketRows[i][4].text,
        '1': ticketRows[i][5].text,
      };
      ticketSalesData.add(rowData);
    }

    Map<String, dynamic> formData = {
      'unitNumber': unitNumberController.text,
      'driverName': driverNameController.text,
      'conductorName': conductorNameController.text,
      'inspectionTime': inspectionTimeController.text,
      'noOfPass': noOfPassController.text,
      'location': locationController.text,
      'noOfTrips': noOfTripsController.text,
      'ticketSalesData': ticketSalesData,
      'uid': user.uid,
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('inspector_trip')
          .add(formData);

      // Clear form
      unitNumberController.clear();
      driverNameController.clear();
      conductorNameController.clear();
      inspectionTimeController.clear();
      noOfPassController.clear();
      locationController.clear();
      noOfTripsController.clear();

      // Reset ticket rows
      setState(() {
        for (var row in ticketRows) {
          for (var controller in row) {
            controller.dispose();
          }
        }
        ticketRows.clear();
        _addTicketRow();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Form submitted successfully!'),
            backgroundColor: Color(0xFF0D2364),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving form: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
