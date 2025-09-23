import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverConductorManagementScreen extends StatefulWidget {
  const DriverConductorManagementScreen({super.key});

  @override
  State<DriverConductorManagementScreen> createState() =>
      _DriverConductorManagementScreenState();
}

class _DriverConductorManagementScreenState
    extends State<DriverConductorManagementScreen> {
  final TextEditingController searchCtrl = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String searchQuery = '';

  // Stream for real-time updates from users collection
  Stream<QuerySnapshot> get employeesStream {
    return _firestore
        .collection('users')
        .where('role', whereIn: ['driver', 'conductor'])
        .orderBy('name')
        .snapshots();
  }

  // Update employee schedule + save to schedules history
  Future<void> _updateEmployeeSchedule(String docId, String newSchedule) async {
    try {
      await _firestore.collection('users').doc(docId).update({
        'schedule': newSchedule,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('schedules').add({
        'userId': docId,
        'schedule': newSchedule,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Schedule updated & saved in schedules'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating schedule: $e')));
      }
    }
  }

  // Get the employee schedules (history)
  Future<List<Map<String, dynamic>>> _getEmployeeSchedules(
    String userId,
  ) async {
    final snapshot = await _firestore
        .collection('schedules')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  void _showScheduleHistory(BuildContext context, String userId) async {
    final schedules = await _getEmployeeSchedules(userId);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Schedule History'),
          content: SizedBox(
            width: 300,
            height: 300,
            child: schedules.isEmpty
                ? const Center(child: Text("No schedule history"))
                : SingleChildScrollView(
                    child: Column(
                      children: schedules.map((s) {
                        return ListTile(
                          title: Text(s['schedule']),
                          subtitle: Text(
                            s['createdAt'] != null
                                ? (s['createdAt'] as Timestamp)
                                      .toDate()
                                      .toString()
                                : '',
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
        );
      },
    );
  }

  // Update employee vehicle
  Future<void> _updateEmployeeVehicle(String docId, String newVehicle) async {
    try {
      await _firestore.collection('users').doc(docId).update({
        'assignedVehicle': int.tryParse(newVehicle) ?? 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating vehicle: $e')));
      }
    }
  }

  // Filter employees based on search query
  List<QueryDocumentSnapshot> _filterEmployees(
    List<QueryDocumentSnapshot> docs,
  ) {
    if (searchQuery.isEmpty) return docs;

    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = data['name']?.toString().toLowerCase() ?? '';
      return name.contains(searchQuery.toLowerCase());
    }).toList();
  }

  // Action menu (schedule / vehicle / history)
  void _showActionMenu(BuildContext context, QueryDocumentSnapshot doc) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Change Schedule'),
                onTap: () {
                  Navigator.pop(context);
                  _showScheduleSelector(context, doc);
                },
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('View Schedule History'),
                onTap: () {
                  Navigator.pop(context);
                  _showScheduleHistory(context, doc.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.directions_bus),
                title: const Text('Change Vehicle'),
                onTap: () {
                  Navigator.pop(context);
                  _showVehicleSelector(context, doc);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Schedule selector dialog
  void _showScheduleSelector(BuildContext context, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final Map<String, bool> selectedDays = {
      'Monday': false,
      'Tuesday': false,
      'Wednesday': false,
      'Thursday': false,
      'Friday': false,
      'Saturday': false,
      'Sunday': false,
    };

    final currentSchedule = data['schedule']?.toString() ?? '';
    if (currentSchedule.isNotEmpty) {
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final fullDays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];

      if (currentSchedule.contains('–')) {
        final parts = currentSchedule.split('–');
        final startDay = parts[0];
        final endDay = parts[1];

        final startIndex = days.indexOf(startDay);
        final endIndex = days.indexOf(endDay);

        if (startIndex != -1 && endIndex != -1) {
          for (int i = startIndex; i <= endIndex; i++) {
            selectedDays[fullDays[i]] = true;
          }
        }
      } else {
        final dayIndex = days.indexOf(currentSchedule);
        if (dayIndex != -1) {
          selectedDays[fullDays[dayIndex]] = true;
        }
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              insetPadding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Select Schedule',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        childAspectRatio: 3,
                        children: selectedDays.entries.map((entry) {
                          return CheckboxListTile(
                            title: Text(entry.key),
                            value: entry.value,
                            onChanged: (bool? value) {
                              setState(() {
                                selectedDays[entry.key] = value ?? false;
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Selected: ${selectedDays.entries.where((e) => e.value).map((e) => e.key.substring(0, 3)).join(', ')}',
                        style: const TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              final selectedDayList = selectedDays.entries
                                  .where((e) => e.value)
                                  .map((e) => e.key.substring(0, 3))
                                  .toList();

                              if (selectedDayList.isNotEmpty) {
                                await _updateEmployeeSchedule(
                                  doc.id,
                                  selectedDayList.join(', '),
                                );
                                Navigator.pop(context);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please select at least one day',
                                    ),
                                  ),
                                );
                              }
                            },
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Load vehicle IDs from vehicles collection
  Future<List<String>> _getVehicles() async {
    final snapshot = await _firestore.collection('vehicles').get();
    return snapshot.docs.map((doc) => doc['vehicleId'].toString()).toList();
  }

  // Vehicle selector dialog
  void _showVehicleSelector(
    BuildContext context,
    QueryDocumentSnapshot doc,
  ) async {
    final data = doc.data() as Map<String, dynamic>;
    final vehicles = await _getVehicles();

    String currentVehicle =
        data['assignedVehicle']?.toString() ??
        (vehicles.isNotEmpty ? vehicles.first : '0');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<String>(
                      value: currentVehicle,
                      isExpanded: true,
                      items: vehicles.map((v) {
                        return DropdownMenuItem<String>(
                          value: v,
                          child: Text('Vehicle $v'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => currentVehicle = val!);
                      },
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await _updateEmployeeVehicle(doc.id, currentVehicle);
                        Navigator.pop(context);
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Build responsive employee card for mobile view
  Widget _buildEmployeeCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    data['name']?.toString() ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showActionMenu(context, doc),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Employee ID', data['employeeId']?.toString() ?? ''),
            _buildInfoRow(
              'Employment Type',
              data['employmentType']?.toString() ?? '',
            ),
            _buildInfoRow('Role', data['role']?.toString() ?? ''),
            _buildInfoRow(
              'Vehicle',
              data['assignedVehicle'] != null
                  ? 'UNIT ${data['assignedVehicle']}'
                  : 'Not assigned',
            ),
            _buildInfoRow(
              'Schedule',
              data['schedule']?.toString() ?? 'Not set',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Driver & Conductor Oversight',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0D2364),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            TextField(
              controller: searchCtrl,
              decoration: InputDecoration(
                labelText: 'Search by name',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
            const SizedBox(height: 16),

            // Data Container with responsive layout
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(128),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Employees',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                  ),

                  // StreamBuilder for real-time data
                  StreamBuilder<QuerySnapshot>(
                    stream: employeesStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text('Error: ${snapshot.error}'),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];
                      final filteredDocs = _filterEmployees(docs);

                      if (filteredDocs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No employees found'),
                        );
                      }

                      // Horizontally scrollable table for all screen sizes
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 16,
                          headingRowColor: MaterialStateColor.resolveWith(
                            (states) => Colors.grey.shade100,
                          ),
                          columns: const [
                            DataColumn(
                              label: Text(
                                'Name',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Employee ID',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Employment Type',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Role',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Vehicle',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Schedule',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Actions',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                          rows: filteredDocs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return DataRow(
                              cells: [
                                DataCell(
                                  SizedBox(
                                    width: 120,
                                    child: Text(
                                      data['name']?.toString() ?? '',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      data['employeeId']?.toString() ?? '',
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 100,
                                    child: Text(
                                      data['employmentType']?.toString() ?? '',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 80,
                                    child: Text(data['role']?.toString() ?? ''),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      data['assignedVehicle'] != null
                                          ? 'UNIT ${data['assignedVehicle']}'
                                          : 'Not assigned',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 120,
                                    child: Text(
                                      data['schedule']?.toString() ?? 'Not set',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  IconButton(
                                    icon: const Icon(Icons.more_vert, size: 20),
                                    onPressed: () =>
                                        _showActionMenu(context, doc),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }
}
