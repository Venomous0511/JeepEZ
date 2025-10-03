import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class Candidate {
  final String name;
  final String position;
  final String interviewDate;
  File? resumeFile;
  Map<String, bool> requirements;

  Candidate({
    required this.name,
    required this.position,
    required this.interviewDate,
    this.resumeFile,
    Map<String, bool>? requirements,
  }) : requirements =
           requirements ??
           {
             'Driver License': false,
             'Government Issued IDs': false,
             'NBI Clearance': false,
             'Barangay Clearance': false,
             'Medical Certificate': false,
           };
}

class HiringManagementScreen extends StatefulWidget {
  const HiringManagementScreen({super.key});

  @override
  State<HiringManagementScreen> createState() => _HiringManagementScreenState();
}

class _HiringManagementScreenState extends State<HiringManagementScreen> {
  List<Candidate> candidates = [
    Candidate(
      name: 'MJ Capayan',
      position: 'Driver',
      interviewDate: '09/30/26',
    ),
    Candidate(name: 'Jeriel', position: 'Conductor', interviewDate: '09/29/26'),
  ];

  // Function to upload resume using file_picker
  Future<void> _uploadResume(int index) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;
        setState(() {
          candidates[index].resumeFile = File(file.path!);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Resume uploaded for ${candidates[index].name}'),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File selection canceled')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading file: $e')));
      }
    }
  }

  // Function to view resume
  void _viewResume(int index) {
    if (candidates[index].resumeFile == null) {
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
            'Resume - ${candidates[index].name}',
            style: TextStyle(fontSize: isMobile ? 16 : 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Position: ${candidates[index].position}',
                  style: TextStyle(fontSize: isMobile ? 13 : 14),
                ),
                const SizedBox(height: 10),
                Text(
                  'File: ${candidates[index].resumeFile!.path.split('/').last}',
                  style: TextStyle(fontSize: isMobile ? 12 : 14),
                ),
                Text(
                  'Size: ${(candidates[index].resumeFile!.lengthSync() / 1024).toStringAsFixed(2)} KB',
                  style: TextStyle(fontSize: isMobile ? 12 : 14),
                ),
                const SizedBox(height: 20),
                Text(
                  'Resume Content Preview:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 13 : 14,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'PDF preview would be shown here. In a real app, you would use a PDF viewer package.',
                    style: TextStyle(fontSize: isMobile ? 11 : 12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Opening resume: ${candidates[index].resumeFile!.path}',
                    ),
                  ),
                );
                Navigator.pop(context);
              },
              child: const Text('Open File'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Function to show requirements checklist
  void _showRequirementsChecklist(int index) {
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
                      'Requirements - ${candidates[index].name}',
                      style: TextStyle(fontSize: isMobile ? 14 : 16),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: isMobile ? double.maxFinite : 500,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    _buildRequirementItem(
                      'Driver License',
                      candidates[index].requirements['Driver License'] ?? false,
                      (value) {
                        setDialogState(() {
                          setState(() {
                            candidates[index].requirements['Driver License'] =
                                value;
                          });
                        });
                      },
                      isMobile,
                    ),
                    _buildRequirementItem(
                      'Government Issued IDs',
                      candidates[index].requirements['Government Issued IDs'] ??
                          false,
                      (value) {
                        setDialogState(() {
                          setState(() {
                            candidates[index]
                                    .requirements['Government Issued IDs'] =
                                value;
                          });
                        });
                      },
                      isMobile,
                    ),
                    _buildRequirementItem(
                      'NBI Clearance',
                      candidates[index].requirements['NBI Clearance'] ?? false,
                      (value) {
                        setDialogState(() {
                          setState(() {
                            candidates[index].requirements['NBI Clearance'] =
                                value;
                          });
                        });
                      },
                      isMobile,
                    ),
                    _buildRequirementItem(
                      'Barangay Clearance',
                      candidates[index].requirements['Barangay Clearance'] ??
                          false,
                      (value) {
                        setDialogState(() {
                          setState(() {
                            candidates[index]
                                    .requirements['Barangay Clearance'] =
                                value;
                          });
                        });
                      },
                      isMobile,
                    ),
                    _buildRequirementItem(
                      'Medical Certificate',
                      candidates[index].requirements['Medical Certificate'] ??
                          false,
                      (value) {
                        setDialogState(() {
                          setState(() {
                            candidates[index]
                                    .requirements['Medical Certificate'] =
                                value;
                          });
                        });
                      },
                      isMobile,
                    ),
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
                          _buildCompletionStatus(candidates[index], isMobile),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Requirements updated for ${candidates[index].name}',
                        ),
                      ),
                    );
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
            decoration: isChecked
                ? TextDecoration.lineThrough
                : TextDecoration.none,
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Hiring Management',
            style: TextStyle(fontSize: isMobile ? 16 : 20),
          ),
        ),
        backgroundColor: const Color(0xFF0D2364),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: isMobile ? 12 : 16),
            Text(
              'Candidates',
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isMobile ? 12 : 16),
            _buildCandidateStats(isMobile, isTablet),
            SizedBox(height: isMobile ? 16 : 24),
            const Divider(),
            SizedBox(height: isMobile ? 12 : 16),
            Text(
              'Candidates on the final interview',
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isMobile ? 12 : 16),
            isMobile ? _buildCandidateCards() : _buildFinalStageTable(isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildCandidateStats(bool isMobile, bool isTablet) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
        child: isMobile
            ? Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn('Initial Interview', '7', isMobile),
                      _buildStatColumn('Training', '2', isMobile),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildStatColumn('J.O(Contract)', '1', isMobile),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn('Initial Interview', '7', isMobile),
                  _buildStatColumn('Training', '2', isMobile),
                  _buildStatColumn('J.O(Contract)', '1', isMobile),
                ],
              ),
      ),
    );
  }

  Widget _buildStatColumn(String title, String value, bool isMobile) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: isMobile ? 28 : 32,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0D2364),
          ),
        ),
        SizedBox(height: isMobile ? 4 : 8),
        Text(
          title,
          style: TextStyle(
            fontSize: isMobile ? 12 : 14,
            color: Colors.grey[700],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Mobile card view
  Widget _buildCandidateCards() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: candidates.asMap().entries.map((entry) {
            int index = entry.key;
            Candidate candidate = entry.value;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
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
                        child: Icon(
                          Icons.checklist,
                          size: 16,
                          color: _getCompletionColor(candidate),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildCardInfoRow(Icons.work, 'Position', candidate.position),
                  const SizedBox(height: 8),
                  _buildCardInfoRow(
                    Icons.calendar_today,
                    'Interview Date',
                    candidate.interviewDate,
                  ),
                  const SizedBox(height: 12),
                  // FIXED: Wrap buttons in SingleChildScrollView for horizontal scrolling
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        TextButton.icon(
                          onPressed: () => _uploadResume(index),
                          icon: Icon(
                            Icons.upload,
                            size: 18,
                            color: candidate.resumeFile != null
                                ? Colors.green
                                : null,
                          ),
                          label: Text(
                            'Upload',
                            style: TextStyle(
                              color: candidate.resumeFile != null
                                  ? Colors.green
                                  : null,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _viewResume(index),
                          icon: Icon(
                            Icons.visibility,
                            size: 18,
                            color: candidate.resumeFile != null
                                ? const Color(0xFF0D2364)
                                : Colors.grey,
                          ),
                          label: Text(
                            'View',
                            style: TextStyle(
                              color: candidate.resumeFile != null
                                  ? const Color(0xFF0D2364)
                                  : Colors.grey,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _showRequirementsChecklist(index),
                          icon: Icon(
                            Icons.checklist,
                            size: 18,
                            color: _getCompletionColor(candidate),
                          ),
                          label: Text(
                            'Check',
                            style: TextStyle(
                              color: _getCompletionColor(candidate),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCardInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinalStageTable(bool isTablet) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 16.0 : 20.0),
        child: Column(
          children: candidates.asMap().entries.map((entry) {
            int index = entry.key;
            Candidate candidate = entry.value;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
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
                        child: Icon(
                          Icons.checklist,
                          size: 16,
                          color: _getCompletionColor(candidate),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildCardInfoRow(Icons.work, 'Position', candidate.position),
                  const SizedBox(height: 8),
                  _buildCardInfoRow(
                    Icons.calendar_today,
                    'Interview Date',
                    candidate.interviewDate,
                  ),
                  const SizedBox(height: 12),
                  // FIXED: Wrap buttons in SingleChildScrollView for horizontal scrolling
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        TextButton.icon(
                          onPressed: () => _uploadResume(index),
                          icon: Icon(
                            Icons.upload,
                            size: 18,
                            color: candidate.resumeFile != null
                                ? Colors.green
                                : null,
                          ),
                          label: Text(
                            'Upload',
                            style: TextStyle(
                              color: candidate.resumeFile != null
                                  ? Colors.green
                                  : null,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _viewResume(index),
                          icon: Icon(
                            Icons.visibility,
                            size: 18,
                            color: candidate.resumeFile != null
                                ? const Color(0xFF0D2364)
                                : Colors.grey,
                          ),
                          label: Text(
                            'View',
                            style: TextStyle(
                              color: candidate.resumeFile != null
                                  ? const Color(0xFF0D2364)
                                  : Colors.grey,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _showRequirementsChecklist(index),
                          icon: Icon(
                            Icons.checklist,
                            size: 18,
                            color: _getCompletionColor(candidate),
                          ),
                          label: Text(
                            'Check',
                            style: TextStyle(
                              color: _getCompletionColor(candidate),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _getCompletionColor(Candidate candidate) {
    int completed = candidate.requirements.values
        .where((value) => value)
        .length;
    int total = candidate.requirements.length;
    double percentage = total > 0 ? (completed / total) * 100 : 0;

    if (percentage == 100) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }
}
