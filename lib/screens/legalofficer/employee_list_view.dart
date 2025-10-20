import 'package:cloud_firestore/cloud_firestore.dart';
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
  int _rowsPerPage = 10;
  int _currentPage = 0;

  /// ----------- ROLE COLOR FUNCTION -----------
  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'legal_officer':
        return Colors.orange;
      case 'driver':
        return Colors.green;
      case 'conductor':
        return Colors.blue;
      case 'inspector':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search employees by name or email...',
                hintStyle: const TextStyle(fontSize: 14),
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
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Table Section
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('status', isEqualTo: true)
                    .where(
                      'role',
                      whereIn: ['driver', 'conductor', 'inspector'],
                    )
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final docs = snapshot.data?.docs ?? [];

                  final employees = docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return {
                      'name': data['name'] ?? '',
                      'email': data['email'] ?? '',
                      'employeeId': data['employeeId'] ?? 'N/A',
                      'role': data['role'] ?? 'N/A',
                      'employmentType': data['employmentType'] ?? 'N/A',
                      'status': (data['status'] == true)
                          ? 'Active'
                          : 'Inactive',
                    };
                  }).toList();

                  final search = _searchController.text.toLowerCase();
                  final filteredEmployees = employees.where((emp) {
                    return emp['name']!.toLowerCase().contains(search) ||
                        emp['email']!.toLowerCase().contains(search);
                  }).toList();

                  if (filteredEmployees.isEmpty) {
                    return const Center(child: Text('No employees found.'));
                  }

                  final totalPages = (filteredEmployees.length / _rowsPerPage)
                      .ceil();
                  final startIndex = _currentPage * _rowsPerPage;
                  final endIndex = startIndex + _rowsPerPage;
                  final paginatedEmployees = filteredEmployees.sublist(
                    startIndex,
                    endIndex > filteredEmployees.length
                        ? filteredEmployees.length
                        : endIndex,
                  );

                  return isMobile
                      ? _buildEmployeeCards(paginatedEmployees)
                      : Column(
                          children: [
                            // Table
                            Expanded(
                              child: _buildEmployeeTable(paginatedEmployees),
                            ),
                            // Pagination
                            _buildPaginationControls(
                              totalPages,
                              filteredEmployees.length,
                            ),
                          ],
                        );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Mobile card view
  Widget _buildEmployeeCards(List<Map<String, dynamic>> employees) {
    return ListView.builder(
      itemCount: employees.length,
      itemBuilder: (context, index) {
        final emp = employees[index];
        final role = emp['role']?.toString() ?? '';
        final roleColor = _getRoleColor(role);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            emp['name']!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D2364),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Employee ID: ${emp['employeeId']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(emp['status']!),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                _buildCardInfoRow(Icons.email, 'Email', emp['email']!),
                const SizedBox(height: 8),
                _buildCardInfoRow(
                  Icons.person,
                  'Role',
                  emp['role']!,
                  valueColor: roleColor,
                ),
                const SizedBox(height: 8),
                _buildCardInfoRow(
                  Icons.cases_outlined,
                  'Employment Type',
                  emp['employmentType']!,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: valueColor != null
                    ? BoxDecoration(
                        color: valueColor.withAlpha(1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: valueColor.withAlpha(3)),
                      )
                    : null,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: valueColor ?? Colors.black87,
                    fontWeight: valueColor != null
                        ? FontWeight.w600
                        : FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Desktop table view
  Widget _buildEmployeeTable(List<Map<String, dynamic>> employees) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          // Table Header
          Container(
            height: 50,
            decoration: const BoxDecoration(
              color: Color(0xFF0D2364),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Expanded(flex: 1, child: _TableHeader(text: 'NO.')),
                Expanded(flex: 2, child: _TableHeader(text: 'EMPLOYEE ID')),
                Expanded(flex: 3, child: _TableHeader(text: 'NAME')),
                Expanded(flex: 4, child: _TableHeader(text: 'EMAIL')),
                Expanded(flex: 2, child: _TableHeader(text: 'ROLE')),
                Expanded(flex: 2, child: _TableHeader(text: 'EMPLOYEE TYPE')),
                Expanded(flex: 2, child: _TableHeader(text: 'STATUS')),
              ],
            ),
          ),

          // Table Body
          Expanded(
            child: Container(
              color: Colors.white,
              child: ListView.builder(
                itemCount: employees.length,
                itemBuilder: (context, index) {
                  final emp = employees[index];
                  final role = emp['role']?.toString() ?? '';
                  final roleColor = _getRoleColor(role);

                  return Container(
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: _TableCell(
                            content:
                                '${_currentPage * _rowsPerPage + index + 1}',
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: _TableCell(
                            content: emp['employeeId']?.toString() ?? 'N/A',
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: _TableCell(
                            content: emp['name']?.toString() ?? '',
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: _TableCell(
                            content: emp['email']?.toString() ?? 'N/A',
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: roleColor.withAlpha(1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: roleColor.withAlpha(3),
                                  ),
                                ),
                                child: Text(
                                  emp['role']?.toString() ?? 'N/A',
                                  style: TextStyle(
                                    color: roleColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: _TableCell(
                            content: emp['employmentType']?.toString() ?? 'N/A',
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Center(
                              child: _buildStatusBadge(
                                emp['status']?.toString() ?? 'Inactive',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls(int totalPages, int totalItems) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[300]!,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total: $totalItems employees',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),

          Row(
            children: [
              const Text('Rows per page:', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _rowsPerPage,
                items: [10, 20, 50].map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text('$value'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _rowsPerPage = value!;
                    _currentPage = 0;
                  });
                },
              ),
              const SizedBox(width: 16),

              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20),
                onPressed: _currentPage > 0
                    ? () {
                        setState(() {
                          _currentPage--;
                        });
                      }
                    : null,
              ),

              Text(
                'Page ${_currentPage + 1} of $totalPages',
                style: const TextStyle(fontSize: 14),
              ),

              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                onPressed: _currentPage < totalPages - 1
                    ? () {
                        setState(() {
                          _currentPage++;
                        });
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isActive = status == 'Active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: isActive ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
          fontSize: 11,
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

// Custom Table Header Widget
class _TableHeader extends StatelessWidget {
  final String text;

  const _TableHeader({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

// Custom Table Cell Widget
class _TableCell extends StatelessWidget {
  final String content;

  const _TableCell({required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Center(
        child: Text(
          content,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
