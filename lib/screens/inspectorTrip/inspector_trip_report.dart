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
  String? selectedUnitNumber;
  String? selectedDriverName;
  String? selectedConductorName;
  final TextEditingController inspectionTimeController =
      TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController noOfPassController = TextEditingController();
  final TextEditingController noOfTripsController = TextEditingController();

  // Add new lists for dropdown data
  List<Map<String, dynamic>> availableVehicles = [];
  List<Map<String, dynamic>> todayDrivers = [];
  List<Map<String, dynamic>> todayConductors = [];

  bool isLoadingData = false;

  String _getTodayDayName() {
    final now = DateTime.now();
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[now.weekday - 1];
  }

  // Single row of ticket data
  late List<TextEditingController> ticketRow;

  // Ticket denominations (header)
  final List<String> ticketHeaders = ['20', '15', '10', '5', '2', '1'];

  @override
  void initState() {
    super.initState();
    ticketRow = List.generate(6, (index) => TextEditingController(text: '0'));
    _loadDropdownData();
  }

  Future<void> _loadDropdownData() async {
    setState(() => isLoadingData = true);

    try {
      final today = _getTodayDayName();

      // Get all vehicles
      final vehiclesSnapshot = await FirebaseFirestore.instance
          .collection('vehicles')
          .get();

      availableVehicles = vehiclesSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'vehicleId': doc.id,
          'data': data,
        };
      }).toList();

      // Get drivers scheduled for today
      final driversSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'driver')
          .where('status', isEqualTo: true)
          .get();

      todayDrivers = driversSnapshot.docs.where((doc) {
        final schedule = doc.data()['schedule'] as String?;
        return schedule != null && schedule.contains(today);
      }).map((doc) {
        return {
          'uid': doc.id,
          'name': doc.data()['name'] ?? 'Unknown',
          'data': doc.data(),
        };
      }).toList();

      // Get conductors scheduled for today
      final conductorsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'conductor')
          .where('status', isEqualTo: true)
          .get();

      todayConductors = conductorsSnapshot.docs.where((doc) {
        final schedule = doc.data()['schedule'] as String?;
        return schedule != null && schedule.contains(today);
      }).map((doc) {
        return {
          'uid': doc.id,
          'name': doc.data()['name'] ?? 'Unknown',
          'data': doc.data(),
        };
      }).toList();

    } catch (e) {
      print('Error loading dropdown data: $e');
    } finally {
      setState(() => isLoadingData = false);
    }
  }

  @override
  void dispose() {
    for (var controller in ticketRow) {
      controller.dispose();
    }
    inspectionTimeController.dispose();
    locationController.dispose();
    noOfPassController.dispose();
    noOfTripsController.dispose();
    super.dispose();
  }

  // Validation functions
  String? _validateUnitNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Unit number is required';
    }
    if (!RegExp(r'^[0-9]*$').hasMatch(value)) {
      return 'Only numbers are allowed';
    }
    if (value.length > 36) {
      return 'Maximum 36 numbers only';
    }
    return null;
  }

  String? _validateName(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    if (!RegExp(r'^[a-zA-Z\s]*$').hasMatch(value)) {
      return 'Only letters and spaces are allowed';
    }
    if (value.length > 36) {
      return 'Maximum 36 letters only';
    }
    return null;
  }

  String? _validateNumber(
    String? value,
    String fieldName, {
    int maxLength = 10,
  }) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    if (!RegExp(r'^[0-9]*$').hasMatch(value)) {
      return 'Only numbers are allowed';
    }
    if (value.length > maxLength) {
      return 'Maximum $maxLength numbers only';
    }
    return null;
  }

  String? _validateLocation(String? value) {
    if (value == null || value.isEmpty) {
      return 'Location is required';
    }
    if (!RegExp(r'^[a-zA-Z\s]*$').hasMatch(value)) {
      return 'Only letters and spaces are allowed';
    }
    if (value.length > 36) {
      return 'Maximum 36 letters only';
    }
    return null;
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
                        _buildDropdownField(
                          'Unit number',
                          selectedUnitNumber,
                          availableVehicles.map((v) => v['vehicleId'] as String).toList(),
                              (value) {
                            setState(() {
                              selectedUnitNumber = value;
                            });
                          },
                          'Select unit number',
                        ),
                        const SizedBox(height: 15),

                        _buildDropdownField(
                          'Name of Driver',
                          selectedDriverName,
                          todayDrivers.map((d) => d['name'] as String).toList(),
                              (value) {
                            setState(() {
                              selectedDriverName = value;
                            });
                          },
                          'Select driver',
                        ),
                        const SizedBox(height: 15),

                        _buildDropdownField(
                          'Name of Conductor',
                          selectedConductorName,
                          todayConductors.map((c) => c['name'] as String).toList(),
                              (value) {
                            setState(() {
                              selectedConductorName = value;
                            });
                          },
                          'Select conductor',
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
                          validator: (value) =>
                              _validateNumber(value, 'Number of passengers'),
                          keyboardType: TextInputType.number,
                          maxLength: 10,
                        ),
                        const SizedBox(height: 15),

                        _buildFormField(
                          'Location',
                          locationController,
                          'Enter location',
                          textColor: Colors.black,
                          validator: _validateLocation,
                          keyboardType: TextInputType.text,
                          maxLength: 36,
                        ),
                        const SizedBox(height: 15),

                        _buildFormField(
                          'No. of Trips',
                          noOfTripsController,
                          'Enter number of trips',
                          textColor: Colors.black,
                          validator: (value) =>
                              _validateNumber(value, 'Number of trips'),
                          keyboardType: TextInputType.number,
                          maxLength: 10,
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
                              Text(
                                'Ticket Inspection Report',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D2364),
                                ),
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
                                            for (String header in ticketHeaders)
                                              SizedBox(
                                                width: 80,
                                                child: Center(
                                                  child: Text(
                                                    header,
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

                                      // Single Data Row
                                      Row(
                                        children: [
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
                                                    color: Colors.grey[400]!,
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
                                                      ticketRow[colIndex],
                                                  textAlign: TextAlign.center,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  maxLength: 10,
                                                  onTap: () {
                                                    if (ticketRow[colIndex].text == '0') {
                                                      ticketRow[colIndex].clear();
                                                    }
                                                  },
                                                  decoration:
                                                      const InputDecoration(
                                                        border:
                                                            InputBorder.none,
                                                        contentPadding:
                                                            EdgeInsets.zero,
                                                        isDense: true,
                                                        hintText: '0',
                                                        counterText: '',
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
                                                      ticketRow[colIndex].text =
                                                          value.replaceAll(
                                                            RegExp(r'[^0-9]'),
                                                            '',
                                                          );
                                                      ticketRow[colIndex]
                                                              .selection =
                                                          TextSelection.fromPosition(
                                                            TextPosition(
                                                              offset:
                                                                  ticketRow[colIndex]
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

  Widget _buildDropdownField(
      String label,
      String? value,
      List<String> items,
      Function(String?) onChanged,
      String hint,
      ) {
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
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: hint,
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
          items: items.isEmpty
              ? null
              : items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
          }).toList(),
          onChanged: items.isEmpty ? null : onChanged,
          hint: items.isEmpty
              ? Text(
            'No options available for today',
            style: TextStyle(color: Colors.grey[600]),
            overflow: TextOverflow.ellipsis,
          )
              : null,
        ),
      ],
    );
  }

  Widget _buildFormField(
    String label,
    TextEditingController controller,
    String hintText, {
    Color textColor = Colors.black,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
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
        TextFormField(
          controller: controller,
          style: TextStyle(color: textColor, fontSize: 16),
          keyboardType: keyboardType,
          maxLength: maxLength,
          validator: validator,
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
            counterText: '',
          ),
          onChanged: (value) {
            // Real-time validation and filtering
            if (keyboardType == TextInputType.number) {
              // Filter out non-numeric characters
              if (value.isNotEmpty && !RegExp(r'^[0-9]*$').hasMatch(value)) {
                final filteredValue = value.replaceAll(RegExp(r'[^0-9]'), '');
                controller.value = controller.value.copyWith(
                  text: filteredValue,
                  selection: TextSelection.collapsed(
                    offset: filteredValue.length,
                  ),
                );
              }
            } else if (label.contains('Driver') ||
                label.contains('Conductor') ||
                label.contains('Location')) {
              // Filter out numbers and allow only letters and spaces
              if (value.isNotEmpty &&
                  !RegExp(r'^[a-zA-Z\s]*$').hasMatch(value)) {
                final filteredValue = value.replaceAll(
                  RegExp(r'[^a-zA-Z\s]'),
                  '',
                );
                controller.value = controller.value.copyWith(
                  text: filteredValue,
                  selection: TextSelection.collapsed(
                    offset: filteredValue.length,
                  ),
                );
              }
            }
          },
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

    // Validate all fields
    final noOfPassError = _validateNumber(
      noOfPassController.text,
      'Number of passengers',
    );
    final locationError = _validateLocation(locationController.text);
    final noOfTripsError = _validateNumber(
      noOfTripsController.text,
      'Number of trips',
    );

    if (noOfPassError != null ||
        locationError != null ||
        noOfTripsError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix all validation errors before submitting'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedUnitNumber == null || selectedUnitNumber!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a unit number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedDriverName == null || selectedDriverName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a driver'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedConductorName == null || selectedConductorName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a conductor'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Convert ticket row to Map<String, dynamic>
    Map<String, dynamic> ticketInspectionData = {
      'row': 1,
      '20': ticketRow[0].text,
      '15': ticketRow[1].text,
      '10': ticketRow[2].text,
      '5': ticketRow[3].text,
      '2': ticketRow[4].text,
      '1': ticketRow[5].text,
    };

    Map<String, dynamic> formData = {
      'unitNumber': selectedUnitNumber,
      'driverName': selectedDriverName,
      'conductorName': selectedConductorName,
      'inspectionTime': inspectionTimeController.text,
      'noOfPass': noOfPassController.text,
      'location': locationController.text,
      'noOfTrips': noOfTripsController.text,
      'ticketInspection': ticketInspectionData,
      'uid': user.uid,
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('inspector_trip')
          .add(formData);

      // Clear form
      inspectionTimeController.clear();
      noOfPassController.clear();
      locationController.clear();
      noOfTripsController.clear();

      // Reset ticket row
      setState(() {
        selectedUnitNumber = null;
        selectedDriverName = null;
        selectedConductorName = null;
        for (var controller in ticketRow) {
          controller.text = '0';
        }
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
