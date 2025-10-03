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

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incident report submitted!')),
      );
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
              // Header Container
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

              // Form Container
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
                        // Type of Incident
                        _buildFormField(
                          label: "Type of Incident",
                          hintText: "e.g. Street/Road",
                          controller: _typeController,
                          focusNode: _typeFocusNode,
                          isRequired: true,
                        ),
                        const SizedBox(height: 20),

                        // Location of Incident
                        _buildFormField(
                          label: "Location of Incident",
                          hintText: "e.g. Road + Landmark/Intersection",
                          controller: _locationController,
                          focusNode: _locationFocusNode,
                          isRequired: true,
                        ),
                        const SizedBox(height: 20),

                        // Person/s Involved
                        _buildFormField(
                          label: "Person/s Involved",
                          hintText: "e.g. Driver, conductor and passenger",
                          controller: _personsController,
                          focusNode: _personsFocusNode,
                          isRequired: true,
                        ),
                        const SizedBox(height: 20),

                        // DESCRIPTION OF INCIDENT
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

                        // Save & Submit Button
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
                        const SizedBox(height: 16),
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
