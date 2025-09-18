import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Employee List Management',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const EmployeeListScreen(),
    );
  }
}

class Employee {
  final String id;
  final String name;
  final String joiningDate;
  final String dateOfBirth;
  final String email;
  final String position;
  final String status;

  Employee({
    required this.id,
    required this.name,
    required this.joiningDate,
    required this.dateOfBirth,
    required this.email,
    required this.position,
    required this.status,
  });
}

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  final List<Employee> employees = [
    Employee(
      id: 'EMP001',
      name: 'John Doe',
      joiningDate: '2023-01-15',
      dateOfBirth: '1990-05-20',
      email: 'john.doe@company.com',
      position: 'Developer',
      status: 'Active',
    ),
    Employee(
      id: 'EMP002',
      name: 'Jane Smith',
      joiningDate: '2022-08-10',
      dateOfBirth: '1988-12-05',
      email: 'jane.smith@company.com',
      position: 'Designer',
      status: 'Active',
    ),
    Employee(
      id: 'EMP003',
      name: 'Robert Johnson',
      joiningDate: '2021-03-22',
      dateOfBirth: '1992-07-14',
      email: 'robert.j@company.com',
      position: 'Manager',
      status: 'Active',
    ),
    Employee(
      id: 'EMP004',
      name: 'Sarah Williams',
      joiningDate: '2023-05-30',
      dateOfBirth: '1995-02-18',
      email: 'sarah.w@company.com',
      position: 'Analyst',
      status: 'Inactive',
    ),
    Employee(
      id: 'EMP005',
      name: 'Michael Brown',
      joiningDate: '2020-11-05',
      dateOfBirth: '1987-09-30',
      email: 'michael.b@company.com',
      position: 'Developer',
      status: 'Active',
    ),
  ];

  List<Employee> filteredEmployees = [];
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredEmployees = employees;
    searchController.addListener(_filterEmployees);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _filterEmployees() {
    final query = searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredEmployees = employees;
      } else {
        filteredEmployees = employees.where((employee) {
          return employee.name.toLowerCase().contains(query) ||
              employee.email.toLowerCase().contains(query) ||
              employee.position.toLowerCase().contains(query) ||
              employee.id.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String selectedFilter = 'Name';
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Filter By'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile(
                    title: const Text('Name'),
                    value: 'Name',
                    groupValue: selectedFilter,
                    onChanged: (value) {
                      setState(() {
                        selectedFilter = value.toString();
                      });
                    },
                  ),
                  RadioListTile(
                    title: const Text('Position'),
                    value: 'Position',
                    groupValue: selectedFilter,
                    onChanged: (value) {
                      setState(() {
                        selectedFilter = value.toString();
                      });
                    },
                  ),
                  RadioListTile(
                    title: const Text('Status'),
                    value: 'Status',
                    groupValue: selectedFilter,
                    onChanged: (value) {
                      setState(() {
                        selectedFilter = value.toString();
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Implement filter logic based on selectedFilter
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee List Management'),
        backgroundColor: const Color(0xFF0D2364),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search employees...',
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
                const SizedBox(width: 8.0),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _showFilterDialog,
                  tooltip: 'Filter',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF0D2364),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16.0),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
                columns: const [
                  DataColumn(label: Text('Employee ID')),
                  DataColumn(label: Text('Employee\'s Name')),
                  DataColumn(label: Text('Joining Date')),
                  DataColumn(label: Text('Date of Birth')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Position')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: filteredEmployees.map((employee) {
                  return DataRow(
                    cells: [
                      DataCell(Text(employee.id)),
                      DataCell(Text(employee.name)),
                      DataCell(Text(employee.joiningDate)),
                      DataCell(Text(employee.dateOfBirth)),
                      DataCell(Text(employee.email)),
                      DataCell(Text(employee.position)),
                      DataCell(
                        Text(
                          employee.status,
                          style: TextStyle(
                            color: employee.status == 'Active'
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () {
                                // Edit employee action
                              },
                              color: Colors.blue,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              onPressed: () {
                                // Deactivate employee action
                              },
                              color: Colors.red,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add new employee action
        },
        backgroundColor: const Color(0xFF0D2364),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
