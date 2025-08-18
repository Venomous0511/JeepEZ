import 'package:flutter/material.dart';
import '../../models/app_user.dart';

class InspectorDashboard extends StatelessWidget {
  final AppUser user;
  const InspectorDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Inspector Dashboard")),
      body: Center(child: Text("Welcome, ${user.email}\nRole: ${user.role}")),
    );
  }
}
