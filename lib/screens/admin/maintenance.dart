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
          'issueDate': (data['issueDate'] as Timestamp?)?.toDate().toString() ?? '',
          'status': data['status'] ?? '',
          'priority': data['priority'] ?? '',
          'assigned': data['assigned'] ?? '',
        };
      }).toList();
    });
  }

  // ADD RECORD FOR MAINTENANCE
  Future<void> _addMaintenanceRecord(String vehicleId) async {
    await FirebaseFirestore.instance
        .collection('vehicles')
        .doc(vehicleId)
        .collection('maintenance')
        .add({
      'title': 'Brake Check',
      'issueDate': FieldValue.serverTimestamp(),
      'status': 'DUE',
      'priority': 'HIGH',
      'assigned': 'mechanic',
    });

    _loadMaintenanceData(vehicleId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance'),
        backgroundColor: const Color(0xFF0D2364),
        foregroundColor: Colors.white,
      ),
      body: Row(
        children: [
          // Left side - Vehicle list
          Container(
            width: 120,
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey.shade300)),
            ),
            // child: Column(
            //   crossAxisAlignment: CrossAxisAlignment.start,
            //   children: [
            //     const Padding(
            //       padding: EdgeInsets.all(16.0),
            //       child: Text(
            //         'Vehicle',
            //         style: TextStyle(
            //           fontSize: 16, // Reduced font size
            //           fontWeight: FontWeight.bold,
            //         ),
            //       ),
            //     ),
            //     Padding(
            //       padding: const EdgeInsets.symmetric(horizontal: 16.0),
            //       child: TextField(
            //         decoration: InputDecoration(
            //           hintText: 'Search',
            //           prefixIcon: const Icon(
            //             Icons.search,
            //             size: 20,
            //           ), // Smaller icon
            //           border: OutlineInputBorder(
            //             borderRadius: BorderRadius.circular(8.0),
            //           ),
            //           contentPadding: const EdgeInsets.symmetric(
            //             vertical: 6.0, // Reduced padding
            //             horizontal: 10.0,
            //           ),
            //         ),
            //       ),
            //     ),
            //     const SizedBox(height: 12), // Reduced spacing
            //     Expanded(
            //       child: ListView.builder(
            //         itemCount: 25, // UNIT 01 to UNIT 25
            //         itemBuilder: (context, index) {
            //           final unitNumber = (index + 1).toString().padLeft(2, '0');
            //           final unitName = 'UNIT $unitNumber';
            //
            //           return ListTile(
            //             title: Text(
            //               unitName,
            //               style: TextStyle(
            //                 fontSize: 14, // Smaller font for vehicle list
            //                 fontWeight: selectedVehicle == unitName
            //                     ? FontWeight.bold
            //                     : FontWeight.normal,
            //               ),
            //             ),
            //             selected: selectedVehicle == unitName,
            //             selectedTileColor: Colors.blue.shade50,
            //             onTap: () {
            //               setState(() {
            //                 selectedVehicle = unitName;
            //               });
            //             },
            //           );
            //         },
            //       ),
            //     ),
            //   ],
            // ),
            child: ListView.builder(
              itemCount: 25,
              itemBuilder: (context, index) {
                final unitNumber = (2101 + index).toString();
                final unitName = unitNumber;

                return ListTile(
                  title: Text(
                    'UNIT $unitName',
                    style: TextStyle(
                      fontWeight: selectedVehicle == unitName
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  selected: selectedVehicle == unitName,
                  selectedTileColor: Colors.blue.shade50,
                  onTap: () {
                    setState(() {
                      selectedVehicle = unitName;
                    });
                    _loadMaintenanceData(unitName);
                  },
                );
              },
            ),
          ),

          // Right side - Maintenance details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedVehicle,
                    style: const TextStyle(
                      fontSize: 24, // Increased font size for selected unit
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (maintenanceList.isEmpty)
                    const Center(
                      child: Text(
                        'No maintenance issues for this vehicle',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  else
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            Colors.grey.shade200,
                          ),
                          columns: const [
                            DataColumn(label: Text('Title')),
                            DataColumn(label: Text('Issue Date')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Priority')),
                            DataColumn(
                              label: Text('Assigned'),
                            ),
                          ],
                          rows: maintenanceList.map((issue) {
                            return DataRow(
                              cells: [
                                DataCell(Text(issue['title'])),
                                DataCell(Text(issue['issueDate'])),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(issue['status']),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      issue['status'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    issue['priority'],
                                    style: TextStyle(
                                      color: _getPriorityColor(
                                        issue['priority'],
                                      ),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(issue['assigned']),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
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
