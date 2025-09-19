import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/app_user.dart';

class DeactivatedAccountScreen extends StatefulWidget {
  final AppUser user;
  const DeactivatedAccountScreen({super.key, required this.user});

  @override
  State<DeactivatedAccountScreen> createState() => _DeactivatedAccountScreenState();
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
          stream: FirebaseFirestore.instance.collection('users').where('status', isEqualTo: false).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No deactivated accounts."));
            }

            final users = snapshot.data!.docs;

            return SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 600),
                  padding: const EdgeInsets.all(16),
                  child: Table(
                    columnWidths: const {
                      0: FlexColumnWidth(3), // Employee ID
                      1: FlexColumnWidth(3), // Role
                      2: FlexColumnWidth(2), // Status
                      3: FlexColumnWidth(4), // Email
                      4: FlexColumnWidth(4), // Action
                    },
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
                            _DataCell("Inactive",
                                color: Colors.red, isBold: true),
                            _DataCell(data['email'] ?? ''),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: ElevatedButton(
                                onPressed: () => _reactivateUser(doc.id, data),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
      )


      // LayoutBuilder(
      //   builder: (context, constraints) {
      //     return SingleChildScrollView(
      //       scrollDirection: Axis.vertical,
      //       child: SingleChildScrollView(
      //         scrollDirection: Axis.horizontal,
      //         child: Container(
      //           constraints: const BoxConstraints(minWidth: 600),
      //           padding: const EdgeInsets.all(16),
      //           child: Table(
      //             columnWidths: const {
      //               0: FlexColumnWidth(2), // ID Number
      //               1: FlexColumnWidth(2), // Status
      //               2: FlexColumnWidth(2), // Name
      //               3: FlexColumnWidth(3), // Email
      //             },
      //             border: TableBorder.all(color: Colors.grey.shade300),
      //             children: [
      //               // Header Row
      //               TableRow(
      //                 decoration: BoxDecoration(color: Colors.blue[50]),
      //                 children: const [
      //                   Padding(
      //                     padding: EdgeInsets.all(12.0),
      //                     child: Text(
      //                       "ID Number",
      //                       style: TextStyle(fontWeight: FontWeight.bold),
      //                       textAlign: TextAlign.center,
      //                     ),
      //                   ),
      //                   Padding(
      //                     padding: EdgeInsets.all(12.0),
      //                     child: Text(
      //                       "Status",
      //                       style: TextStyle(fontWeight: FontWeight.bold),
      //                       textAlign: TextAlign.center,
      //                     ),
      //                   ),
      //                   Padding(
      //                     padding: EdgeInsets.all(12.0),
      //                     child: Text(
      //                       "Name",
      //                       style: TextStyle(fontWeight: FontWeight.bold),
      //                       textAlign: TextAlign.center,
      //                     ),
      //                   ),
      //                   Padding(
      //                     padding: EdgeInsets.all(12.0),
      //                     child: Text(
      //                       "Email",
      //                       style: TextStyle(fontWeight: FontWeight.bold),
      //                       textAlign: TextAlign.center,
      //                     ),
      //                   ),
      //                 ],
      //               ),
      //               // Data Rows
      //               ...attendanceData.map((record) {
      //                 int index = attendanceData.indexOf(record);
      //                 return TableRow(
      //                   decoration: BoxDecoration(
      //                     color: index % 2 == 0
      //                         ? Colors.white
      //                         : Colors.grey[100],
      //                   ),
      //                   children: [
      //                     Padding(
      //                       padding: const EdgeInsets.all(12.0),
      //                       child: Text(
      //                         record['ID number'] ?? '',
      //                         textAlign: TextAlign.center,
      //                         style: const TextStyle(color: Colors.black87),
      //                       ),
      //                     ),
      //                     Padding(
      //                       padding: const EdgeInsets.all(12.0),
      //                       child: Text(
      //                         record['Status'] ?? '',
      //                         textAlign: TextAlign.center,
      //                         style: const TextStyle(
      //                           color: Colors.green,
      //                           fontWeight: FontWeight.w500,
      //                         ),
      //                       ),
      //                     ),
      //                     Padding(
      //                       padding: const EdgeInsets.all(12.0),
      //                       child: Text(
      //                         record['Name'] ?? '',
      //                         textAlign: TextAlign.center,
      //                         style: const TextStyle(color: Colors.black87),
      //                       ),
      //                     ),
      //                     Padding(
      //                       padding: const EdgeInsets.all(12.0),
      //                       child: Text(
      //                         record['Email'] ?? '',
      //                         maxLines: 1,
      //                         overflow: TextOverflow.ellipsis,
      //                         textAlign: TextAlign.center,
      //                         style: const TextStyle(color: Colors.black87),
      //                       ),
      //                     ),
      //                   ],
      //                 );
      //               }),
      //             ],
      //           ),
      //         ),
      //       ),
      //     );
      //   },
      // ),
    );
  }
  /// ------------ REACTIVATE USER FUNCTION ------------
  Future<void> _reactivateUser(String docId, Map<String, dynamic> data) async {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    String role = "conductor";
    final employeeIdCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Reactivate User"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Name"),
                ),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: "Email"),
                ),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Password"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Reactivate")),
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
          'message': 'Reactivated and assigned to ${nameCtrl.text.trim()} (${emailCtrl.text.trim()})',
          'time': FieldValue.serverTimestamp(),
          'dismissed': false,
          'type': 'updates',
          'createdBy': widget.user.email,
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Account reactivated for ${nameCtrl.text.trim()}")),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
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
      child: Text(text,
          style: const TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center),
    );
  }
}

class _DataCell extends StatelessWidget {
  final String text;
  final Color? color;
  final bool isBold;
  const _DataCell(this.text, {this.color, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color ?? Colors.black87,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}