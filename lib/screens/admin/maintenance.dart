import 'package:flutter/material.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  String selectedVehicle = 'UNIT 2101';

  // Sample maintenance data for each vehicle unit
  final Map<String, List<Map<String, dynamic>>> maintenanceData = {
    'UNIT 01': [
      {
        'title': 'Oil Change',
        'issueDate': 'Dec 16, 2021 10:30 AM',
        'status': 'DUE',
        'priority': 'LOW',
        'assigned': 'mechanic',
      },
      {
        'title': 'Brake Inspection',
        'issueDate': 'Dec 15, 2021 02:45 PM',
        'status': 'In Progress',
        'priority': 'MEDIUM',
        'assigned': 'mechanic',
      },
    ],
    'UNIT 02': [
      {
        'title': 'Tire Rotation',
        'issueDate': 'Dec 17, 2021 09:15 AM',
        'status': 'Completed',
        'priority': 'LOW',
        'assigned': 'mechanic',
      },
    ],
    'UNIT 03': [
      {
        'title': 'Engine Tune-up',
        'issueDate': 'Dec 14, 2021 11:20 AM',
        'status': 'DUE',
        'priority': 'HIGH',
        'assigned': 'mechanic',
      },
    ],
    'UNIT 2104': [],
    'UNIT 2105': [],
    'UNIT 2106': [],
    'UNIT 2107': [],
    'UNIT 2108': [],
    'UNIT 2109': [],
    'UNIT 2120': [
      {
        'title': 'Replace Tires',
        'issueDate': 'Dec 15, 2021 12:17 AM',
        'status': 'DUE',
        'priority': 'NONE',
        'assigned': 'mechanic',
      },
      {
        'title': 'Needs Brakes',
        'issueDate': 'Dec 14, 2021 09:42 PM',
        'status': 'DUE',
        'priority': 'NONE',
        'assigned': 'mechanic',
      },
      {
        'title': 'Oil Change and Tire Rotation',
        'issueDate': 'Dec 14, 2021 09:28 PM',
        'status': 'DUE',
        'priority': 'NONE',
        'assigned': 'mechanic',
      },
      {
        'title': 'Replace Transmission',
        'issueDate': 'Dec 14, 2021 09:01 PM',
        'status': 'In Progress',
        'priority': 'HIGH',
        'assigned': 'mechanic',
      },
    ],
  };

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
            width: 180, // Slightly reduced width
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Vehicle',
                    style: TextStyle(
                      fontSize: 16, // Reduced font size
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search',
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 20,
                      ), // Smaller icon
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 6.0, // Reduced padding
                        horizontal: 10.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12), // Reduced spacing
                Expanded(
                  child: ListView.builder(
                    itemCount: 25, // UNIT 01 to UNIT 25
                    itemBuilder: (context, index) {
                      final unitNumber = (index + 1).toString().padLeft(2, '0');
                      final unitName = 'UNIT $unitNumber';

                      return ListTile(
                        title: Text(
                          unitName,
                          style: TextStyle(
                            fontSize: 14, // Smaller font for vehicle list
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
                        },
                      );
                    },
                  ),
                ),
              ],
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
                  if (maintenanceData[selectedVehicle]!.isEmpty)
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
                            ), // Changed back to 'Assigned'
                          ],
                          rows: maintenanceData[selectedVehicle]!.map((issue) {
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
                                ), // Changed back to 'assigned'
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
