import 'package:flutter/material.dart';
import 'screens/login.dart';

void main() {
  runApp(const JeepEZApp());
}

class JeepEZApp extends StatelessWidget {
  const JeepEZApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JeepEZ',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginScreen(),
    );
  }
}
