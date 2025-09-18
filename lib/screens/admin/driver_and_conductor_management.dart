import 'package:flutter/material.dart';

class DriverAndConductorManagementScreen extends StatelessWidget {
  const DriverAndConductorManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver & Conductor Management'),
        backgroundColor: const Color(0xFF0D2364),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Driver and Conductor Management',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
