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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2364),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Employee List View (View-only)',
            style: TextStyle(color: Colors.white, fontSize: isMobile ? 16 : 20),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Header
            Text(
              'Search',
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isMobile ? 12 : 16),

            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search employee name...',
                hintStyle: TextStyle(fontSize: isMobile ? 14 : 16),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF0D2364)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Color(0xFF0D2364),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: isMobile ? 12 : 16,
                  horizontal: 16,
                ),
              ),
              onChanged: (value) {
                // Implement search functionality here
              },
            ),
            SizedBox(height: isMobile ? 16 : 24),

            // Employee count badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0D2364).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF0D2364)),
              ),
              child: Text(
                'Total Employees: ${employees.length}',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0D2364),
                ),
              ),
            ),
            SizedBox(height: isMobile ? 12 : 16),

            // Employees List
            Expanded(
              child: isMobile
                  ? _buildEmployeeCards()
                  : _buildEmployeeTable(isTablet),
            ),
          ],
        ),
      ),
    );
  }

  // Mobile card view
  Widget _buildEmployeeCards() {
    return ListView.builder(
      itemCount: employees.length,
      itemBuilder: (context, index) {
        final employee = employees[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with name and status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            employee['name']!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D2364),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Joined: ${employee['joiningDate']!}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: employee['status'] == 'Active'
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: employee['status'] == 'Active'
                              ? Colors.green
                              : Colors.red,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        employee['status']!,
                        style: TextStyle(
                          color: employee['status'] == 'Active'
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Employee details
                _buildCardInfoRow(
                  Icons.cake,
                  'Date of Birth',
                  employee['dateOfBirth']!,
                ),
                const SizedBox(height: 8),
                _buildCardInfoRow(
                  Icons.warning_amber,
                  'Violation',
                  employee['violation']!,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Tablet/Desktop table view
  Widget _buildEmployeeTable(bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: isTablet ? 16 : 20,
            horizontalMargin: isTablet ? 12 : 16,
            dataRowMinHeight: 48,
            dataRowMaxHeight: 56,
            headingRowColor: WidgetStateProperty.all(
              const Color(0xFF0D2364).withOpacity(0.1),
            ),
            headingTextStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isTablet ? 13 : 14,
              color: const Color(0xFF0D2364),
            ),
            dataTextStyle: TextStyle(fontSize: isTablet ? 12 : 14),
            columns: const [
              DataColumn(label: Text('Employee Name')),
              DataColumn(label: Text('Joining Date')),
              DataColumn(label: Text('Date of Birth')),
              DataColumn(label: Text('Violation')),
              DataColumn(label: Text('Status')),
            ],
            rows: employees.map((employee) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      employee['name']!,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataCell(Text(employee['joiningDate']!)),
                  DataCell(Text(employee['dateOfBirth']!)),
                  DataCell(
                    Text(
                      employee['violation']!,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 10,
                      ),
                      decoration: BoxDecoration(
                        color: employee['status'] == 'Active'
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
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
                          fontSize: isTablet ? 11 : 12,
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
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
