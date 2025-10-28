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
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _violationController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _otherViolationController =
      TextEditingController();

  String? selectedViolatorName;
  List<Map<String, dynamic>> todayDrivers = [];
  List<Map<String, dynamic>> todayConductors = [];
  List<Map<String, dynamic>> availableViolators = [];
  bool isLoadingData = false;

  String? _reportedEmployeeId;
  String? _reporterEmployeeId;
  bool _isLoading = false;
  String? _selectedViolationType; // For dropdown selection

  String _getTodayDayName() {
    final now = DateTime.now();
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[now.weekday - 1];
  }

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
    _loadDropdownData();
  }

  Future<void> _loadDropdownData() async {
    setState(() => isLoadingData = true);

    try {
      final today = _getTodayDayName();

      // Get drivers scheduled for today
      final driversSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'driver')
          .where('status', isEqualTo: true)
          .get();

      todayDrivers = driversSnapshot.docs
          .where((doc) {
            final schedule = doc.data()['schedule'] as String?;
            return schedule != null && schedule.contains(today);
          })
          .map((doc) {
            return {
              'uid': doc.id,
              'name':
                  doc.data()['name'] ??
                  doc.data()['displayName'] ??
                  '${doc.data()['firstName'] ?? ''} ${doc.data()['lastName'] ?? ''}'
                      .trim(),
              'employeeId': doc.data()['employeeId'] ?? '',
              'data': doc.data(),
            };
          })
          .toList();

      // Get conductors scheduled for today
      final conductorsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'conductor')
          .where('status', isEqualTo: true)
          .get();

      todayConductors = conductorsSnapshot.docs
          .where((doc) {
            final schedule = doc.data()['schedule'] as String?;
            return schedule != null && schedule.contains(today);
          })
          .map((doc) {
            return {
              'uid': doc.id,
              'name':
                  doc.data()['name'] ??
                  doc.data()['displayName'] ??
                  '${doc.data()['firstName'] ?? ''} ${doc.data()['lastName'] ?? ''}'
                      .trim(),
              'employeeId': doc.data()['employeeId'] ?? '',
              'data': doc.data(),
            };
          })
          .toList();

      _updateAvailableViolators();
    } catch (e) {
      debugPrint('Error loading dropdown data: $e');
    } finally {
      setState(() => isLoadingData = false);
    }
  }

  void _updateAvailableViolators() {
    setState(() {
      if (_positionController.text == 'Driver') {
        availableViolators = todayDrivers;
      } else if (_positionController.text == 'Conductor') {
        availableViolators = todayConductors;
      } else {
        availableViolators = [];
      }
      // Reset selected name when position changes
      selectedViolatorName = null;
    });
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
      // Find from the filtered lists based on position
      final violatorList = position.toLowerCase() == 'driver'
          ? todayDrivers
          : todayConductors;

      final violator = violatorList.firstWhere(
        (v) => v['name'] == name,
        orElse: () => {},
      );

      return violator['employeeId'] as String?;
    } catch (e) {
      debugPrint('Error fetching violator employeeId: $e');
      return null;
    }
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
                    'Kindly complete the form with accurate and detailed information.',
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
                  DropdownButtonFormField<String>(
                    initialValue: selectedViolatorName,
                    isExpanded: true,
                    decoration: InputDecoration(
                      hintText: 'Select violator name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: availableViolators.isEmpty
                        ? null
                        : availableViolators.map((violator) {
                            return DropdownMenuItem<String>(
                              value: violator['name'] as String,
                              child: Text(
                                violator['name'] as String,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            );
                          }).toList(),
                    onChanged: availableViolators.isEmpty
                        ? null
                        : (value) {
                            setState(() {
                              selectedViolatorName = value;
                            });
                          },
                    hint: availableViolators.isEmpty
                        ? Text(
                            'Select position first or no violators available today',
                            style: TextStyle(color: Colors.grey[600]),
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                    validator: (value) =>
                        value == null ? 'Please select violator name' : null,
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
                      initialValue: _positionController.text.isNotEmpty
                          ? _positionController.text
                          : null,
                      onChanged: (String? newValue) {
                        setState(() {
                          _positionController.text = newValue ?? '';
                          _updateAvailableViolators();
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
                      initialValue: _selectedViolationType,
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

    if (selectedViolatorName == null ||
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
        selectedViolatorName ?? '',
        _positionController.text.trim(),
      );

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
        'reportedName': selectedViolatorName ?? '',
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

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Violation report submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear form
      setState(() {
        selectedViolatorName = null;
        availableViolators = [];
      });
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
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

  @override
  void dispose() {
    _positionController.dispose();
    _violationController.dispose();
    _locationController.dispose();
    _timeController.dispose();
    _otherViolationController.dispose();
    super.dispose();
  }
}
