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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Deactivated Account',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0D2364),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('status', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No deactivated accounts."));
          }

          final users = snapshot.data!.docs;

          return LayoutBuilder(
            builder: (context, constraints) {
              // For mobile screens (width < 600)
              if (constraints.maxWidth < 600) {
                return _buildMobileList(users);
              }
              // For tablet screens (600 <= width < 900)
              else if (constraints.maxWidth < 900) {
                return _buildTabletView(users);
              }
              // For desktop screens (width >= 900)
              else {
                return _buildDesktopTable(users);
              }
            },
          );
        },
      ),
    );
  }

  /// Mobile View - Vertical List
  Widget _buildMobileList(List<QueryDocumentSnapshot> users) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final doc = users[index];
        final data = doc.data() as Map<String, dynamic>;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMobileRow("Employee ID", data['employeeId'] ?? ''),
                _buildMobileRow("Role", data['role'] ?? ''),
                _buildMobileRow(
                  "Status",
                  "Inactive",
                  valueColor: Colors.red,
                  isBold: true,
                ),
                _buildMobileRow("Email", data['email'] ?? ''),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _reactivateUser(doc.id, data),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      "Reactivate",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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
                color: valueColor ?? Colors.black87,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tablet View - Compact Table
  Widget _buildTabletView(List<QueryDocumentSnapshot> users) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width,
        ),
        padding: const EdgeInsets.all(16),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(2), // Employee ID
            1: FlexColumnWidth(2), // Role
            2: FlexColumnWidth(1.5), // Status
            3: FlexColumnWidth(3), // Email
            4: FlexColumnWidth(2), // Action
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          border: TableBorder.all(color: Colors.grey.shade300),
          children: [
            // Header
            TableRow(
              decoration: BoxDecoration(color: Colors.blue[50]),
              children: const [
                _HeaderCell("Emp ID"),
                _HeaderCell("Role"),
                _HeaderCell("Status"),
                _HeaderCell("Email"),
                _HeaderCell("Action"),
              ],
            ),
            // Data Rows
            ...users.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return TableRow(
                decoration: BoxDecoration(
                  color: users.indexOf(doc) % 2 == 0
                      ? Colors.white
                      : Colors.grey[100],
                ),
                children: [
                  _DataCell(data['employeeId'] ?? '', isCompact: true),
                  _DataCell(data['role'] ?? '', isCompact: true),
                  _DataCell(
                    "Inactive",
                    color: Colors.red,
                    isBold: true,
                    isCompact: true,
                  ),
                  _DataCell(data['email'] ?? '', isCompact: true),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () => _reactivateUser(doc.id, data),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 8,
                        ),
                        minimumSize: Size.zero,
                      ),
                      child: const Text(
                        "Reactivate",
                        style: TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Desktop View - Full Table
  Widget _buildDesktopTable(List<QueryDocumentSnapshot> users) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          constraints: const BoxConstraints(minWidth: 800),
          padding: const EdgeInsets.all(16),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(3), // Employee ID
              1: FlexColumnWidth(3), // Role
              2: FlexColumnWidth(2), // Status
              3: FlexColumnWidth(4), // Email
              4: FlexColumnWidth(4), // Action
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            border: TableBorder.all(color: Colors.grey.shade300),
            children: [
              // Header
              TableRow(
                decoration: BoxDecoration(color: Colors.blue[50]),
                children: const [
                  _HeaderCell("Employee ID"),
                  _HeaderCell("Role"),
                  _HeaderCell("Status"),
                  _HeaderCell("Email"),
                  _HeaderCell("Action"),
                ],
              ),
              // Data Rows
              ...users.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return TableRow(
                  decoration: BoxDecoration(
                    color: users.indexOf(doc) % 2 == 0
                        ? Colors.white
                        : Colors.grey[100],
                  ),
                  children: [
                    _DataCell(data['employeeId'] ?? ''),
                    _DataCell(data['role'] ?? ''),
                    _DataCell("Inactive", color: Colors.red, isBold: true),
                    _DataCell(data['email'] ?? ''),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: ElevatedButton(
                        onPressed: () => _reactivateUser(doc.id, data),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                        ),
                        child: const Text("Reactivate"),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  /// ------------ REACTIVATE USER FUNCTION ------------
  Future<void> _reactivateUser(String docId, Map<String, dynamic> data) async {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final nameCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Reactivate User"),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: "Name"),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: "Email"),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: "Password"),
                  ),
                ],
              ),
            ),
          ),
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
      ),
    );

    if (confirmed == true) {
      try {
        // 1. Create Firebase Auth account
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailCtrl.text.trim(),
          password: passCtrl.text.trim(),
        );

        // 2. Update Firestore slot with new info
        await FirebaseFirestore.instance.collection('users').doc(docId).update({
          "name": nameCtrl.text.trim(),
          "email": emailCtrl.text.trim(),
          "status": true,
          "uid": cred.user?.uid,
          "reactivatedAt": FieldValue.serverTimestamp(),
          "reactivatedBy": widget.user.email,
        });

        // 3. Add notification
        await FirebaseFirestore.instance.collection('notifications').add({
          'title': 'Reactivated Account',
          'message':
              'Reactivated and assigned to ${nameCtrl.text.trim()} (${emailCtrl.text.trim()})',
          'time': FieldValue.serverTimestamp(),
          'dismissed': false,
          'type': 'updates',
          'createdBy': widget.user.email,
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Account reactivated for ${nameCtrl.text.trim()}"),
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

/// ----------- SMALL WIDGETS TO AVOID REPETITION -----------
class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  final String text;
  final Color? color;
  final bool isBold;
  final bool isCompact;

  const _DataCell(
    this.text, {
    this.color,
    this.isBold = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: isCompact
          ? const EdgeInsets.all(8.0)
          : const EdgeInsets.all(12.0),
      child: Tooltip(
        message: text,
        child: Text(
          text,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
          style: TextStyle(
            color: color ?? Colors.black87,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isCompact ? 12 : 14,
          ),
        ),
      ),
    );
  }
}
