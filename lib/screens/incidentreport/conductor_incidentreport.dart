import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class IncidentReportScreen extends StatefulWidget {
  const IncidentReportScreen({super.key});

  @override
  State<IncidentReportScreen> createState() => _IncidentReportScreenState();
}

class _IncidentReportScreenState extends State<IncidentReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _personsController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _otherTypeController = TextEditingController();

  // Focus nodes to track field focus
  final FocusNode _locationFocusNode = FocusNode();
  final FocusNode _personsFocusNode = FocusNode();
  final FocusNode _descriptionFocusNode = FocusNode();
  final FocusNode _otherTypeFocusNode = FocusNode();

  String? _vehicleId; // store assigned vehicle ID
  String? _selectedAccidentType; // store selected accident type

  // List of accident types for dropdown
  final List<String> _accidentTypes = [
    'Brake failure or loss of braking power',
    'Traffic obstruction due to stalled jeepney',
    'Overheating engine during stop-and-go traffic',
    'Flat tire / tire blowout',
    'Accident due to slippery or flooded roads',
    'Other/s',
  ];

  @override
  void initState() {
    super.initState();
    _fetchAssignedVehicle(); // fetch vehicle when screen opens

    // Add listeners to update character count
    _locationController.addListener(() => setState(() {}));
    _personsController.addListener(() => setState(() {}));
    _otherTypeController.addListener(() => setState(() {}));
  }

  Future<void> _fetchAssignedVehicle() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      final assignedVehicleId =
          userData['assignedVehicle']?.toString() ?? 'N/A';
      setState(() {
        _vehicleId = assignedVehicleId;
      });
    } catch (e) {
      debugPrint('Error fetching assigned vehicle: $e');
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final employeeId = _personsController.text.trim();
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to submit a report.'),
        ),
      );
      return;
    }

    try {
      // Determine the final type value
      String finalType;
      if (_selectedAccidentType == 'Other/s' &&
          _otherTypeController.text.isNotEmpty) {
        finalType = _otherTypeController.text.trim();
      } else {
        finalType = _selectedAccidentType ?? '';
      }

      await FirebaseFirestore.instance.collection('incident_report').add({
        'type': finalType,
        'location': _locationController.text.trim(),
        'persons': employeeId,
        'description': _descriptionController.text.trim(),
        'assignedVehicleId': _vehicleId ?? 'Not Assigned',
        'createdBy': currentUser.email,
        'createdById': currentUser.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incident report submitted successfully!'),
          ),
        );
      }

      // Reset form
      _resetForm();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error submitting report: $e')));
      }
    }
  }

  void _resetForm() {
    setState(() {
      _selectedAccidentType = null;
    });
    _locationController.clear();
    _personsController.clear();
    _descriptionController.clear();
    _otherTypeController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D2364),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: const Text(
                  "Incident Report Form",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withAlpha(3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: Colors.grey.shade300, width: 1.0),
                  ),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        // Type of Accident Dropdown
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Type of Accident *",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey.shade400,
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: DropdownButtonFormField<String>(
                                value: _selectedAccidentType,
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedAccidentType = newValue;
                                    if (newValue != 'Other/s') {
                                      _otherTypeController.clear();
                                    }
                                  });
                                },
                                items: _accidentTypes
                                    .map<DropdownMenuItem<String>>((
                                      String value,
                                    ) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(
                                          value,
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontSize: 14,
                                          ),
                                        ),
                                      );
                                    })
                                    .toList(),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                    vertical: 16.0,
                                  ),
                                  isDense: true,
                                ),
                                validator: (value) => value == null
                                    ? 'Please select accident type'
                                    : null,
                                isExpanded: true,
                                hint: Text(
                                  'Select type of accident...',
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Other Type Text Field (appears only when "Other/s" is selected)
                        if (_selectedAccidentType == 'Other/s') ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Specify Other Accident Type *",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade400,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    TextFormField(
                                      controller: _otherTypeController,
                                      focusNode: _otherTypeFocusNode,
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                      ),
                                      maxLength: 100,
                                      decoration: InputDecoration(
                                        hintText:
                                            'Please specify the accident type...',
                                        hintStyle: TextStyle(
                                          color: Colors.grey.shade500,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.all(
                                          12.0,
                                        ),
                                      ),
                                      validator: (value) => value!.isEmpty
                                          ? 'Please specify accident type'
                                          : null,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        right: 12.0,
                                        bottom: 8.0,
                                      ),
                                      child: Text(
                                        '${_otherTypeController.text.length}/100',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              _otherTypeController.text.length >
                                                  100
                                              ? Colors.red
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],

                        _buildFormField(
                          label: "Location of Incident *",
                          hintText: "e.g. Road + Landmark/Intersection",
                          controller: _locationController,
                          focusNode: _locationFocusNode,
                          isRequired: true,
                          maxLength: 100,
                          currentLength: _locationController.text.length,
                        ),
                        const SizedBox(height: 20),
                        _buildFormField(
                          label: "Person/s Involved *",
                          hintText: "e.g. Driver, Conductor, or Passenger",
                          controller: _personsController,
                          focusNode: _personsFocusNode,
                          isRequired: true,
                          maxLength: 100,
                          currentLength: _personsController.text.length,
                        ),
                        const SizedBox(height: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "DESCRIPTION OF INCIDENT *",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey.shade400,
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: TextFormField(
                                controller: _descriptionController,
                                focusNode: _descriptionFocusNode,
                                maxLines: 5,
                                style: TextStyle(color: Colors.grey.shade700),
                                decoration: InputDecoration(
                                  hintText:
                                      _descriptionController.text.isEmpty &&
                                          !_descriptionFocusNode.hasFocus
                                      ? 'Describe what happened...'
                                      : null,
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade500,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.all(12.0),
                                ),
                                validator: (value) => value!.isEmpty
                                    ? 'Please describe the incident'
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _vehicleId == 'N/A' || _vehicleId == null
                                ? null
                                : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _vehicleId == 'N/A' || _vehicleId == null
                                  ? Colors.grey
                                  : const Color(0xFF0D2364),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: Text(
                              _vehicleId == 'N/A' || _vehicleId == null
                                  ? 'No Vehicle Assigned'
                                  : 'Save & Submit Form',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        if (_vehicleId == 'N/A' || _vehicleId == null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              '⚠️ No vehicle assigned. Please contact admin to submit incident reports.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.red[700],
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isRequired,
    required int maxLength,
    required int currentLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400, width: 1.0),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextFormField(
                controller: controller,
                focusNode: focusNode,
                style: TextStyle(color: Colors.grey.shade700),
                maxLength: maxLength,
                buildCounter:
                    (
                      BuildContext context, {
                      int? currentLength,
                      int? maxLength,
                      bool? isFocused,
                    }) => null, // Hide default counter
                decoration: InputDecoration(
                  hintText: controller.text.isEmpty && !focusNode.hasFocus
                      ? hintText
                      : null,
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(12.0),
                ),
                validator: isRequired
                    ? (value) =>
                          value!.isEmpty ? 'This field is required' : null
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12.0, bottom: 8.0),
                child: Text(
                  '$currentLength/$maxLength',
                  style: TextStyle(
                    fontSize: 12,
                    color: currentLength > maxLength
                        ? Colors.red
                        : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _locationController.dispose();
    _personsController.dispose();
    _descriptionController.dispose();
    _otherTypeController.dispose();
    _locationFocusNode.dispose();
    _personsFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _otherTypeFocusNode.dispose();
    super.dispose();
  }
}
