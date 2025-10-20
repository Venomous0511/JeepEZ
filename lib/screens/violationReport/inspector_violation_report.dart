import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Violation Report',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ViolationReportForm(),
    );
  }
}

class ViolationReportForm extends StatefulWidget {
  const ViolationReportForm({super.key});

  @override
  State<ViolationReportForm> createState() => _ViolationReportFormState();
}

class _ViolationReportFormState extends State<ViolationReportForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _violationController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _otherViolationController =
      TextEditingController();

  String? _reportedEmployeeId;
  String? _reporterEmployeeId;
  bool _isLoading = false;
  String? _selectedViolationType; // For dropdown selection

  // List of violation types for dropdown
  final List<String> _violationTypes = [
    'Reckless driving',
    'Driver Misconduct',
    'Conductor Misconduct',
    'Taking a non-registered route',
    'Aggressive driving / road rage',
    'Other/s',
  ];

  // Position dropdown options
  final List<String> _positionOptions = ['Driver', 'Conductor'];

  @override
  void initState() {
    super.initState();
    _fetchReporterEmployeeId();
  }

  /// Fetch the reporter's employeeId from users collection
  Future<void> _fetchReporterEmployeeId() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _reporterEmployeeId = userDoc.data()?['employeeId']?.toString();
        });
      }
    } catch (e) {
      debugPrint('Error fetching reporter employeeId: $e');
    }
  }

  /// Fetch employeeId for the violator based on name and position
  Future<String?> _fetchViolatorEmployeeId(String name, String position) async {
    try {
      // Normalize input: remove commas, extra spaces, lowercase, split and sort
      List<String> inputWords =
          name
              .toLowerCase()
              .replaceAll(',', '')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim()
              .split(' ')
            ..sort();

      // Search by role first
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: position.toLowerCase())
          .get();

      // Compare normalized names
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final dbName = data['name']?.toString() ?? '';

        // Normalize database name the same way
        List<String> dbWords =
            dbName
                .toLowerCase()
                .replaceAll(',', '')
                .replaceAll(RegExp(r'\s+'), ' ')
                .trim()
                .split(' ')
              ..sort();

        // Compare sorted word lists
        if (inputWords.join(' ') == dbWords.join(' ')) {
          final employeeId = data['employeeId']?.toString();
          if (employeeId != null && employeeId.isNotEmpty) {
            debugPrint('Found employee: $dbName with ID: $employeeId');
            return employeeId;
          }
        }
      }

      debugPrint('No match found for: $name');
      return null;
    } catch (e) {
      debugPrint('Error fetching violator employeeId: $e');
      return null;
    }
  }

  // Validation functions
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name of violator is required';
    }
    if (!RegExp(r'^[a-zA-Z\s]*$').hasMatch(value)) {
      return 'Only letters and spaces are allowed';
    }
    if (value.length > 36) {
      return 'Maximum 36 letters only';
    }
    return null;
  }

  String? _validateViolation(String? value) {
    if (value == null || value.isEmpty) {
      return 'Violation committed is required';
    }
    if (value.length > 100) {
      return 'Maximum 100 characters only';
    }
    return null;
  }

  String? _validateLocation(String? value) {
    if (value == null || value.isEmpty) {
      return 'Location is required';
    }
    if (value.length > 36) {
      return 'Maximum 36 characters only';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0D2364),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Violation Report Form',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Study according to the form on accurate and correct information.',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Name of violator field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Name of violator:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    maxLength: 36,
                    validator: _validateName,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      hintText: 'Enter violator name',
                      counterText: '',
                    ),
                    onChanged: (value) {
                      // Filter out numbers and allow only letters and spaces
                      if (value.isNotEmpty &&
                          !RegExp(r'^[a-zA-Z\s]*$').hasMatch(value)) {
                        final filteredValue = value.replaceAll(
                          RegExp(r'[^a-zA-Z\s]'),
                          '',
                        );
                        _nameController.value = _nameController.value.copyWith(
                          text: filteredValue,
                          selection: TextSelection.collapsed(
                            offset: filteredValue.length,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Position field - CHANGED TO DROPDOWN
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Position:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey.shade400,
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _positionController.text.isNotEmpty
                          ? _positionController.text
                          : null,
                      onChanged: (String? newValue) {
                        setState(() {
                          _positionController.text = newValue ?? '';
                        });
                      },
                      items: _positionOptions.map<DropdownMenuItem<String>>((
                        String value,
                      ) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                          ),
                        );
                      }).toList(),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 8.0,
                        ),
                        isDense: true,
                      ),
                      validator: (value) =>
                          value == null ? 'Please select position' : null,
                      isExpanded: true,
                      hint: Text(
                        'Select position...',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Violation Type Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Violation Type:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // Dropdown for violation types
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey.shade400,
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedViolationType,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedViolationType = newValue;
                          if (newValue != 'Other/s') {
                            _otherViolationController.clear();
                            // Auto-fill the violation description with selected type
                            _violationController.text = newValue ?? '';
                          } else {
                            _violationController.clear();
                          }
                        });
                      },
                      items: _violationTypes.map<DropdownMenuItem<String>>((
                        String value,
                      ) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                          ),
                        );
                      }).toList(),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 8.0,
                        ),
                        isDense: true,
                      ),
                      validator: (value) =>
                          value == null ? 'Please select violation type' : null,
                      isExpanded: true,
                      hint: Text(
                        'Select violation type...',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),

                  // Other Violation Text Field (appears only when "Other/s" is selected)
                  if (_selectedViolationType == 'Other/s') ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _otherViolationController,
                      maxLength: 36,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        hintText: 'Specify other violation type...',
                        labelText: 'Other Violation Type',
                        counterText: '',
                      ),
                      onChanged: (value) {
                        // Auto-fill the violation description with other type
                        _violationController.text = value;
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Violation Committed field (Description) - UPDATED TO 100 CHARACTERS
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Violation Committed:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _violationController,
                    maxLines: 3,
                    maxLength: 100, // CHANGED FROM 36 TO 100
                    validator: _validateViolation,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      hintText:
                          'Describe the violation in detail (max 100 characters)',
                      counterText: '',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Location field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Location:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _locationController,
                    maxLength: 36,
                    validator: _validateLocation,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      hintText: 'Enter location',
                      counterText: '',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Time field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Time:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (pickedTime != null) {
                        final formattedTime = pickedTime.format(context);
                        setState(() {
                          _timeController.text = formattedTime;
                        });
                      }
                    },
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: _timeController,
                        decoration: InputDecoration(
                          hintText: 'Select time',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          suffixIcon: const Icon(Icons.access_time),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Save & Submit button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          _saveAndSubmit();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D2364),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Save & Submit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _saveAndSubmit() async {
    // Validate all fields
    final nameError = _validateName(_nameController.text);
    final violationError = _validateViolation(_violationController.text);
    final locationError = _validateLocation(_locationController.text);

    if (nameError != null || violationError != null || locationError != null) {
      _showDialog(
        'Error',
        'Please fix all validation errors before submitting',
      );
      return;
    }

    // Validation for violation type field
    if (_selectedViolationType == null) {
      _showDialog('Error', 'Please select a violation type');
      return;
    }

    if (_selectedViolationType == 'Other/s' &&
        _otherViolationController.text.isEmpty) {
      _showDialog('Error', 'Please specify the other violation type');
      return;
    }

    if (_nameController.text.isEmpty ||
        _positionController.text.isEmpty ||
        _violationController.text.isEmpty ||
        _locationController.text.isEmpty ||
        _timeController.text.isEmpty) {
      _showDialog('Error', 'Please fill in all fields');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get logged-in user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showDialog('Error', 'You must be logged in to submit a report');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Fetch violator's employeeId
      _reportedEmployeeId = await _fetchViolatorEmployeeId(
        _nameController.text.trim(),
        _positionController.text.trim(),
      );

      if (_reportedEmployeeId == null || _reportedEmployeeId!.isEmpty) {
        final shouldContinue = await _showConfirmationDialog(
          'Employee Not Found',
          'The violator "${_nameController.text.trim()}" with position "${_positionController.text.trim()}" was not found in the system.\n\nDo you want to submit the report anyway?',
        );

        if (!shouldContinue) {
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // Determine the final violation type value
      String finalViolationType;
      if (_selectedViolationType == 'Other/s' &&
          _otherViolationController.text.isNotEmpty) {
        finalViolationType = _otherViolationController.text.trim();
      } else {
        finalViolationType = _selectedViolationType ?? '';
      }

      // Add to Firestore
      await FirebaseFirestore.instance.collection('violation_report').add({
        'reportedName': _nameController.text.trim(),
        'reportedPosition': _positionController.text.trim(),
        'reportedEmployeeId': _reportedEmployeeId ?? '',
        'violationType': finalViolationType, // New field for violation type
        'violation': _violationController.text
            .trim(), // Existing violation description
        'location': _locationController.text.trim(),
        'time': _timeController.text.trim(),
        'reporterUid': user.uid,
        'reporterEmployeeId': _reporterEmployeeId ?? 'Not found',
        'submittedAt': FieldValue.serverTimestamp(),
      });

      _showDialog('Success', 'Violation report submitted successfully!');

      // Clear form
      _nameController.clear();
      _positionController.clear();
      _violationController.clear();
      _locationController.clear();
      _timeController.clear();
      _otherViolationController.clear();
      setState(() {
        _reportedEmployeeId = null;
        _selectedViolationType = null;
      });
    } catch (e) {
      _showDialog('Error', 'Failed to submit report: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _showConfirmationDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _positionController.dispose();
    _violationController.dispose();
    _locationController.dispose();
    _timeController.dispose();
    _otherViolationController.dispose();
    super.dispose();
  }
}
