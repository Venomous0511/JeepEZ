import 'package:flutter/material.dart';

class UserForm extends StatefulWidget {
  final Function(String email, String password, String role) onSubmit;

  const UserForm({super.key, required this.onSubmit});

  @override
  State<UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = 'driver';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          decoration: InputDecoration(labelText: 'Email'),
        ),
        TextField(
          controller: _passwordController,
          decoration: InputDecoration(labelText: 'Password'),
        ),
        DropdownButton<String>(
          value: _role,
          items: [
            "super_admin",
            "admin",
            "driver",
            "conductor",
            "inspector",
          ].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
          onChanged: (v) => setState(() => _role = v!),
        ),
        ElevatedButton(
          onPressed: () => widget.onSubmit(
            _emailController.text,
            _passwordController.text,
            _role,
          ),
          child: const Text('Create User'),
        ),
      ],
    );
  }
}
