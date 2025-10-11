import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../firebase_options.dart';
import '../../models/app_user.dart';
import 'dart:math';

class EmployeeListScreen extends StatefulWidget {
  final AppUser user;
  const EmployeeListScreen({super.key, required this.user});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  final TextEditingController searchController = TextEditingController();
  int _currentPage = 0;
  final int _pageSize = 10;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  /// ----------- GET AND CREATE SECONDARY FUNCTION -----------
  Future<FirebaseApp> _getOrCreateSecondaryApp() async {
    try {
      return Firebase.app('adminSecondary');
    } catch (_) {
      return await Firebase.initializeApp(
        name: 'adminSecondary',
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }

  /// ----------- GENERATE EMPLOYEE ID FUNCTION -----------
  Future<String> _generateEmployeeId(String role) async {
    final Map<String, String> rolePrefixes = {
      'legal_officer': '20',
      'driver': '30',
      'conductor': '40',
      'inspector': '50',
    };

    final prefix = rolePrefixes[role] ?? '99';

    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('employeeId', isGreaterThanOrEqualTo: prefix)
        .where('employeeId', isLessThan: '${prefix}999999')
        .orderBy('employeeId', descending: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      return '${prefix}001';
    } else {
      final lastId = query.docs.first['employeeId'] as String;
      final lastNum = int.tryParse(lastId) ?? int.parse('${prefix}000');
      return (lastNum + 1).toString().padLeft(5, '0');
    }
  }

  /// ----------- GENERATE PASSWORD FUNCTION -----------
  String _generatePassword() {
    const String upperCase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const String lowerCase = 'abcdefghijklmnopqrstuvwxyz';
    const String numbers = '0123456789';
    const String specialChars = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

    final random = Random();
    String password = '';

    password += upperCase[random.nextInt(upperCase.length)];
    password += lowerCase[random.nextInt(lowerCase.length)];
    password += numbers[random.nextInt(numbers.length)];
    password += specialChars[random.nextInt(specialChars.length)];

    const allChars = upperCase + lowerCase + numbers + specialChars;
    for (int i = 0; i < 8; i++) {
      password += allChars[random.nextInt(allChars.length)];
    }

    final passwordList = password.split('')..shuffle();
    return passwordList.join();
  }

  /// ----------- VALIDATE GMAIL FUNCTION -----------
  bool _isValidGmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$');
    return emailRegex.hasMatch(email);
  }

  /// ----------- VALIDATE NAME FUNCTION -----------
  String? _validateName(String name, String fieldName) {
    if (name.isEmpty) {
      return '$fieldName is required';
    }
    if (name.length > 20) {
      return '$fieldName must be 20 characters or less';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(name)) {
      return '$fieldName can only contain letters and spaces';
    }
    return null;
  }

  /// ----------- FILTER NAME INPUT (NO NUMBERS) -----------
  String _filterNameInput(String input) {
    return input.replaceAll(RegExp(r'[^a-zA-Z\s]'), '');
  }

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

  // Get paginated employee documents
  List<QueryDocumentSnapshot> _getPaginatedEmployees(
    List<QueryDocumentSnapshot> allEmployees,
  ) {
    final startIndex = _currentPage * _pageSize;
    final endIndex = startIndex + _pageSize;

    if (startIndex >= allEmployees.length) {
      return [];
    }

    if (endIndex > allEmployees.length) {
      return allEmployees.sublist(startIndex);
    }

    return allEmployees.sublist(startIndex, endIndex);
  }

  // Get total pages
  int _getTotalPages(int totalEmployees) {
    return (totalEmployees / _pageSize).ceil();
  }

  // Build pagination controls
  Widget _buildPaginationControls(int totalEmployees) {
    final totalPages = _getTotalPages(totalEmployees);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 16),
            onPressed: _currentPage > 0
                ? () {
                    setState(() {
                      _currentPage--;
                    });
                  }
                : null,
          ),

          for (int i = 0; i < totalPages; i++)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _currentPage = i;
                  });
                },
                style: TextButton.styleFrom(
                  backgroundColor: _currentPage == i
                      ? const Color(0xFF0D2364)
                      : Colors.transparent,
                  foregroundColor: _currentPage == i
                      ? Colors.white
                      : const Color(0xFF0D2364),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: BorderSide(
                      color: _currentPage == i
                          ? const Color(0xFF0D2364)
                          : Colors.grey.shade300,
                    ),
                  ),
                  minimumSize: const Size(36, 36),
                ),
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    fontWeight: _currentPage == i
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),

          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---------------- SEARCH BAR ----------------
            Container(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withAlpha(40),
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
                  onChanged: (_) {
                    setState(() {
                      _currentPage = 0;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ---------------- MAIN CONTENT ----------------
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where(
                        'role',
                        whereIn: [
                          'legal_officer',
                          'driver',
                          'conductor',
                          'inspector',
                        ],
                      )
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snap.hasData || snap.data!.docs.isEmpty) {
                      return const Center(child: Text('No users yet.'));
                    }

                    var employeeDocs = snap.data!.docs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      return data['status'] == true;
                    }).toList();

                    final query = searchController.text.toLowerCase();
                    if (query.isNotEmpty) {
                      employeeDocs = employeeDocs.where((d) {
                        final data = d.data() as Map<String, dynamic>;
                        final name = (data['name'] ?? '')
                            .toString()
                            .toLowerCase();
                        final email = (data['email'] ?? '')
                            .toString()
                            .toLowerCase();
                        final empId = (data['employeeId'] ?? '')
                            .toString()
                            .toLowerCase();
                        return name.contains(query) ||
                            email.contains(query) ||
                            empId.contains(query);
                      }).toList();
                    }

                    if (employeeDocs.isEmpty) {
                      return const Center(
                        child: Text('No employees match your search.'),
                      );
                    }

                    final paginatedEmployees = _getPaginatedEmployees(
                      employeeDocs,
                    );

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Showing ${paginatedEmployees.length} of ${employeeDocs.length} employees',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ),

                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final bool isMobile = constraints.maxWidth < 600;
                              final bool isTablet = constraints.maxWidth < 900;

                              if (isMobile) {
                                return _buildMobileList(paginatedEmployees);
                              } else if (isTablet) {
                                return _buildTabletView(paginatedEmployees);
                              } else {
                                return _buildDesktopView(paginatedEmployees);
                              }
                            },
                          ),
                        ),

                        _buildPaginationControls(employeeDocs.length),
                      ],
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        backgroundColor: const Color(0xFF0D2364),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Mobile View - Card List
  Widget _buildMobileList(List<QueryDocumentSnapshot> employeeDocs) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: employeeDocs.length,
      itemBuilder: (context, index) {
        final doc = employeeDocs[index];
        final data = doc.data() as Map<String, dynamic>;
        final displayNumber = (_currentPage * _pageSize) + index + 1;
        final role = data['role'] ?? '';
        final roleColor = _getRoleColor(role);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: roleColor.withOpacity(0.2),
                      child: Text(
                        data['name']?.toString().isNotEmpty == true
                            ? data['name']
                                  .toString()
                                  .substring(0, 1)
                                  .toUpperCase()
                            : 'U',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: roleColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['name'] ?? 'No Name',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '$displayNumber. ${data['employeeId']?.toString() ?? 'N/A'}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: data['status'] == true
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: data['status'] == true
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      child: Text(
                        data['status'] == true ? "Active" : "Inactive",
                        style: TextStyle(
                          color: data['status'] == true
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                _buildMobileDetailRow("No.", displayNumber.toString()),
                _buildMobileDetailRow(
                  "Employee ID",
                  data['employeeId'] ?? 'N/A',
                ),
                _buildMobileDetailRow("Email", data['email'] ?? 'N/A'),
                _buildMobileDetailRow(
                  "Role",
                  _capitalizeRole(role),
                  valueColor: roleColor,
                ),
                if (data['employmentType'] != null)
                  _buildMobileDetailRow(
                    "Employment Type",
                    _capitalizeEmploymentType(data['employmentType']),
                  ),

                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editUser(doc.id, data),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteUser(doc.id, data),
                      ),
                    ),
                  ],
                ),
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
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.grey[700],
                fontSize: 14,
                fontWeight: valueColor != null
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tablet View - Compact DataTable
  Widget _buildTabletView(List<QueryDocumentSnapshot> employeeDocs) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.only(bottom: 16),
          child: DataTable(
            columnSpacing: 12,
            horizontalMargin: 8,
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF5F7FA)),
            columns: const [
              DataColumn(label: Text("No.")),
              DataColumn(label: Text("Employee ID")),
              DataColumn(label: Text("Name")),
              DataColumn(label: Text("Status")),
              DataColumn(label: Text("Email")),
              DataColumn(label: Text("Role")),
              DataColumn(label: Text("Actions")),
            ],
            rows: employeeDocs.asMap().entries.map((entry) {
              final index = entry.key;
              final doc = entry.value;
              final data = doc.data() as Map<String, dynamic>;
              final displayNumber = (_currentPage * _pageSize) + index + 1;
              return _buildDataRow(
                doc.id,
                data,
                displayNumber,
                isCompact: true,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  /// Desktop View - Full DataTable
  Widget _buildDesktopView(List<QueryDocumentSnapshot> employeeDocs) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.only(bottom: 16),
          child: DataTable(
            columnSpacing: 20,
            horizontalMargin: 12,
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF5F7FA)),
            columns: const [
              DataColumn(label: Text("No.")),
              DataColumn(label: Text("Employee ID")),
              DataColumn(label: Text("Employee Name")),
              DataColumn(label: Text("Status")),
              DataColumn(label: Text("Email")),
              DataColumn(label: Text("Role")),
              DataColumn(label: Text("Actions")),
            ],
            rows: employeeDocs.asMap().entries.map((entry) {
              final index = entry.key;
              final doc = entry.value;
              final data = doc.data() as Map<String, dynamic>;
              final displayNumber = (_currentPage * _pageSize) + index + 1;
              return _buildDataRow(
                doc.id,
                data,
                displayNumber,
                isCompact: false,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  /// Helper method to build DataRows for both tablet and desktop
  DataRow _buildDataRow(
    String docId,
    Map<String, dynamic> data,
    int displayNumber, {
    bool isCompact = false,
  }) {
    final role = data['role'] ?? '';
    final roleColor = _getRoleColor(role);

    return DataRow(
      cells: [
        DataCell(
          Text(
            displayNumber.toString(),
            style: isCompact ? const TextStyle(fontSize: 12) : null,
          ),
        ),
        DataCell(
          Text(
            data['employeeId'].toString(),
            style: isCompact ? const TextStyle(fontSize: 12) : null,
          ),
        ),
        DataCell(
          Text(
            data['name'] ?? '',
            style: isCompact ? const TextStyle(fontSize: 12) : null,
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: data['status'] == true
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: data['status'] == true ? Colors.green : Colors.red,
              ),
            ),
            child: Text(
              data['status'] == true ? "Active" : "Inactive",
              style: TextStyle(
                color: data['status'] == true ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: isCompact ? 11 : 12,
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            data['email'] ?? '',
            style: isCompact ? const TextStyle(fontSize: 12) : null,
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: roleColor.withOpacity(0.3)),
            ),
            child: Text(
              _capitalizeRole(role),
              style: TextStyle(
                color: roleColor,
                fontWeight: FontWeight.w600,
                fontSize: isCompact ? 11 : 12,
              ),
            ),
          ),
        ),
        DataCell(
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.edit,
                    color: Colors.blue,
                    size: isCompact ? 18 : 20,
                  ),
                  onPressed: () => _editUser(docId, data),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.delete,
                    color: Colors.red,
                    size: isCompact ? 18 : 20,
                  ),
                  onPressed: () => _deleteUser(docId, data),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _capitalizeRole(String role) {
    if (role.isEmpty) return '';
    final parts = role.split('_');
    return parts
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  String _capitalizeEmploymentType(String? employmentType) {
    if (employmentType == null) return '';
    return employmentType
        .split('_')
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  /// ---------------- ADD NEW USER (UPDATED TO MATCH SUPER-ADMIN) ----------------
  Future<void> _showAddUserDialog() async {
    final TextEditingController emailCtrl = TextEditingController();
    final TextEditingController firstNameCtrl = TextEditingController();
    final TextEditingController middleNameCtrl = TextEditingController();
    final TextEditingController lastNameCtrl = TextEditingController();

    bool loading = false;
    String? role;
    bool obscurePassword = true;
    String generatedPassword = _generatePassword();
    String? employmentType;
    String? area;

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final roleColor = role != null ? _getRoleColor(role!) : Colors.grey;

            return AlertDialog(
              title: const Text('Create User'),
              content: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // First Name Field
                      TextField(
                        controller: firstNameCtrl,
                        maxLength: 20,
                        decoration: const InputDecoration(
                          labelText: 'First Name',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          counterText: "",
                        ),
                        onChanged: (value) {
                          final filteredValue = _filterNameInput(value);
                          if (filteredValue != value) {
                            firstNameCtrl.value = firstNameCtrl.value.copyWith(
                              text: filteredValue,
                              selection: TextSelection.collapsed(
                                offset: filteredValue.length,
                              ),
                            );
                          }
                        },
                      ),

                      const SizedBox(height: 12),

                      // Middle Name Field
                      TextField(
                        controller: middleNameCtrl,
                        maxLength: 20,
                        decoration: const InputDecoration(
                          labelText: 'Middle Name (Optional)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          counterText: "",
                        ),
                        onChanged: (value) {
                          final filteredValue = _filterNameInput(value);
                          if (filteredValue != value) {
                            middleNameCtrl.value = middleNameCtrl.value
                                .copyWith(
                                  text: filteredValue,
                                  selection: TextSelection.collapsed(
                                    offset: filteredValue.length,
                                  ),
                                );
                          }
                        },
                      ),

                      const SizedBox(height: 12),

                      // Last Name Field
                      TextField(
                        controller: lastNameCtrl,
                        maxLength: 20,
                        decoration: const InputDecoration(
                          labelText: 'Last Name',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          counterText: "",
                        ),
                        onChanged: (value) {
                          final filteredValue = _filterNameInput(value);
                          if (filteredValue != value) {
                            lastNameCtrl.value = lastNameCtrl.value.copyWith(
                              text: filteredValue,
                              selection: TextSelection.collapsed(
                                offset: filteredValue.length,
                              ),
                            );
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      TextField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),

                      const SizedBox(height: 12),

                      // Auto-generated password display
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Auto-generated Password:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    obscurePassword
                                        ? '•' * generatedPassword.length
                                        : generatedPassword,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      obscurePassword = !obscurePassword;
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'User will be required to change password on first login',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Role selection with color indicator
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: role != null ? roleColor : Colors.grey,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: DropdownButtonFormField<String>(
                          initialValue: role,
                          decoration: const InputDecoration(
                            labelText: 'Role *',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            hintText: 'Select a role',
                          ),
                          hint: const Text('Select a role'),
                          items: [
                            _buildRoleDropdownItem(
                              "legal_officer",
                              "Legal Officer",
                            ),
                            _buildRoleDropdownItem("driver", "Driver"),
                            _buildRoleDropdownItem("conductor", "Conductor"),
                            _buildRoleDropdownItem("inspector", "Inspector"),
                          ],
                          onChanged: (value) {
                            setState(() {
                              role = value;
                              employmentType = null;
                              area = null;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a role';
                            }
                            return null;
                          },
                        ),
                      ),

                      if (role != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: roleColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: roleColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _capitalizeRole(role!),
                                style: TextStyle(
                                  color: roleColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (role == "driver" ||
                          role == "conductor" ||
                          role == "inspector") ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: employmentType,
                          items: const [
                            DropdownMenuItem(
                              value: "full_time",
                              child: Text("Full-Time"),
                            ),
                            DropdownMenuItem(
                              value: "part_time",
                              child: Text("Part-Time"),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              employmentType = value;
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: "Employment Type",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],

                      if (role == "inspector") ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: area,
                          items: const [
                            DropdownMenuItem(
                              value: "Gaya Gaya",
                              child: Text("Gaya Gaya"),
                            ),
                            DropdownMenuItem(
                              value: "SM Tungko",
                              child: Text("SM Tungko"),
                            ),
                            DropdownMenuItem(
                              value: "Road 2",
                              child: Text("Road 2"),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              area = value;
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: "Area",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                          final email = emailCtrl.text.trim();
                          final firstName = firstNameCtrl.text.trim();
                          final middleName = middleNameCtrl.text.trim();
                          final lastName = lastNameCtrl.text.trim();

                          // Role validation
                          if (role == null) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please select a role'),
                                ),
                              );
                            }
                            return;
                          }

                          // Name validations
                          final firstNameError = _validateName(
                            firstName,
                            'First name',
                          );
                          if (firstNameError != null) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(firstNameError)),
                              );
                            }
                            return;
                          }

                          final lastNameError = _validateName(
                            lastName,
                            'Last name',
                          );
                          if (lastNameError != null) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(lastNameError)),
                              );
                            }
                            return;
                          }

                          if (middleName.isNotEmpty) {
                            final middleNameError = _validateName(
                              middleName,
                              'Middle name',
                            );
                            if (middleNameError != null) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(middleNameError)),
                                );
                              }
                              return;
                            }
                          }

                          // Generate display name
                          final mi = middleName.isNotEmpty
                              ? ' ${middleName[0]}.'
                              : '';
                          final displayName = '$lastName, $firstName$mi';

                          // Email validation - Gmail only
                          if (email.isEmpty) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter email address'),
                                ),
                              );
                            }
                            return;
                          }

                          if (!_isValidGmail(email)) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Only Gmail accounts are allowed',
                                  ),
                                ),
                              );
                            }
                            return;
                          }

                          setState(() => loading = true);

                          try {
                            // Generate employee ID
                            final employeeId = await _generateEmployeeId(role!);

                            // Create User In Secondary Auth Instance
                            final secondaryApp =
                                await _getOrCreateSecondaryApp();
                            final secondaryAuth = FirebaseAuth.instanceFor(
                              app: secondaryApp,
                            );

                            final newCred = await secondaryAuth
                                .createUserWithEmailAndPassword(
                                  email: email,
                                  password: generatedPassword,
                                );
                            final newUid = newCred.user!.uid;

                            // Update user profile with display name
                            await newCred.user!.updateDisplayName(displayName);

                            // Save to Firestore
                            final userData = {
                              'uid': newUid,
                              'email': email,
                              'employeeId': employeeId,
                              'firstName': firstName,
                              'middleName': middleName,
                              'lastName': lastName,
                              'name': displayName,
                              'role': role,
                              'status': true,
                              'createdAt': FieldValue.serverTimestamp(),
                              'createdBy': widget.user.email,
                              'tempPassword': generatedPassword,
                            };

                            // Add optional fields
                            if (employmentType != null) {
                              userData['employmentType'] = employmentType;
                            }
                            if (role == "inspector" && area != null) {
                              userData['area'] = area;
                            }

                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(newUid)
                                .set(userData);

                            // Create notification
                            await FirebaseFirestore.instance
                                .collection('notifications')
                                .add({
                                  'title': 'New Account Created',
                                  'message':
                                      '$displayName has been added as $role with ID $employeeId',
                                  'time': FieldValue.serverTimestamp(),
                                  'dismissed': false,
                                  'type': 'updates',
                                  'createdBy': widget.user.email,
                                });

                            await secondaryAuth.signOut();

                            if (context.mounted) {
                              Navigator.pop(dialogCtx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'User $displayName created as $role with ID $employeeId. Temporary password has been set.',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          } finally {
                            setState(() => loading = false);
                          }
                        },
                  child: loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Create User"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Helper method to build role dropdown items with colors
  DropdownMenuItem<String> _buildRoleDropdownItem(String value, String text) {
    final roleColor = _getRoleColor(value);
    return DropdownMenuItem(
      value: value,
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: roleColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }

  /// ---------------- UPDATE USER ----------------
  Future<void> _editUser(String docId, Map<String, dynamic> data) async {
    final nameCtrl = TextEditingController(text: data['name']);
    String? role = data['role'];
    String? employmentType = data['employmentType'];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final roleColor = _getRoleColor(role ?? '');

          return AlertDialog(
            title: const Text("Update User"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: "Name"),
                  ),
                  const SizedBox(height: 12),

                  // Role selection with color
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: role != null ? roleColor : Colors.grey,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DropdownButtonFormField<String>(
                      initialValue: role,
                      decoration: const InputDecoration(
                        labelText: 'Role *',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      items: [
                        _buildRoleDropdownItem(
                          "legal_officer",
                          "Legal Officer",
                        ),
                        _buildRoleDropdownItem("driver", "Driver"),
                        _buildRoleDropdownItem("conductor", "Conductor"),
                        _buildRoleDropdownItem("inspector", "Inspector"),
                      ],
                      onChanged: (value) {
                        setState(() {
                          role = value;
                          // Reset employment type when role changes
                          if (value != "driver" &&
                              value != "conductor" &&
                              value != "inspector") {
                            employmentType = null;
                          }
                        });
                      },
                    ),
                  ),

                  if (role != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: roleColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _capitalizeRole(role!),
                            style: TextStyle(
                              color: roleColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (role == 'driver' ||
                      role == 'conductor' ||
                      role == 'inspector')
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: DropdownButtonFormField<String>(
                        initialValue: employmentType,
                        items: const [
                          DropdownMenuItem(
                            value: "full_time",
                            child: Text("Full-Time"),
                          ),
                          DropdownMenuItem(
                            value: "part_time",
                            child: Text("Part-Time"),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            employmentType = value;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: "Employment Type",
                        ),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final updateData = {
                    "name": nameCtrl.text.trim(),
                    "role": role,
                    "updatedAt": FieldValue.serverTimestamp(),
                  };

                  // Only add employmentType if it exists and user has a role that should have it
                  if (employmentType != null &&
                      (role == 'driver' ||
                          role == 'conductor' ||
                          role == 'inspector')) {
                    updateData["employmentType"] = employmentType;
                  }

                  try {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(docId)
                        .update(updateData);

                    await FirebaseFirestore.instance
                        .collection('notifications')
                        .add({
                          'title': 'Updated Account',
                          'message':
                              'Updated account for ${nameCtrl.text.trim()}',
                          'time': FieldValue.serverTimestamp(),
                          'dismissed': false,
                          'type': 'updates',
                          'createdBy': widget.user.email,
                        });

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Updated ${nameCtrl.text.trim()} successfully",
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error updating user: $e")),
                      );
                    }
                  }
                },
                child: const Text("Update"),
              ),
            ],
          );
        },
      ),
    );

    nameCtrl.dispose();
  }

  /// ---------------- DELETE USER ----------------
  Future<void> _deleteUser(String docId, Map<String, dynamic> data) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Deactivate User"),
        content: Text("Deactivate ${data['email']}? Deactivate Account."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Deactivate",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final userRef = FirebaseFirestore.instance.collection('users').doc(docId);
      final snap = await userRef.get();
      if (!snap.exists) return;

      final userData = snap.data()!;

      await FirebaseFirestore.instance
          .collection('archived_users')
          .doc(docId)
          .set({
            ...userData,
            "archivedAt": FieldValue.serverTimestamp(),
            "archivedBy": widget.user.email,
            "status": false,
          });

      await userRef.update({
        "status": false,
        "updatedAt": FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('notifications').add({
        'title': 'Deactivated Account',
        'message': 'Deactivated account for ${data['email']}',
        'time': FieldValue.serverTimestamp(),
        'dismissed': false,
        'type': 'updates',
        'createdBy': widget.user.email,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("User ${data['email']} deactivated successfully"),
        ),
      );
    }
  }
}
