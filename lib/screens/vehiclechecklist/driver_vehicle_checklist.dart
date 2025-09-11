import 'package:flutter/material.dart';

class VehicleChecklistScreen extends StatefulWidget {
  const VehicleChecklistScreen({super.key});

  @override
  State<VehicleChecklistScreen> createState() => _VehicleChecklistScreenState();
}

class _VehicleChecklistScreenState extends State<VehicleChecklistScreen> {
  final List<ChecklistItem> _checklistItems = [
    ChecklistItem(title: 'Tires and Wheels', checked: false),
    ChecklistItem(title: 'Lights and Signals', checked: false),
    ChecklistItem(title: 'Brakes', checked: false),
    ChecklistItem(title: 'Engine and Fluids', checked: false),
    ChecklistItem(title: 'Steering Mechanism', checked: false),
    ChecklistItem(title: 'Emergency Equipment', checked: false),
    ChecklistItem(title: 'Mirrors and Windows', checked: false),
    ChecklistItem(title: 'Vehicle Body', checked: false),
  ];

  final TextEditingController _defectsController = TextEditingController();

  void _submitForm() {
    int checkedCount = _checklistItems.where((item) => item.checked).length;

    if (checkedCount == _checklistItems.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checklist completed successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_checklistItems.length - checkedCount} items remaining',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vehicle Checklist')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pre-Trip Inspection',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Kindly perform the Pre-Trip Inspection to ensure the vehicle is safe to use.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),

            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: const Border(
                        bottom: BorderSide(color: Colors.grey),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(
                            'Inspection Item',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Status',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ..._checklistItems.map((item) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(flex: 4, child: Text(item.title)),
                          Expanded(
                            flex: 1,
                            child: Checkbox(
                              value: item.checked,
                              onChanged: (bool? value) {
                                setState(() {
                                  item.checked = value ?? false;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Any Defects:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _defectsController,
              maxLines: 3,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                hintText: 'Describe any defects found during inspection...',
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF0D47A1),
                ),
                child: const Text(
                  'Save & Submit',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Center(
              child: TextButton(
                onPressed: () {},
                child: const Text(
                  'View submitted form',
                  style: TextStyle(decoration: TextDecoration.underline),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChecklistItem {
  String title;
  bool checked;

  ChecklistItem({required this.title, required this.checked});
}
