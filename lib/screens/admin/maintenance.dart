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
    'UNIT 2101': [
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
    'UNIT 2102': [
      {
        'title': 'Tire Rotation',
        'issueDate': 'Dec 17, 2021 09:15 AM',
        'status': 'Completed',
        'priority': 'LOW',
        'assigned': 'mechanic',
      },
    ],
    'UNIT 2103': [
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
    'UNIT 2110': [],
    'UNIT 2111': [],
    'UNIT 2112': [],
    'UNIT 2113': [],
    'UNIT 2114': [],
    'UNIT 2115': [],
    'UNIT 2116': [],
    'UNIT 2117': [],
    'UNIT 2118': [],
    'UNIT 2119': [],
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
    'UNIT 2121': [],
    'UNIT 2122': [],
    'UNIT 2123': [],
    'UNIT 2124': [],
    'UNIT 2125': [],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance'),
        backgroundColor: const Color(0xFF0D2364),
        foregroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isMobile = constraints.maxWidth < 600;
            final bool isTablet = constraints.maxWidth < 900;

            if (isMobile) {
              return _buildMobileView();
            } else if (isTablet) {
              return _buildTabletView();
            } else {
              return _buildDesktopView();
            }
          },
        ),
      ),
    );
  }

  /// Mobile View - Vertical layout
  Widget _buildMobileView() {
    return Column(
      children: [
        // Vehicle selection dropdown
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Vehicle',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: selectedVehicle,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: List.generate(25, (index) {
                    final unitNumber = (2101 + index).toString();
                    final unitName = 'UNIT $unitNumber';
                    return DropdownMenuItem<String>(
                      value: unitName,
                      child: Text(unitName),
                    );
                  }),
                  onChanged: (value) {
                    setState(() {
                      selectedVehicle = value!;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _buildMaintenanceContent()),
      ],
    );
  }

  /// Tablet View - Horizontal layout with smaller sidebar
  Widget _buildTabletView() {
    return Row(
      children: [
        // Left side - Vehicle list
        Container(
          width: 200,
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 12.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: 25, // UNIT 2101 to UNIT 2125
                  itemBuilder: (context, index) {
                    final unitNumber = (2101 + index).toString();
                    final unitName = 'UNIT $unitNumber';

                    return ListTile(
                      title: Text(
                        unitName,
                        style: TextStyle(
                          fontSize: 14,
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
        Expanded(child: _buildMaintenanceContent()),
      ],
    );
  }

  /// Desktop View - Full sidebar and table
  Widget _buildDesktopView() {
    return Row(
      children: [
        // Left side - Vehicle list
        Container(
          width: 250,
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Vehicle List',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search vehicles...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 16.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: 25, // UNIT 2101 to UNIT 2125
                  itemBuilder: (context, index) {
                    final unitNumber = (2101 + index).toString();
                    final unitName = 'UNIT $unitNumber';

                    return ListTile(
                      title: Text(
                        unitName,
                        style: TextStyle(
                          fontSize: 16,
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
        Expanded(child: _buildMaintenanceContent()),
      ],
    );
  }

  /// Common maintenance content for all layouts
  Widget _buildMaintenanceContent() {
    final currentIssues = maintenanceData[selectedVehicle] ?? [];

    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selectedVehicle,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Maintenance Issues',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),

          if (currentIssues.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: Colors.green.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No maintenance issues',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'All systems are operational for $selectedVehicle',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bool isMobile = constraints.maxWidth < 600;

                  if (isMobile) {
                    return _buildMobileMaintenanceList(currentIssues);
                  } else {
                    return _buildMaintenanceTable(currentIssues);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  /// Mobile maintenance list view
  Widget _buildMobileMaintenanceList(List<Map<String, dynamic>> issues) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: issues.length,
      itemBuilder: (context, index) {
        final issue = issues[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue['title'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildMobileDetailRow('Issue Date', issue['issueDate']),
                _buildMobileDetailRow(
                  'Status',
                  issue['status'],
                  isStatus: true,
                ),
                _buildMobileDetailRow(
                  'Priority',
                  issue['priority'],
                  isPriority: true,
                ),
                _buildMobileDetailRow('Assigned', issue['assigned']),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileDetailRow(
    String label,
    String value, {
    bool isStatus = false,
    bool isPriority = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
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
            child: isStatus
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(value),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      value,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  )
                : isPriority
                ? Text(
                    value,
                    style: TextStyle(
                      color: _getPriorityColor(value),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  )
                : Text(value, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  /// Maintenance table for tablet and desktop
  Widget _buildMaintenanceTable(List<Map<String, dynamic>> issues) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          width: MediaQuery.of(context).size.width,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.grey.shade200),
            columns: const [
              DataColumn(label: Text('Title')),
              DataColumn(label: Text('Issue Date')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Priority')),
              DataColumn(label: Text('Assigned')),
            ],
            rows: issues.map((issue) {
              return DataRow(
                cells: [
                  DataCell(
                    SizedBox(
                      width: 200,
                      child: Text(
                        issue['title'],
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
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
                        color: _getPriorityColor(issue['priority']),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataCell(Text(issue['assigned'])),
                ],
              );
            }).toList(),
          ),
        ),
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
