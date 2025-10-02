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
        int tripNumber = 1;

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
              "tripNumber": tripNumber,
            });
            outCount++;
            tripNumber++;
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
            "tripNumber": tripNumber,
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
        automaticallyImplyLeading: false,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date Selection Row
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[50],
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
                          ? DateFormat("MMM d, yyyy").format(selectedDate)
                          : "Pick Date",
                    ),
                    selected: mode == "custom",
                    onSelected: (_) => _pickDate(),
                  ),
                ],
              ),
            ),

            // Main Content
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

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final bool isMobile = constraints.maxWidth < 600;
                          final bool isTablet = constraints.maxWidth < 900;

                          if (isMobile) {
                            return _buildMobileView(docs, attendanceData);
                          } else if (isTablet) {
                            return _buildTabletView(docs, attendanceData);
                          } else {
                            return _buildDesktopView(docs, attendanceData);
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mobile View - Card List
  Widget _buildMobileView(
    List<QueryDocumentSnapshot> docs,
    List<Map<String, dynamic>> attendanceData,
  ) {
    final employeesWithAttendance = docs.where((doc) {
      final user = doc.data() as Map<String, dynamic>;
      final name = user['name']?.toString() ?? '';
      return attendanceData.any((a) => a['name'] == name);
    }).toList();

    if (employeesWithAttendance.isEmpty) {
      return const Center(
        child: Text("No attendance records found for selected date"),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: employeesWithAttendance.length,
      itemBuilder: (context, index) {
        final doc = employeesWithAttendance[index];
        final user = doc.data() as Map<String, dynamic>;
        final name = user['name']?.toString() ?? '';
        final matches = attendanceData.where((a) => a['name'] == name).toList();

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Employee Info
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue[100],
                      child: Text(
                        user['employeeId']?.toString().isNotEmpty == true
                            ? user['employeeId'].toString().substring(0, 1)
                            : 'U',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'ID: ${user['employeeId']?.toString() ?? 'N/A'}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),

                // Attendance Records
                ...matches.map((match) {
                  final timeInString = match['timeIn'] != null
                      ? formatTime(DateTime.parse(match['timeIn']).toLocal())
                      : '';
                  final timeOutString = match['timeOut'] != null
                      ? formatTime(DateTime.parse(match['timeOut']).toLocal())
                      : '';

                  String ordinal(int number) {
                    if (number == 1) return "1st Trip";
                    if (number == 2) return "2nd Trip";
                    if (number == 3) return "3rd Trip";
                    return "${number}th Trip";
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ordinal(match['tripNumber']),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.login,
                                    size: 14,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text('In: $timeInString')),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.logout,
                                    size: 14,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text('Out: $timeOutString')),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            match['unit']?.toString().isNotEmpty == true
                                ? "Unit ${match['unit']}"
                                : (user['assignedVehicle'] != null
                                      ? "Unit ${user['assignedVehicle']}"
                                      : 'N/A'),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Tablet View - Compact DataTable
  Widget _buildTabletView(
    List<QueryDocumentSnapshot> docs,
    List<Map<String, dynamic>> attendanceData,
  ) {
    final rows = _buildDataRows(docs, attendanceData, isCompact: true);

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.all(8),
          child: DataTable(
            columnSpacing: 12,
            horizontalMargin: 8,
            headingRowColor: WidgetStateProperty.all(Colors.blue[50]),
            columns: const [
              DataColumn(label: Text("ID")),
              DataColumn(label: Text("Name")),
              DataColumn(label: Text("Unit")),
              DataColumn(label: Text("Date")),
              DataColumn(label: Text("Time In")),
              DataColumn(label: Text("Time Out")),
              DataColumn(label: Text("Trip")),
            ],
            rows: rows,
          ),
        ),
      ),
    );
  }

  /// Desktop View - Full DataTable
  Widget _buildDesktopView(
    List<QueryDocumentSnapshot> docs,
    List<Map<String, dynamic>> attendanceData,
  ) {
    final rows = _buildDataRows(docs, attendanceData, isCompact: false);

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.all(16),
          child: DataTable(
            columnSpacing: 20,
            horizontalMargin: 12,
            headingRowColor: WidgetStateProperty.all(Colors.blue[50]),
            columns: const [
              DataColumn(label: Text("Employee's ID")),
              DataColumn(label: Text("Employee's Name")),
              DataColumn(label: Text("Vehicle Unit")),
              DataColumn(label: Text("Date")),
              DataColumn(label: Text("Tap In")),
              DataColumn(label: Text("Tap Out")),
              DataColumn(label: Text("Trips")),
            ],
            rows: rows,
          ),
        ),
      ),
    );
  }

  /// Helper method to build DataRows for both tablet and desktop
  List<DataRow> _buildDataRows(
    List<QueryDocumentSnapshot> docs,
    List<Map<String, dynamic>> attendanceData, {
    bool isCompact = false,
  }) {
    return docs.expand<DataRow>((doc) {
      final user = doc.data() as Map<String, dynamic>;
      final name = user['name']?.toString() ?? '';

      final matches = attendanceData.where((a) => a['name'] == name).toList();

      if (matches.isEmpty) {
        return [];
      }

      return matches.map((match) {
        final dateString = match['timeIn'] != null
            ? formatDate(DateTime.parse(match['timeIn']).toLocal())
            : (match['timeOut'] != null
                  ? formatDate(DateTime.parse(match['timeOut']).toLocal())
                  : '');

        final timeInString = match['timeIn'] != null
            ? formatTime(DateTime.parse(match['timeIn']).toLocal())
            : '';

        final timeOutString = match['timeOut'] != null
            ? formatTime(DateTime.parse(match['timeOut']).toLocal())
            : '';

        String ordinal(int number) {
          if (number == 1) return "1st Trip";
          if (number == 2) return "2nd Trip";
          if (number == 3) return "3rd Trip";
          return "${number}th Trip";
        }

        return DataRow(
          cells: [
            DataCell(
              Text(
                user['employeeId']?.toString() ?? '',
                style: isCompact ? const TextStyle(fontSize: 12) : null,
              ),
            ),
            DataCell(
              Text(
                name,
                style: isCompact ? const TextStyle(fontSize: 12) : null,
              ),
            ),
            DataCell(
              Text(
                match['unit'] != null && match['unit'].toString().isNotEmpty
                    ? "Unit ${match['unit']}"
                    : (user['assignedVehicle'] != null
                          ? "Unit ${user['assignedVehicle']}"
                          : ''),
                style: isCompact ? const TextStyle(fontSize: 12) : null,
              ),
            ),
            DataCell(
              Text(
                dateString,
                style: isCompact ? const TextStyle(fontSize: 12) : null,
              ),
            ),
            DataCell(
              Text(
                timeInString,
                style: isCompact ? const TextStyle(fontSize: 12) : null,
              ),
            ),
            DataCell(
              Text(
                timeOutString,
                style: isCompact ? const TextStyle(fontSize: 12) : null,
              ),
            ),
            DataCell(
              Text(
                ordinal(match['tripNumber']),
                style: isCompact ? const TextStyle(fontSize: 12) : null,
              ),
            ),
          ],
        );
      });
    }).toList();
  }
}
