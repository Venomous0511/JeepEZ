import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class AttendanceScreen extends StatefulWidget {
  final VoidCallback onBackPressed;
  const AttendanceScreen({super.key, required this.onBackPressed});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String mode = "today";
  DateTime selectedDate = DateTime.now();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Pick custom date
  void _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        mode = "custom";
        selectedDate = picked;
      });
    }
  }

  /// Get the active date (today, yesterday, or custom)
  DateTime _getTargetDate() {
    if (mode == "today") return DateTime.now();
    if (mode == "yesterday") {
      return DateTime.now().subtract(const Duration(days: 1));
    }
    return selectedDate;
  }

  /// Fetch and process attendance logs from backend
  Future<List<Map<String, dynamic>>> fetchAttendance(
    DateTime targetDate,
  ) async {
    final response = await http.get(
      Uri.parse("https://jeepez-attendance.onrender.com/api/logs"),
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);

      final filterDate = DateFormat('yyyy-MM-dd').format(targetDate);

      // Group logs by name and date
      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (var log in data) {
        final logDate = DateFormat(
          'yyyy-MM-dd',
        ).format(DateTime.parse(log['timestamp']).toLocal());

        if (logDate == filterDate) {
          final key = "${log['name']}_$logDate";
          grouped.putIfAbsent(key, () => []).add(log);
        }
      }

      final List<Map<String, dynamic>> attendance = [];

      grouped.forEach((key, logs) {
        logs.sort(
          (a, b) => DateTime.parse(
            a['timestamp'],
          ).compareTo(DateTime.parse(b['timestamp'])),
        );

        String name = logs.first['name'];
        String date = logs.first['date'];
        int inCount = 0, outCount = 0;

        Map<String, dynamic>? currentIn;

        for (var log in logs) {
          if (log['type'] == 'tap-in' && inCount < 4) {
            currentIn = log;
            inCount++;
          } else if (log['type'] == 'tap-out' &&
              currentIn != null &&
              outCount < 4) {
            attendance.add({
              "name": name,
              "date": date,
              "timeIn": currentIn['timestamp'],
              "timeOut": log['timestamp'],
              "unit": log["unit"] ?? "",
            });
            outCount++;
            currentIn = null;
          }
        }

        // If ended with tap-in without tap-out
        if (currentIn != null && inCount <= 4) {
          attendance.add({
            "name": name,
            "date": date,
            "timeIn": currentIn['timestamp'],
            "timeOut": null,
            "unit": currentIn["unit"] ?? "",
          });
        }
      });

      return attendance;
    } else {
      throw Exception("Failed to load attendance");
    }
  }

  // Firestore employees stream
  Stream<QuerySnapshot> get employeesStream {
    return _firestore
        .collection('users')
        .where('role', whereIn: ['driver', 'conductor'])
        .orderBy('name')
        .snapshots();
  }

  String formatTime(DateTime dateTime) {
    return DateFormat('hh:mm:ss a').format(dateTime);
  }

  String formatDate(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final targetDate = _getTargetDate();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: widget.onBackPressed,
        ),
        title: const Text(
          'Attendance Record',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0D2364),
        automaticallyImplyLeading:
            false, // Ito ang nagtatanggal ng hamburger menu
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text("Today"),
                  selected: mode == "today",
                  onSelected: (_) => setState(() => mode = "today"),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text("Yesterday"),
                  selected: mode == "yesterday",
                  onSelected: (_) => setState(() => mode = "yesterday"),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(
                    mode == "custom"
                        ? DateFormat("yyyy-MM-dd").format(selectedDate)
                        : "Pick Date",
                  ),
                  selected: mode == "custom",
                  onSelected: (_) => _pickDate(),
                ),
              ],
            ),
          ),

          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchAttendance(targetDate),
              builder: (context, attendanceSnapshot) {
                if (attendanceSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (attendanceSnapshot.hasError) {
                  return Center(
                    child: Text("Error: ${attendanceSnapshot.error}"),
                  );
                }

                final attendanceData = attendanceSnapshot.data ?? [];

                return StreamBuilder<QuerySnapshot>(
                  stream: employeesStream,
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
                          headingRowColor: WidgetStateProperty.all(
                            Colors.blue[50],
                          ),
                          columns: const [
                            DataColumn(label: Text("Employee's ID")),
                            DataColumn(label: Text("Employee's Name")),
                            DataColumn(label: Text("Vehicle Unit")),
                            DataColumn(label: Text("Date")),
                            DataColumn(label: Text("Tap In")),
                            DataColumn(label: Text("Tap Out")),
                            DataColumn(label: Text("Trips")),
                          ],
                          rows: docs.expand<DataRow>((doc) {
                            final user = doc.data() as Map<String, dynamic>;
                            final name = user['name']?.toString() ?? '';

                            // Find attendance logs for this employee
                            final matches = attendanceData
                                .where((a) => a['name'] == name)
                                .toList();

                            if (matches.isEmpty) {
                              return [];
                            }

                            return matches.map((match) {
                              final dateString = match['timeIn'] != null
                                  ? formatDate(
                                      DateTime.parse(match['timeIn']).toLocal(),
                                    )
                                  : (match['timeOut'] != null
                                        ? formatDate(
                                            DateTime.parse(
                                              match['timeOut'],
                                            ).toLocal(),
                                          )
                                        : '');

                              final timeInString = match['timeIn'] != null
                                  ? formatTime(
                                      DateTime.parse(match['timeIn']).toLocal(),
                                    )
                                  : '';

                              final timeOutString = match['timeOut'] != null
                                  ? formatTime(
                                      DateTime.parse(
                                        match['timeOut'],
                                      ).toLocal(),
                                    )
                                  : '';

                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(user['employeeId']?.toString() ?? ''),
                                  ),
                                  DataCell(Text(name)),
                                  DataCell(
                                    Text(
                                      match['unit'] != null &&
                                              match['unit']
                                                  .toString()
                                                  .isNotEmpty
                                          ? "Unit ${match['unit']}"
                                          : (user['assignedVehicle'] != null
                                                ? "Unit ${user['assignedVehicle']}"
                                                : ''),
                                    ),
                                  ),
                                  DataCell(Text(dateString)),
                                  DataCell(Text(timeInString)),
                                  DataCell(Text(timeOutString)),
                                ],
                              );
                            });
                          }).toList(), // Flatten rows
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
