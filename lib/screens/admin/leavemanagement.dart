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

  int? _selectedStartDay;
  final List<int> _availableDays = List.generate(31, (index) => index + 1);

  void _showCalendarDialog(BuildContext context, int index) {
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
        final endDay = _selectedStartDay! + 2;
        final month = 'Dec';

        _leaveRequests[index]['from'] = '$month $_selectedStartDay';
        _leaveRequests[index]['to'] = '$month $endDay';

        final totalHours = 3 * 24;
        _leaveRequests[index]['totalTime'] = '${totalHours}h';

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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Expanded(child: _buildMainContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 600;
        final bool isTablet = constraints.maxWidth < 900;

        if (isMobile) {
          return _buildMobileView();
        } else if (isTablet) {
          return _buildTabletView();
        } else {
          return _buildDesktopView();
        }
      },
    );
  }

  /// Mobile View - Card List
  Widget _buildMobileView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _leaveRequests.length,
      itemBuilder: (context, index) {
        final request = _leaveRequests[index];
        final status = request['status'];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: status == 'Approved'
              ? Colors.green.shade50
              : status == 'Rejected'
              ? Colors.red.shade50
              : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        request['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today, size: 20),
                      onPressed: () => _showCalendarDialog(context, index),
                      tooltip: 'View Calendar',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                _buildMobileDetailRow(
                  'Leave Period',
                  '${request['from']} - ${request['to']}',
                ),
                _buildMobileDetailRow('Total Time', request['totalTime']),
                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withAlpha(128),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                if (status == 'Pending') ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _rejectRequest(index),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Reject'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _approveRequest(index),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  /// Tablet View - Compact Table
  Widget _buildTabletView() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.all(16),
          child: Table(
            border: TableBorder.all(color: Colors.grey.shade300, width: 1.0),
            columnWidths: {
              0: const FlexColumnWidth(2),
              1: const FlexColumnWidth(2),
              2: const FlexColumnWidth(1),
              3: const FlexColumnWidth(1.2),
              4: const FlexColumnWidth(2),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade100),
                children: [
                  _buildHeaderCell('Name', isCompact: true),
                  _buildHeaderCell('Leave Period', isCompact: true),
                  _buildHeaderCell('Time', isCompact: true),
                  _buildHeaderCell('Status', isCompact: true),
                  _buildHeaderCell('Actions', isCompact: true),
                ],
              ),
              ..._leaveRequests.asMap().entries.map((entry) {
                final index = entry.key;
                final request = entry.value;
                return TableRow(
                  decoration: BoxDecoration(
                    color: request['status'] == 'Approved'
                        ? Colors.green.shade50
                        : request['status'] == 'Rejected'
                        ? Colors.red.shade50
                        : Colors.white,
                  ),
                  children: [
                    _buildNameCell(request, index, isCompact: true),
                    _buildPeriodCell(
                      '${request['from']} - ${request['to']}',
                      isCompact: true,
                    ),
                    _buildTimeCell(request['totalTime'], isCompact: true),
                    _buildStatusCell(request['status'], isCompact: true),
                    _buildActionButtons(
                      context,
                      index,
                      request,
                      isCompact: true,
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  /// Desktop View - Full Table
  Widget _buildDesktopView() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.all(16),
          child: Table(
            border: TableBorder.all(color: Colors.grey.shade300, width: 1.0),
            columnWidths: {
              0: const FlexColumnWidth(2.5),
              1: const FlexColumnWidth(2),
              2: const FlexColumnWidth(1.2),
              3: const FlexColumnWidth(1.5),
              4: const FlexColumnWidth(2.5),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade100),
                children: [
                  _buildHeaderCell('Name'),
                  _buildHeaderCell('Leave Period'),
                  _buildHeaderCell('Total Time'),
                  _buildHeaderCell('Status'),
                  _buildHeaderCell('Actions'),
                ],
              ),
              ..._leaveRequests.asMap().entries.map((entry) {
                final index = entry.key;
                final request = entry.value;
                return TableRow(
                  decoration: BoxDecoration(
                    color: request['status'] == 'Approved'
                        ? Colors.green.shade50
                        : request['status'] == 'Rejected'
                        ? Colors.red.shade50
                        : Colors.white,
                  ),
                  children: [
                    _buildNameCell(request, index),
                    _buildPeriodCell('${request['from']} - ${request['to']}'),
                    _buildTimeCell(request['totalTime']),
                    _buildStatusCell(request['status']),
                    _buildActionButtons(context, index, request),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text, {bool isCompact = false}) {
    return Padding(
      padding: isCompact
          ? const EdgeInsets.all(8.0)
          : const EdgeInsets.all(12.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isCompact ? 12 : 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildNameCell(
    Map<String, dynamic> request,
    int index, {
    bool isCompact = false,
  }) {
    return Padding(
      padding: isCompact
          ? const EdgeInsets.all(4.0)
          : const EdgeInsets.all(8.0),
      child: Text(
        request['name'],
        style: TextStyle(fontSize: isCompact ? 12 : 14),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildPeriodCell(String period, {bool isCompact = false}) {
    return Padding(
      padding: isCompact
          ? const EdgeInsets.all(8.0)
          : const EdgeInsets.all(12.0),
      child: Text(
        period,
        style: TextStyle(fontSize: isCompact ? 12 : 14),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTimeCell(String time, {bool isCompact = false}) {
    return Padding(
      padding: isCompact
          ? const EdgeInsets.all(8.0)
          : const EdgeInsets.all(12.0),
      child: Text(
        time,
        style: TextStyle(fontSize: isCompact ? 12 : 14),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildStatusCell(String status, {bool isCompact = false}) {
    return Padding(
      padding: isCompact
          ? const EdgeInsets.all(4.0)
          : const EdgeInsets.all(8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getStatusColor(status).withAlpha(128),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          status,
          style: TextStyle(
            fontSize: isCompact ? 10 : 12,
            color: _getStatusColor(status),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    int index,
    Map<String, dynamic> request, {
    bool isCompact = false,
  }) {
    return Padding(
      padding: isCompact
          ? const EdgeInsets.all(4.0)
          : const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.calendar_today, size: isCompact ? 16 : 20),
            onPressed: () => _showCalendarDialog(context, index),
            tooltip: 'View Calendar',
          ),
          if (request['status'] == 'Pending') ...[
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(
                Icons.close,
                size: isCompact ? 16 : 20,
                color: Colors.red,
              ),
              onPressed: () => _rejectRequest(index),
              tooltip: 'Reject',
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(
                Icons.check,
                size: isCompact ? 16 : 20,
                color: Colors.green,
              ),
              onPressed: () => _approveRequest(index),
              tooltip: 'Approve',
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    return status == 'Pending'
        ? Colors.orange
        : status == 'Approved'
        ? Colors.green
        : Colors.red;
  }

  Widget _buildCalendarDialog(BuildContext context, int index) {
    final request = _leaveRequests[index];

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${request['name']}\'s Leave Request',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text('Start Day:'),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButton<int>(
                          value: _selectedStartDay,
                          hint: const Text('Select day'),
                          isExpanded: true,
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
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                          childAspectRatio: 1.5,
                        ),
                    itemCount: 31,
                    itemBuilder: (context, dayIndex) {
                      final day = dayIndex + 1;
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
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () => _updateSelectedDay(index),
                        icon: const Icon(Icons.save, size: 18),
                        label: const Text('Save'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
