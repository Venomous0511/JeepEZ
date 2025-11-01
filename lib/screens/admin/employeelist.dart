import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../firebase_options.dart';
import '../../models/app_user.dart';
import 'dart:math';

/// TODO: Put back the admin can resend verification email functionality

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

  /// ----------- VALIDATE EMAIL FUNCTION -----------
  bool _isValidEmail(String email) {
    // Basic email format validation
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// ----------- CHECK IF EMAIL EXISTS -----------
  Future<bool> _checkEmailExists(String email) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
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

  /// Get paginated employee documents
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

  /// Show Account Created Dialog
  void _showAccountCreatedDialog({
    required BuildContext context,
    required String displayName,
    required String email,
    required String employeeId,
    required String tempPassword,
    required String role,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[700], size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Account Created Successfully',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Role: ${_capitalizeRole(role)}'),
                    Text('Employee ID: $employeeId'),
                    Text('Email: $email'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Verification Status
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.mark_email_unread,
                          color: Colors.orange[700],
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Verification Email Sent',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Sent to: $email'),
                    const SizedBox(height: 8),
                    const Text(
                      'User must verify email before logging in',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Instructions
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Instructions for User:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Check email inbox (and spam folder)\n'
                      '2. Click the verification link\n'
                      '3. Return to login page\n'
                      '4. Use credentials below to login\n'
                      '5. Change password on first login',
                      style: TextStyle(height: 1.6, fontSize: 14),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Credentials Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.vpn_key, color: Colors.red[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'Temporary Credentials',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SelectableText(
                      'Email: $email',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      'Employee ID: $employeeId',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      'Temporary Password: $tempPassword',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Keep these credentials secure and share only with the user!',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Important Note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.yellow.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.yellow.shade700),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.yellow[800],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'If user doesn\'t receive the email, check the Employee List for a "Resend Email" button.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D2364),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Done', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Resend Verification Email
  Future<void> _resendVerificationEmail(
    String docId,
    Map<String, dynamic> data,
  ) async {
    // Check if email is already verified
    if (data['emailVerified'] == true) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email is already verified'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Confirm action
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.mail_outline, color: Colors.orange),
            const SizedBox(width: 12),
            const Expanded(child: Text('Resend Verification Email')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resend verification email to:',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              data['email'] ?? 'Unknown email',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will send a new verification link to the user.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.send, size: 18, color: Colors.white),
            label: const Text('Resend', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D2364),
            ),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show loading
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 16),
              Text('Sending verification email...'),
            ],
          ),
          duration: Duration(seconds: 10),
        ),
      );
    }

    try {
      // Get user data
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(docId)
          .get();

      if (!userSnapshot.exists) {
        throw Exception('User not found');
      }

      final email = userSnapshot.data()!['email'] as String;
      final tempPassword = userSnapshot.data()!['tempPassword'] as String?;

      if (tempPassword == null) {
        throw Exception(
          'Cannot resend - temporary password not found. User may need to reset password.',
        );
      }

      // Use secondary auth to avoid signing out current admin
      final secondaryApp = await _getOrCreateSecondaryApp();
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      // Sign in temporarily
      final userCred = await secondaryAuth.signInWithEmailAndPassword(
        email: email,
        password: tempPassword,
      );

      // Send verification email
      await userCred.user!.sendEmailVerification();

      // Update Firestore with timestamp
      await FirebaseFirestore.instance.collection('users').doc(docId).update({
        'verificationEmailSentAt': FieldValue.serverTimestamp(),
        'verificationEmailCount': FieldValue.increment(1),
        'lastVerificationEmailBy': widget.user.email,
      });

      // Create notification
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': 'Verification Email Resent',
        'message': 'Verification email resent to ${data['name']} ($email)',
        'time': FieldValue.serverTimestamp(),
        'dismissed': false,
        'type': 'updates',
        'createdBy': widget.user.email,
      });

      // Sign out from secondary auth
      await secondaryAuth.signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Verification email sent successfully to $email'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Failed to send verification email';

      switch (e.code) {
        case 'wrong-password':
          errorMessage =
              'Cannot resend - password may have been changed. User should use "Forgot Password" instead.';
          break;
        case 'user-not-found':
          errorMessage = 'User account not found';
          break;
        case 'too-many-requests':
          errorMessage =
              'Too many attempts. Please wait a few minutes before trying again.';
          break;
        default:
          errorMessage = e.message ?? 'Failed to send verification email';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Send Password Reset to User
  Future<void> _sendPasswordResetToUser(
    String docId,
    Map<String, dynamic> data,
  ) async {
    final email = data['email'] as String?;

    if (email == null || email.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User email not found'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Confirm action
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.lock_reset, color: Colors.orange),
            const SizedBox(width: 12),
            const Expanded(child: Text('Send Password Reset')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Send password reset email to:',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['name'] ?? 'Unknown',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(email),
                  const SizedBox(height: 4),
                  Text(
                    'Employee ID: ${data['employeeId'] ?? 'N/A'}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'User will receive an email with instructions to reset their password',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.send, size: 18, color: Colors.white),
            label: const Text(
              'Send Reset Email',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D2364),
            ),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show loading
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 16),
              Text('Sending password reset email...'),
            ],
          ),
          duration: Duration(seconds: 10),
        ),
      );
    }

    try {
      // Send password reset email using Firebase Auth
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      // Update Firestore to track this action
      await FirebaseFirestore.instance.collection('users').doc(docId).update({
        'passwordResetSentAt': FieldValue.serverTimestamp(),
        'passwordResetSentBy': widget.user.email,
      });

      // Create notification
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': 'Password Reset Sent',
        'message': 'Password reset email sent to ${data['name']} ($email)',
        'time': FieldValue.serverTimestamp(),
        'dismissed': false,
        'type': 'updates',
        'createdBy': widget.user.email,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();

        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[700], size: 28),
                const SizedBox(width: 12),
                const Text('Email Sent'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Password reset email sent successfully to:'),
                const SizedBox(height: 8),
                Text(
                  email,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Text(
                    'The user will receive an email with instructions to reset their password. The link will expire in 1 hour.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D2364),
                ),
                child: const Text('OK', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Failed to send password reset email';

      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'User account not found';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many requests. Please wait a few minutes.';
          break;
        default:
          errorMessage = e.message ?? 'Failed to send password reset email';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
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
        final isEmailVerified = data['emailVerified'] ?? false;

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
                      backgroundColor: roleColor.withAlpha(2),
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
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  data['name'] ?? 'No Name',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            data['employeeId']?.toString() ?? 'N/A',
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
                            ? Colors.green.withAlpha(26)
                            : Colors.red.withAlpha(26),
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

                // 🔥 NEW: Email verification status row
                if (!isEmailVerified)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 120,
                          child: Text(
                            "Email Status:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withAlpha(26),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.mail_outline,
                                  size: 16,
                                  color: Colors.orange[700],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Not Verified',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

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
                    // 🔥 NEW: Resend verification button
                    if (!isEmailVerified) ...[
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.orange.withAlpha(26),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.mark_email_unread,
                            color: Colors.orange,
                          ),
                          tooltip: 'Resend verification email',
                          onPressed: () =>
                              _resendVerificationEmail(doc.id, data),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],

                    // Edit button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withAlpha(26),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editUser(doc.id, data),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Delete button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(26),
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
            headingRowColor: WidgetStateProperty.all(
              const Color(0xFF0D2364),
            ), // Blue background
            headingTextStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white, // White text
              fontSize: 14,
            ),
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
            headingRowColor: WidgetStateProperty.all(
              const Color(0xFF0D2364),
            ), // Blue background
            headingTextStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white, // White text
              fontSize: 14,
            ),
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
    final isEmailVerified = data['emailVerified'] ?? false;

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
          Row(
            children: [
              Text(
                data['name'] ?? 'No Name Found',
                style: isCompact ? const TextStyle(fontSize: 12) : null,
              ),
              // NEW: Email verification indicator
              if (!isEmailVerified) ...[
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Email not verified',
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: isCompact ? 16 : 18,
                  ),
                ),
              ],
            ],
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: data['status'] == true
                  ? Colors.green.withAlpha(26)
                  : Colors.red.withAlpha(26),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                data['email'] ?? '',
                style: isCompact ? const TextStyle(fontSize: 12) : null,
              ),
              // 🔥 NEW: Show verification status
              if (!isEmailVerified)
                Text(
                  'Not verified',
                  style: TextStyle(
                    fontSize: isCompact ? 10 : 11,
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: roleColor.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: roleColor.withAlpha(3)),
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
              // NEW: Resend verification button (only if not verified)
              if (!isEmailVerified) ...[
                Tooltip(
                  message: 'Resend verification email',
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.mark_email_unread,
                        color: Colors.orange,
                        size: isCompact ? 18 : 20,
                      ),
                      onPressed: () => _resendVerificationEmail(docId, data),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],

              // NEW: Verified checkmark (only if verified)
              if (isEmailVerified) ...[
                Tooltip(
                  message: 'Email verified',
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withAlpha(51)),
                    ),
                    child: Icon(
                      Icons.verified,
                      color: Colors.green,
                      size: isCompact ? 18 : 20,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],

              Tooltip(
                message: 'Send password reset email',
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.purple.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.lock_reset,
                      color: Colors.purple,
                      size: isCompact ? 18 : 20,
                    ),
                    onPressed: () => _sendPasswordResetToUser(docId, data),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // Edit button
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(26),
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
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ),
              const SizedBox(width: 4),

              // Delete button
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(26),
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
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
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

  /// Add User Dialog - FIXED VERSION (No overflow)
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
    String? emailError;
    bool isCheckingEmail = false;

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final roleColor = role != null ? _getRoleColor(role!) : Colors.grey;

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D2364),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.person_add, color: Colors.white, size: 24),
                          SizedBox(width: 12),
                          Text(
                            'Create User',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // First Name Field
                            TextField(
                              controller: firstNameCtrl,
                              maxLength: 20,
                              decoration: const InputDecoration(
                                labelText: 'First Name *',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                counterText: "",
                              ),
                              onChanged: (value) {
                                final filteredValue = _filterNameInput(value);
                                if (filteredValue != value) {
                                  firstNameCtrl.value = firstNameCtrl.value
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

                            // Middle Name Field
                            TextField(
                              controller: middleNameCtrl,
                              maxLength: 20,
                              decoration: const InputDecoration(
                                labelText: 'Middle Name (Optional)',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
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
                                labelText: 'Last Name *',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                counterText: "",
                              ),
                              onChanged: (value) {
                                final filteredValue = _filterNameInput(value);
                                if (filteredValue != value) {
                                  lastNameCtrl.value = lastNameCtrl.value
                                      .copyWith(
                                        text: filteredValue,
                                        selection: TextSelection.collapsed(
                                          offset: filteredValue.length,
                                        ),
                                      );
                                }
                              },
                            ),

                            const SizedBox(height: 16),

                            // Email Field
                            TextField(
                              controller: emailCtrl,
                              decoration: InputDecoration(
                                labelText: 'Email *',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                errorText: emailError,
                                suffixIcon: isCheckingEmail
                                    ? Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      )
                                    : emailError == null &&
                                          emailCtrl.text.isNotEmpty
                                    ? Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                      )
                                    : null,
                              ),
                              keyboardType: TextInputType.emailAddress,
                              onChanged: (value) async {
                                setState(() {
                                  isCheckingEmail = true;
                                  emailError = null;
                                });

                                // Debounce: wait for user to stop typing
                                await Future.delayed(
                                  Duration(milliseconds: 500),
                                );

                                if (value.isEmpty) {
                                  setState(() {
                                    emailError = 'Email is required';
                                    isCheckingEmail = false;
                                  });
                                  return;
                                }

                                if (!_isValidEmail(value)) {
                                  setState(() {
                                    emailError = 'Invalid email format';
                                    isCheckingEmail = false;
                                  });
                                  return;
                                }

                                // Check if email already exists
                                final exists = await _checkEmailExists(value);
                                setState(() {
                                  if (exists) {
                                    emailError =
                                        'This email is already registered';
                                  }
                                  isCheckingEmail = false;
                                });
                              },
                            ),

                            const SizedBox(height: 16),

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
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
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
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Role selection
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: role != null ? roleColor : Colors.grey,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: DropdownButtonFormField<String>(
                                value: role,
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
                                  _buildRoleDropdownItem(
                                    "conductor",
                                    "Conductor",
                                  ),
                                  _buildRoleDropdownItem(
                                    "inspector",
                                    "Inspector",
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    role = value;
                                    employmentType = null;
                                  });
                                },
                              ),
                            ),

                            if (role != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: roleColor.withAlpha(26),
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
                                value: employmentType,
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
                                  labelText: "Employment Type *",
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 16),

                            // Email verification info box
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.blue.shade700,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text(
                                          'Email Verification',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'A verification email will be sent automatically. '
                                    'The user must verify their email before they can log in.',
                                    style: TextStyle(fontSize: 12, height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Actions
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogCtx),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: loading
                                ? null
                                : () async {
                                    final email = emailCtrl.text.trim();
                                    final firstName = firstNameCtrl.text.trim();
                                    final middleName = middleNameCtrl.text
                                        .trim();
                                    final lastName = lastNameCtrl.text.trim();

                                    // Validation
                                    if (role == null) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Please select a role',
                                            ),
                                          ),
                                        );
                                      }
                                      return;
                                    }

                                    final firstNameError = _validateName(
                                      firstName,
                                      'First name',
                                    );
                                    if (firstNameError != null) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(firstNameError),
                                          ),
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
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(lastNameError),
                                          ),
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
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(middleNameError),
                                            ),
                                          );
                                        }
                                        return;
                                      }
                                    }

                                    // Format display name as "Last Name, First Name M.I."
                                    final mi = middleName.isNotEmpty
                                        ? ' ${middleName[0]}.'
                                        : '';
                                    final displayName =
                                        '$lastName, $firstName$mi';

                                    if (email.isEmpty) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Please enter email address',
                                            ),
                                          ),
                                        );
                                      }
                                      return;
                                    }

                                    if (!_isValidEmail(email)) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Please enter a valid email address',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    final emailExists = await _checkEmailExists(
                                      email,
                                    );
                                    if (emailExists) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'This email is already registered',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    setState(() => loading = true);

                                    try {
                                      final employeeId =
                                          await _generateEmployeeId(role!);

                                      // Create user with secondary auth
                                      final secondaryApp =
                                          await _getOrCreateSecondaryApp();
                                      final secondaryAuth =
                                          FirebaseAuth.instanceFor(
                                            app: secondaryApp,
                                          );

                                      final newCred = await secondaryAuth
                                          .createUserWithEmailAndPassword(
                                            email: email,
                                            password: generatedPassword,
                                          );
                                      final newUid = newCred.user!.uid;

                                      await newCred.user!.updateDisplayName(
                                        displayName,
                                      );

                                      // SEND VERIFICATION EMAIL
                                      await newCred.user!
                                          .sendEmailVerification();

                                      // Save to Firestore with separate name fields and area
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
                                        'emailVerified': false,
                                        'tempPassword': generatedPassword,
                                        'verificationEmailSentAt':
                                            FieldValue.serverTimestamp(),
                                        'verificationEmailCount': 1,
                                        'createdAt':
                                            FieldValue.serverTimestamp(),
                                        'createdBy': widget.user.email,
                                      };

                                      if (employmentType != null) {
                                        userData['employmentType'] =
                                            employmentType;
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
                                                '$displayName has been added as $role with ID $employeeId. Verification email sent.',
                                            'time':
                                                FieldValue.serverTimestamp(),
                                            'dismissed': false,
                                            'type': 'updates',
                                            'createdBy': widget.user.email,
                                          });

                                      await secondaryAuth.signOut();

                                      if (mounted && context.mounted) {
                                        Navigator.pop(dialogCtx);

                                        // Show success dialog with instructions
                                        if (mounted) {
                                          _showAccountCreatedDialog(
                                            context: context,
                                            displayName: displayName,
                                            email: email,
                                            employeeId: employeeId,
                                            tempPassword: generatedPassword,
                                            role: role!,
                                          );
                                        }
                                      }
                                    } on FirebaseAuthException catch (e) {
                                      String errorMessage =
                                          'Error creating user';

                                      switch (e.code) {
                                        case 'email-already-in-use':
                                          errorMessage =
                                              'This email is already registered';
                                          break;
                                        case 'invalid-email':
                                          errorMessage =
                                              'Invalid email address';
                                          break;
                                        case 'weak-password':
                                          errorMessage = 'Password is too weak';
                                          break;
                                        default:
                                          errorMessage =
                                              e.message ??
                                              'Error creating user';
                                      }

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(errorMessage),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text('Error: $e'),
                                            backgroundColor: Colors.red,
                                          ),
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
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text("Create User"),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
    final firstNameCtrl = TextEditingController(text: data['firstName'] ?? '');
    final middleNameCtrl = TextEditingController(
      text: data['middleName'] ?? '',
    );
    final lastNameCtrl = TextEditingController(text: data['lastName'] ?? '');
    final emailCtrl = TextEditingController(text: data['email'] ?? '');
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
                  // First Name
                  TextField(
                    controller: firstNameCtrl,
                    maxLength: 20,
                    decoration: const InputDecoration(
                      labelText: 'First Name *',
                      border: OutlineInputBorder(),
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

                  // Middle Name
                  TextField(
                    controller: middleNameCtrl,
                    maxLength: 20,
                    decoration: const InputDecoration(
                      labelText: 'Middle Name (Optional)',
                      border: OutlineInputBorder(),
                      counterText: "",
                    ),
                    onChanged: (value) {
                      final filteredValue = _filterNameInput(value);
                      if (filteredValue != value) {
                        middleNameCtrl.value = middleNameCtrl.value.copyWith(
                          text: filteredValue,
                          selection: TextSelection.collapsed(
                            offset: filteredValue.length,
                          ),
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  // Last Name
                  TextField(
                    controller: lastNameCtrl,
                    maxLength: 20,
                    decoration: const InputDecoration(
                      labelText: 'Last Name *',
                      border: OutlineInputBorder(),
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

                  // Email Field
                  TextField(
                    controller: emailCtrl,
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'Email (Cannot be changed)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 16),

                  // Role Display (read-only) - CHANGED TO DISPLAY ONLY
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: roleColor),
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
                          'Role: ${_capitalizeRole(role!)}',
                          style: TextStyle(
                            color: roleColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Employment Type
                  if (role == 'driver' ||
                      role == 'conductor' ||
                      role == 'inspector') ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: employmentType,
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
                        labelText: "Employment Type *",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
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
                  final firstName = firstNameCtrl.text.trim();
                  final middleName = middleNameCtrl.text.trim();
                  final lastName = lastNameCtrl.text.trim();
                  final email = emailCtrl.text.trim();

                  // Basic validation
                  final firstNameError = _validateName(firstName, 'First name');
                  if (firstNameError != null) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(firstNameError)));
                    return;
                  }

                  final lastNameError = _validateName(lastName, 'Last name');
                  if (lastNameError != null) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(lastNameError)));
                    return;
                  }

                  if (email.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter email address'),
                      ),
                    );
                    return;
                  }

                  final mi = middleName.isNotEmpty ? ' ${middleName[0]}.' : '';
                  final displayName = '$lastName, $firstName$mi';

                  // Update data map
                  final updateData = {
                    "firstName": firstName,
                    "middleName": middleName,
                    "lastName": lastName,
                    "name": displayName,
                    "email": email,
                    "updatedAt": FieldValue.serverTimestamp(),
                  };

                  if (employmentType != null &&
                      (role == 'driver' ||
                          role == 'conductor' ||
                          role == 'inspector')) {
                    updateData["employmentType"] = employmentType as Object;
                  }

                  try {
                    // Update email in Firebase Auth if changed
                    if (email != data['email']) {
                      final secondaryApp = await _getOrCreateSecondaryApp();
                      final secondaryAuth = FirebaseAuth.instanceFor(
                        app: secondaryApp,
                      );

                      final tempPassword = data['tempPassword'] as String?;
                      if (tempPassword != null) {
                        await secondaryAuth.signInWithEmailAndPassword(
                          email: data['email'],
                          password: tempPassword,
                        );

                        final currentUser = secondaryAuth.currentUser;
                        if (currentUser != null) {
                          await currentUser.verifyBeforeUpdateEmail(email);
                          await currentUser.sendEmailVerification();
                        }

                        await secondaryAuth.signOut();
                      }
                    }

                    // Firestore update
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(docId)
                        .update(updateData);

                    await FirebaseFirestore.instance
                        .collection('notifications')
                        .add({
                          'title': 'Updated Account',
                          'message': 'Updated account for $displayName',
                          'time': FieldValue.serverTimestamp(),
                          'dismissed': false,
                          'type': 'updates',
                          'createdBy': widget.user.email,
                        });

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Updated $displayName successfully"),
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

    firstNameCtrl.dispose();
    middleNameCtrl.dispose();
    lastNameCtrl.dispose();
    emailCtrl.dispose();
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
