import 'package:flutter/material.dart';
import 'leaveapplication.dart'; // Import the form page

void main() => runApp(const LeaveApplicationApp());

class LeaveApplicationApp extends StatelessWidget {
  const LeaveApplicationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Leave Application',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const LeaveApplicationPage(),
    );
  }
}
