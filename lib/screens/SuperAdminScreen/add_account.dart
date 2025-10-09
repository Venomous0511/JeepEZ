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
    // Check if name contains only letters and spaces
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(name)) {
      return '$fieldName can only contain letters and spaces';
    }
    return null;
  }

  /// ----------- FILTER NAME INPUT (NO NUMBERS) -----------
  String _filterNameInput(String input) {
    // Remove numbers and special characters except spaces
    return input.replaceAll(RegExp(r'[^a-zA-Z\s]'), '');
  }

  /// ----------- CREATE FUNCTION -----------
  Future<void> _createUser() async {
    final email = emailCtrl.text.trim();
    final firstName = firstNameCtrl.text.trim();
    final middleName = middleNameCtrl.text.trim();
    final lastName = lastNameCtrl.text.trim();

    // Role validation - must select a specific role, not "Employee"
    if (role == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please select a role')));
      }
      return;
    }

    // Name validations
    final firstNameError = _validateName(firstName, 'First name');
    if (firstNameError != null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(firstNameError)));
      }
      return;
    }

    final lastNameError = _validateName(lastName, 'Last name');
    if (lastNameError != null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(lastNameError)));
      }
      return;
    }

    // Validate middle name if provided
    if (middleName.isNotEmpty) {
      final middleNameError = _validateName(middleName, 'Middle name');
      if (middleNameError != null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(middleNameError)));
        }
        return;
      }
    }

    // Generate display name (Last Name, First Name MI)
    final mi = middleName.isNotEmpty ? ' ${middleName[0]}.' : '';
    final displayName = '$lastName, $firstName$mi';

    // Email validation - Gmail only
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

    // Generate employee ID and password
    final employeeId = await _generateEmployeeId(role!);
    final password = _generatePassword();

    setState(() => loading = true);

    try {
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

      // Save to Firestore
      await FirebaseFirestore.instance.collection('users').doc(newUid).set({
        'uid': newUid,
        'email': email,
        'employeeId': employeeId,
        'firstName': firstName,
        'middleName': middleName,
        'lastName': lastName,
        'displayName': displayName,
        'role': role,
        'status': true,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': widget.user.email,
        'tempPassword': password,
      });

      // Create notification
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': 'New Account Created',
        'message': '$displayName has been added as $role with ID $employeeId',
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
          role = null; // Reset role selection
          generatedPassword =
              _generatePassword(); // Generate new password for next user
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'User $displayName created as $role with ID $employeeId. Temporary password has been set.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
    // Generate initial password
    generatedPassword = _generatePassword();
  }

  /// ----------- SCREEN VIEW -----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // REMOVED: appBar and drawer properties
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // Bordered Create User Form with Box Shadow
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
                  BoxShadow(
                    color: Colors.grey.withAlpha(128),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
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
                      // Filter out numbers in real-time
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
                      // Filter out numbers in real-time
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
                      // Filter out numbers in real-time
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

                  DropdownButtonFormField<String>(
                    value: role,
                    decoration: const InputDecoration(
                      labelText: 'Role *',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      hintText: 'Select a role',
                    ),
                    hint: const Text('Select a role'),
                    items: const [
                      DropdownMenuItem(value: "admin", child: Text("Admin")),
                      DropdownMenuItem(
                        value: "legal_officer",
                        child: Text("Legal Officer"),
                      ),
                      DropdownMenuItem(value: "driver", child: Text("Driver")),
                      DropdownMenuItem(
                        value: "conductor",
                        child: Text("Conductor"),
                      ),
                      DropdownMenuItem(
                        value: "inspector",
                        child: Text("Inspector"),
                      ),
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

                  const SizedBox(height: 8),
                  Text(
                    'Please select a specific role (Admin, Legal Officer, Driver, Conductor, or Inspector)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity, // full width
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
                          ? const CircularProgressIndicator()
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
