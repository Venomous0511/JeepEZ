import 'package:flutter/material.dart';

class DriverConductorManagementScreen extends StatefulWidget {
  const DriverConductorManagementScreen({super.key});

  @override
  State<DriverConductorManagementScreen> createState() =>
      _DriverConductorManagementScreenState();
}

class _DriverConductorManagementScreenState
    extends State<DriverConductorManagementScreen> {
  final TextEditingController searchCtrl = TextEditingController();
  String searchQuery = '';

  final List<Map<String, String>> employeeData = [
    {
      'name': 'Tom',
      'role': 'Driver',
      'schedule': 'Mon–Fri, 6AM–2PM',
      'performance': 'Excellent',
    },
    {
      'name': 'Mj',
      'role': 'Conductor',
      'schedule': 'Mon–Fri, 6AM–2PM',
      'performance': 'Good',
    },
    {
      'name': 'Jian',
      'role': 'Driver',
      'schedule': 'Tue–Sat, 2PM–10PM',
      'performance': 'Needs Review',
    },
    {
      'name': 'Diego',
      'role': 'Conductor',
      'schedule': 'Wed–Sun, 6AM–2PM',
      'performance': 'Excellent',
    },
    {
      'name': 'Jeriel Celis',
      'role': 'Driver',
      'schedule': 'Mon–Fri, 6AM–2PM',
      'performance': 'Outstanding',
    },
  ];

  List<Map<String, String>> get filteredData {
    if (searchQuery.isEmpty) return employeeData;
    return employeeData
        .where(
          (e) => e['name']!.toLowerCase().contains(searchQuery.toLowerCase()),
        )
        .toList();
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          final fontSize = isMobile ? 14.0 : 16.0;
          final padding = isMobile ? 8.0 : 12.0;

          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🔍 Search Bar
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

                /// 📋 Table Header + Rows
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    children: [
                      /// Header
                      Container(
                        color: Colors.blue[50],
                        padding: EdgeInsets.symmetric(vertical: padding),
                        child: Row(
                          children: [
                            _headerCell("Name", 150, fontSize),
                            _headerCell("Role", 100, fontSize),
                            _headerCell("Schedule", 200, fontSize),
                            _headerCell("Performance", 120, fontSize),
                          ],
                        ),
                      ),

                      /// Rows
                      ...filteredData.map((e) {
                        final index = filteredData.indexOf(e);
                        final bgColor = index % 2 == 0
                            ? Colors.white
                            : Colors.grey[100];

                        return Container(
                          color: bgColor,
                          padding: EdgeInsets.symmetric(vertical: padding),
                          child: Row(
                            children: [
                              _dataCell(e['name'], 150, fontSize),
                              _dataCell(e['role'], 100, fontSize),
                              _dataCell(e['schedule'], 200, fontSize),
                              _dataCell(e['performance'], 120, fontSize),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _headerCell(String text, double width, double fontSize) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
      ),
    );
  }

  Widget _dataCell(String? text, double width, double fontSize) {
    return SizedBox(
      width: width,
      child: Text(
        text ?? '',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: fontSize),
      ),
    );
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }
}
