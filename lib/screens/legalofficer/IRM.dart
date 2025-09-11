import 'package:flutter/material.dart';
import '../../models/app_user.dart';

class IncidentReportManagementScreen extends StatelessWidget {
  const IncidentReportManagementScreen({super.key, required this.user});

  final AppUser user;

  // Sample incident data
  final List<Map<String, dynamic>> incidents = const [
    {
      'unit': 'INC-001',
      'date': '2025-09-01',
      'type': 'Traffic Violation',
      'reporter': 'Juan Dela Cruz',
      'priority': 'Critical',
      'status': 'Open',
    },
    {
      'unit': 'INC-002',
      'date': '2025-09-02',
      'type': 'Passenger Misconduct',
      'reporter': 'Maria Lopez',
      'priority': 'Medium',
      'status': 'Under Investigation',
    },
    {
      'unit': 'INC-003',
      'date': '2025-09-03',
      'type': 'Overloading',
      'reporter': 'Pedro Santos',
      'priority': 'High',
      'status': 'Resolved',
    },
    {
      'unit': 'INC-004',
      'date': '2025-09-04',
      'type': 'No Valid ID',
      'reporter': 'Ana Reyes',
      'priority': 'Low',
      'status': 'Closed',
    },
    {
      'unit': 'INC-005',
      'date': '2025-09-05',
      'type': 'Smoking in Vehicle',
      'reporter': 'Carlos Gomez',
      'priority': 'Medium',
      'status': 'Open',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: const Text('Incident Report Management'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) {
                // Implement search functionality
              },
            ),
            const SizedBox(height: 16),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: true,
                    onSelected: (bool value) {},
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Open'),
                    onSelected: (bool value) {},
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Under Investigation'),
                    onSelected: (bool value) {},
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Resolved'),
                    onSelected: (bool value) {},
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Closed'),
                    onSelected: (bool value) {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Statistics Cards
            const Row(
              children: [
                Expanded(
                  child: _StatCard(title: 'Total Incidents', value: '24'),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _StatCard(title: 'Open Cases', value: '8'),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _StatCard(title: 'Resolved', value: '12'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Incidents Table Header
            const Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    'UNIT',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Date',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Type',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Reporter',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Priority',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Status',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Actions',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),

            // Incidents List
            Expanded(
              child: ListView(
                children: incidents
                    .map(
                      (incident) => _IncidentItem(
                        unit: incident['unit'],
                        date: incident['date'],
                        type: incident['type'],
                        reporter: incident['reporter'],
                        priority: incident['priority'],
                        status: incident['status'],
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add new incident functionality
        },
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IncidentItem extends StatelessWidget {
  const _IncidentItem({
    required this.unit,
    required this.date,
    required this.type,
    required this.reporter,
    required this.priority,
    required this.status,
  });

  final String unit;
  final String date;
  final String type;
  final String reporter;
  final String priority;
  final String status;

  void _showIncidentDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Incident Details - $unit'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(title: 'UNIT:', value: unit),
                _DetailRow(title: 'Date:', value: date),
                _DetailRow(title: 'Type:', value: type),
                _DetailRow(title: 'Reporter:', value: reporter),
                _DetailRow(title: 'Priority:', value: priority),
                _DetailRow(title: 'Status:', value: status),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                // Edit incident functionality
                Navigator.pop(context);
              },
              child: const Text('Edit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(flex: 1, child: Text(unit)),
            Expanded(flex: 2, child: Text(date)),
            Expanded(flex: 2, child: Text(type)),
            Expanded(flex: 2, child: Text(reporter)),
            Expanded(
              flex: 2,
              child: Text(
                priority,
                style: TextStyle(
                  color: _getPriorityColor(priority),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                status,
                style: TextStyle(
                  color: _getStatusColor(status),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: IconButton(
                icon: const Icon(Icons.more_vert, size: 20),
                onPressed: () => _showIncidentDetails(context),
              ),
            ),
          ],
        ),
        const Divider(),
      ],
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Critical':
        return Colors.red;
      case 'High':
        return Colors.orange;
      case 'Medium':
        return Colors.amber;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Open':
        return Colors.blue;
      case 'Under Investigation':
        return Colors.orange;
      case 'Resolved':
        return Colors.green;
      case 'Closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
