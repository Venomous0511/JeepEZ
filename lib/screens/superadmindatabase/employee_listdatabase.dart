import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../SuperAdminScreen/employee_list.dart'; // Your existing screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Employee Management',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const EmployeeListScreen(),
    );
  }
}
