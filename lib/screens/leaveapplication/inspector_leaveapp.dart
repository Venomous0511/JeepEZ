import 'package:flutter/material.dart';

class LeaveApplicationScreen extends StatefulWidget {
  const LeaveApplicationScreen({super.key});

  @override
  State<LeaveApplicationScreen> createState() => _LeaveApplicationScreenState();
}

class _LeaveApplicationScreenState extends State<LeaveApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedLeaveType;
  final TextEditingController _daysController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  DateTime _startDate = DateTime(2025, 10, 11);
  DateTime _endDate = DateTime(2025, 10, 13);

  final List<String> _leaveTypes = [
    'Sick leave',
    'Vacation leave',
    'Emergency leave',
    'Maternity leave',
    'Paternity leave',
    'Bereavement leave',
  ];

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Leave application submitted!')),
      );
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime(2026),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        final difference = _endDate.difference(_startDate).inDays + 1;
        _daysController.text = difference.toString();
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Application'),
        backgroundColor: const Color(0xFF0D47A1),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Leave Application Form',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ready if I can file form with automatic details. Once',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),

              const Text(
                'Type of Leave',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedLeaveType,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: _leaveTypes.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedLeaveType = newValue;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select leave type' : null,
              ),
              const SizedBox(height: 16),

              const Text(
                'Number of Calendar Days',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _daysController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter number of days',
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              const Text(
                'Reason for requesting leave:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter reason for leave',
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              // Divider
              const Divider(thickness: 1, color: Colors.grey),
              const SizedBox(height: 20),

              const Text(
                'Leave Application Form',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text(
                    'Date Requested:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text(_formatDate(DateTime.now())),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  const Text(
                    'Type of Leave:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text(_selectedLeaveType ?? ''),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  const Text(
                    'Number of Calendar Days:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _daysController.text.isEmpty ? '' : _daysController.text,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _selectDateRange(context),
                  child: const Text('Request Leave'),
                ),
              ),
              const SizedBox(height: 8),

              Center(
                child: Text(
                  '${_formatDate(_startDate)}-${_formatDate(_endDate)}',

                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Reason for requesting leave:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _reasonController.text.isEmpty
                    ? 'No reason provided'
                    : _reasonController.text,
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Submit Leave Application',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Center(
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    'View submitted form',
                    style: TextStyle(
                      color: Color(0xFF0D47A1),
                      decoration: TextDecoration.underline,
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
}
