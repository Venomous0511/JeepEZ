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
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const EmployeeListScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Employee {
  final String id;
  final String name;
  final String joiningDate;
  final String email;
  final String status;

  Employee({
    required this.id,
    required this.name,
    required this.joiningDate,
    required this.email,
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
      email: 'john.doe@company.com',
      status: 'Active',
    ),
    Employee(
      id: 'EMP002',
      name: 'Jane Smith',
      joiningDate: '2022-08-10',
      email: 'jane.smith@company.com',
      status: 'Active',
    ),
    Employee(
      id: 'EMP003',
      name: 'Robert Johnson',
      joiningDate: '2021-03-22',
      email: 'robert.j@company.com',
      status: 'Active',
    ),
    Employee(
      id: 'EMP004',
      name: 'Sarah Williams',
      joiningDate: '2023-05-30',
      email: 'sarah.w@company.com',
      status: 'Inactive',
    ),
    Employee(
      id: 'EMP005',
      name: 'Michael Brown',
      joiningDate: '2020-11-05',
      email: 'michael.b@company.com',
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withAlpha(3),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search employees...',
                            prefixIcon: Icon(Icons.search),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 12.0,
                              horizontal: 16.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D2364),
                        borderRadius: BorderRadius.circular(8.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withAlpha(3),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.filter_list),
                        onPressed: _showFilterDialog,
                        tooltip: 'Filter',
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    width: constraints.maxWidth,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withAlpha(5),
                          spreadRadius: 2,
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth - 32,
                        ),
                        padding: const EdgeInsets.all(16.0),
                        child: DataTable(
                          columnSpacing: 20,
                          headingRowColor: WidgetStateProperty.all(
                            const Color(0xFFF5F7FA),
                          ),
                          columns: const [
                            DataColumn(
                              label: SizedBox(
                                width: 100,
                                child: Text(
                                  'Employee ID',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: SizedBox(
                                width: 150,
                                child: Text(
                                  'Employee\'s Name',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: SizedBox(
                                width: 120,
                                child: Text(
                                  'Joining Date',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: SizedBox(
                                width: 200,
                                child: Text(
                                  'Email',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: SizedBox(
                                width: 100,
                                child: Text(
                                  'Status',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: SizedBox(
                                width: 120,
                                child: Text(
                                  'Actions',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                          rows: filteredEmployees.map((employee) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  SizedBox(
                                    width: 100,
                                    child: Text(employee.id),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 150,
                                    child: Text(employee.name),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 120,
                                    child: Text(employee.joiningDate),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 200,
                                    child: Text(
                                      employee.email,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: employee.status == 'Active'
                                          ? Colors.green.withAlpha(2)
                                          : Colors.red.withAlpha(2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: SizedBox(
                                      width: 100,
                                      child: Text(
                                        employee.status,
                                        style: TextStyle(
                                          color: employee.status == 'Active'
                                              ? Colors.green
                                              : Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 120,
                                    child: Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            // Edit employee action
                                          },
                                          color: Colors.blue,
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            // Deactivate employee action
                                          },
                                          color: Colors.red,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
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
