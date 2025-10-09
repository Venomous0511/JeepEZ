import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  String selectedVehicle = '2101';
  List<Map<String, dynamic>> maintenanceList = [];

  @override
  void initState() {
    super.initState();
    _loadMaintenanceData(selectedVehicle);
  }

  Future<void> _loadMaintenanceData(String vehicleId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('vehicles')
        .doc(vehicleId)
        .collection('maintenance')
        .orderBy('issueDate', descending: true)
        .get();

    setState(() {
      maintenanceList = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'issueDate':
              (data['issueDate'] as Timestamp?)?.toDate().toString() ?? '',
          'status': data['status'] ?? 'Pending',
          'type': (data['checklistItems'] as List<dynamic>?)?.join(', ') ?? '',
          'reportedBy': data['reportedBy'] ?? 'Unknown',
          'updates': data['updates'] ?? [],
        };
      }).toList();
    });
  }

  Future<void> _updateMaintenanceStatus(
    String vehicleId,
    String maintenanceId,
    String newStatus,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(vehicleId)
          .collection('maintenance')
          .doc(maintenanceId)
          .update({
            'status': newStatus,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      _loadMaintenanceData(vehicleId);
    } catch (e) {
      print('Error updating status: $e');
    }
  }

  Future<void> _addStatusUpdate(
    String vehicleId,
    String maintenanceId,
    String updateText,
  ) async {
    try {
      final update = {
        'text': updateText,
        'timestamp': FieldValue.serverTimestamp(),
        'updatedBy': 'Admin', // You can replace this with actual user name
      };

      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(vehicleId)
          .collection('maintenance')
          .doc(maintenanceId)
          .update({
            'updates': FieldValue.arrayUnion([update]),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      _loadMaintenanceData(vehicleId);
    } catch (e) {
      print('Error adding update: $e');
    }
  }

  void _showStatusMenu(
    BuildContext context,
    String vehicleId,
    String maintenanceId,
    String currentStatus,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.build_circle, color: Colors.orange),
                title: const Text('In Repair'),
                onTap: () {
                  Navigator.pop(context);
                  _updateMaintenanceStatus(
                    vehicleId,
                    maintenanceId,
                    'In Repair',
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Completed'),
                onTap: () {
                  Navigator.pop(context);
                  _updateMaintenanceStatus(
                    vehicleId,
                    maintenanceId,
                    'Completed',
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showUpdatesDialog(
    BuildContext context,
    List<dynamic> updates,
    String title,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Updates - $title'),
          content: SizedBox(
            width: 400,
            height: 300,
            child: updates.isEmpty
                ? const Center(child: Text("No updates available"))
                : SingleChildScrollView(
                    child: Column(
                      children: updates.map((update) {
                        final updateData = update as Map<String, dynamic>;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(updateData['text'] ?? ''),
                            subtitle: Text(
                              updateData['timestamp'] != null
                                  ? 'Updated on: ${(updateData['timestamp'] as Timestamp).toDate().toString()}'
                                  : '',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            leading: const Icon(
                              Icons.update,
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

  void _showAddUpdateDialog(
    BuildContext context,
    String vehicleId,
    String maintenanceId,
  ) {
    final updateController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Status Update'),
          content: TextField(
            controller: updateController,
            decoration: const InputDecoration(
              labelText: 'Update details',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (updateController.text.trim().isNotEmpty) {
                  _addStatusUpdate(
                    vehicleId,
                    maintenanceId,
                    updateController.text.trim(),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Add Update'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          final leftPanelWidth = isMobile ? 100.0 : 140.0;

          return Row(
            children: [
              // Left side - Vehicle list
              Container(
                width: leftPanelWidth,
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: ListView.builder(
                  itemCount: 25,
                  itemBuilder: (context, index) {
                    final unitNumber = (2101 + index).toString();
                    final unitName = 'Unit $unitNumber';

                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 6.0 : 10.0,
                        vertical: 0,
                      ),
                      dense: true,
                      title: Text(
                        isMobile ? unitName : unitName.toUpperCase(),
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 14,
                          fontWeight: selectedVehicle == unitNumber
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      selected: selectedVehicle == unitNumber,
                      selectedTileColor: Colors.blue.shade50,
                      onTap: () {
                        setState(() {
                          selectedVehicle = unitNumber;
                        });
                        _loadMaintenanceData(unitNumber);
                      },
                    );
                  },
                ),
              ),

              // Right side - Maintenance details
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unit $selectedVehicle',
                        style: TextStyle(
                          fontSize: isMobile ? 18 : 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: isMobile ? 8 : 16),
                      if (maintenanceList.isEmpty)
                        Expanded(
                          child: Center(
                            child: Text(
                              'No maintenance issues for this vehicle',
                              style: TextStyle(
                                fontSize: isMobile ? 12 : 16,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.builder(
                            itemCount: maintenanceList.length,
                            itemBuilder: (context, index) {
                              final issue = maintenanceList[index];
                              return Card(
                                margin: EdgeInsets.only(
                                  bottom: isMobile ? 8 : 12,
                                ),
                                elevation: 2,
                                child: Padding(
                                  padding: EdgeInsets.all(
                                    isMobile ? 8.0 : 12.0,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              issue['title'],
                                              style: TextStyle(
                                                fontSize: isMobile ? 13 : 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                            ),
                                          ),
                                          // 3-dot status menu
                                          PopupMenuButton<String>(
                                            icon: Icon(
                                              Icons.more_vert,
                                              size: isMobile ? 18 : 20,
                                            ),
                                            onSelected: (value) {
                                              if (value == 'status') {
                                                _showStatusMenu(
                                                  context,
                                                  selectedVehicle,
                                                  issue['id'],
                                                  issue['status'],
                                                );
                                              } else if (value == 'updates') {
                                                _showUpdatesDialog(
                                                  context,
                                                  issue['updates'],
                                                  issue['title'],
                                                );
                                              } else if (value ==
                                                  'add_update') {
                                                _showAddUpdateDialog(
                                                  context,
                                                  selectedVehicle,
                                                  issue['id'],
                                                );
                                              }
                                            },
                                            itemBuilder:
                                                (BuildContext context) => [
                                                  PopupMenuItem<String>(
                                                    value: 'status',
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.build,
                                                          size: 20,
                                                        ),
                                                        SizedBox(width: 8),
                                                        Text('Change Status'),
                                                      ],
                                                    ),
                                                  ),
                                                  PopupMenuItem<String>(
                                                    value: 'updates',
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.history,
                                                          size: 20,
                                                        ),
                                                        SizedBox(width: 8),
                                                        Text('View Updates'),
                                                      ],
                                                    ),
                                                  ),
                                                  PopupMenuItem<String>(
                                                    value: 'add_update',
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.add,
                                                          size: 20,
                                                        ),
                                                        SizedBox(width: 8),
                                                        Text('Add Update'),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: isMobile ? 6 : 8),

                                      // Status indicator
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isMobile ? 8 : 12,
                                          vertical: isMobile ? 4 : 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(
                                            issue['status'],
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          border: Border.all(
                                            color: _getStatusColor(
                                              issue['status'],
                                            ),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _getStatusIcon(issue['status']),
                                              size: isMobile ? 12 : 14,
                                              color: _getStatusColor(
                                                issue['status'],
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              issue['status'],
                                              style: TextStyle(
                                                fontSize: isMobile ? 10 : 12,
                                                color: _getStatusColor(
                                                  issue['status'],
                                                ),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: isMobile ? 6 : 8),

                                      // Reported by information
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.person,
                                            size: isMobile ? 14 : 16,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Reported by: ${issue['reportedBy']}',
                                            style: TextStyle(
                                              fontSize: isMobile ? 11 : 14,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: isMobile ? 4 : 6),

                                      // Maintenance type
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.build,
                                            size: isMobile ? 14 : 16,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              issue['type'],
                                              style: TextStyle(
                                                fontSize: isMobile ? 11 : 14,
                                                color: Colors.grey[700],
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: isMobile ? 4 : 6),

                                      // Issue date
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            size: isMobile ? 14 : 16,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              issue['issueDate'],
                                              style: TextStyle(
                                                fontSize: isMobile ? 11 : 14,
                                                color: Colors.grey[700],
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),

                                      // Updates count
                                      if ((issue['updates'] as List).isNotEmpty)
                                        Padding(
                                          padding: EdgeInsets.only(
                                            top: isMobile ? 4 : 6,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.update,
                                                size: isMobile ? 12 : 14,
                                                color: Colors.blue,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                '${(issue['updates'] as List).length} update${(issue['updates'] as List).length == 1 ? '' : 's'}',
                                                style: TextStyle(
                                                  fontSize: isMobile ? 10 : 12,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'In Repair':
        return Colors.orange;
      case 'Completed':
        return Colors.green;
      case 'Pending':
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'In Repair':
        return Icons.build_circle;
      case 'Completed':
        return Icons.check_circle;
      case 'Pending':
      default:
        return Icons.pending;
    }
  }
}
