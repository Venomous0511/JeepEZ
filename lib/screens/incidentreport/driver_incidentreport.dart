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
      appBar: AppBar(title: const Text('Incident Report')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text("Type of Incident"),
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Vehicle breakdown',
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              const Text("Location of Incident"),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  hintText: 'e.g. EDSA corner Ortigas',
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              const Text("Person/s Involved"),
              TextFormField(
                controller: _personsController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Driver, Passenger',
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              const Text("DESCRIPTION OF INCIDENT"),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Describe what happened...',
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Save & Submit Form'),
              ),
              const SizedBox(height: 16),

              TextButton(
                onPressed: () {},
                child: const Text('View Submitted Form'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
