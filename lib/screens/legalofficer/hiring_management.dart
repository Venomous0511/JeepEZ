import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class Candidate {
  final String id;
  String name;
  String position;
  String interviewDate;
  File? resumeFile;
  Map<String, bool> requirements;

  Candidate({
    String? id,
    required this.name,
    required this.position,
    required this.interviewDate,
    this.resumeFile,
    Map<String, bool>? requirements,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       requirements =
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
}

class HiringManagementScreen extends StatefulWidget {
  const HiringManagementScreen({super.key});

  @override
  State<HiringManagementScreen> createState() => _HiringManagementScreenState();
}

class _HiringManagementScreenState extends State<HiringManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  int _rowsPerPage = 10;
  int _currentPage = 0;

  List<Candidate> candidates = [
    Candidate(
      name: 'MJ Capayan',
      position: 'Driver',
      interviewDate: '09/30/26',
    ),
    Candidate(name: 'Jeriel', position: 'Conductor', interviewDate: '09/29/26'),
    Candidate(name: 'John Doe', position: 'Driver', interviewDate: '10/01/26'),
    Candidate(
      name: 'Jane Smith',
      position: 'Inspector',
      interviewDate: '10/02/26',
    ),
    Candidate(
      name: 'Mike Johnson',
      position: 'Conductor',
      interviewDate: '10/03/26',
    ),
    Candidate(
      name: 'Sarah Williams',
      position: 'Driver',
      interviewDate: '10/04/26',
    ),
    Candidate(
      name: 'Robert Brown',
      position: 'Inspector',
      interviewDate: '10/05/26',
    ),
    Candidate(
      name: 'Emily Davis',
      position: 'Conductor',
      interviewDate: '10/06/26',
    ),
    Candidate(
      name: 'David Wilson',
      position: 'Driver',
      interviewDate: '10/07/26',
    ),
    Candidate(
      name: 'Lisa Anderson',
      position: 'Inspector',
      interviewDate: '10/08/26',
    ),
    Candidate(
      name: 'Tom Martinez',
      position: 'Driver',
      interviewDate: '10/09/26',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Candidate> get filteredCandidates {
    List<Candidate> filtered = candidates;

    if (_searchController.text.isNotEmpty) {
      final search = _searchController.text.toLowerCase();
      filtered = filtered.where((candidate) {
        return candidate.name.toLowerCase().contains(search) ||
            candidate.position.toLowerCase().contains(search);
      }).toList();
    }

    if (_selectedFilter != 'All') {
      filtered = filtered
          .where((candidate) => candidate.position == _selectedFilter)
          .toList();
    }

    return filtered;
  }

  List<Candidate> get _paginatedCandidates {
    final startIndex = _currentPage * _rowsPerPage;
    final endIndex = startIndex + _rowsPerPage;
    if (startIndex >= filteredCandidates.length) {
      return [];
    }
    return filteredCandidates.sublist(
      startIndex,
      endIndex > filteredCandidates.length
          ? filteredCandidates.length
          : endIndex,
    );
  }

  int get _totalPages => (filteredCandidates.length / _rowsPerPage).ceil();

  void _showCandidateDialog({Candidate? candidate}) {
    final isEditing = candidate != null;
    final nameController = TextEditingController(text: candidate?.name ?? '');
    final positionController = TextEditingController(
      text: candidate?.position ?? '',
    );
    final dateController = TextEditingController(
      text: candidate?.interviewDate ?? '',
    );

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                  TextField(
                    controller: positionController,
                    decoration: const InputDecoration(
                      labelText: 'Position',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.work),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: dateController,
                    decoration: const InputDecoration(
                      labelText: 'Interview Date (MM/DD/YY)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
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
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D2364),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    positionController.text.isNotEmpty &&
                    dateController.text.isNotEmpty) {
                  setState(() {
                    if (isEditing) {
                      candidate.name = nameController.text;
                      candidate.position = positionController.text;
                      candidate.interviewDate = dateController.text;
                    } else {
                      candidates.add(
                        Candidate(
                          name: nameController.text,
                          position: positionController.text,
                          interviewDate: dateController.text,
                        ),
                      );
                    }
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isEditing
                            ? 'Candidate updated successfully'
                            : 'Candidate added successfully',
                      ),
                    ),
                  );
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
  }

  Future<void> _uploadResume(Candidate candidate) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;
        setState(() {
          candidate.resumeFile = File(file.path!);
        });

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
    }
  }

  void _viewResume(Candidate candidate) {
    if (candidate.resumeFile == null) {
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
                    'File: ${candidate.resumeFile!.path.split('/').last}',
                    style: TextStyle(fontSize: isMobile ? 12 : 14),
                  ),
                  Text(
                    'Size: ${(candidate.resumeFile!.lengthSync() / 1024).toStringAsFixed(2)} KB',
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
                    setState(() {});
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Requirements updated for ${candidate.name}',
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

  Widget _buildDesktopTable(List<Candidate> candidates, bool isTablet) {
    return Container(
      width: double.infinity, // Sakop ang buong width
      height: double.infinity, // Sakop ang buong height
      child: Column(
        children: [
          Expanded(
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              margin: EdgeInsets.zero,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    columnSpacing: 16,
                    dataRowMinHeight: 60,
                    dataRowMaxHeight: 80,
                    headingRowColor: WidgetStateProperty.all(
                      const Color(0xFF0D2364).withOpacity(0.1),
                    ),
                    columns: [
                      DataColumn(
                        label: SizedBox(
                          width: 150,
                          child: Text(
                            'Candidate Name',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isTablet ? 14 : 16,
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
                              fontSize: isTablet ? 14 : 16,
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
                              fontSize: isTablet ? 14 : 16,
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 130,
                          child: Text(
                            'Requirements',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isTablet ? 14 : 16,
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 180,
                          child: Text(
                            'Resume',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isTablet ? 14 : 16,
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 120,
                          child: Text(
                            'Actions',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isTablet ? 14 : 16,
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
                              width: 150,
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
                              width: 120,
                              child: Text(
                                candidate.position,
                                style: TextStyle(fontSize: isTablet ? 13 : 15),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 120,
                              child: Text(
                                candidate.interviewDate,
                                style: TextStyle(fontSize: isTablet ? 13 : 15),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 130,
                              child: InkWell(
                                onTap: () =>
                                    _showRequirementsChecklist(candidate),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getCompletionColor(
                                      candidate,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _getCompletionColor(candidate),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
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
                              width: 180,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.upload, size: 16),
                                      label: Text(
                                        candidate.resumeFile == null
                                            ? 'Upload'
                                            : 'Reupload',
                                        style: TextStyle(
                                          fontSize: isTablet ? 12 : 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      onPressed: () => _uploadResume(candidate),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF0D2364,
                                        ),
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isTablet ? 8 : 10,
                                          vertical: isTablet ? 6 : 8,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (candidate.resumeFile != null) ...[
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.visibility,
                                        size: 18,
                                      ),
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
                              width: 120,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 18),
                                    onPressed: () => _showCandidateDialog(
                                      candidate: candidate,
                                    ),
                                    tooltip: 'Edit',
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.blue[50],
                                      foregroundColor: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 18),
                                    onPressed: () =>
                                        _deleteCandidate(candidate),
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
          ),
          if (filteredCandidates.length > _rowsPerPage)
            _buildPaginationControls(false),
        ],
      ),
    );
  }

  Widget _buildMobileCards(List<Candidate> candidates) {
    return Container(
      width: double.infinity, // Sakop ang buong width
      height: double.infinity, // Sakop ang buong height
      child: Column(
        children: [
          Expanded(
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              margin: EdgeInsets.zero,
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
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 20,
                            ),
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
                                color: _getCompletionColor(
                                  candidate,
                                ).withOpacity(0.1),
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
                        _buildCardInfoRow(
                          Icons.work,
                          'Position',
                          candidate.position,
                        ),
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
                                  candidate.resumeFile == null
                                      ? 'Upload Resume'
                                      : 'Reupload',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                onPressed: () => _uploadResume(candidate),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0D2364),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (candidate.resumeFile != null)
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
                            onPressed: () =>
                                _showRequirementsChecklist(candidate),
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
                                onPressed: () => _deleteCandidate(candidate),
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
          ),
          if (filteredCandidates.length > _rowsPerPage)
            _buildPaginationControls(true),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(bool isMobile) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: Padding(
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
                    items: ['All', 'Driver', 'Conductor', 'Inspector']
                        .map(
                          (position) => DropdownMenuItem(
                            value: position,
                            child: Text(position),
                          ),
                        )
                        .toList(),
                    decoration: InputDecoration(
                      labelText: 'Filter by Position',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
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
                      items: ['All', 'Driver', 'Conductor', 'Inspector']
                          .map(
                            (position) => DropdownMenuItem(
                              value: position,
                              child: Text(position),
                            ),
                          )
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

  Widget _buildPaginationControls(bool isMobile) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isMobile)
              const Text('Rows per page:', style: TextStyle(fontSize: 14)),
            if (!isMobile) const SizedBox(width: 8),
            if (!isMobile)
              DropdownButton<int>(
                value: _rowsPerPage,
                onChanged: (value) {
                  setState(() {
                    _rowsPerPage = value!;
                    _currentPage = 0;
                  });
                },
                items: [5, 10, 15, 20]
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text('$value')),
                    )
                    .toList(),
              ),
            const Spacer(),
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
              'Page ${_currentPage + 1} of $_totalPages',
              style: const TextStyle(fontSize: 14),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              onPressed: _currentPage < _totalPages - 1
                  ? () {
                      setState(() {
                        _currentPage++;
                      });
                    }
                  : null,
            ),
            if (isMobile) const Spacer(),
            if (isMobile)
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
        ),
      ),
    );
  }

  void _deleteCandidate(Candidate candidate) {
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
                setState(() {
                  candidates.remove(candidate);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${candidate.name} has been deleted')),
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return Scaffold(
      body: Container(
        width: double.infinity, // Sakop ang buong screen width
        height: double.infinity, // Sakop ang buong screen height
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchAndFilter(isMobile),
            const SizedBox(height: 16),
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
              child: Container(
                width: double.infinity, // Sakop ang buong available width
                child: isMobile
                    ? _buildMobileCards(_paginatedCandidates)
                    : _buildDesktopTable(_paginatedCandidates, isTablet),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
