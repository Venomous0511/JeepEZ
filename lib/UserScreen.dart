import 'package:flutter/material.dart';
import 'services/api_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MongoDB Flutter Demo',
      home: Scaffold(
        appBar: AppBar(title: const Text('Users')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  addUser("John Doe", "john@example.com");
                },
                child: const Text("Add User"),
              ),
              ElevatedButton(
                onPressed: () {
                  fetchUsers();
                },
                child: const Text("Fetch Users"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
