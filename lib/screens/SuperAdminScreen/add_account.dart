import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:math';
import '../../firebase_options.dart';
import '../../models/app_user.dart';

class AddAccountScreen extends StatefulWidget {
  final AppUser user;
  const AddAccountScreen({super.key, required this.user});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController firstNameCtrl = TextEditingController();
  final TextEditingController middleNameCtrl = TextEditingController();
  final TextEditingController lastNameCtrl = TextEditingController();

  bool loading = false;
  String? role;
  String? employmentType;
  String? area;
  bool _obscurePassword = true;
  String generatedPassword = "";

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
      'admin': '10',
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

  /// ----------- Called when role changes -----------
  Future<void> _updateEmployeeId(String? newRole) async {
    setState(() {
      role = newRole;
      // Reset dependent fields when role changes
      if (newRole != 'driver' && newRole != 'conductor' && newRole != 'inspector') {
        employmentType = null;
      }
      if (newRole != 'inspector') {
        area = null;
      }
    });
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

  /// ----------- CAPITALIZE ROLE -----------
  String _capitalizeRole(String role) {
    if (role.isEmpty) return '';
    final parts = role.split('_');
    return parts
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  /// ----------- ROLE COLOR -----------
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

  /// ----------- BUILD ROLE DROPDOWN ITEM -----------
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

  /// ----------- SHOW SUCCESS DIALOG -----------
  void _showAccountCreatedDialog({
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
                        Icon(Icons.mark_email_unread, color: Colors.orange[700]),
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
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
            child: const Text(
              'Done',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// ----------- CREATE FUNCTION -----------
  Future<void> _createUser() async {
    final email = emailCtrl.text.trim();
    final firstName = firstNameCtrl.text.trim();
    final middleName = middleNameCtrl.text.trim();
    final lastName = lastNameCtrl.text.trim();

    // Role validation
    if (role == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a role')),
        );
      }
      return;
    }

    // Name validations
    final firstNameError = _validateName(firstName, 'First name');
    if (firstNameError != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(firstNameError)),
        );
      }
      return;
    }

    final lastNameError = _validateName(lastName, 'Last name');
    if (lastNameError != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(lastNameError)),
        );
      }
      return;
    }

    if (middleName.isNotEmpty) {
      final middleNameError = _validateName(middleName, 'Middle name');
      if (middleNameError != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(middleNameError)),
          );
        }
        return;
      }
    }

    // Generate display name
    final mi = middleName.isNotEmpty ? ' ${middleName[0]}.' : '';
    final displayName = '$lastName, $firstName$mi';

    // Email validation
    if (email.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter email address')),
        );
      }
      return;
    }

    if (!_isValidGmail(email)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Only Gmail accounts are allowed')),
        );
      }
      return;
    }

    setState(() => loading = true);

    try {
      // Generate employee ID and password
      final employeeId = await _generateEmployeeId(role!);
      final password = generatedPassword;

      // Create User In Secondary Auth Instance
      final secondaryApp = await _getOrCreateSecondaryApp();
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final newCred = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final newUid = newCred.user!.uid;

      // Update user profile with display name
      await newCred.user!.updateDisplayName(displayName);

      // Send verification email
      await newCred.user!.sendEmailVerification();

      // Save to Firestore with verification tracking
      final userData = {
        'uid': newUid,
        'email': email,
        'employeeId': employeeId,
        'firstName': firstName,
        'middleName': middleName,
        'lastName': lastName,
        'name': displayName,
        'displayName': displayName,
        'role': role,
        'status': true,
        'emailVerified': false,
        'tempPassword': password,
        'verificationEmailSentAt': FieldValue.serverTimestamp(),
        'verificationEmailCount': 1,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': widget.user.email,
      };

      // Add optional fields
      if (employmentType != null &&
          (role == 'driver' || role == 'conductor' || role == 'inspector')) {
        userData['employmentType'] = employmentType;
      }
      if (role == 'inspector' && area != null) {
        userData['area'] = area;
      }

      await FirebaseFirestore.instance.collection('users').doc(newUid).set(userData);

      // Create notification
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': 'New Account Created',
        'message': '$displayName has been added as ${_capitalizeRole(role!)} with ID $employeeId. Verification email sent.',
        'time': FieldValue.serverTimestamp(),
        'dismissed': false,
        'type': 'updates',
        'createdBy': widget.user.email,
      });

      await secondaryAuth.signOut();

      // Clear all fields
      emailCtrl.clear();
      firstNameCtrl.clear();
      middleNameCtrl.clear();
      lastNameCtrl.clear();

      if (mounted) {
        setState(() {
          role = null;
          employmentType = null;
          area = null;
          generatedPassword = _generatePassword();
        });

        // Show success dialog
        _showAccountCreatedDialog(
          displayName: displayName,
          email: email,
          employeeId: employeeId,
          tempPassword: password,
          role: role!,
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Error creating user';

      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'This email is already registered';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        case 'weak-password':
          errorMessage = 'Password is too weak';
          break;
        default:
          errorMessage = e.message ?? 'Error creating user';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    generatedPassword = _generatePassword();
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    firstNameCtrl.dispose();
    middleNameCtrl.dispose();
    lastNameCtrl.dispose();
    super.dispose();
  }

  /// ----------- SCREEN VIEW -----------
  @override
  Widget build(BuildContext context) {
    final roleColor = role != null ? _getRoleColor(role!) : Colors.grey;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(128),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create User',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D2364),
                    ),
                  ),

                  const SizedBox(height: 16),

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
                                _obscurePassword
                                    ? '•' * generatedPassword.length
                                    : generatedPassword,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Role Dropdown with color
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
                        _buildRoleDropdownItem("admin", "Admin"),
                        _buildRoleDropdownItem("legal_officer", "Legal Officer"),
                        _buildRoleDropdownItem("driver", "Driver"),
                        _buildRoleDropdownItem("conductor", "Conductor"),
                        _buildRoleDropdownItem("inspector", "Inspector"),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          _updateEmployeeId(value);
                        }
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

                  // Employment Type (for driver, conductor, inspector)
                  if (role == 'driver' || role == 'conductor' || role == 'inspector') ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: employmentType,
                      items: const [
                        DropdownMenuItem(value: "full_time", child: Text("Full-Time")),
                        DropdownMenuItem(value: "part_time", child: Text("Part-Time")),
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

                  // Area (for inspector only)
                  if (role == 'inspector') ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: area,
                      items: const [
                        DropdownMenuItem(value: "Gaya Gaya", child: Text("Gaya Gaya")),
                        DropdownMenuItem(value: "SM Tungko", child: Text("SM Tungko")),
                        DropdownMenuItem(value: "Road 2", child: Text("Road 2")),
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
                            Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Email Verification',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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

                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Notes',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Please copy the temporary password and send it to the users.'
                              'The temporary password cannot be send in the email for security purposes.',
                          style: TextStyle(fontSize: 12, height: 1.4),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D2364),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: (role == null || loading) ? null : _createUser,
                      child: loading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                          : const Text(
                        "Create User",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}