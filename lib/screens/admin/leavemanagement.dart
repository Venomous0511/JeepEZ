import 'package:flutter/material.dart';

class LeaveManagementScreen extends StatefulWidget {
  const LeaveManagementScreen({super.key});

  @override
  State<LeaveManagementScreen> createState() => _LeaveManagementScreenState();
}

class _LeaveManagementScreenState extends State<LeaveManagementScreen> {
  final List<Map<String, dynamic>> _leaveRequests = [
    {
      'name': 'Kathryn Murphy',
      'from': 'Dec 10',
      'to': 'Dec 12',
      'totalTime': '48h',
      'status': 'Pending',
      'selected': false,
      'selectedDays': [10, 11, 12],
    },
    {
      'name': 'Robert Fox',
      'from': 'Dec 9',
      'to': 'Dec 10',
      'totalTime': '24h',
      'status': 'Pending',
      'selected': true,
      'selectedDays': [9, 10],
    },
    {
      'name': 'Ralph Edwards',
      'from': 'Dec 8',
      'to': 'Dec 11',
      'totalTime': '72h',
      'status': 'Pending',
      'selected': false,
      'selectedDays': [8, 9, 10, 11],
    },
    {
      'name': 'Jacob Jones',
      'from': 'Dec 8',
      'to': 'Dec 10',
      'totalTime': '48h',
      'status': 'Pending',
      'selected': false,
      'selectedDays': [8, 9, 10],
    },
  ];

  // For the start day dropdown
  int? _selectedStartDay;
  final List<int> _availableDays = List.generate(31, (index) => index + 1);

  void _showCalendarDialog(BuildContext context, int index) {
    // Initialize selected start day with the first day of the request
    final selectedDays = _leaveRequests[index]['selectedDays'];
    _selectedStartDay = selectedDays.isNotEmpty ? selectedDays.first : null;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildCalendarDialog(context, index);
      },
    );
  }

  void _approveRequest(int index) {
    setState(() {
      _leaveRequests[index]['status'] = 'Approved';
    });
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_leaveRequests[index]['name']}\'s request approved'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _rejectRequest(int index) {
    setState(() {
      _leaveRequests[index]['status'] = 'Rejected';
    });
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_leaveRequests[index]['name']}\'s request rejected'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _updateSelectedDay(int index) {
    if (_selectedStartDay != null) {
      setState(() {
        // For simplicity, we'll assume a fixed duration of 3 days
        // You can modify this logic as needed
        final endDay = _selectedStartDay! + 2;
        final month = 'Dec';

        _leaveRequests[index]['from'] = '$month $_selectedStartDay';
        _leaveRequests[index]['to'] = '$month $endDay';

        // Calculate total time (assuming 24h per day)
        final totalHours = 3 * 24;
        _leaveRequests[index]['totalTime'] = '${totalHours}h';

        // Update selected days
        _leaveRequests[index]['selectedDays'] = List.generate(
          3,
          (i) => _selectedStartDay! + i,
        );
      });
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Leave Management',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0D2364),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [const SizedBox(height: 24), _buildVacationTable(context)],
        ),
      ),
    );
  }

  Widget _buildVacationTable(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(padding: EdgeInsets.all(16.0)),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: isWideScreen
                    ? MediaQuery.of(context).size.width * 0.9
                    : 700,
              ),
              child: Table(
                border: TableBorder.all(
                  color: Colors.grey.shade300,
                  width: 1.0,
                ),
                columnWidths: {
                  0: const FlexColumnWidth(2.5),
                  1: const FlexColumnWidth(1.2),
                  2: const FlexColumnWidth(1.2),
                  3: const FlexColumnWidth(1.2),
                  4: const FlexColumnWidth(1.5),
                  5: const FixedColumnWidth(60),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey.shade100),
                    children: [
                      _buildHeaderCell('Name'),
                      _buildHeaderCell('From'),
                      _buildHeaderCell('To'),
                      _buildHeaderCell('Total Time'),
                      _buildHeaderCell('Status'),
                      _buildHeaderCell(''),
                    ],
                  ),
                  ..._leaveRequests.asMap().entries.map((entry) {
                    final index = entry.key;
                    final request = entry.value;
                    return TableRow(
                      decoration: const BoxDecoration(color: Colors.white),
                      children: [
                        _buildNameCell(request, index),
                        _buildDateCell(request['from']),
                        _buildDateCell(request['to']),
                        _buildTimeCell(request['totalTime']),
                        _buildStatusCell(request['status']),
                        _buildActionCell(context, index),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildNameCell(Map<String, dynamic> request, int index) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Checkbox(
            value: request['selected'],
            onChanged: (value) {
              setState(() {
                request['selected'] = value;
              });
            },
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              request['name'],
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateCell(String date) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(
        date,
        style: const TextStyle(fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTimeCell(String time) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(
        time,
        style: const TextStyle(fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildStatusCell(String status) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: status == 'Pending'
              ? Colors.orange.withAlpha(128)
              : status == 'Approved'
              ? Colors.green.withAlpha(128)
              : Colors.red.withAlpha(128),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          status,
          style: TextStyle(
            fontSize: 12,
            color: status == 'Pending'
                ? Colors.orange
                : status == 'Approved'
                ? Colors.green
                : Colors.red,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildActionCell(BuildContext context, int index) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, size: 20),
        itemBuilder: (BuildContext context) => [
          const PopupMenuItem(value: 'calendar', child: Text('View Calendar')),
          if (_leaveRequests[index]['status'] == 'Pending')
            const PopupMenuItem(value: 'approve', child: Text('Approve')),
          if (_leaveRequests[index]['status'] == 'Pending')
            const PopupMenuItem(value: 'reject', child: Text('Reject')),
        ],
        onSelected: (String value) {
          if (value == 'calendar') {
            _showCalendarDialog(context, index);
          } else if (value == 'approve') {
            _approveRequest(index);
          } else if (value == 'reject') {
            _rejectRequest(index);
          }
        },
      ),
    );
  }

  Widget _buildCalendarDialog(BuildContext context, int index) {
    final request = _leaveRequests[index];

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${request['name']}\'s Leave Request'),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Start Day dropdown only
                Row(
                  children: [
                    const Text('Start Day:'),
                    const SizedBox(width: 16),
                    DropdownButton<int>(
                      value: _selectedStartDay,
                      hint: const Text('Select day'),
                      items: _availableDays.map((int day) {
                        return DropdownMenuItem<int>(
                          value: day,
                          child: Text('December $day'),
                        );
                      }).toList(),
                      onChanged: (int? newValue) {
                        setState(() {
                          _selectedStartDay = newValue;
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Calendar view
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: 31, // December has 31 days
                  itemBuilder: (context, dayIndex) {
                    final day = dayIndex + 1;
                    // For simplicity, highlight the selected start day and next 2 days
                    final isSelected =
                        _selectedStartDay != null &&
                        day >= _selectedStartDay! &&
                        day <= _selectedStartDay! + 2;

                    return Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.blue.withAlpha(128)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Center(
                        child: Text(
                          '$day',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),
                if (request['status'] == 'Pending')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                        onPressed: () => _rejectRequest(index),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Reject'),
                      ),
                      ElevatedButton(
                        onPressed: () => _updateSelectedDay(index),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Save'),
                      ),
                      ElevatedButton(
                        onPressed: () => _approveRequest(index),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Approve'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
