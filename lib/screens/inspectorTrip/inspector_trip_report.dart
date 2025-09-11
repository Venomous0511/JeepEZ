import 'package:flutter/material.dart';

class InspectorTripReportScreen extends StatefulWidget {
  const InspectorTripReportScreen({super.key});

  @override
  State<InspectorTripReportScreen> createState() =>
      _InspectorTripReportScreenState();
}

class _InspectorTripReportScreenState extends State<InspectorTripReportScreen> {
  final List<String> headers = const [
    'REP NO',
    'DRIVER',
    'CONDUCTOR',
    'PLATE NO',
    'ROUTE',
    'FROM',
    'TO',
    'KM',
    'TIME IN',
    'TIME OUT',
    '2:00',
    '8:00',
    '15:00',
    '18:00',
    '20:00',
    'COND. SIGNATURE',
  ];

  Widget _headerCell(String label) => Padding(
    padding: const EdgeInsets.all(6),
    child: Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      textAlign: TextAlign.center,
    ),
  );

  Widget _inputCell() => Padding(
    padding: const EdgeInsets.all(4),
    child: TextField(
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    ),
  );

  TableRow _buildHeaderRow() =>
      TableRow(children: headers.map(_headerCell).toList());

  TableRow _buildInputRow() =>
      TableRow(children: List.generate(headers.length, (_) => _inputCell()));

  Widget _checkboxLabel(String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Checkbox(value: false, onChanged: (_) {}),
      Text(label),
    ],
  );

  @override
  Widget build(BuildContext context) {
    const int rowCount = 5;

    return Scaffold(
      appBar: AppBar(title: const Text('INSPECTOR TRIP REPORT')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'NAME OF INSPECTOR:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            _inputCell(),
            const SizedBox(height: 8),
            const Text('DATE:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            _inputCell(),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                border: TableBorder.all(color: Colors.grey),
                defaultColumnWidth: const IntrinsicColumnWidth(),
                children: [
                  _buildHeaderRow(),
                  ...List.generate(rowCount, (_) => _buildInputRow()),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Remarks:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Wrap(
              spacing: 12,
              children: [
                _checkboxLabel('1 day'),
                _checkboxLabel('½ day'),
                _checkboxLabel('Straight'),
                _checkboxLabel('Under time'),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Reminder: Please submit report one (1) day before pay day. Thank you!',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 12),
            const Text(
              'PLEASE FILL UP THE FORM COMPLETELY',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            const Text(
              'Inspector\'s Signature:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            _inputCell(),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Save or preview logic here
                },
                child: const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
