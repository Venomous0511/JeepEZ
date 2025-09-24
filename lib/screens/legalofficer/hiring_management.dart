import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hiring Management',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HiringManagementScreen(),
    );
  }
}

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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Resume uploaded for ${candidates[index].name}'),
          ),
        );
      } else {
        // User canceled the picker
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File selection canceled')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error uploading file: $e')));
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

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Resume - ${candidates[index].name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Position: ${candidates[index].position}'),
                const SizedBox(height: 10),
                Text(
                  'File: ${candidates[index].resumeFile!.path.split('/').last}',
                ),
                Text(
                  'Size: ${(candidates[index].resumeFile!.lengthSync() / 1024).toStringAsFixed(2)} KB',
                ),
                const SizedBox(height: 20),
                const Text(
                  'Resume Content Preview:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'PDF preview would be shown here. In a real app, you would use a PDF viewer package.',
                    style: TextStyle(fontSize: 12),
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.checklist, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text('Requirements - ${candidates[index].name}'),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    _buildRequirementItem(
                      'Driver License',
                      candidates[index].requirements['Driver License'] ?? false,
                      (value) {
                        setState(() {
                          candidates[index].requirements['Driver License'] =
                              value;
                        });
                      },
                    ),
                    _buildRequirementItem(
                      'Government Issued IDs',
                      candidates[index].requirements['Government Issued IDs'] ??
                          false,
                      (value) {
                        setState(() {
                          candidates[index]
                                  .requirements['Government Issued IDs'] =
                              value;
                        });
                      },
                    ),
                    _buildRequirementItem(
                      'NBI Clearance',
                      candidates[index].requirements['NBI Clearance'] ?? false,
                      (value) {
                        setState(() {
                          candidates[index].requirements['NBI Clearance'] =
                              value;
                        });
                      },
                    ),
                    _buildRequirementItem(
                      'Barangay Clearance',
                      candidates[index].requirements['Barangay Clearance'] ??
                          false,
                      (value) {
                        setState(() {
                          candidates[index].requirements['Barangay Clearance'] =
                              value;
                        });
                      },
                    ),
                    _buildRequirementItem(
                      'Medical Certificate',
                      candidates[index].requirements['Medical Certificate'] ??
                          false,
                      (value) {
                        setState(() {
                          candidates[index]
                                  .requirements['Medical Certificate'] =
                              value;
                        });
                      },
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
                          const Text(
                            'Completion Status:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildCompletionStatus(candidates[index]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Save changes
                    setState(() {});
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
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Checkbox(
          value: isChecked,
          onChanged: (value) => onChanged(value ?? false),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            decoration: isChecked
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            color: isChecked ? Colors.green : Colors.black,
          ),
        ),
        trailing: Icon(
          isChecked ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isChecked ? Colors.green : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildCompletionStatus(Candidate candidate) {
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
          color: percentage == 100 ? Colors.green : Colors.blue,
        ),
        const SizedBox(height: 8),
        Text(
          '$completed/$total requirements completed (${percentage.toStringAsFixed(1)}%)',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: percentage == 100 ? Colors.green : Colors.blue,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hiring Management'),
        backgroundColor: const Color(0xFF0D2364),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Candidates',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildCandidateStats(),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Candidates on the final interview',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFinalStageTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildCandidateStats() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 600) {
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn('Initial Interview', '7'),
                      _buildStatColumn('Final Interview', '5'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn('Training', '2'),
                      _buildStatColumn('J.O(Contract)', '1'),
                    ],
                  ),
                ],
              );
            } else {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn('Initial Interview', '7'),
                  _buildStatColumn('Final Interview', '5'),
                  _buildStatColumn('Training', '2'),
                  _buildStatColumn('J.O(Contract)', '1'),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildStatColumn(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFinalStageTable() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isSmallScreen = constraints.maxWidth < 600;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: isSmallScreen ? constraints.maxWidth : 700,
                ),
                child: DataTable(
                  columnSpacing: 20,
                  columns: [
                    DataColumn(
                      label: Text(
                        'NAME',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 12 : 14,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'POSITION',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 12 : 14,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: isSmallScreen ? 120 : 150,
                        child: Text(
                          'FINAL INTERVIEW DATE',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 10 : 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: isSmallScreen ? 50 : 60,
                        child: Text(
                          '',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 10 : 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                  rows: candidates.asMap().entries.map((entry) {
                    int index = entry.key;
                    Candidate candidate = entry.value;

                    return DataRow(
                      cells: [
                        DataCell(
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                candidate.name,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 12 : 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Text(
                            candidate.position,
                            style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                          ),
                        ),
                        DataCell(
                          Center(
                            child: Text(
                              candidate.interviewDate,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 11 : 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        DataCell(
                          Center(
                            child: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              itemBuilder: (BuildContext context) => [
                                PopupMenuItem<String>(
                                  value: 'upload',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.upload,
                                        size: 20,
                                        color: candidate.resumeFile != null
                                            ? Colors.green
                                            : null,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Upload Resume',
                                        style: TextStyle(
                                          color: candidate.resumeFile != null
                                              ? Colors.green
                                              : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem<String>(
                                  value: 'view',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.visibility,
                                        size: 20,
                                        color: candidate.resumeFile != null
                                            ? Colors.blue
                                            : Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'View Resume',
                                        style: TextStyle(
                                          color: candidate.resumeFile != null
                                              ? Colors.blue
                                              : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const PopupMenuDivider(),
                                PopupMenuItem<String>(
                                  value: 'checklist',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.checklist,
                                        size: 20,
                                        color: _getCompletionColor(candidate),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Requirements Checklist',
                                        style: TextStyle(
                                          color: _getCompletionColor(candidate),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (String value) {
                                switch (value) {
                                  case 'upload':
                                    _uploadResume(index);
                                    break;
                                  case 'view':
                                    _viewResume(index);
                                    break;
                                  case 'checklist':
                                    _showRequirementsChecklist(index);
                                    break;
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            );
          },
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
