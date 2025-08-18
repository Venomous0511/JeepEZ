import 'package:flutter/material.dart';
import '../../models/app_user.dart';

class ConductorDashboard extends StatelessWidget {
  final AppUser user;
  const ConductorDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Conductor Dashboard")),
      body: Center(child: Text("Welcome, ${user.email}\nRole: ${user.role}")),
    );
  }
}
