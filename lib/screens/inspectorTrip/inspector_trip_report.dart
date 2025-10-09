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

  List<Map<String, String>> submittedForms = [];

  // Controllers for editable table cells
  List<List<TextEditingController>> tableControllers = List.generate(
    5,
    (row) => List.generate(
      6,
      (col) => TextEditingController()..text = _getDefaultValue(row),
    ),
  );

  static String _getDefaultValue(int row) {
    switch (row) {
      case 0:
        return '44';
      case 1:
        return '10';
      case 2:
        return '02';
      case 3:
        return '05';
      case 4:
        return '02';
      default:
        return '';
    }
  }

  @override
  void dispose() {
    // Dispose all text controllers
    for (var row in tableControllers) {
      for (var controller in row) {
        controller.dispose();
      }
    }
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
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
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
                      Expanded(
                        child: Container(
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
                                  fontSize: constraints.maxWidth < 600
                                      ? 18
                                      : 20,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0D2364),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Responsive form fields
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      // Unit Number - BLUE TEXT
                                      _buildFormField(
                                        'Unit number',
                                        unitNumberController,
                                        'Enter unit number',
                                        textColor: const Color(0xFF0D2364),
                                      ),
                                      const SizedBox(height: 15),

                                      // Driver Name - BLUE TEXT
                                      _buildFormField(
                                        'Name of Driver',
                                        driverNameController,
                                        'Enter driver name',
                                        textColor: const Color(0xFF0D2364),
                                      ),
                                      const SizedBox(height: 15),

                                      // Conductor Name - BLUE TEXT
                                      _buildFormField(
                                        'Name of Conductor',
                                        conductorNameController,
                                        'Enter conductor name',
                                        textColor: const Color(0xFF0D2364),
                                      ),
                                      const SizedBox(height: 15),

                                      // Inspection Time - BLUE TEXT
                                      _buildTimePickerField(
                                        'Ticket inspection time',
                                        inspectionTimeController,
                                        textColor: const Color(0xFF0D2364),
                                      ),
                                      const SizedBox(height: 15),

                                      // No. of Pass - BLUE TEXT
                                      _buildFormField(
                                        'No. of Pass',
                                        noOfPassController,
                                        'Enter number of passengers',
                                        textColor: const Color(0xFF0D2364),
                                      ),
                                      const SizedBox(height: 15),

                                      // Location - BLACK TEXT (Start of black text)
                                      _buildFormField(
                                        'Location',
                                        locationController,
                                        'Enter location',
                                        textColor: Colors.black,
                                      ),
                                      const SizedBox(height: 15),

                                      // No. of Trips - BLACK TEXT
                                      _buildFormField(
                                        'No. of Trips',
                                        noOfTripsController,
                                        'Enter number of trips',
                                        textColor: Colors.black,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Ticket Log Button - Responsive
                              Center(
                                child: SizedBox(
                                  width: constraints.maxWidth < 600 ? 150 : 200,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      _showTicketLogDialog();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0D2364),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      'Ticket log',
                                      style: TextStyle(
                                        fontSize: constraints.maxWidth < 600
                                            ? 16
                                            : 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Single Save & Submit Button
                              SizedBox(
                                height: 50,
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _saveAndSubmit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0D2364),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Save & Submit',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
              // Format to 12-hour or 24-hour string
              final formattedTime = pickedTime.format(context);
              controller.text = formattedTime;
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
        Container(
          constraints: const BoxConstraints(minHeight: 50),
          child: TextField(
            controller: controller,
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
        ),
      ],
    );
  }

  void _showTicketLogDialog() {
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Ticket Log',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D2364),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // UPDATED TABLE DESIGN - Matching the image
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!, width: 1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      children: [
                        // Header Row
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey[400]!,
                              width: 1,
                            ),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              _buildTableHeaderCell('20'),
                              _buildTableHeaderCell('15'),
                              _buildTableHeaderCell('10'),
                              _buildTableHeaderCell('5'),
                              _buildTableHeaderCell('2'),
                              _buildTableHeaderCell('1'),
                            ],
                          ),
                        ),

                        // Editable Rows
                        for (int row = 0; row < 5; row++)
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey[400]!,
                                width: 1,
                              ),
                              color: Colors.white,
                            ),
                            child: Row(
                              children: [
                                for (int col = 0; col < 6; col++)
                                  _buildEditableTableCell(row, col),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),
                  const Divider(),
                  const SizedBox(height: 15),

                  Center(
                    child: SizedBox(
                      width: 120,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
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
          ),
        );
      },
    );
  }

  // UPDATED: Helper methods for table cells - Matching image design
  Widget _buildTableHeaderCell(String text) {
    return Expanded(
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: Colors.grey[400]!, width: 1)),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D2364), // BLUE TEXT
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditableTableCell(int row, int col) {
    return Expanded(
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: Colors.grey[400]!, width: 1)),
        ),
        child: TextField(
          controller: tableControllers[row][col],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true,
            hintText: '0',
          ),
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black,
          ),
          onChanged: (value) {
            if (value.isNotEmpty && !RegExp(r'^[0-9]*$').hasMatch(value)) {
              tableControllers[row][col].text = value.replaceAll(
                RegExp(r'[^0-9]'),
                '',
              );
              tableControllers[row][col].selection = TextSelection.fromPosition(
                TextPosition(offset: tableControllers[row][col].text.length),
              );
            }
          },
        ),
      ),
    );
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

    // Convert ticket log table to List<Map<String, String>>
    List<Map<String, String>> ticketLogData = [];
    for (int row = 0; row < tableControllers.length; row++) {
      Map<String, String> rowData = {};
      for (int col = 0; col < tableControllers[row].length; col++) {
        rowData['col$col'] = tableControllers[row][col].text;
      }
      ticketLogData.add(rowData);
    }

    Map<String, dynamic> formData = {
      'unitNumber': unitNumberController.text,
      'driverName': driverNameController.text,
      'conductorName': conductorNameController.text,
      'inspectionTime': inspectionTimeController.text,
      'noOfPass': noOfPassController.text,
      'location': locationController.text,
      'noOfTrips': noOfTripsController.text,
      'ticketLog': ticketLogData,
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

      for (var row in tableControllers) {
        for (var cell in row) {
          cell.clear();
        }
      }

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
