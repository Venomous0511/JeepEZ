import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class Candidate {
  final String id;
  String name;
  String position;
  String interviewDate;
  String? resumeUrl;
  String? resumeFileName;
  Map<String, bool> requirements;
  DateTime? createdAt;
  DateTime? updatedAt;

  Candidate({
    required this.id,
    required this.name,
    required this.position,
    required this.interviewDate,
    this.resumeUrl,
    this.resumeFileName,
    Map<String, bool>? requirements,
    this.createdAt,
    this.updatedAt,
  }) : requirements =
           requirements ??
           {
             'Driver License': false,
             'Government Issued IDs': false,
             'NBI Clearance': false,
             'Barangay Clearance': false,
             'Medical Certificate': false,
             'Initial Interview': false,
             'Training': false,
           };

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'position': position,
      'interviewDate': interviewDate,
      'resumeUrl': resumeUrl,
      'resumeFileName': resumeFileName,
      'requirements': requirements,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory Candidate.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Candidate(
      id: doc.id,
      name: data['name'] ?? '',
      position: data['position'] ?? '',
      interviewDate: data['interviewDate'] ?? '',
      resumeUrl: data['resumeUrl'],
      resumeFileName: data['resumeFileName'],
      requirements: Map<String, bool>.from(data['requirements'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<List<Candidate>> _getCandidatesStream() {
    Query query = _firestore
        .collection('candidates')
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
      return candidate.name.toLowerCase().contains(search) ||
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

  void _showCandidateDialog({Candidate? candidate}) {
    final isEditing = candidate != null;
    final nameController = TextEditingController(text: candidate?.name ?? '');

    // FIX: Ensure the initial value exists in the position options
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
    DateTime? selectedDate;

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
                width: isMobile ? double.maxFinite : 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedPosition,
                        onChanged: (String? newValue) {
                          setDialogState(() {
                            selectedPosition = newValue!;
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
                          labelText: 'Position',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.work),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: dateController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Interview Date',
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
                          final DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: selectedDate ?? DateTime.now(),
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
                    if (nameController.text.isNotEmpty &&
                        selectedPosition.isNotEmpty &&
                        dateController.text.isNotEmpty) {
                      if (isEditing) {
                        candidate!.name = nameController.text;
                        candidate.position = selectedPosition;
                        candidate.interviewDate = dateController.text;
                        _updateCandidate(candidate);
                      } else {
                        final newCandidate = Candidate(
                          id: '',
                          name: nameController.text,
                          position: selectedPosition,
                          interviewDate: dateController.text,
                        );
                        _addCandidate(newCandidate);
                      }
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all fields')),
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

  // Iba pang methods nananatiling pareho...
  Future<void> _uploadResume(Candidate candidate) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() => _isLoading = true);

        PlatformFile file = result.files.first;
        File fileToUpload = File(file.path!);

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

        UploadTask uploadTask = storageRef.putFile(fileToUpload);
        TaskSnapshot snapshot = await uploadTask;

        String downloadUrl = await snapshot.ref.getDownloadURL();

        candidate.resumeUrl = downloadUrl;
        candidate.resumeFileName = file.name;
        await _updateCandidate(candidate);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Resume uploaded for ${candidate.name}')),
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

  void _viewResume(Candidate candidate) {
    if (candidate.resumeUrl == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No resume available')));
      return;
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Resume - ${candidate.name}',
            style: TextStyle(fontSize: isMobile ? 16 : 18),
          ),
          content: SizedBox(
            width: isMobile ? double.maxFinite : 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Position: ${candidate.position}',
                    style: TextStyle(fontSize: isMobile ? 13 : 14),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'File: ${candidate.resumeFileName ?? "Unknown"}',
                    style: TextStyle(fontSize: isMobile ? 12 : 14),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Resume stored and can be downloaded',
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.download),
                      label: const Text('Download Resume'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Resume URL: ${candidate.resumeUrl}'),
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D2364),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
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
          ],
        );
      },
    );
  }

  void _showRequirementsChecklist(Candidate candidate) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                      'Requirements - ${candidate.name}',
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
                      ...candidate.requirements.keys.map((key) {
                        return _buildRequirementItem(
                          key,
                          candidate.requirements[key] ?? false,
                          (value) {
                            setDialogState(() {
                              candidate.requirements[key] = value;
                            });
                          },
                          isMobile,
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

  Widget _buildRequirementItem(
    String title,
    bool isChecked,
    Function(bool) onChanged,
    bool isMobile,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 8 : 16,
          vertical: isMobile ? 4 : 8,
        ),
        leading: Checkbox(
          value: isChecked,
          onChanged: (value) => onChanged(value ?? false),
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
    );
  }

  Widget _buildCompletionStatus(Candidate candidate, bool isMobile) {
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
    int completed = candidate.requirements.values
        .where((value) => value)
        .length;
    int total = candidate.requirements.length;
    return '$completed/$total';
  }

  Color _getCompletionColor(Candidate candidate) {
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

  void _showDeleteDialog(Candidate candidate) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Candidate'),
          content: Text('Are you sure you want to delete ${candidate.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                _deleteCandidate(candidate);
                Navigator.pop(context);
              },
              child: const Text('Delete'),
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
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
              columnSpacing: 16,
              horizontalMargin: 16,
              dataRowMinHeight: 60,
              dataRowMaxHeight: 80,
              headingRowColor: WidgetStateProperty.all(const Color(0xFF0D2364)),
              columns: [
                DataColumn(
                  label: SizedBox(
                    width: 300,
                    child: Text(
                      'Candidate Name',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isTablet ? 14 : 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: 220,
                    child: Text(
                      'Position',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isTablet ? 14 : 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: 220,
                    child: Text(
                      'Interview Date',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isTablet ? 14 : 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: 220,
                    child: Text(
                      'Requirements',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isTablet ? 14 : 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: 300,
                    child: Text(
                      'Resume',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isTablet ? 14 : 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: 220,
                    child: Text(
                      'Actions',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isTablet ? 14 : 16,
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
                        width: 250,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                candidate.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: isTablet ? 13 : 15,
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
                        width: 150,
                        child: Text(
                          candidate.position,
                          style: TextStyle(fontSize: isTablet ? 13 : 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 200,
                        child: Text(
                          candidate.interviewDate,
                          style: TextStyle(fontSize: isTablet ? 13 : 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 200,
                        child: InkWell(
                          onTap: () => _showRequirementsChecklist(candidate),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _getCompletionColor(
                                candidate,
                              ).withAlpha(1),
                              borderRadius: BorderRadius.circular(12),
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
                                  size: 14,
                                  color: _getCompletionColor(candidate),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _getRequirementsStatus(candidate),
                                  style: TextStyle(
                                    fontSize: isTablet ? 12 : 14,
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
                        width: 200,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.upload, size: 16),
                                label: Text(
                                  candidate.resumeUrl == null
                                      ? 'Upload'
                                      : 'Reupload',
                                  style: TextStyle(
                                    fontSize: isTablet ? 12 : 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onPressed: () => _uploadResume(candidate),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0D2364),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isTablet ? 8 : 10,
                                    vertical: isTablet ? 6 : 8,
                                  ),
                                ),
                              ),
                            ),
                            if (candidate.resumeUrl != null) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.visibility, size: 18),
                                onPressed: () => _viewResume(candidate),
                                tooltip: 'View Resume',
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.green[50],
                                  foregroundColor: Colors.green,
                                  padding: const EdgeInsets.all(6),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 150,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18),
                              onPressed: () =>
                                  _showCandidateDialog(candidate: candidate),
                              tooltip: 'Edit',
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.blue[50],
                                foregroundColor: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18),
                              onPressed: () => _showDeleteDialog(candidate),
                              tooltip: 'Delete',
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.red[50],
                                foregroundColor: Colors.red,
                              ),
                            ),
                          ],
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
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
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
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          candidate.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D2364),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getCompletionColor(candidate).withAlpha(1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getCompletionColor(candidate),
                          ),
                        ),
                        child: Text(
                          'REQs: ${_getRequirementsStatus(candidate)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getCompletionColor(candidate),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildCardInfoRow(Icons.work, 'Position', candidate.position),
                  _buildCardInfoRow(
                    Icons.calendar_today,
                    'Interview Date',
                    candidate.interviewDate,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.upload, size: 16),
                          label: Text(
                            candidate.resumeUrl == null
                                ? 'Upload Resume'
                                : 'Reupload',
                            style: const TextStyle(fontSize: 12),
                          ),
                          onPressed: () => _uploadResume(candidate),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D2364),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (candidate.resumeUrl != null)
                        IconButton(
                          icon: const Icon(Icons.visibility, size: 20),
                          onPressed: () => _viewResume(candidate),
                          tooltip: 'View Resume',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.green[50],
                            foregroundColor: Colors.green,
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.checklist, size: 16),
                      label: const Text(
                        'Requirements',
                        style: TextStyle(fontSize: 14),
                      ),
                      onPressed: () => _showRequirementsChecklist(candidate),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0D2364),
                        side: const BorderSide(color: Color(0xFF0D2364)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Edit'),
                          onPressed: () =>
                              _showCandidateDialog(candidate: candidate),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            side: const BorderSide(color: Colors.blue),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.delete, size: 16),
                          label: const Text('Delete'),
                          onPressed: () => _showDeleteDialog(candidate),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
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

  Future<void> _deleteCandidate(Candidate candidate) async {
    try {
      setState(() => _isLoading = true);

      if (candidate.resumeUrl != null) {
        try {
          await _storage.refFromURL(candidate.resumeUrl!).delete();
        } catch (e) {
          debugPrint('Error deleting resume file: $e');
        }
      }

      await _firestore.collection('candidates').doc(candidate.id).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${candidate.name} has been deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting candidate: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
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
