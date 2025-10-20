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
  String selectedRole = 'all'; // 'all', 'driver', 'conductor', 'inspector'

  /// ----------- ROLE COLOR FUNCTION -----------
  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'legal_officer':
        return Colors.orange;
      case 'driver':
        return Colors.green;
      case 'conductor':
        return Colors.blue;
      case 'inspector':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  /// ----------- VEHICLE STATUS COLOR FUNCTION -----------
  Color _getVehicleStatusColor(String? assignedVehicle) {
    if (assignedVehicle == null ||
        assignedVehicle.toString().isEmpty ||
        assignedVehicle == 'Not assigned') {
      return Colors.red; // Not assigned - Red
    }
    return Colors.blue; // Assigned - Blue
  }

  /// ----------- SCHEDULE STATUS COLOR FUNCTION -----------
  Color _getScheduleStatusColor(String? schedule) {
    if (schedule == null || schedule.isEmpty || schedule == 'Not set') {
      return Colors.red; // Not set - Red
    }
    return Colors.blue; // Set - Blue
  }

  /// ----------- ASSIGNMENT STATUS COLOR FUNCTION (For Inspector) -----------
  Color _getAssignmentStatusColor(String? assignment) {
    if (assignment == null ||
        assignment.isEmpty ||
        assignment == 'Not assigned') {
      return Colors.red; // Not assigned - Red
    }
    return Colors.green; // Assigned - Green
  }

  // Stream for real-time updates from users collection based on selected role
  Stream<QuerySnapshot> get employeesStream {
    if (selectedRole == 'all') {
      return _firestore
          .collection('users')
          .where('role', whereIn: ['driver', 'conductor', 'inspector'])
          .orderBy('name')
          .snapshots();
    } else {
      return _firestore
          .collection('users')
          .where('role', isEqualTo: selectedRole)
          .orderBy('name')
          .snapshots();
    }
  }

  // Update employee schedule + save to appropriate history collection
  Future<void> _updateEmployeeSchedule(
    String docId,
    String newSchedule,
    Map<String, dynamic> employeeData,
  ) async {
    try {
      final currentSchedule = employeeData['schedule']?.toString() ?? 'Not set';
      final role = employeeData['role']?.toString() ?? '';

      await _firestore.collection('users').doc(docId).update({
        'schedule': newSchedule,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Determine which collection to use based on role
      String collectionName = role == 'inspector'
          ? 'inspector_schedules'
          : 'schedules';

      await _firestore.collection(collectionName).add({
        'userId': docId,
        'employeeName': employeeData['name'] ?? 'Unknown',
        'employeeId': employeeData['employeeId'] ?? 'Unknown',
        'role': role,
        'previousSchedule': currentSchedule,
        'newSchedule': newSchedule,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schedule updated & history saved')),
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

  // Get the employee schedules (history) based on role
  Future<List<Map<String, dynamic>>> _getEmployeeSchedules(
    String userId,
    String role,
  ) async {
    String collectionName = role == 'inspector'
        ? 'inspector_schedules'
        : 'schedules';

    final snapshot = await _firestore
        .collection(collectionName)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  void _showScheduleHistory(
    BuildContext context,
    String userId,
    String employeeName,
    String role,
  ) async {
    final schedules = await _getEmployeeSchedules(userId, role);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Schedule History - $employeeName'),
          content: SizedBox(
            width: 400,
            height: 400,
            child: schedules.isEmpty
                ? const Center(child: Text("No schedule history"))
                : SingleChildScrollView(
                    child: Column(
                      children: schedules.map((s) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text('New: ${s['newSchedule']}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Previous: ${s['previousSchedule']}'),
                                const SizedBox(height: 4),
                                Text(
                                  s['createdAt'] != null
                                      ? 'Changed on: ${(s['createdAt'] as Timestamp).toDate().toString()}'
                                      : '',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            leading: const Icon(
                              Icons.calendar_today,
                              color: Colors.blue,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Update employee vehicle + save to vehicle history
  Future<void> _updateEmployeeVehicle(
    String docId,
    String newVehicle,
    Map<String, dynamic> employeeData,
  ) async {
    try {
      final currentVehicle =
          employeeData['assignedVehicle']?.toString() ?? 'Not assigned';

      await _firestore.collection('users').doc(docId).update({
        'assignedVehicle': int.parse(newVehicle),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('vehicle_history').add({
        'userId': docId,
        'employeeName': employeeData['name'] ?? 'Unknown',
        'employeeId': employeeData['employeeId'] ?? 'Unknown',
        'role': employeeData['role'] ?? '',
        'previousVehicle': currentVehicle != 'Not assigned'
            ? 'UNIT $currentVehicle'
            : currentVehicle,
        'newVehicle': 'UNIT $newVehicle',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle updated & history saved')),
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

  // Get the employee vehicle history
  Future<List<Map<String, dynamic>>> _getEmployeeVehicleHistory(
    String userId,
  ) async {
    final snapshot = await _firestore
        .collection('vehicle_history')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  void _showVehicleHistory(
    BuildContext context,
    String userId,
    String employeeName,
  ) async {
    final vehicleHistory = await _getEmployeeVehicleHistory(userId);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Vehicle History - $employeeName'),
          content: SizedBox(
            width: 400,
            height: 400,
            child: vehicleHistory.isEmpty
                ? const Center(child: Text("No vehicle history"))
                : SingleChildScrollView(
                    child: Column(
                      children: vehicleHistory.map((history) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text('New: ${history['newVehicle']}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Previous: ${history['previousVehicle']}'),
                                const SizedBox(height: 4),
                                Text(
                                  history['createdAt'] != null
                                      ? 'Changed on: ${(history['createdAt'] as Timestamp).toDate().toString()}'
                                      : '',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            leading: const Icon(
                              Icons.directions_bus,
                              color: Colors.green,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Update inspector assignment area + save to inspector_assignments history
  Future<void> _updateInspectorAssignment(
    String docId,
    String newArea,
    Map<String, dynamic> inspectorData,
  ) async {
    try {
      final currentArea =
          inspectorData['assignedArea']?.toString() ?? 'Not assigned';

      await _firestore.collection('users').doc(docId).update({
        'assignedArea': newArea,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('inspector_assignments').add({
        'userId': docId,
        'inspectorName': inspectorData['name'] ?? 'Unknown',
        'employeeId': inspectorData['employeeId'] ?? 'Unknown',
        'previousArea': currentArea,
        'newArea': newArea,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assignment area updated & history saved'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating assignment: $e')),
        );
      }
    }
  }

  // Get the inspector assignment history
  Future<List<Map<String, dynamic>>> _getInspectorAssignmentHistory(
    String userId,
  ) async {
    final snapshot = await _firestore
        .collection('inspector_assignments')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  void _showAssignmentHistory(
    BuildContext context,
    String userId,
    String inspectorName,
  ) async {
    final assignmentHistory = await _getInspectorAssignmentHistory(userId);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Assignment History - $inspectorName'),
          content: SizedBox(
            width: 400,
            height: 400,
            child: assignmentHistory.isEmpty
                ? const Center(child: Text("No assignment history"))
                : SingleChildScrollView(
                    child: Column(
                      children: assignmentHistory.map((history) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text('New: ${history['newArea']}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Previous: ${history['previousArea']}'),
                                const SizedBox(height: 4),
                                Text(
                                  history['createdAt'] != null
                                      ? 'Changed on: ${(history['createdAt'] as Timestamp).toDate().toString()}'
                                      : '',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            leading: const Icon(
                              Icons.assignment,
                              color: Colors.green,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Filter employees based on search query
  List<QueryDocumentSnapshot> _filterEmployees(
    List<QueryDocumentSnapshot> docs,
  ) {
    if (searchQuery.isEmpty) return docs;

    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = data['name']?.toString().toLowerCase() ?? '';
      final employeeId = data['employeeId']?.toString().toLowerCase() ?? '';
      return name.contains(searchQuery.toLowerCase()) ||
          employeeId.contains(searchQuery.toLowerCase());
    }).toList();
  }

  // Check if employee has a schedule set
  bool _hasSchedule(Map<String, dynamic> data) {
    final schedule = data['schedule']?.toString();
    return schedule != null && schedule.isNotEmpty && schedule != 'Not set';
  }

  // Check if employee has a vehicle assigned
  bool _hasVehicle(Map<String, dynamic> data) {
    final vehicle = data['assignedVehicle']?.toString();
    return vehicle != null && vehicle.isNotEmpty && vehicle != 'Not assigned';
  }

  // Check if inspector has an assignment area
  bool _hasAssignment(Map<String, dynamic> data) {
    final assignment = data['assignedArea']?.toString();
    return assignment != null &&
        assignment.isNotEmpty &&
        assignment != 'Not assigned';
  }

  // Check if employee is inspector
  bool _isInspector(Map<String, dynamic> data) {
    return data['role']?.toString().toLowerCase() == 'inspector';
  }

  // State-based Action Menu
  void _showActionMenu(BuildContext context, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final employeeName = data['name']?.toString() ?? 'Employee';
    final role = data['role']?.toString() ?? '';
    final hasSchedule = _hasSchedule(data);
    final hasVehicle = _hasVehicle(data);
    final hasAssignment = _hasAssignment(data);
    final isInspector = _isInspector(data);

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              // Schedule Actions - State-based (for all roles)
              if (!hasSchedule) ...[
                ListTile(
                  leading: const Icon(
                    Icons.calendar_today,
                    color: Colors.green,
                  ),
                  title: const Text('Set Schedule'),
                  onTap: () {
                    Navigator.pop(context);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        _showScheduleSelector(this.context, doc, data);
                      }
                    });
                  },
                ),
              ] else ...[
                ListTile(
                  leading: const Icon(
                    Icons.edit_calendar,
                    color: Colors.orange,
                  ),
                  title: const Text('Change Schedule'),
                  onTap: () {
                    Navigator.pop(context);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        _showScheduleSelector(this.context, doc, data);
                      }
                    });
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Clear Schedule'),
                  onTap: () {
                    Navigator.pop(context);
                    _clearSchedule(doc.id, data);
                  },
                ),
              ],

              // Vehicle Actions - State-based (only for driver/conductor)
              if (!isInspector) ...[
                if (!hasVehicle) ...[
                  ListTile(
                    leading: const Icon(
                      Icons.directions_bus,
                      color: Colors.green,
                    ),
                    title: const Text('Assign Vehicle'),
                    onTap: () {
                      Navigator.pop(context);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          // Get fresh context from the widget tree
                          _showVehicleSelector(this.context, doc, data);
                        }
                      });
                    },
                  ),
                ] else ...[
                  ListTile(
                    leading: const Icon(Icons.edit, color: Colors.orange),
                    title: const Text('Change Vehicle'),
                    onTap: () {
                      Navigator.pop(context);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          // Get fresh context from the widget tree
                          _showVehicleSelector(this.context, doc, data);
                        }
                      });
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.cancel, color: Colors.red),
                    title: const Text('Remove Vehicle'),
                    onTap: () {
                      Navigator.pop(context);
                      _removeVehicle(doc.id, data);
                    },
                  ),
                ],
              ],

              // Assignment Area Actions - State-based (only for inspector)
              if (isInspector) ...[
                if (!hasAssignment) ...[
                  ListTile(
                    leading: const Icon(Icons.assignment, color: Colors.green),
                    title: const Text('Assign Area'),
                    onTap: () {
                      Navigator.pop(context);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          _showAreaSelector(this.context, doc, data);
                        }
                      });
                    },
                  ),
                ] else ...[
                  ListTile(
                    leading: const Icon(Icons.edit, color: Colors.orange),
                    title: const Text('Change Area'),
                    onTap: () {
                      Navigator.pop(context);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          _showAreaSelector(this.context, doc, data);
                        }
                      });
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.cancel, color: Colors.red),
                    title: const Text('Remove Area'),
                    onTap: () {
                      Navigator.pop(context);
                      _removeAssignment(doc.id, data);
                    },
                  ),
                ],
              ],

              // History Actions (always available)
              const Divider(),
              ListTile(
                leading: const Icon(Icons.history, color: Colors.blue),
                title: const Text('View Schedule History'),
                onTap: () {
                  Navigator.pop(context);
                  _showScheduleHistory(context, doc.id, employeeName, role);
                },
              ),

              // Vehicle History (only for driver/conductor)
              if (!isInspector) ...[
                ListTile(
                  leading: const Icon(Icons.history_edu, color: Colors.blue),
                  title: const Text('View Vehicle History'),
                  onTap: () {
                    Navigator.pop(context);
                    _showVehicleHistory(context, doc.id, employeeName);
                  },
                ),
              ],

              // Assignment History (only for inspector)
              if (isInspector) ...[
                ListTile(
                  leading: const Icon(Icons.assignment_ind, color: Colors.blue),
                  title: const Text('View Assignment History'),
                  onTap: () {
                    Navigator.pop(context);
                    _showAssignmentHistory(context, doc.id, employeeName);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // Clear schedule function
  Future<void> _clearSchedule(
    String docId,
    Map<String, dynamic> employeeData,
  ) async {
    try {
      final currentSchedule = employeeData['schedule']?.toString() ?? 'Not set';
      final role = employeeData['role']?.toString() ?? '';

      await _firestore.collection('users').doc(docId).update({
        'schedule': 'Not set',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      String collectionName = role == 'inspector'
          ? 'inspector_schedules'
          : 'schedules';

      await _firestore.collection(collectionName).add({
        'userId': docId,
        'employeeName': employeeData['name'] ?? 'Unknown',
        'employeeId': employeeData['employeeId'] ?? 'Unknown',
        'role': role,
        'previousSchedule': currentSchedule,
        'newSchedule': 'Not set',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schedule cleared & history saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error clearing schedule: $e')));
      }
    }
  }

  // Remove vehicle function
  Future<void> _removeVehicle(
    String docId,
    Map<String, dynamic> employeeData,
  ) async {
    try {
      final currentVehicle =
          employeeData['assignedVehicle']?.toString() ?? 'Not assigned';

      await _firestore.collection('users').doc(docId).update({
        'assignedVehicle': 'Not assigned',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('vehicle_history').add({
        'userId': docId,
        'employeeName': employeeData['name'] ?? 'Unknown',
        'employeeId': employeeData['employeeId'] ?? 'Unknown',
        'role': employeeData['role'] ?? '',
        'previousVehicle': currentVehicle != 'Not assigned'
            ? 'UNIT $currentVehicle'
            : currentVehicle,
        'newVehicle': 'Not assigned',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle removed & history saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error removing vehicle: $e')));
      }
    }
  }

  // Remove assignment function (for inspector)
  Future<void> _removeAssignment(
    String docId,
    Map<String, dynamic> inspectorData,
  ) async {
    try {
      final currentAssignment =
          inspectorData['assignedArea']?.toString() ?? 'Not assigned';

      await _firestore.collection('users').doc(docId).update({
        'assignedArea': 'Not assigned',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('inspector_assignments').add({
        'userId': docId,
        'inspectorName': inspectorData['name'] ?? 'Unknown',
        'employeeId': inspectorData['employeeId'] ?? 'Unknown',
        'previousArea': currentAssignment,
        'newArea': 'Not assigned',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment removed & history saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing assignment: $e')),
        );
      }
    }
  }

  // Schedule selector dialog (for all roles)
  void _showScheduleSelector(
    BuildContext context,
    QueryDocumentSnapshot doc,
    Map<String, dynamic> employeeData,
  ) {
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
    if (currentSchedule.isNotEmpty && currentSchedule != 'Not set') {
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
                        _hasSchedule(data)
                            ? 'Change Schedule for ${employeeData['name']}'
                            : 'Set Schedule for ${employeeData['name']}',
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
                                  employeeData,
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
                            child: Text(
                              _hasSchedule(data) ? 'Update' : 'Set Schedule',
                            ),
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
    return snapshot.docs
        .map((doc) => doc['vehicleId'].toString().trim())
        .toList();
  }

  // Get available vehicles
  Future<List<String>> _getAvailableVehicles(
    String? currentUserId,
    String role,
  ) async {
    // Get all vehicles
    final allVehicles = await _getVehicles();

    // Get vehicles that are under repair
    final vehiclesSnapshot = await _firestore.collection('vehicles').get();
    final underRepairVehicles = <String>{};
    for (var doc in vehiclesSnapshot.docs) {
      final isUnderRepair = doc.data()['isUnderRepair'] ?? false;
      if (isUnderRepair) {
        underRepairVehicles.add(doc.data()['vehicleId'].toString().trim());
      }
    }

    // Get all users with the SAME role who have assigned vehicles
    final usersSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: role)
        .where('status', isEqualTo: true)
        .get();

    // Collect assigned vehicle IDs
    final assignedVehicles = <String>{};
    for (var doc in usersSnapshot.docs) {
      if (doc.id == currentUserId) {
        continue;
      }

      final data = doc.data();
      final assignedVehicle = data['assignedVehicle'];

      // Add to assigned list if it's a valid vehicle number
      if (assignedVehicle != null &&
          assignedVehicle.toString() != 'Not assigned') {
        // Convert to string for consistent comparison
        final vehicleStr = assignedVehicle is int
            ? assignedVehicle.toString()
            : assignedVehicle.toString().trim();
        if (vehicleStr.isNotEmpty && vehicleStr != 'Not assigned') {
          assignedVehicles.add(vehicleStr);
        }
      }
    }

    // Filter out assigned vehicles
    final availableVehicles = allVehicles
        .where(
          (vehicle) =>
              !assignedVehicles.contains(vehicle) &&
              !underRepairVehicles.contains(vehicle),
        )
        .toList();

    return availableVehicles;
  }

  // Vehicle selector dialog (for driver/conductor)
  // Vehicle selector dialog (for driver/conductor)
  void _showVehicleSelector(
    BuildContext context,
    QueryDocumentSnapshot doc,
    Map<String, dynamic> employeeData,
  ) async {
    final data = doc.data() as Map<String, dynamic>;
    final role = data['role']?.toString() ?? '';

    // Get available vehicles based on role
    final availableVehicles = await _getAvailableVehicles(doc.id, role);

    // Get current vehicle assignment
    String? currentVehicleValue = data['assignedVehicle']?.toString();

    // If employee already has a vehicle, add it to the list
    if (currentVehicleValue != null &&
        currentVehicleValue != 'Not assigned' &&
        !availableVehicles.contains(currentVehicleValue)) {
      availableVehicles.insert(0, currentVehicleValue);
    }

    // Check mounted BEFORE any UI operations
    if (!mounted) {
      return;
    }

    // Check if there are any available vehicles
    if (availableVehicles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No available vehicles to assign'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Determine initial selection
    String currentVehicle;
    if (currentVehicleValue != null &&
        currentVehicleValue != 'Not assigned' &&
        availableVehicles.contains(currentVehicleValue)) {
      currentVehicle = currentVehicleValue;
    } else {
      currentVehicle = availableVehicles.first;
    }

    // Use Builder to get a fresh context
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent accidental dismissal
      builder: (dialogContext) {
        // ← Use dialogContext instead of context
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _hasVehicle(data)
                          ? 'Change Vehicle for ${employeeData['name']}'
                          : 'Assign Vehicle for ${employeeData['name']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Info message
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Showing ${availableVehicles.length} available vehicle(s) (excluding assigned & under repair)',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    DropdownButton<String>(
                      value: currentVehicle,
                      isExpanded: true,
                      items: availableVehicles.map((v) {
                        final isCurrentVehicle = v == currentVehicleValue;
                        return DropdownMenuItem<String>(
                          value: v,
                          child: Row(
                            children: [
                              Text('UNIT $v'),
                              if (isCurrentVehicle) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.green.shade300,
                                    ),
                                  ),
                                  child: Text(
                                    'Current',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => currentVehicle = val!);
                      },
                    ),

                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(dialogContext); // ← Use dialogContext
                          },
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            await _updateEmployeeVehicle(
                              doc.id,
                              currentVehicle,
                              employeeData,
                            );
                            if (dialogContext.mounted) {
                              // ← Check dialogContext
                              Navigator.pop(
                                dialogContext,
                              ); // ← Use dialogContext
                            }
                          },
                          child: Text(_hasVehicle(data) ? 'Update' : 'Assign'),
                        ),
                      ],
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

  // Area selector dialog (for inspector) - gaya gaya tungko at road 2
  void _showAreaSelector(
    BuildContext context,
    QueryDocumentSnapshot doc,
    Map<String, dynamic> inspectorData,
  ) {
    final data = doc.data() as Map<String, dynamic>;

    final List<String> areas = [
      'Not assigned',
      'Gaya-gaya',
      'Tungko',
      'Road 2',
    ];

    String currentArea = data['assignedArea']?.toString() ?? 'Not assigned';

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
                    Text(
                      _hasAssignment(data)
                          ? 'Change Assignment Area for ${inspectorData['name']}'
                          : 'Assign Area for ${inspectorData['name']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButton<String>(
                      value: currentArea,
                      isExpanded: true,
                      items: areas.map((area) {
                        return DropdownMenuItem<String>(
                          value: area,
                          child: Text(area),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => currentArea = val!);
                      },
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
                            await _updateInspectorAssignment(
                              doc.id,
                              currentArea,
                              inspectorData,
                            );
                            Navigator.pop(context);
                          },
                          child: Text(
                            _hasAssignment(data) ? 'Update' : 'Assign',
                          ),
                        ),
                      ],
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
  Widget _buildEmployeeCard(QueryDocumentSnapshot doc, int index) {
    final data = doc.data() as Map<String, dynamic>;
    final employeeId = data['employeeId']?.toString() ?? 'N/A';
    final role = data['role']?.toString() ?? '';
    final roleColor = _getRoleColor(role);
    final isInspector = _isInspector(data);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with name and action button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name']?.toString() ?? 'No Name',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'No. ${index + 1}',
                        style: TextStyle(fontSize: 14, color: Colors.black),
                      ),
                    ],
                  ),
                ),
                // UPDATED: Light blue container with dark blue pencil icon (exactly like the image)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50, // Light blue background
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue.shade100, // Light blue border
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.edit,
                      size: 18,
                      color: Colors.blue.shade800, // Dark blue pencil
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () => _showActionMenu(context, doc),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Employee details in specified order
            _buildInfoRow('No.', (index + 1).toString()),
            _buildInfoRow('Employee ID', employeeId),
            _buildInfoRow('Role', _capitalizeRole(role), valueColor: roleColor),
            _buildInfoRow(
              'Employment Type',
              data['employmentType']?.toString() ?? 'N/A',
            ),

            // Show Vehicle for driver/conductor, Assigned Area for inspector
            if (!isInspector) ...[
              _buildInfoRow(
                'Vehicle',
                data['assignedVehicle'] != null
                    ? 'UNIT ${data['assignedVehicle']}'
                    : 'Not assigned',
                valueColor: _getVehicleStatusColor(
                  data['assignedVehicle']?.toString(),
                ),
              ),
            ] else ...[
              _buildInfoRow(
                'Assigned Area',
                data['assignedArea']?.toString() ?? 'Not assigned',
                valueColor: _getAssignmentStatusColor(
                  data['assignedArea']?.toString(),
                ),
              ),
            ],

            _buildInfoRow(
              'Schedule',
              data['schedule']?.toString() ?? 'Not set',
              valueColor: _getScheduleStatusColor(data['schedule']?.toString()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: valueColor ?? Colors.black,
                fontWeight: valueColor != null
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _capitalizeRole(String role) {
    if (role.isEmpty) return '';
    return role[0].toUpperCase() + role.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // UPDATED: Search and Filter Bar - Responsive Design
            Container(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bool isMobile = constraints.maxWidth < 600;

                  if (isMobile) {
                    // Mobile Layout - Vertical
                    return Column(
                      children: [
                        // Search Bar - Full width on mobile
                        TextField(
                          controller: searchCtrl,
                          decoration: InputDecoration(
                            labelText: 'Search by name or ID',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                          ),
                          onChanged: (value) =>
                              setState(() => searchQuery = value),
                        ),
                        const SizedBox(height: 12),
                        // Filter - Full width on mobile
                        Row(
                          children: [
                            const Text(
                              'Filter by Role:',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButton<String>(
                                value: selectedRole,
                                isExpanded: true,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'all',
                                    child: Text('All'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'driver',
                                    child: Text('Driver'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'conductor',
                                    child: Text('Conductor'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'inspector',
                                    child: Text('Inspector'),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    selectedRole = value!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  } else {
                    // Desktop/Tablet Layout - Horizontal
                    return Row(
                      children: [
                        // Search Bar - Takes more space
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: searchCtrl,
                            decoration: InputDecoration(
                              labelText: 'Search by name or ID',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                            ),
                            onChanged: (value) =>
                                setState(() => searchQuery = value),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Filter - Fixed width
                        SizedBox(
                          width: 250,
                          child: Row(
                            children: [
                              const Text(
                                'Filter by Role:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButton<String>(
                                  value: selectedRole,
                                  isExpanded: true,
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'all',
                                      child: Text('All'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'driver',
                                      child: Text('Driver'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'conductor',
                                      child: Text('Conductor'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'inspector',
                                      child: Text('Inspector'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      selectedRole = value!;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
            ),

            // Main Content
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: StreamBuilder<QuerySnapshot>(
                  stream: employeesStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data?.docs ?? [];
                    final filteredDocs = _filterEmployees(docs);

                    if (filteredDocs.isEmpty) {
                      return const Center(child: Text('No employees found'));
                    }

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final bool isMobile = constraints.maxWidth < 600;
                        final bool isTablet = constraints.maxWidth < 900;

                        if (isMobile) {
                          return _buildMobileView(filteredDocs);
                        } else if (isTablet) {
                          return _buildTabletView(filteredDocs);
                        } else {
                          return _buildDesktopView(filteredDocs);
                        }
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mobile View - Card List
  Widget _buildMobileView(List<QueryDocumentSnapshot> filteredDocs) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: filteredDocs.length,
      itemBuilder: (context, index) {
        return _buildEmployeeCard(filteredDocs[index], index);
      },
    );
  }

  /// Tablet View - Compact DataTable
  Widget _buildTabletView(List<QueryDocumentSnapshot> filteredDocs) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.only(bottom: 16),
          child: DataTable(
            columnSpacing: 12,
            horizontalMargin: 8,
            headingRowColor: WidgetStateColor.resolveWith(
              (states) => const Color(0xFF0D2364),
            ),
            columns: const [
              DataColumn(
                label: Text(
                  'NO.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'EMPLOYEE ID',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'NAME',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'ROLE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'EMPLOYEE TYPE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'ASSIGN UNIT/AREA',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'SCHEDULE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'ACTION',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
            rows: filteredDocs.asMap().entries.map((entry) {
              final index = entry.key;
              final doc = entry.value;
              final data = doc.data() as Map<String, dynamic>;
              return _buildDataRow(doc, data, index, isCompact: true);
            }).toList(),
          ),
        ),
      ),
    );
  }

  /// Desktop View - Full DataTable
  Widget _buildDesktopView(List<QueryDocumentSnapshot> filteredDocs) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.only(bottom: 16),
          child: DataTable(
            columnSpacing: 20,
            horizontalMargin: 12,
            headingRowColor: WidgetStateColor.resolveWith(
              (states) => const Color(0xFF0D2364),
            ),
            columns: const [
              DataColumn(
                label: Text(
                  'NO.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'EMPLOYEE ID',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'NAME',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'ROLE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'EMPLOYEE TYPE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'ASSIGN UNIT/AREA',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'SCHEDULE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'ACTION',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
            rows: filteredDocs.asMap().entries.map((entry) {
              final index = entry.key;
              final doc = entry.value;
              final data = doc.data() as Map<String, dynamic>;
              return _buildDataRow(doc, data, index, isCompact: false);
            }).toList(),
          ),
        ),
      ),
    );
  }

  /// Helper method to build DataRows for both tablet and desktop
  DataRow _buildDataRow(
    QueryDocumentSnapshot doc,
    Map<String, dynamic> data,
    int index, {
    bool isCompact = false,
  }) {
    final employeeId = data['employeeId']?.toString() ?? 'N/A';
    final role = data['role']?.toString() ?? '';
    final roleColor = _getRoleColor(role);
    final isInspector = _isInspector(data);

    // Determine assignment text and color based on role
    String assignmentText;
    Color assignmentColor;

    if (isInspector) {
      assignmentText = data['assignedArea']?.toString() ?? 'Not assigned';
      assignmentColor = _getAssignmentStatusColor(
        data['assignedArea']?.toString(),
      );
    } else {
      assignmentText = data['assignedVehicle'] != null
          ? 'UNIT ${data['assignedVehicle']}'
          : 'Not assigned';
      assignmentColor = _getVehicleStatusColor(
        data['assignedVehicle']?.toString(),
      );
    }

    final scheduleStatusColor = _getScheduleStatusColor(
      data['schedule']?.toString(),
    );

    return DataRow(
      cells: [
        // NO. (Number)
        DataCell(
          SizedBox(
            width: isCompact ? 60 : 80,
            child: Text(
              (index + 1).toString(),
              style: TextStyle(
                fontSize: isCompact ? 12 : 14,
                color: Colors.black,
              ),
            ),
          ),
        ),
        // EMP ID
        DataCell(
          SizedBox(
            width: isCompact ? 100 : 120,
            child: Text(
              employeeId,
              style: TextStyle(fontSize: isCompact ? 12 : 14),
            ),
          ),
        ),
        // NAME
        DataCell(
          SizedBox(
            width: isCompact ? 120 : 150,
            child: Text(
              data['name']?.toString() ?? '',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: isCompact ? 12 : 14),
            ),
          ),
        ),
        // ROLE
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: roleColor.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: roleColor),
            ),
            child: Text(
              _capitalizeRole(role),
              style: TextStyle(
                color: roleColor,
                fontWeight: FontWeight.w600,
                fontSize: isCompact ? 11 : 12,
              ),
            ),
          ),
        ),
        // EMPLOYEE TYPE
        DataCell(
          SizedBox(
            width: isCompact ? 80 : 120,
            child: Text(
              data['employmentType']?.toString() ?? '',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: isCompact ? 12 : 14),
            ),
          ),
        ),
        // ASSIGNMENT (Vehicle for driver/conductor, Area for inspector)
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: assignmentColor.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: assignmentColor),
            ),
            child: Text(
              assignmentText,
              style: TextStyle(
                color: assignmentColor,
                fontWeight: FontWeight.w600,
                fontSize: isCompact ? 11 : 12,
              ),
            ),
          ),
        ),
        // SCHEDULE
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: scheduleStatusColor.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheduleStatusColor),
            ),
            child: Text(
              data['schedule']?.toString() ?? 'Not set',
              style: TextStyle(
                color: scheduleStatusColor,
                fontWeight: FontWeight.w600,
                fontSize: isCompact ? 11 : 12,
              ),
            ),
          ),
        ),
        DataCell(
          Container(
            width: isCompact ? 32 : 36,
            height: isCompact ? 32 : 36,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade100, width: 1),
            ),
            child: IconButton(
              icon: Icon(
                Icons.edit,
                size: isCompact ? 16 : 18,
                color: Colors.blue.shade800,
              ),
              padding: EdgeInsets.zero,
              onPressed: () => _showActionMenu(context, doc),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }
}
