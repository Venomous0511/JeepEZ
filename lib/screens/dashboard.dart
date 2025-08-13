import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  final Map<String, dynamic> employeeData;

  const DashboardScreen({super.key, required this.employeeData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome, ${employeeData['name'] ?? 'Employee'}',
              style: const TextStyle(fontSize: 24),
            ),
            Text('Employee ID: ${employeeData['employeeId']}'),
            Text('Role: ${employeeData['role']}'),
          ],
        ),
      ),
    );
  }
}
