import 'package:flutter/material.dart';
import '../../models/app_user.dart';

class DriverDashboard extends StatelessWidget {
  final AppUser user;
  const DriverDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Driver Dashboard")),
      body: Center(child: Text("Welcome, ${user.email}\nRole: ${user.role}")),
    );
  }
}
