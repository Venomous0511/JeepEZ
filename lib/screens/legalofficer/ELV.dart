import 'package:flutter/material.dart';
import '../../models/app_user.dart';

class EmployeeListViewScreen extends StatelessWidget {
  const EmployeeListViewScreen({super.key, required this.user});

  final AppUser user;

  // Sample employee data based on the screenshot
  final List<Map<String, String>> employees = const [
    {
      'name': 'Mj Capbuyaw',
      'joiningDate': 'June 5 2019',
      'dateOfBirth': 'May 2 1995',
      'violation': 'safasfaefea',
      'status': 'Active',
    },
    {
      'name': 'Jaren Cruz',
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
      'name': 'Aeon evarra',
      'joiningDate': 'March 19 2021',
      'dateOfBirth': 'September 22 1992',
      'violation': 'Gmail.com',
      'status': 'Active',
    },
    {
      'name': 'Melatza Florez',
      'joiningDate': 'May 7 2013',
      'dateOfBirth': 'August 22 1995',
      'violation': 'Gmail.com',
      'status': 'Active',
    },
    {
      'name': 'Jeriel Celts',
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
      'name': 'Russele Almario',
      'joiningDate': 'December 2 2015',
      'dateOfBirth': 'July 22 1985',
      'violation': 'Gmail.com',
      'status': 'Active',
    },
    {
      'name': 'Jenny Tarog',
      'joiningDate': 'October 19 2010',
      'dateOfBirth': 'March 15 1990',
      'violation': 'Gmail.com',
      'status': 'Active',
    },
    {
      'name': 'Jian Simblabi',
      'joiningDate': 'June 29 2012',
      'dateOfBirth': 'June 25 1991',
      'violation': 'Gmail.com',
      'status': 'Active',
    },
    {
      'name': 'Sean Iowi Magboo',
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
        backgroundColor: Colors.indigo,
        title: const Text('Employee List View (View-only)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
              decoration: InputDecoration(
                hintText: 'Search employee name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) {
                // Implement search functionality here
              },
            ),
            const SizedBox(height: 24),

            // Table Header
            const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Employees Name',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Joining Date',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Date of Birth',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Violation',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Status',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),

            // Employees List
            Expanded(
              child: ListView(
                children: employees
                    .map(
                      (employee) => _EmployeeItem(
                        name: employee['name']!,
                        joiningDate: employee['joiningDate']!,
                        dateOfBirth: employee['dateOfBirth']!,
                        violation: employee['violation']!,
                        status: employee['status']!,
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmployeeItem extends StatelessWidget {
  const _EmployeeItem({
    required this.name,
    required this.joiningDate,
    required this.dateOfBirth,
    required this.violation,
    required this.status,
  });

  final String name;
  final String joiningDate;
  final String dateOfBirth;
  final String violation;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(flex: 2, child: Text(name)),
            Expanded(flex: 2, child: Text(joiningDate)),
            Expanded(flex: 2, child: Text(dateOfBirth)),
            Expanded(flex: 2, child: Text(violation)),
            Expanded(
              flex: 1,
              child: Text(
                status,
                style: TextStyle(
                  color: status == 'Active' ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const Divider(),
      ],
    );
  }
}
