import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/app_user.dart';

class DeactivatedAccountScreen extends StatefulWidget {
  final AppUser user;
  const DeactivatedAccountScreen({super.key, required this.user});

  @override
  State<DeactivatedAccountScreen> createState() =>
      _DeactivatedAccountScreenState();
}

class _DeactivatedAccountScreenState extends State<DeactivatedAccountScreen> {
  int _currentPage = 0;
  final int _pageSize = 10;
  String _searchQuery = '';

  static const double tabletBreakpoint = 768.0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ---------------- HEADER ----------------
              _buildHeader(),
              const SizedBox(height: 16),

              /// ---------------- SEARCH AND FILTERS ----------------
              _buildSearchAndFilters(),
              const SizedBox(height: 16),

              /// ---------------- LIST CONTAINER ----------------
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withAlpha(25),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .where('status', isEqualTo: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildLoadingState();
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return _buildEmptyState();
                      }

                      final allUsers = snapshot.data!.docs;

                      // Filter by search query
                      final filteredUsers = _searchQuery.isEmpty
                          ? allUsers
                          : allUsers.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final name =
                                  data['name']?.toString().toLowerCase() ?? '';
                              final email =
                                  data['email']?.toString().toLowerCase() ?? '';
                              final employeeId =
                                  data['employeeId']
                                      ?.toString()
                                      .toLowerCase() ??
                                  '';
                              final role =
                                  data['role']?.toString().toLowerCase() ?? '';

                              return name.contains(
                                    _searchQuery.toLowerCase(),
                                  ) ||
                                  email.contains(_searchQuery.toLowerCase()) ||
                                  employeeId.contains(
                                    _searchQuery.toLowerCase(),
                                  ) ||
                                  role.contains(_searchQuery.toLowerCase());
                            }).toList();

                      final totalPages = (filteredUsers.length / _pageSize)
                          .ceil();

                      // Calculate pagination
                      final startIndex = _currentPage * _pageSize;
                      final endIndex = startIndex + _pageSize;
                      final users = filteredUsers.sublist(
                        startIndex,
                        endIndex > filteredUsers.length
                            ? filteredUsers.length
                            : endIndex,
                      );

                      return screenWidth >= tabletBreakpoint
                          ? _buildDesktopView(
                              users,
                              startIndex,
                              totalPages,
                              filteredUsers.length,
                            )
                          : _buildMobileView(
                              users,
                              startIndex,
                              totalPages,
                              filteredUsers.length,
                            );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ---------------- HEADER WIDGET ----------------
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Deactivated Accounts',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D2364),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Manage all deactivated employee accounts',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('status', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
              return Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D2364),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$count Deactivated Accounts',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// ---------------- SEARCH AND FILTERS WIDGET ----------------
  Widget _buildSearchAndFilters() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _currentPage = 0;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search by name, email, ID, or role...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ---------------- DESKTOP VIEW ----------------
  Widget _buildDesktopView(
    List<QueryDocumentSnapshot> users,
    int startIndex,
    int totalPages,
    int totalItems,
  ) {
    return Column(
      children: [
        // Table Info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing ${startIndex + 1}-${startIndex + users.length} of $totalItems deactivated accounts',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              if (totalPages > 1)
                Text(
                  'Page ${_currentPage + 1} of $totalPages',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
            ],
          ),
        ),

        // Table with Horizontal Scroll
        Expanded(
          child: SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width - 32,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
                    headingTextStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D2364),
                      fontSize: 14,
                    ),
                    dataRowHeight: 60,
                    columnSpacing: 20,
                    horizontalMargin: 16,
                    columns: const [
                      DataColumn(
                        label: SizedBox(
                          width: 50,
                          child: Text('#', textAlign: TextAlign.center),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 120,
                          child: Text(
                            'Employee ID',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 150,
                          child: Text('Name', textAlign: TextAlign.center),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 200,
                          child: Text('Email', textAlign: TextAlign.center),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 120,
                          child: Text('Role', textAlign: TextAlign.center),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 100,
                          child: Text('Status', textAlign: TextAlign.center),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 150,
                          child: Text('Actions', textAlign: TextAlign.center),
                        ),
                      ),
                    ],
                    rows: users.asMap().entries.map((entry) {
                      final index = entry.key;
                      final doc = entry.value;
                      final data = doc.data() as Map<String, dynamic>;
                      final rowNumber = startIndex + index + 1;

                      return DataRow(
                        cells: [
                          DataCell(
                            SizedBox(
                              width: 50,
                              child: Center(
                                child: Text(
                                  rowNumber.toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0D2364),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 120,
                              child: Center(
                                child: Text(
                                  data['employeeId']?.toString() ?? '',
                                  style: const TextStyle(
                                    fontFamily: 'Monospace',
                                  ),
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 150,
                              child: Center(
                                child: Text(
                                  data['name'] ?? '',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 200,
                              child: Center(
                                child: Text(
                                  data['email'] ?? '',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 120,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getRoleColor(
                                      data['role'],
                                    ).withAlpha(25),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _getRoleColor(data['role']),
                                    ),
                                  ),
                                  child: Text(
                                    _formatRole(data['role'] ?? ''),
                                    style: TextStyle(
                                      color: _getRoleColor(data['role']),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 100,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withAlpha(25),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.red),
                                  ),
                                  child: const Text(
                                    'Inactive',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 150,
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildActionButton(
                                      icon: Icons.refresh,
                                      color: Colors.green,
                                      tooltip: 'Reactivate User',
                                      onPressed: () =>
                                          _reactivateUser(doc.id, data),
                                    ),
                                  ],
                                ),
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

        // Pagination
        if (totalPages > 1) _buildPaginationControls(totalPages),
      ],
    );
  }

  /// ---------------- MOBILE VIEW ----------------
  Widget _buildMobileView(
    List<QueryDocumentSnapshot> users,
    int startIndex,
    int totalPages,
    int totalItems,
  ) {
    return Column(
      children: [
        // List Info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '$totalItems deactivated accounts',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (totalPages > 1)
                Flexible(
                  child: Text(
                    '${_currentPage + 1}/$totalPages',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
            ],
          ),
        ),

        // List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final doc = users[index];
              final data = doc.data() as Map<String, dynamic>;
              final rowNumber = startIndex + index + 1;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withAlpha(25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with row number and status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D2364),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '#$rowNumber',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withAlpha(25),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red),
                            ),
                            child: const Text(
                              'Inactive',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Employee Details
                      _buildMobileDetailItem(
                        'Employee ID',
                        data['employeeId']?.toString() ?? '',
                      ),
                      _buildMobileDetailItem('Name', data['name'] ?? ''),
                      _buildMobileDetailItem('Email', data['email'] ?? ''),
                      _buildMobileDetailItem(
                        'Role',
                        _formatRole(data['role'] ?? ''),
                      ),

                      const SizedBox(height: 16),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: _buildMobileActionButton(
                              icon: Icons.refresh,
                              text: 'Reactivate',
                              color: Colors.green,
                              onPressed: () => _reactivateUser(doc.id, data),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Pagination
        if (totalPages > 1) _buildMobilePaginationControls(totalPages),
      ],
    );
  }

  /// ---------------- MOBILE PAGINATION CONTROLS ----------------
  Widget _buildMobilePaginationControls(int totalPages) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          // Page Info
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Page ${_currentPage + 1} of $totalPages',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D2364),
              ),
            ),
          ),

          // Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Previous Button
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: ElevatedButton(
                    onPressed: _currentPage > 0
                        ? () {
                            setState(() {
                              _currentPage--;
                            });
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentPage > 0
                          ? const Color(0xFF0D2364)
                          : Colors.grey[300],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chevron_left, size: 18),
                        SizedBox(width: 4),
                        Text('Previous'),
                      ],
                    ),
                  ),
                ),
              ),

              // Next Button
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: ElevatedButton(
                    onPressed: _currentPage < totalPages - 1
                        ? () {
                            setState(() {
                              _currentPage++;
                            });
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentPage < totalPages - 1
                          ? const Color(0xFF0D2364)
                          : Colors.grey[300],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Next'),
                        SizedBox(width: 4),
                        Icon(Icons.chevron_right, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ---------------- DESKTOP PAGINATION CONTROLS ----------------
  Widget _buildPaginationControls(int totalPages) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous Button
          ElevatedButton(
            onPressed: _currentPage > 0
                ? () {
                    setState(() {
                      _currentPage--;
                    });
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _currentPage > 0
                  ? const Color(0xFF0D2364)
                  : Colors.grey[300],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chevron_left, size: 20),
                SizedBox(width: 4),
                Text('Previous'),
              ],
            ),
          ),

          // Page Numbers
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              '${_currentPage + 1} / $totalPages',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D2364),
              ),
            ),
          ),

          // Next Button
          ElevatedButton(
            onPressed: _currentPage < totalPages - 1
                ? () {
                    setState(() {
                      _currentPage++;
                    });
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _currentPage < totalPages - 1
                  ? const Color(0xFF0D2364)
                  : Colors.grey[300],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Next'),
                SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ---------------- HELPER WIDGETS ----------------
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading deactivated accounts...',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No deactivated accounts',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'All accounts are currently active',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, size: 20),
      color: color,
      onPressed: onPressed,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: color.withAlpha(25),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  Widget _buildMobileActionButton({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 16),
      label: Text(text, style: const TextStyle(fontSize: 12)),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withAlpha(25),
        foregroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
    );
  }

  Widget _buildMobileDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

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

  String _formatRole(String role) {
    return role.replaceAll('_', ' ').toUpperCase();
  }

  /// ------------ REACTIVATE USER FUNCTION ------------
  Future<void> _reactivateUser(String docId, Map<String, dynamic> data) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reactivate User"),
        content: Text("Are you sure you want to reactivate ${data['name']}?\n\nA password reset email will be sent to ${data['email']}."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Reactivate"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Create Firebase Auth account
        await FirebaseAuth.instance.sendPasswordResetEmail(
          email: data['email'],
        );

        // Update Firestore slot with new info
        await FirebaseFirestore.instance.collection('users').doc(docId).update({
          "status": true,
          "isReactivated": true,
          "requiresPasswordReset": true,
          "emailVerified": false,
          "reactivatedAt": FieldValue.serverTimestamp(),
          "reactivatedBy": widget.user.email,
        });

        // 3. Add notification
        await FirebaseFirestore.instance.collection('notifications').add({
          'title': 'Reactivated Account',
          'message': 'Account reactivated for ${data['name']} (${data['email']})',
          'time': FieldValue.serverTimestamp(),
          'dismissed': false,
          'type': 'updates',
          'createdBy': widget.user.email,
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Account reactivated. Password reset email sent to ${data['email']}"),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }
}
