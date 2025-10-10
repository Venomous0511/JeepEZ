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

  // Controllers for UNIT NO. ROW
  List<TextEditingController> unitNoControllers = List.generate(
    6,
    (index) => TextEditingController()..text = _getDefaultValue(index),
  );

  static String _getDefaultValue(int index) {
    switch (index) {
      case 0:
        return '20';
      case 1:
        return '15';
      case 2:
        return '10';
      case 3:
        return '5';
      case 4:
        return '2';
      case 5:
        return '1';
      default:
        return '';
    }
  }

  @override
  void dispose() {
    // Dispose all text controllers
    for (var controller in unitNoControllers) {
      controller.dispose();
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

                              // UNIT NO. ROW Section
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[400]!),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.white,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'UNIT NO.',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0D2364),
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // SINGLE ROW table for UNIT NO. (20, 15, 10, 5, 2, 1)
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey[400]!,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Column(
                                        children: [
                                          // Header Row
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
                                                for (
                                                  int i = 0;
                                                  i < unitNoControllers.length;
                                                  i++
                                                )
                                                  Expanded(
                                                    child: Center(
                                                      child: Text(
                                                        unitNoControllers[i]
                                                            .text,
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),

                                          // SINGLE Editable Row
                                          Container(
                                            decoration: BoxDecoration(
                                              border: Border(
                                                bottom: BorderSide(
                                                  color: Colors.grey[400]!,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                for (
                                                  int i = 0;
                                                  i < unitNoControllers.length;
                                                  i++
                                                )
                                                  Expanded(
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        border: Border(
                                                          right:
                                                              i ==
                                                                  unitNoControllers
                                                                          .length -
                                                                      1
                                                              ? BorderSide.none
                                                              : BorderSide(
                                                                  color: Colors
                                                                      .grey[400]!,
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
                                                              unitNoControllers[i],
                                                          textAlign:
                                                              TextAlign.center,
                                                          keyboardType:
                                                              TextInputType
                                                                  .number,
                                                          decoration:
                                                              const InputDecoration(
                                                                border:
                                                                    InputBorder
                                                                        .none,
                                                                contentPadding:
                                                                    EdgeInsets
                                                                        .zero,
                                                                isDense: true,
                                                                hintText: '0',
                                                              ),
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 14,
                                                                color: Colors
                                                                    .black,
                                                              ),
                                                          onChanged: (value) {
                                                            if (value
                                                                    .isNotEmpty &&
                                                                !RegExp(
                                                                  r'^[0-9]*$',
                                                                ).hasMatch(
                                                                  value,
                                                                )) {
                                                              unitNoControllers[i]
                                                                  .text = value
                                                                  .replaceAll(
                                                                    RegExp(
                                                                      r'[^0-9]',
                                                                    ),
                                                                    '',
                                                                  );
                                                              unitNoControllers[i]
                                                                      .selection =
                                                                  TextSelection.fromPosition(
                                                                    TextPosition(
                                                                      offset: unitNoControllers[i]
                                                                          .text
                                                                          .length,
                                                                    ),
                                                                  );
                                                            }
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Buttons Row
                              Row(
                                children: [
                                  // History Button
                                  Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      child: ElevatedButton(
                                        onPressed: _showHistory,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFF0D2364),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
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

                                  // Save & Submit Button
                                  Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      child: ElevatedButton(
                                        onPressed: _saveAndSubmit,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF0D2364,
                                          ),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
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

                // History List
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

    // Convert UNIT NO. row to List<String>
    List<String> unitNoData = [];
    for (var controller in unitNoControllers) {
      unitNoData.add(controller.text);
    }

    Map<String, dynamic> formData = {
      'unitNumber': unitNumberController.text,
      'driverName': driverNameController.text,
      'conductorName': conductorNameController.text,
      'inspectionTime': inspectionTimeController.text,
      'noOfPass': noOfPassController.text,
      'location': locationController.text,
      'noOfTrips': noOfTripsController.text,
      'unitNoData': unitNoData,
      'uid': user.uid,  // ✅ Keep as 'uid'
      'violations': [],  // ✅ Add violations array
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

      for (var controller in unitNoControllers) {
        controller.clear();
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
