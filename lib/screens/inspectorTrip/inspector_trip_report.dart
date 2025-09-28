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
  _InspectorTripScreenState createState() => _InspectorTripScreenState();
}

class _InspectorTripScreenState extends State<InspectorTripScreen> {
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
                                      _buildFormField(
                                        'Ticket inspection time',
                                        inspectionTimeController,
                                        'Enter inspection time',
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

                              // Action Buttons - Responsive layout
                              constraints.maxWidth < 600
                                  ? _buildVerticalButtons()
                                  : _buildHorizontalButtons(),
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

  Widget _buildHorizontalButtons() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 50,
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
        ),
        const SizedBox(width: 15),
        Expanded(
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _viewSubmittedForms,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D2364), // BLUE COLOR
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'View submitted form',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalButtons() {
    return Column(
      children: [
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
            child: const Text('Save & Submit', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 50,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _viewSubmittedForms,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D2364), // BLUE COLOR
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'View submitted form',
              style: TextStyle(fontSize: 16),
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
                        // Header Row - WHITE BACKGROUND WITH BLUE TEXT
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

                        // NO.123 Static Row - WHITE BACKGROUND WITH BLUE TEXT
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
                              _buildTableCell('NO.123'),
                              _buildTableCell('NO.123'),
                              _buildTableCell('NO.123'),
                              _buildTableCell('NO.123'),
                              _buildTableCell('NO.123'),
                              _buildTableCell('NO.123'),
                            ],
                          ),
                        ),

                        // Editable Rows - WHITE BACKGROUND WITH BLACK TEXT
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

  Widget _buildTableCell(String text) {
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
              fontSize: 14,
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
            color: Colors.black, // BLACK TEXT for editable cells
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

  void _saveAndSubmit() {
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

    Map<String, String> formData = {
      'Unit Number': unitNumberController.text,
      'Driver Name': driverNameController.text,
      'Conductor Name': conductorNameController.text,
      'Inspection Time': inspectionTimeController.text,
      'No. of Pass': noOfPassController.text,
      'Location': locationController.text,
      'No. of Trips': noOfTripsController.text,
    };

    setState(() {
      submittedForms.add(formData);
    });

    // Clear form
    unitNumberController.clear();
    driverNameController.clear();
    conductorNameController.clear();
    inspectionTimeController.clear();
    noOfPassController.clear();
    locationController.clear();
    noOfTripsController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Form submitted successfully!'),
        backgroundColor: Color(0xFF0D2364),
      ),
    );
  }

  void _viewSubmittedForms() {
    if (submittedForms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No forms submitted yet'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Submitted Forms (${submittedForms.length})',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D2364),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // FIXED: Using Expanded with proper parent constraints
                  Expanded(
                    child: ListView.builder(
                      itemCount: submittedForms.length,
                      itemBuilder: (context, index) {
                        final form = submittedForms[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          color: Colors.grey[50],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Form ${index + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0D2364),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text('Unit: ${form['Unit Number'] ?? 'N/A'}'),
                                Text('Driver: ${form['Driver Name'] ?? 'N/A'}'),
                                Text(
                                  'Conductor: ${form['Conductor Name'] ?? 'N/A'}',
                                ),
                                Text(
                                  'Time: ${form['Inspection Time'] ?? 'N/A'}',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
