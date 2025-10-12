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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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

  /// Refresh data
  void _refreshData() {
    setState(() {});
  }

  /// Clear search
  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
    });
  }

  /// Get the active date (today, yesterday, or custom)
  DateTime _getTargetDate() {
    if (mode == "today") return DateTime.now();
    if (mode == "yesterday") {
      return DateTime.now().subtract(const Duration(days: 1));
    }
    return selectedDate;
  }

  /// Fetch and process attendance logs from backend - OPTIMIZED
  Future<List<Map<String, dynamic>>> fetchAttendance(
    DateTime targetDate,
  ) async {
    try {
      final response = await http.get(
        Uri.parse("https://jeepez-attendance.onrender.com/api/logs"),
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        final filterDate = DateFormat('yyyy-MM-dd').format(targetDate);

        // Group logs by name
        final Map<String, List<Map<String, dynamic>>> groupedByName = {};
        for (var log in data) {
          try {
            final logDate = DateFormat(
              'yyyy-MM-dd',
            ).format(DateTime.parse(log['timestamp']).toLocal());

            if (logDate == filterDate) {
              final name = log['name']?.toString() ?? 'Unknown';
              groupedByName.putIfAbsent(name, () => []).add(log);
            }
          } catch (e) {
            print('Error parsing log: $e');
          }
        }

        final List<Map<String, dynamic>> attendance = [];

        // Process each employee's logs
        groupedByName.forEach((name, logs) {
          // Sort logs by timestamp
          logs.sort(
            (a, b) => DateTime.parse(
              a['timestamp'],
            ).compareTo(DateTime.parse(b['timestamp'])),
          );

          List<Map<String, dynamic>> trips = [];
          Map<String, dynamic>? currentIn;

          for (var log in logs) {
            if (log['type'] == 'tap-in') {
              // If there's a pending tap-in, close it first
              if (currentIn != null) {
                trips.add({
                  "timeIn": currentIn['timestamp'],
                  "timeOut": null,
                  "unit": currentIn["unit"] ?? "",
                });
              }
              currentIn = log;
            } else if (log['type'] == 'tap-out' && currentIn != null) {
              trips.add({
                "timeIn": currentIn['timestamp'],
                "timeOut": log['timestamp'],
                "unit": log["unit"] ?? currentIn["unit"] ?? "",
              });
              currentIn = null;
            }
          }

          // Handle last pending tap-in
          if (currentIn != null) {
            trips.add({
              "timeIn": currentIn['timestamp'],
              "timeOut": null,
              "unit": currentIn["unit"] ?? "",
            });
          }

          // Add trips to attendance list with proper numbering
          for (int i = 0; i < trips.length; i++) {
            attendance.add({
              "name": name,
              "date": DateFormat('yyyy-MM-dd').format(targetDate),
              "timeIn": trips[i]["timeIn"],
              "timeOut": trips[i]["timeOut"],
              "unit": trips[i]["unit"],
              "tripNumber": i + 1,
            });
          }
        });

        // Sort by name and trip number
        attendance.sort((a, b) {
          final nameCompare = (a['name'] ?? '').compareTo(b['name'] ?? '');
          if (nameCompare != 0) return nameCompare;
          return (a['tripNumber'] ?? 0).compareTo(b['tripNumber'] ?? 0);
        });

        return attendance;
      } else {
        throw Exception("Failed to load attendance: ${response.statusCode}");
      }
    } catch (e) {
      print('Error fetching attendance: $e');
      throw Exception("Network error: $e");
    }
  }

  // Filter attendance data based on search query
  List<Map<String, dynamic>> _filterAttendanceData(
    List<Map<String, dynamic>> data,
  ) {
    if (_searchQuery.isEmpty) return data;

    final query = _searchQuery.toLowerCase();
    return data.where((attendance) {
      final name = attendance['name']?.toString().toLowerCase() ?? '';
      final unit = attendance['unit']?.toString().toLowerCase() ?? '';
      final trip = _getTripText(attendance['tripNumber']).toLowerCase();

      return name.contains(query) ||
          unit.contains(query) ||
          trip.contains(query);
    }).toList();
  }

  // Firestore employees stream
  Stream<QuerySnapshot> get employeesStream {
    return _firestore
        .collection('users')
        .where('role', whereIn: ['driver', 'conductor'])
        .orderBy('name')
        .snapshots();
  }

  String formatTime(String timestamp) {
    try {
      return DateFormat('hh:mm a').format(DateTime.parse(timestamp).toLocal());
    } catch (e) {
      return 'Invalid time';
    }
  }

  String formatDate(String timestamp) {
    try {
      return DateFormat(
        'MMM dd, yyyy',
      ).format(DateTime.parse(timestamp).toLocal());
    } catch (e) {
      return 'Invalid date';
    }
  }

  String getDisplayDate() {
    final targetDate = _getTargetDate();
    if (mode == "today") return "Today";
    if (mode == "yesterday") return "Yesterday";
    return DateFormat("MMMM d, yyyy").format(selectedDate);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final targetDate = _getTargetDate();
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Attendance - ${getDisplayDate()}',
          style: const TextStyle(fontSize: 18),
        ),
        backgroundColor: const Color(0xFF0D2364),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBackPressed,
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date Selection Row - Responsive
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 24,
                vertical: 16,
              ),
              color: Colors.grey[50],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Responsive date chips
                  Flexible(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildDateChip("Today", mode == "today"),
                        _buildDateChip("Yesterday", mode == "yesterday"),
                        _buildDateChip(
                          mode == "custom"
                              ? DateFormat("MMM d").format(selectedDate)
                              : "Pick Date",
                          mode == "custom",
                        ),
                      ],
                    ),
                  ),

                  // Refresh button
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    child: IconButton(
                      onPressed: _refreshData,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh data',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by name, unit, or trip...',
                          border: InputBorder.none,
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.grey,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    color: Colors.grey,
                                  ),
                                  onPressed: _clearSearch,
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.trim();
                          });
                        },
                      ),
                    ),
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
                    return _buildErrorWidget(
                      attendanceSnapshot.error.toString(),
                    );
                  }

                  final attendanceData = attendanceSnapshot.data ?? [];
                  final filteredData = _filterAttendanceData(attendanceData);

                  return StreamBuilder<QuerySnapshot>(
                    stream: employeesStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return _buildErrorWidget(snapshot.error.toString());
                      }

                      final docs = snapshot.data?.docs ?? [];

                      if (attendanceData.isEmpty) {
                        return _buildEmptyWidget();
                      }

                      if (filteredData.isEmpty) {
                        return _buildNoResultsWidget();
                      }

                      return _buildAttendanceContent(
                        docs,
                        filteredData,
                        isMobile,
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

  Widget _buildDateChip(String label, bool selected) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: selected ? Colors.white : Colors.black87,
        ),
      ),
      selected: selected,
      onSelected: (_) {
        if (label == "Today") {
          setState(() => mode = "today");
        } else if (label == "Yesterday") {
          setState(() => mode = "yesterday");
        } else {
          _pickDate();
        }
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF0D2364),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? const Color(0xFF0D2364) : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            const Text(
              "Error loading attendance",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.length > 100 ? '${error.substring(0, 100)}...' : error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D2364),
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              "No attendance records",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "No attendance data found for ${getDisplayDate()}",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              "No results found",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "No records match '$_searchQuery'",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _clearSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D2364),
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear Search'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceContent(
    List<QueryDocumentSnapshot> docs,
    List<Map<String, dynamic>> attendanceData,
    bool isMobile,
  ) {
    if (isMobile) {
      return _buildMobileView(docs, attendanceData);
    } else {
      return _buildDesktopView(attendanceData);
    }
  }

  /// Mobile View - Grouped by employee name
  Widget _buildMobileView(
    List<QueryDocumentSnapshot> docs,
    List<Map<String, dynamic>> attendanceData,
  ) {
    // Group attendance by employee name
    final Map<String, List<Map<String, dynamic>>> groupedAttendance = {};
    for (var attendance in attendanceData) {
      final name = attendance['name']?.toString() ?? 'Unknown';
      groupedAttendance.putIfAbsent(name, () => []).add(attendance);
    }

    // Get employee details
    final employeeMap = <String, Map<String, dynamic>>{};
    for (var doc in docs) {
      final user = doc.data() as Map<String, dynamic>;
      final name = user['name']?.toString() ?? '';
      employeeMap[name] = user;
    }

    final employeeNames = groupedAttendance.keys.toList();
    employeeNames.sort();

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: employeeNames.length,
      itemBuilder: (context, index) {
        final name = employeeNames[index];
        final user = employeeMap[name] ?? {};
        final trips = groupedAttendance[name] ?? [];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Employee Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF0D2364),
                      child: Text(
                        user['employeeId']?.toString().isNotEmpty == true
                            ? user['employeeId'].toString().substring(0, 1)
                            : 'U',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'ID: ${user['employeeId']?.toString() ?? 'N/A'}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
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
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${trips.length} ${trips.length == 1 ? 'Trip' : 'Trips'}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D2364),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),

                // Trips List
                ...trips.map((trip) => _buildMobileTripCard(trip)).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileTripCard(Map<String, dynamic> trip) {
    final timeInString = trip['timeIn'] != null
        ? formatTime(trip['timeIn'].toString())
        : 'N/A';
    final timeOutString = trip['timeOut'] != null
        ? formatTime(trip['timeOut'].toString())
        : 'N/A';

    final isCompleted = trip['timeOut'] != null;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCompleted ? Colors.green[100]! : Colors.orange[100]!,
        ),
      ),
      child: Row(
        children: [
          // Trip Number
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0D2364),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _getTripText(trip['tripNumber']),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Unit
                Row(
                  children: [
                    Icon(Icons.directions_bus, size: 12, color: Colors.blue),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Unit: ${trip['unit']?.toString().isNotEmpty == true ? trip['unit'] : 'N/A'}',
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Time In
                Row(
                  children: [
                    Icon(Icons.login, size: 12, color: Colors.green),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'In: $timeInString',
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                // Time Out
                Row(
                  children: [
                    Icon(Icons.logout, size: 12, color: Colors.red),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Out: $timeOutString',
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Desktop View - Clean table format
  Widget _buildDesktopView(List<Map<String, dynamic>> attendanceData) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        child: Column(
          children: [
            // Table Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF0D2364),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      "Employee Name",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "Unit",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "Time In",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "Time Out",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "Trip",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Table Content
            Expanded(
              child: ListView.builder(
                itemCount: attendanceData.length,
                itemBuilder: (context, index) {
                  final attendance = attendanceData[index];

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: index.isEven ? Colors.white : Colors.grey[50],
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey[300]!,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            attendance['name']?.toString() ?? 'N/A',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Expanded(
                          child: Text(attendance['unit']?.toString() ?? 'N/A'),
                        ),
                        Expanded(
                          child: Text(
                            attendance['timeIn'] != null
                                ? formatTime(attendance['timeIn'].toString())
                                : 'N/A',
                          ),
                        ),
                        Expanded(
                          child: Text(
                            attendance['timeOut'] != null
                                ? formatTime(attendance['timeOut'].toString())
                                : 'N/A',
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _getTripText(attendance['tripNumber']),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D2364),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTripText(dynamic tripNumber) {
    if (tripNumber == null) return 'N/A';
    final number = tripNumber is int
        ? tripNumber
        : int.tryParse(tripNumber.toString()) ?? 1;

    if (number == 1) return "1st Trip";
    if (number == 2) return "2nd Trip";
    if (number == 3) return "3rd Trip";
    return "${number}th Trip";
  }
}
