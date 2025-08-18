import 'package:flutter/material.dart';

class EmployeeForm extends StatefulWidget {
  final Function(String name, String phone) onSubmit;

  const EmployeeForm({super.key, required this.onSubmit});

  @override
  State<EmployeeForm> createState() => _EmployeeFormState();
}

class _EmployeeFormState extends State<EmployeeForm> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _nameController,
          decoration: InputDecoration(labelText: 'Name'),
        ),
        TextField(
          controller: _phoneController,
          decoration: InputDecoration(labelText: 'Phone'),
        ),
        ElevatedButton(
          onPressed: () =>
              widget.onSubmit(_nameController.text, _phoneController.text),
          child: const Text('Save Employee'),
        ),
      ],
    );
  }
}
