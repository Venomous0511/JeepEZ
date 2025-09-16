import 'package:flutter/material.dart';
import '../../models/app_user.dart';

class LeaveManagementScreen extends StatefulWidget {
  final AppUser user;
  const LeaveManagementScreen({super.key, required this.user});

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
    },
    {
      'name': 'Robert Fox',
      'from': 'Dec 9',
      'to': 'Dec 10',
      'totalTime': '24h',
      'status': 'Pending',
      'selected': true,
    },
    {
      'name': 'Ralph Edwards',
      'from': 'Dec 8',
      'to': 'Dec 11',
      'totalTime': '72h',
      'status': 'Pending',
      'selected': false,
    },
    {
      'name': 'Jacob Jones',
      'from': 'Dec 8',
      'to': 'Dec 10',
      'totalTime': '48h',
      'status': 'Pending',
      'selected': false,
    },
  ];

  void _showCalendarDialog(BuildContext context, int index) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Management'),
        backgroundColor: const Color.fromARGB(255, 9, 60, 119),
        // Removed the back icon button
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Leave Summary Section
            _buildLeaveSummary(),
            const SizedBox(height: 24),

            // Vacation Table
            _buildVacationTable(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Leave Management',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1565C0),
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              // Responsive layout for leave type cards
              final isWideScreen = constraints.maxWidth > 600;
              final crossAxisCount = isWideScreen ? 4 : 2;

              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: isWideScreen ? 1 : 1.2,
                children: [
                  _buildLeaveTypeCard(
                    'Annual Leave',
                    '15',
                    'This month',
                    Colors.blue,
                  ),
                  _buildLeaveTypeCard(
                    'Sick Leave',
                    '11',
                    'This month',
                    Colors.orange,
                  ),
                  _buildLeaveTypeCard(
                    'Other Leave',
                    '6',
                    'This month',
                    Colors.green,
                  ),
                  _buildLeaveTypeCard(
                    'Pending Request',
                    '5',
                    'This month',
                    Colors.red,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveTypeCard(
    String title,
    String count,
    String subtitle,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              count,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildVacationTable(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Vacation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0),
              ),
            ),
          ),
          // Use horizontal scroll for the table on small screens
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: isWideScreen
                    ? MediaQuery.of(context).size.width * 0.9
                    : 700, // Minimum width to ensure table is readable
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
                  5: const FixedColumnWidth(60), // Fixed width for actions
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  // Table header
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
                  // Table rows
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
                  }).toList(),
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
              ? Colors.orange.withOpacity(0.2)
              : status == 'Approved'
              ? Colors.green.withOpacity(0.2)
              : Colors.red.withOpacity(0.2),
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
    DateTime now = DateTime.now();
    DateTime firstDay = DateTime(now.year, now.month, 1);

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
            Text(
              '${request['from']} to ${request['to']} (${request['totalTime']})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: 1.5,
              ),
              itemCount: 7 * 6,
              itemBuilder: (context, dayIndex) {
                DateTime day = firstDay.add(Duration(days: dayIndex));
                bool isCurrentMonth = day.month == now.month;
                bool isLeaveDay = _isDateInRange(
                  day,
                  request['from'],
                  request['to'],
                );

                return Container(
                  decoration: BoxDecoration(
                    color: isLeaveDay
                        ? Colors.blue.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isCurrentMonth
                          ? Colors.grey[300]!
                          : Colors.grey[100]!,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: isCurrentMonth ? Colors.black : Colors.grey,
                        fontWeight: isLeaveDay
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
  }

  bool _isDateInRange(DateTime date, String fromStr, String toStr) {
    try {
      int fromDay = int.parse(fromStr.split(' ')[1]);
      int toDay = int.parse(toStr.split(' ')[1]);

      return date.day >= fromDay && date.day <= toDay;
    } catch (e) {
      return false;
    }
  }
}
