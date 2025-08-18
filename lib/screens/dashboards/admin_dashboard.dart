import 'package:flutter/material.dart';
import '../../models/app_user.dart';

class AdminDashboard extends StatelessWidget {
  final AppUser user;
  const AdminDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Dashboard")),
      body: Center(child: Text("Welcome, ${user.email}\nRole: ${user.role}")),
    );
  }
}
