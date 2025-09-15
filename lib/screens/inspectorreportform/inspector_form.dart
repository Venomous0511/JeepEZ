import 'package:flutter/material.dart';

class InspectorReportScreen extends StatelessWidget {
  const InspectorReportScreen({super.key});

  final List<String> tripHeaders = const [
    'JEEP NO',
    'DRIVER',
    'CONDUCTOR',
    'FROM KM',
    'FROM TIME',
    'TO KM',
    'TO TIME',
    'NO OF TRIPS',
    'ROUND',
    '20.00',
    '15.00',
    '10.00',
    '2.00',
    '1.00',
    'NO OF PASS',
    'COND. SIGNATURE',
  ];

  final List<String> reportHeaders = const [
    'REPORT/REMARKS',
    'NAME',
    'POSITION',
    'VIOLATION',
    'KM',
    'TIME',
    'BOUND',
  ];

  Widget _headerCell(String label) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _inputCell() {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: TextField(
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
      ),
    );
  }

  TableRow _buildHeaderRow(List<String> headers) {
    return TableRow(children: headers.map(_headerCell).toList());
  }

  TableRow _buildInputRow(int count) {
    return TableRow(children: List.generate(count, (_) => _inputCell()));
  }

  List<TableRow> _buildMultipleInputRows(int count, int columns) {
    return List.generate(count, (_) => _buildInputRow(columns));
  }

  @override
  Widget build(BuildContext context) {
    const int tripRowCount = 5; // You can increase this to show more rows
    const int reportRowCount = 5;

    return Scaffold(
      appBar: AppBar(title: const Text('Trip Summary & Report')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trip Summary',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                border: TableBorder.all(color: Colors.grey),
                defaultColumnWidth: const IntrinsicColumnWidth(),
                children: [
                  _buildHeaderRow(tripHeaders),
                  ..._buildMultipleInputRows(tripRowCount, tripHeaders.length),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Report / Remarks',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                border: TableBorder.all(color: Colors.grey),
                defaultColumnWidth: const IntrinsicColumnWidth(),
                children: [
                  _buildHeaderRow(reportHeaders),
                  ..._buildMultipleInputRows(
                    reportRowCount,
                    reportHeaders.length,
                  ),
                ],
              ),
            ),
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
