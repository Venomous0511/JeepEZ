import 'package:flutter/material.dart';

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
  String resumeStatus;

  Candidate({
    required this.name,
    required this.position,
    required this.interviewDate,
    this.resumeStatus = 'Not Submitted',
  });
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

  void _updateResumeStatus(int index, String status) {
    setState(() {
      candidates[index].resumeStatus = status;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Resume status updated to: $status')),
    );
  }

  void _showResumeDialog(int index) {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Resume Status'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText:
                  'Enter resume status (e.g., Submitted, Reviewed, Approved)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  _updateResumeStatus(index, controller.text);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D2364),
                foregroundColor: Colors.white,
              ),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hiring Management'),
        backgroundColor: const Color(0xFF0D2364),
        foregroundColor: Colors.white,
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
              // Mobile layout
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
                      _buildStatColumn(
                        'J.O(Contract)',
                        '1',
                      ), // Changed from I.O to J.O
                    ],
                  ),
                ],
              );
            } else {
              // Desktop/tablet layout
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn('Initial Interview', '7'),
                  _buildStatColumn('Final Interview', '5'),
                  _buildStatColumn('Training', '2'),
                  _buildStatColumn(
                    'J.O(Contract)',
                    '1',
                  ), // Changed from I.O to J.O
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
                        width: isSmallScreen ? 90 : 120,
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
                        width: isSmallScreen ? 100 : 150,
                        child: Text(
                          'RESUME STATUS',
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
                        width: isSmallScreen ? 100 : 120,
                        child: Text(
                          'ACTION',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 10 : 12,
                          ),
                          textAlign: TextAlign.center,
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
                            child: Text(
                              candidate.resumeStatus,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 11 : 14,
                                color: _getStatusColor(candidate.resumeStatus),
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        DataCell(
                          Center(
                            child: ElevatedButton(
                              onPressed: () => _showResumeDialog(index),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D2364),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 8 : 12,
                                  vertical: isSmallScreen ? 4 : 8,
                                ),
                              ),
                              child: Text(
                                'Update',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 10 : 12,
                                ),
                              ),
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return Colors.blue;
      case 'reviewed':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
