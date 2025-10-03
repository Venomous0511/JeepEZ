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
          'priority': data['priority'] ?? '',
          'type': (data['checklistItems'] as List<dynamic>?)?.join(', ') ?? '',
        };
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance'),
        backgroundColor: const Color(0xFF0D2364),
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          final leftPanelWidth = isMobile
              ? 100.0
              : 140.0; // Increased width to accommodate "Unit"

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
                    final unitName = 'Unit $unitNumber'; // Added "Unit" prefix

                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 6.0 : 10.0,
                        vertical: 0,
                      ),
                      dense: true,
                      title: Text(
                        isMobile ? unitName : unitName.toUpperCase(),
                        style: TextStyle(
                          fontSize: isMobile
                              ? 12
                              : 14, // Slightly increased font size
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
                        'Unit $selectedVehicle', // Added "Unit" prefix
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
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: isMobile ? 6 : 8,
                                              vertical: isMobile ? 3 : 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getPriorityColor(
                                                issue['priority'],
                                              ).withAlpha(1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                color: _getPriorityColor(
                                                  issue['priority'],
                                                ),
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              issue['priority'],
                                              style: TextStyle(
                                                fontSize: isMobile ? 10 : 12,
                                                color: _getPriorityColor(
                                                  issue['priority'],
                                                ),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: isMobile ? 6 : 8),
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
      case 'DUE':
        return Colors.orange;
      case 'In Progress':
        return Colors.blue;
      case 'Completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'HIGH':
        return Colors.red;
      case 'MEDIUM':
        return Colors.orange;
      case 'LOW':
        return Colors.green;
      case 'NONE':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
