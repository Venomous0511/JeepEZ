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
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _personsController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Focus nodes to track field focus
  final FocusNode _typeFocusNode = FocusNode();
  final FocusNode _locationFocusNode = FocusNode();
  final FocusNode _personsFocusNode = FocusNode();
  final FocusNode _descriptionFocusNode = FocusNode();

  String? _vehicleId; // store assigned vehicle ID
  Map<String, dynamic>? _vehicleData; // optional: store vehicle details

  @override
  void initState() {
    super.initState();
    _fetchAssignedVehicle(); // fetch vehicle when screen opens
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
      final assignedVehicleId = userData['assignedVehicle']?.toString();

      Map<String, dynamic>? vehicleData;
      if (assignedVehicleId != null) {
        final vehicleDoc = await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(assignedVehicleId)
            .get();
        if (vehicleDoc.exists) {
          vehicleData = vehicleDoc.data();
        }
      }

      setState(() {
        _vehicleId = assignedVehicleId;
        _vehicleData = vehicleData;
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
      await FirebaseFirestore.instance.collection('incident_report').add({
        'type': _typeController.text.trim(),
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

      _typeController.clear();
      _locationController.clear();
      _personsController.clear();
      _descriptionController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error submitting report: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: const Color(0xFF0D2364)),
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
                        _buildFormField(
                          label: "Type of Incident",
                          hintText: "e.g. Road Crash",
                          controller: _typeController,
                          focusNode: _typeFocusNode,
                          isRequired: true,
                        ),
                        const SizedBox(height: 20),
                        _buildFormField(
                          label: "Location of Incident",
                          hintText: "e.g. Road + Landmark/Intersection",
                          controller: _locationController,
                          focusNode: _locationFocusNode,
                          isRequired: true,
                        ),
                        const SizedBox(height: 20),
                        _buildFormField(
                          label: "Person/s Involved",
                          hintText: "e.g. Driver, Conductor, or Passenger",
                          controller: _personsController,
                          focusNode: _personsFocusNode,
                          isRequired: true,
                        ),
                        const SizedBox(height: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "DESCRIPTION OF INCIDENT",
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
                                validator: (value) =>
                                    value!.isEmpty ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D2364),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: const Text(
                              'Save & Submit Form',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            style: TextStyle(color: Colors.grey.shade700),
            decoration: InputDecoration(
              hintText: controller.text.isEmpty && !focusNode.hasFocus
                  ? hintText
                  : null,
              hintStyle: TextStyle(color: Colors.grey.shade500),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12.0),
            ),
            validator: isRequired
                ? (value) => value!.isEmpty ? 'Required' : null
                : null,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _typeController.dispose();
    _locationController.dispose();
    _personsController.dispose();
    _descriptionController.dispose();
    _typeFocusNode.dispose();
    _locationFocusNode.dispose();
    _personsFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }
}
