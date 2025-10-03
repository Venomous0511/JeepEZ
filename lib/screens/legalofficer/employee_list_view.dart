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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;
    final maxContentWidth = isDesktop ? 1400.0 : double.infinity;

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
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          padding: EdgeInsets.all(isMobile ? 12.0 : (isTablet ? 20.0 : 24.0)),
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
                  hintText: 'Search employees by name or email...',
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
                ),
                onChanged: (_) => setState(() {}),
              ),
              SizedBox(height: isMobile ? 16 : 24),

              // Realtime data from Firestore
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('status', isEqualTo: true)
                      .where('role', whereIn: ['driver', 'conductor', 'inspector'])
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final docs = snapshot.data?.docs ?? [];

                    // ✅ Convert Firestore docs to a list of Map<String, dynamic>
                    final employees = docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return {
                        'name': data['name'] ?? '',
                        'email': data['email'] ?? '',
                        'employeeId': data['employeeId'] ?? 'N/A',
                        'role': data['role'] ?? 'N/A',
                        'employmentType': data['employmentType'] ?? 'N/A',
                        'joiningDate': data['createdAt'] != null
                            ? (data['createdAt'] as Timestamp)
                            .toDate()
                            .toLocal()
                            .toString()
                            .split(' ')[0]
                            : 'N/A',
                        'dateOfBirth': data['dateOfBirth'] ?? 'N/A',
                        'violation': data['violation'] ?? 'None',
                        'status': (data['status'] == true) ? 'Active' : 'Inactive',
                      };
                    }).toList();

                    // ✅ Apply search filter
                    final search = _searchController.text.toLowerCase();
                    final filteredEmployees = employees.where((emp) {
                      return emp['name']!.toLowerCase().contains(search) ||
                          emp['email']!.toLowerCase().contains(search);
                    }).toList();

                    if (filteredEmployees.isEmpty) {
                      return const Center(child: Text('No employees found.'));
                    }

                    return isMobile
                        ? _buildEmployeeCards(filteredEmployees)
                        : _buildEmployeeTable(filteredEmployees, isTablet, isDesktop);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Mobile card view (unchanged layout)
  Widget _buildEmployeeCards(List<Map<String, dynamic>> employees) {
    return ListView.builder(
      itemCount: employees.length,
      itemBuilder: (context, index) {
        final emp = employees[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
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
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                _buildCardInfoRow(Icons.email, 'Gmail Account', emp['email']!),
                const SizedBox(height: 8),
                _buildCardInfoRow(Icons.person, 'Role', emp['role']!),
                const SizedBox(height: 8),
                _buildCardInfoRow(Icons.cases_outlined, 'Employment Type', emp['employmentType']!),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Tablet/Desktop table view (unchanged layout)
  Widget _buildEmployeeTable(
      List<Map<String, dynamic>> employees, bool isTablet, bool isDesktop) {
    return Center(
      child:  Container(
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
              columnSpacing: 40,
              headingRowColor: WidgetStateProperty.all(
                const Color(0xFF0D2364),
              ),
              headingTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              columns: const [
                DataColumn(label: Text('Employee Name')),
                DataColumn(label: Text('Employee ID')),
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Role')),
                DataColumn(label: Text('Employment Type')),
                DataColumn(label: Text('Status')),
              ],
              rows: employees.map((emp) {
                return DataRow(
                  cells: [
                    DataCell(Text(emp['name']?.toString() ?? '')),
                    DataCell(Text(emp['employeeId']?.toString() ?? 'N/A')),
                    DataCell(Text(emp['email']?.toString() ?? 'N/A')),
                    DataCell(Text(emp['role']?.toString() ?? 'N/A')),
                    DataCell(Text(emp['employmentType']?.toString() ?? 'N/A')),
                    DataCell(_buildStatusBadge(emp['status']?.toString() ?? 'Inactive')),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isActive = status == 'Active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withAlpha(1) : Colors.red.withAlpha(1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isActive ? Colors.green : Colors.red, width: 1.5),
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
