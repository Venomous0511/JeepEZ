import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AttendanceScreen extends StatelessWidget {
  final VoidCallback onBackPressed;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AttendanceScreen({super.key, required this.onBackPressed});

  /// Fetch attendance data from Firebase Function
  Future<List<Map<String, dynamic>>> fetchAttendance() async {
    final response = await http.get(
      Uri.parse("https://us-central1-jeepez-5c65d.cloudfunctions.net/getAttendance"),
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => {
        "name": e["name"] ?? "",
        "timeIn": e["timeIn"] ?? "",
        "timeOut": e["timeOut"] ?? "",
      }).toList();
    } else {
      throw Exception("Failed to load attendance");
    }
  }

  // Stream for real-time updates from users collection
  Stream<QuerySnapshot> get employeesStream {
    return _firestore
        .collection('users')
        .where('role', whereIn: ['driver', 'conductor']) // ✅ fixed
        .orderBy('name')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: onBackPressed,
        ),
        title: const Text('Attendance Record', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0D2364),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchAttendance(), // fetch MongoDB attendance
        builder: (context, attendanceSnapshot) {
          if (attendanceSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (attendanceSnapshot.hasError) {
            return Center(child: Text("Error: ${attendanceSnapshot.error}"));
          }

          final attendanceData = attendanceSnapshot.data ?? [];

          return StreamBuilder<QuerySnapshot>(
            stream: employeesStream, // Firestore employees
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text("No employees found"));
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 16,
                    headingRowColor: WidgetStateProperty.all(Colors.blue[50]),
                    columns: const [
                      DataColumn(label: Text("Employee's ID")),
                      DataColumn(label: Text("Employee's Name")),
                      DataColumn(label: Text("Vehicle Unit")),
                      DataColumn(label: Text("Time In")),
                      DataColumn(label: Text("Time Out")),
                    ],
                    rows: docs.map((doc) {
                      final user = doc.data() as Map<String, dynamic>;
                      final name = user['name']?.toString() ?? '';

                      // 🔎 Find attendance by name
                      final match = attendanceData.firstWhere(
                            (a) => a['name'] == name,
                        orElse: () => {},
                      );

                      return DataRow(
                        cells: [
                          DataCell(Text(user['employeeId']?.toString() ?? '')),
                          DataCell(Text(name)),
                          DataCell(Text(match.isNotEmpty
                              ? "Unit ${match['unit'] ?? ''}"
                              : (user['assignedVehicle'] != null
                              ? "Unit ${user['assignedVehicle']}"
                              : ''))),
                          DataCell(Text(match['timeIn']?.toString() ?? '')),
                          DataCell(Text(match['timeOut']?.toString() ?? '')),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
