import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io' show File;
import 'package:url_launcher/url_launcher.dart';

class Candidate {
  final String id;
  String firstName;
  String middleName;
  String lastName;
  String position;
  String interviewDate;
  String interviewTime;
  String? resumeUrl;
  String? resumeFileName;
  Map<String, bool> requirements;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? archivedAt;

  Candidate({
    required this.id,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.position,
    required this.interviewDate,
    required this.interviewTime,
    this.resumeUrl,
    this.resumeFileName,
    Map<String, bool>? requirements,
    this.createdAt,
    this.updatedAt,
    this.archivedAt,
  }) : requirements =
           requirements ??
           _getDefaultRequirements(position); // FIXED: Pass position here

  // Get full name
  String get fullName {
    List<String> names = [firstName];
    if (middleName.isNotEmpty) names.add(middleName);
    names.add(lastName);
    return names.join(' ');
  }

  // Method to get default requirements based on position
  static Map<String, bool> _getDefaultRequirements(String position) {
    String lowerPosition = position.toLowerCase(); // FIXED: Case insensitive

    switch (lowerPosition) {
      case 'driver':
        return {
          'Resume': false,
          'Driver License': false,
          'Government Issued IDs': false,
          'NBI Clearance': false,
          'Barangay Clearance': false,
          'Medical Certificate': false,
          'Initial Interview': false,
          'Training': false,
        };
      case 'conductor':
      case 'inspector':
      case 'legal officer':
        return {
          'Resume': false,
          'Government Issued IDs': false,
          'NBI Clearance': false,
          'Barangay Clearance': false,
          'Medical Certificate': false,
          'Initial Interview': false,
          'Training': false,
        };
      default:
        return {
          'Resume': false,
          'Government Issued IDs': false,
          'NBI Clearance': false,
          'Barangay Clearance': false,
          'Medical Certificate': false,
          'Initial Interview': false,
          'Training': false,
        };
    }
  }

  // Update requirements when position changes
  void updateRequirementsForPosition(String newPosition) {
    final newRequirements = _getDefaultRequirements(newPosition);

    // Preserve existing requirement statuses if they exist in new requirements
    for (var requirement in newRequirements.keys) {
      if (requirements.containsKey(requirement)) {
        newRequirements[requirement] = requirements[requirement]!;
      }
    }

    requirements = newRequirements;
  }

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'position': position,
      'interviewDate': interviewDate,
      'interviewTime': interviewTime,
      'resumeUrl': resumeUrl,
      'resumeFileName': resumeFileName,
      'requirements': requirements,
      'updatedAt': FieldValue.serverTimestamp(),
      'archivedAt': archivedAt != null ? Timestamp.fromDate(archivedAt!) : null,
    };
  }

  factory Candidate.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // FIXED: Ensure requirements are properly initialized based on position
    Map<String, bool>? existingRequirements;
    if (data['requirements'] != null) {
      existingRequirements = Map<String, bool>.from(data['requirements']);
    }

    return Candidate(
      id: doc.id,
      firstName: data['firstName'] ?? '',
      middleName: data['middleName'] ?? '',
      lastName: data['lastName'] ?? '',
      position: data['position'] ?? '',
      interviewDate: data['interviewDate'] ?? '',
      interviewTime: data['interviewTime'] ?? '',
      resumeUrl: data['resumeUrl'],
      resumeFileName: data['resumeFileName'],
      requirements:
          existingRequirements, // Use existing requirements if available
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      archivedAt: (data['archivedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Check if candidate should be automatically removed (archived for more than 30 days)
  bool shouldBeRemoved() {
    if (archivedAt == null) return false;
    final now = DateTime.now();
    final daysInArchive = now.difference(archivedAt!).inDays;
    return daysInArchive > 30;
  }
}

class ApplicantManagementScreen extends StatefulWidget {
  const ApplicantManagementScreen({super.key});

  @override
  State<ApplicantManagementScreen> createState() =>
      _ApplicantManagementScreenState();
}

class _ApplicantManagementScreenState extends State<ApplicantManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

  String _selectedFilter = 'All';
  int _rowsPerPage = 10;
  int _currentPage = 0;
  bool _isLoading = false;

  // List of available positions for dropdown
  final List<String> _positionOptions = [
    'Legal Officer',
    'Driver',
    'Conductor',
    'Inspector',
  ];

  @override
  void initState() {
    super.initState();
    // Auto-clean archived candidates on app start
    _cleanExpiredArchives();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  // Clean candidates that have been archived for more than 30 days
  Future<void> _cleanExpiredArchives() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final expiredQuery = _firestore
          .collection('candidates')
          .where('archivedAt', isLessThan: Timestamp.fromDate(thirtyDaysAgo));

      final snapshot = await expiredQuery.get();

      for (final doc in snapshot.docs) {
        final candidate = Candidate.fromFirestore(doc);
        await _deleteCandidatePermanently(candidate);
      }
    } catch (e) {
      debugPrint('Error cleaning expired archives: $e');
    }
  }

  Stream<List<Candidate>> _getCandidatesStream() {
    Query query = _firestore
        .collection('candidates')
        .where('archivedAt', isNull: true) // Only show non-archived candidates
        .orderBy('createdAt', descending: true);

    if (_selectedFilter != 'All') {
      query = query.where('position', isEqualTo: _selectedFilter);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Candidate.fromFirestore(doc)).toList();
    });
  }

  List<Candidate> _filterCandidates(List<Candidate> candidates) {
    if (_searchController.text.isEmpty) {
      return candidates;
    }

    final search = _searchController.text.toLowerCase();
    return candidates.where((candidate) {
      return candidate.fullName.toLowerCase().contains(search) ||
          candidate.position.toLowerCase().contains(search);
    }).toList();
  }

  List<Candidate> _paginateCandidates(List<Candidate> candidates) {
    final startIndex = _currentPage * _rowsPerPage;
    final endIndex = startIndex + _rowsPerPage;

    if (startIndex >= candidates.length) {
      return [];
    }

    return candidates.sublist(
      startIndex,
      endIndex > candidates.length ? candidates.length : endIndex,
    );
  }

  Future<void> _addCandidate(Candidate candidate) async {
    try {
      setState(() => _isLoading = true);

      await _firestore.collection('candidates').add({
        ...candidate.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Candidate added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding candidate: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateCandidate(Candidate candidate) async {
    try {
      setState(() => _isLoading = true);

      await _firestore
          .collection('candidates')
          .doc(candidate.id)
          .update(candidate.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Candidate updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating candidate: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _archiveCandidate(Candidate candidate) async {
    try {
      setState(() => _isLoading = true);

      // Mark as archived with current timestamp
      await _firestore.collection('candidates').doc(candidate.id).update({
        'archivedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${candidate.fullName} has been archived')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error archiving candidate: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCandidatePermanently(Candidate candidate) async {
    try {
      // Delete resume file if exists
      if (candidate.resumeUrl != null) {
        try {
          await _storage.refFromURL(candidate.resumeUrl!).delete();
        } catch (e) {
          debugPrint('Error deleting resume file: $e');
        }
      }

      // Delete candidate document
      await _firestore.collection('candidates').doc(candidate.id).delete();
    } catch (e) {
      debugPrint('Error permanently deleting candidate: $e');
    }
  }

  void _showCandidateDialog({Candidate? candidate}) {
    final isEditing = candidate != null;
    final firstNameController = TextEditingController(
      text: candidate?.firstName ?? '',
    );
    final middleNameController = TextEditingController(
      text: candidate?.middleName ?? '',
    );
    final lastNameController = TextEditingController(
      text: candidate?.lastName ?? '',
    );

    // FIXED: Ensure the initial value exists in the position options
    String selectedPosition;
    if (candidate?.position != null &&
        _positionOptions.contains(candidate!.position)) {
      selectedPosition = candidate.position;
    } else {
      selectedPosition = _positionOptions.first;
    }

    final dateController = TextEditingController(
      text: candidate?.interviewDate ?? '',
    );
    final timeController = TextEditingController(
      text: candidate?.interviewTime ?? '',
    );
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isEditing ? 'Edit Candidate' : 'Add New Candidate',
                style: TextStyle(fontSize: isMobile ? 16 : 18),
              ),
              content: SizedBox(
                width: isMobile ? double.maxFinite : 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // First Name
                      TextField(
                        controller: firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'First Name *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Middle Name
                      TextField(
                        controller: middleNameController,
                        decoration: const InputDecoration(
                          labelText: 'Middle Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Last Name
                      TextField(
                        controller: lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Last Name *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Position Dropdown
                      DropdownButtonFormField<String>(
                        value: selectedPosition,
                        onChanged: (String? newValue) {
                          setDialogState(() {
                            selectedPosition = newValue!;
                            // Update requirements when position changes
                            if (isEditing) {
                              candidate.updateRequirementsForPosition(newValue);
                            }
                          });
                        },
                        items: _positionOptions.map<DropdownMenuItem<String>>((
                          String position,
                        ) {
                          return DropdownMenuItem<String>(
                            value: position,
                            child: Text(position),
                          );
                        }).toList(),
                        decoration: const InputDecoration(
                          labelText: 'Position *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.work),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Interview Date and Time in a row for desktop
                      if (!isMobile)
                        Row(
                          children: [
                            // Date Picker
                            Expanded(
                              child: TextField(
                                controller: dateController,
                                readOnly: true,
                                decoration: InputDecoration(
                                  labelText: 'Interview Date *',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.calendar_today),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setDialogState(() {
                                        dateController.clear();
                                        selectedDate = null;
                                      });
                                    },
                                  ),
                                ),
                                onTap: () async {
                                  final DateTime? pickedDate =
                                      await showDatePicker(
                                        context: context,
                                        initialDate:
                                            selectedDate ?? DateTime.now(),
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime(2100),
                                      );

                                  if (pickedDate != null) {
                                    setDialogState(() {
                                      selectedDate = pickedDate;
                                      dateController.text =
                                          '${pickedDate.month.toString().padLeft(2, '0')}/'
                                          '${pickedDate.day.toString().padLeft(2, '0')}/'
                                          '${pickedDate.year.toString().substring(2)}';
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Time Picker
                            Expanded(
                              child: TextField(
                                controller: timeController,
                                readOnly: true,
                                decoration: InputDecoration(
                                  labelText: 'Interview Time *',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.access_time),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setDialogState(() {
                                        timeController.clear();
                                        selectedTime = null;
                                      });
                                    },
                                  ),
                                ),
                                onTap: () async {
                                  final TimeOfDay? pickedTime =
                                      await showTimePicker(
                                        context: context,
                                        initialTime:
                                            selectedTime ?? TimeOfDay.now(),
                                      );

                                  if (pickedTime != null) {
                                    setDialogState(() {
                                      selectedTime = pickedTime;
                                      timeController.text =
                                          '${pickedTime.hour.toString().padLeft(2, '0')}:'
                                          '${pickedTime.minute.toString().padLeft(2, '0')}';
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            // Date Picker for mobile
                            TextField(
                              controller: dateController,
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'Interview Date *',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.calendar_today),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setDialogState(() {
                                      dateController.clear();
                                      selectedDate = null;
                                    });
                                  },
                                ),
                              ),
                              onTap: () async {
                                final DateTime? pickedDate =
                                    await showDatePicker(
                                      context: context,
                                      initialDate:
                                          selectedDate ?? DateTime.now(),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );

                                if (pickedDate != null) {
                                  setDialogState(() {
                                    selectedDate = pickedDate;
                                    dateController.text =
                                        '${pickedDate.month.toString().padLeft(2, '0')}/'
                                        '${pickedDate.day.toString().padLeft(2, '0')}/'
                                        '${pickedDate.year.toString().substring(2)}';
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 12),

                            // Time Picker for mobile
                            TextField(
                              controller: timeController,
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'Interview Time *',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.access_time),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setDialogState(() {
                                      timeController.clear();
                                      selectedTime = null;
                                    });
                                  },
                                ),
                              ),
                              onTap: () async {
                                final TimeOfDay? pickedTime =
                                    await showTimePicker(
                                      context: context,
                                      initialTime:
                                          selectedTime ?? TimeOfDay.now(),
                                    );

                                if (pickedTime != null) {
                                  setDialogState(() {
                                    selectedTime = pickedTime;
                                    timeController.text =
                                        '${pickedTime.hour.toString().padLeft(2, '0')}:'
                                        '${pickedTime.minute.toString().padLeft(2, '0')}';
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D2364),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (firstNameController.text.isNotEmpty &&
                        lastNameController.text.isNotEmpty &&
                        selectedPosition.isNotEmpty &&
                        dateController.text.isNotEmpty &&
                        timeController.text.isNotEmpty) {
                      if (isEditing) {
                        candidate.firstName = firstNameController.text;
                        candidate.middleName = middleNameController.text;
                        candidate.lastName = lastNameController.text;
                        candidate.position = selectedPosition;
                        candidate.interviewDate = dateController.text;
                        candidate.interviewTime = timeController.text;
                        _updateCandidate(candidate);
                      } else {
                        // FIXED: Create candidate with position to generate correct requirements
                        final newCandidate = Candidate(
                          id: '',
                          firstName: firstNameController.text,
                          middleName: middleNameController.text,
                          lastName: lastNameController.text,
                          position:
                              selectedPosition, // This will generate correct requirements
                          interviewDate: dateController.text,
                          interviewTime: timeController.text,
                        );

                        // DEBUG: Print requirements to verify
                        debugPrint(
                          'Creating candidate with position: $selectedPosition',
                        );
                        debugPrint(
                          'Requirements: ${newCandidate.requirements}',
                        );

                        _addCandidate(newCandidate);
                      }
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill all required fields (*)'),
                        ),
                      );
                    }
                  },
                  child: Text(isEditing ? 'Save' : 'Add Candidate'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _uploadResume(Candidate candidate) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'], // Only PDF
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;

        // Check file size (3MB limit)
        if (file.size > 3 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File size must be less than 3MB')),
            );
          }
          return;
        }

        setState(() => _isLoading = true);

        // Delete old resume if exists
        if (candidate.resumeUrl != null) {
          try {
            await _storage.refFromURL(candidate.resumeUrl!).delete();
          } catch (e) {
            debugPrint('Error deleting old resume: $e');
          }
        }

        String fileName =
            '${candidate.id}_${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        Reference storageRef = _storage.ref().child('resumes/$fileName');

        UploadTask uploadTask;

        // Use bytes (works on all platforms including web)
        if (file.bytes != null) {
          uploadTask = storageRef.putData(
            file.bytes!,
            SettableMetadata(contentType: 'application/pdf'),
          );
        } else if (file.path != null) {
          // Fallback to file path for platforms that support it
          File fileToUpload = File(file.path!);
          uploadTask = storageRef.putFile(
            fileToUpload,
            SettableMetadata(contentType: 'application/pdf'),
          );
        } else {
          throw Exception('No file data available');
        }

        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();

        candidate.resumeUrl = downloadUrl;
        candidate.resumeFileName = file.name;

        // Mark resume requirement as completed
        candidate.requirements['Resume'] = true;

        await _updateCandidate(candidate);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Resume uploaded for ${candidate.fullName}'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading file: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _viewResumeInBrowser(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No app available to open this link')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error opening URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error opening resume: $e')));
      }
    }
  }

  void _showRequirementsChecklist(Candidate candidate) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // FIXED: Ensure all requirements are properly initialized
            _initializeRequirements(candidate);

            // Auto-check Resume if already uploaded
            if (candidate.resumeUrl != null &&
                !candidate.requirements['Resume']!) {
              candidate.requirements['Resume'] = true;
            }

            // Get ALL requirements without filtering
            List<MapEntry<String, bool>> requirementsList = candidate
                .requirements
                .entries
                .toList();

            // Sort requirements: checked items first, then unchecked
            requirementsList.sort((a, b) {
              if (a.value == b.value) return 0;
              return a.value ? -1 : 1;
            });

            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    Icons.checklist,
                    color: const Color(0xFF0D2364),
                    size: isMobile ? 20 : 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Requirements - ${candidate.fullName}',
                      style: TextStyle(fontSize: isMobile ? 14 : 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: isMobile ? double.maxFinite : 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Display position-specific note
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue[700], size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                candidate.position == 'Driver'
                                    ? 'Driver-specific requirements include Driver License'
                                    : 'General employment requirements',
                                style: TextStyle(
                                  fontSize: isMobile ? 12 : 13,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Requirements Checklist - Show ALL requirements
                      ...requirementsList.map((entry) {
                        return _buildRequirementItem(
                          entry.key,
                          entry.value,
                          (value) {
                            setDialogState(() {
                              candidate.requirements[entry.key] = value;
                              // Re-sort when value changes
                              requirementsList =
                                  candidate.requirements.entries.toList()
                                    ..sort((a, b) {
                                      if (a.value == b.value) return 0;
                                      return a.value ? -1 : 1;
                                    });
                            });
                          },
                          isMobile,
                          candidate: candidate,
                        );
                      }),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Completion Status:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: isMobile ? 13 : 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildCompletionStatus(candidate, isMobile),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _updateCandidate(candidate);
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // FIXED: New method to ensure requirements are properly initialized
  void _initializeRequirements(Candidate candidate) {
    final defaultRequirements = Candidate._getDefaultRequirements(
      candidate.position,
    );

    // Add any missing requirements from the default set
    for (var requirement in defaultRequirements.keys) {
      if (!candidate.requirements.containsKey(requirement)) {
        candidate.requirements[requirement] = false;
      }
    }

    // Remove any requirements that shouldn't be there for this position
    List<String> requirementsToRemove = [];
    for (var requirement in candidate.requirements.keys) {
      if (!defaultRequirements.containsKey(requirement)) {
        requirementsToRemove.add(requirement);
      }
    }

    for (var requirement in requirementsToRemove) {
      candidate.requirements.remove(requirement);
    }
  }

  Widget _buildRequirementItem(
    String title,
    bool isChecked,
    Function(bool) onChanged,
    bool isMobile, {
    Candidate? candidate,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: isChecked ? Colors.green[50] : null,
      child: Column(
        // Changed from ListTile to Column for better mobile control
        children: [
          ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 8 : 16,
              vertical: isMobile ? 4 : 8,
            ),
            leading: Checkbox(
              value: isChecked,
              onChanged: (value) {
                // For Resume, only allow unchecking manually, checking happens through upload
                if (title == 'Resume' &&
                    value == true &&
                    candidate?.resumeUrl == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please upload resume first')),
                  );
                  return;
                }
                onChanged(value ?? false);
              },
            ),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: isMobile ? 13 : 14,
                decoration: isChecked ? TextDecoration.lineThrough : null,
                color: isChecked ? Colors.green : Colors.black,
              ),
            ),
          ),
          // Resume upload section - moved outside ListTile
          if (title == 'Resume' && candidate != null) ...[
            Padding(
              padding: EdgeInsets.only(
                left: isMobile ? 8 : 16,
                right: isMobile ? 8 : 16,
                bottom: isMobile ? 8 : 12,
              ),
              child: candidate.resumeUrl == null
                  ? SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.upload, size: 14),
                        label: Text(
                          'Upload Resume',
                          style: TextStyle(fontSize: isMobile ? 11 : 12),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _uploadResume(candidate);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D2364),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 8 : 12,
                            vertical: isMobile ? 8 : 10,
                          ),
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Filename row
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: isMobile ? 14 : 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                candidate.resumeFileName ?? 'Resume uploaded',
                                style: TextStyle(
                                  fontSize: isMobile ? 11 : 12,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Action buttons row
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: Icon(
                                  Icons.visibility,
                                  size: isMobile ? 14 : 16,
                                ),
                                label: Text(
                                  'View',
                                  style: TextStyle(
                                    fontSize: isMobile ? 11 : 12,
                                  ),
                                ),
                                onPressed: () {
                                  if (candidate.resumeUrl != null) {
                                    _viewResumeInBrowser(candidate.resumeUrl!);
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue,
                                  side: const BorderSide(color: Colors.blue),
                                  padding: EdgeInsets.symmetric(
                                    vertical: isMobile ? 8 : 10,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: Icon(
                                  Icons.upload,
                                  size: isMobile ? 14 : 16,
                                ),
                                label: Text(
                                  'Reupload',
                                  style: TextStyle(
                                    fontSize: isMobile ? 11 : 12,
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  _uploadResume(candidate);
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.orange,
                                  side: const BorderSide(color: Colors.orange),
                                  padding: EdgeInsets.symmetric(
                                    vertical: isMobile ? 8 : 10,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompletionStatus(Candidate candidate, bool isMobile) {
    // Calculate completion based on ALL requirements
    int completed = candidate.requirements.values
        .where((value) => value)
        .length;
    int total = candidate.requirements.length;
    double percentage = total > 0 ? (completed / total) * 100 : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: Colors.grey[300],
          color: percentage == 100 ? Colors.green : const Color(0xFF0D2364),
        ),
        const SizedBox(height: 8),
        Text(
          '$completed/$total requirements completed (${percentage.toStringAsFixed(1)}%)',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 12 : 14,
            color: percentage == 100 ? Colors.green : const Color(0xFF0D2364),
          ),
        ),
      ],
    );
  }

  String _getRequirementsStatus(Candidate candidate) {
    // Calculate status based on ALL requirements
    int completed = candidate.requirements.values
        .where((value) => value)
        .length;
    int total = candidate.requirements.length;
    return '$completed/$total';
  }

  Color _getCompletionColor(Candidate candidate) {
    // Calculate completion based on ALL requirements
    int completed = candidate.requirements.values
        .where((value) => value)
        .length;
    int total = candidate.requirements.length;
    double percentage = total > 0 ? (completed / total) * 100 : 0;

    if (percentage == 100) {
      return Colors.green;
    } else if (percentage >= 50) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Widget _buildCardInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF0D2364)),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showArchiveDialog(Candidate candidate) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.archive, color: Colors.orange),
              SizedBox(width: 8),
              Text('Archive Candidate'),
            ],
          ),
          content: Text(
            'Are you sure you want to archive ${candidate.fullName}? '
            'Archived candidates will be automatically removed after 30 days.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                _archiveCandidate(candidate);
                Navigator.pop(context);
              },
              child: const Text('Archive'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDesktopTable(List<Candidate> candidates, bool isTablet) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: EdgeInsets.zero,
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Scrollbar(
          controller: _verticalScrollController,
          thumbVisibility: true,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
              scrollbars: true,
            ),
            child: SingleChildScrollView(
              controller: _verticalScrollController,
              scrollDirection: Axis.vertical,
              child: Scrollbar(
                controller: _horizontalScrollController,
                thumbVisibility: true,
                notificationPredicate: (notification) =>
                    notification.depth == 1,
                child: SingleChildScrollView(
                  controller: _horizontalScrollController,
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 150,
                    horizontalMargin: 12,
                    dataRowMinHeight: 50,
                    dataRowMaxHeight: 60,
                    headingRowColor: WidgetStateProperty.all(
                      const Color(0xFF0D2364),
                    ),
                    columns: [
                      DataColumn(
                        label: SizedBox(
                          width: 200,
                          child: Text(
                            'Candidate Name',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isTablet ? 13 : 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 120,
                          child: Text(
                            'Position',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isTablet ? 13 : 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 120,
                          child: Text(
                            'Interview Date',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isTablet ? 13 : 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 120,
                          child: Text(
                            'Interview Time',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isTablet ? 13 : 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 100,
                          child: Text(
                            'Requirements',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isTablet ? 13 : 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 80,
                          child: Text(
                            'Actions',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isTablet ? 13 : 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                    rows: candidates.map((candidate) {
                      return DataRow(
                        cells: [
                          DataCell(
                            SizedBox(
                              width: 180,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.person,
                                    color: Color(0xFF0D2364),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      candidate.fullName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: isTablet ? 12 : 13,
                                        color: Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 100,
                              child: Text(
                                candidate.position,
                                style: TextStyle(
                                  fontSize: isTablet ? 12 : 13,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 100,
                              child: Text(
                                candidate.interviewDate,
                                style: TextStyle(
                                  fontSize: isTablet ? 12 : 13,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 100,
                              child: Text(
                                candidate.interviewTime,
                                style: TextStyle(
                                  fontSize: isTablet ? 12 : 13,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 80,
                              child: InkWell(
                                onTap: () =>
                                    _showRequirementsChecklist(candidate),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getCompletionColor(
                                      candidate,
                                    ).withAlpha(30),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _getCompletionColor(candidate),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.checklist,
                                        size: 12,
                                        color: _getCompletionColor(candidate),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _getRequirementsStatus(candidate),
                                        style: TextStyle(
                                          fontSize: isTablet ? 10 : 11,
                                          fontWeight: FontWeight.bold,
                                          color: _getCompletionColor(candidate),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 60,
                              child: IconButton(
                                icon: const Icon(Icons.archive, size: 16),
                                onPressed: () => _showArchiveDialog(candidate),
                                tooltip: 'Archive',
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.orange[50],
                                  foregroundColor: Colors.orange,
                                  padding: const EdgeInsets.all(6),
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
      ),
    );
  }

  Widget _buildMobileCards(List<Candidate> candidates) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: EdgeInsets.zero,
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: ListView.builder(
          itemCount: candidates.length,
          itemBuilder: (context, index) {
            final candidate = candidates[index];
            return Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.person,
                        color: Color(0xFF0D2364),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          candidate.fullName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D2364),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _getCompletionColor(candidate).withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getCompletionColor(candidate),
                          ),
                        ),
                        child: Text(
                          'REQs: ${_getRequirementsStatus(candidate)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _getCompletionColor(candidate),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildCardInfoRow(Icons.work, 'Position', candidate.position),
                  _buildCardInfoRow(
                    Icons.calendar_today,
                    'Interview Date',
                    candidate.interviewDate,
                  ),
                  _buildCardInfoRow(
                    Icons.access_time,
                    'Interview Time',
                    candidate.interviewTime,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.checklist, size: 14),
                      label: const Text(
                        'Requirements & Resume',
                        style: TextStyle(fontSize: 13),
                      ),
                      onPressed: () => _showRequirementsChecklist(candidate),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0D2364),
                        side: const BorderSide(color: Color(0xFF0D2364)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.archive, size: 14),
                      label: const Text(
                        'Archive Candidate',
                        style: TextStyle(fontSize: 13),
                      ),
                      onPressed: () => _showArchiveDialog(candidate),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter(bool isMobile) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12.0),
        child: isMobile
            ? Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name or position...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF0D2364),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (_) {
                      setState(() {
                        _currentPage = 0;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedFilter,
                    onChanged: (value) {
                      setState(() {
                        _selectedFilter = value!;
                        _currentPage = 0;
                      });
                    },
                    items: ['All', ..._positionOptions]
                        .map<DropdownMenuItem<String>>((String position) {
                          return DropdownMenuItem<String>(
                            value: position,
                            child: Text(position),
                          );
                        })
                        .toList(),
                    decoration: InputDecoration(
                      labelText: 'Filter by Position',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('Add Candidate'),
                      onPressed: () => _showCandidateDialog(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D2364),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by name or position...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF0D2364),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                      onChanged: (_) {
                        setState(() {
                          _currentPage = 0;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: _selectedFilter,
                      onChanged: (value) {
                        setState(() {
                          _selectedFilter = value!;
                          _currentPage = 0;
                        });
                      },
                      items: ['All', ..._positionOptions]
                          .map<DropdownMenuItem<String>>((String position) {
                            return DropdownMenuItem<String>(
                              value: position,
                              child: Text(position),
                            );
                          })
                          .toList(),
                      decoration: InputDecoration(
                        labelText: 'Filter by Position',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Add Candidate'),
                    onPressed: () => _showCandidateDialog(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D2364),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPaginationControls(bool isMobile, int totalPages) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(top: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isMobile) ...[
              const Text('Rows per page:', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _rowsPerPage,
                onChanged: (value) {
                  setState(() {
                    _rowsPerPage = value!;
                    _currentPage = 0;
                  });
                },
                items: [5, 10, 15, 20].map<DropdownMenuItem<int>>((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text('$value'),
                  );
                }).toList(),
              ),
              const Spacer(),
            ],
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
            Text(
              'Page ${_currentPage + 1} of $totalPages',
              style: const TextStyle(fontSize: 14),
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
            if (isMobile) ...[
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text(''),
                onPressed: () => _showCandidateDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D2364),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchAndFilter(isMobile),
                  const SizedBox(height: 16),
                  Expanded(
                    child: StreamBuilder<List<Candidate>>(
                      stream: _getCandidatesStream(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: Colors.red,
                                ),
                                const SizedBox(height: 16),
                                Text('Error: ${snapshot.error}'),
                              ],
                            ),
                          );
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final allCandidates = snapshot.data ?? [];
                        final filteredCandidates = _filterCandidates(
                          allCandidates,
                        );
                        final paginatedCandidates = _paginateCandidates(
                          filteredCandidates,
                        );
                        final totalPages =
                            (filteredCandidates.length / _rowsPerPage).ceil();

                        return SizedBox(
                          width: double.infinity,
                          height: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Candidates (${filteredCandidates.length})',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D2364),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: isMobile
                                    ? _buildMobileCards(paginatedCandidates)
                                    : _buildDesktopTable(
                                        paginatedCandidates,
                                        isTablet,
                                      ),
                              ),
                              if (filteredCandidates.length > _rowsPerPage)
                                _buildPaginationControls(isMobile, totalPages),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black26,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
