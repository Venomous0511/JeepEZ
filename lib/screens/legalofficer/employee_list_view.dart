import 'package:flutter/material.dart';
import '../../models/app_user.dart';

class EmployeeListViewScreen extends StatefulWidget {
  const EmployeeListViewScreen({super.key, required this.user});

  final AppUser user;

  @override
  State<EmployeeListViewScreen> createState() => _EmployeeListViewScreenState();
}

class _EmployeeListViewScreenState extends State<EmployeeListViewScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, String>> employees = [
    {
      'name': 'Mj Cupburger',
      'joiningDate': 'June 5 2019',
      'dateOfBirth': 'May 2 1995',
      'violation': 'aylkafarlehea',
      'status': 'Active',
    },
    {
      'name': 'Jaenin Cruz',
      'joiningDate': 'May 3 2017',
      'dateOfBirth': 'June 6 1990',
      'violation': 'Gmail.com',
      'status': 'Active',
    },
    {
      'name': 'Gwen De Castro',
      'joiningDate': 'August 10 2014',
      'dateOfBirth': 'July 21 1988',
      'violation': 'Gmail.com',
      'status': 'Active',
    },
    {
      'name': 'Aeon evans',
      'joiningDate': 'March 19 2021',
      'dateOfBirth': 'September 22 1992',
      'violation': 'Gmail.com',
      'status': 'Active',
    },
    {
      'name': 'Melisiza Florez',
      'joiningDate': 'May 7 2013',
      'dateOfBirth': 'August 22 1995',
      'violation': 'Gmail.com',
      'status': 'Active',
    },
    {
      'name': 'Jariel Calta',
      'joiningDate': 'September 2 2016',
      'dateOfBirth': 'June 4 1998',
      'violation': 'Gmail.com',
      'status': 'Active',
    },
    {
      'name': 'Ashanti Dadivo',
      'joiningDate': 'November 19 2014',
      'dateOfBirth': 'May 23 1990',
      'violation': 'Gmail.com',
      'status': 'Active',
    },
    {
      'name': 'Russelie Almario',
      'joiningDate': 'December 2 2015',
      'dateOfBirth': 'July 22 1989',
      'violation': 'Gmail.com',
      'status': 'Active',
    },
    {
      'name': 'Jenny Tangq',
      'joiningDate': 'October 19 2010',
      'dateOfBirth': 'March 15 1990',
      'violation': 'Gmail.com',
      'status': 'Active',
    },
    {
      'name': 'Juan Sunbiaki',
      'joiningDate': 'June 29 2012',
      'dateOfBirth': 'June 25 1991',
      'violation': 'Gmail.com',
      'status': 'Active',
    },
    {
      'name': 'Selen Iowi Megiboo',
      'joiningDate': 'July 23 2018',
      'dateOfBirth': 'May 27 1999',
      'violation': 'Gmail.com',
      'status': 'Active',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF0D2364),
        title: const Text('Employee List View (View-only)'),
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        color: Colors.grey[100],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Header
            const Text(
              'Search',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search employee name...',
                prefixIcon: const Icon(Icons.search, color: Colors.indigo),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF0D2364)),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) {
                // Implement search functionality here
              },
            ),
            const SizedBox(height: 24),

            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.indigo[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Employee Name',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D2364),
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Joining Date',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D2364),
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Date of Birth',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Violation',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D2364),
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Status',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),

            // Employees List with horizontal scrolling
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 16,
                    headingRowColor: WidgetStateProperty.all(Colors.indigo[50]),
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Employee Name',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Joining Date',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Date of Birth',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Violation',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Status',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    rows: employees.map((employee) {
                      return DataRow(
                        cells: [
                          DataCell(Text(employee['name']!)),
                          DataCell(Text(employee['joiningDate']!)),
                          DataCell(Text(employee['dateOfBirth']!)),
                          DataCell(Text(employee['violation']!)),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: employee['status'] == 'Active'
                                    ? Colors.green[50]
                                    : Colors.red[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: employee['status'] == 'Active'
                                      ? Colors.green
                                      : Colors.red,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                employee['status']!,
                                style: TextStyle(
                                  color: employee['status'] == 'Active'
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
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
          ],
        ),
      ),
    );
  }
}
