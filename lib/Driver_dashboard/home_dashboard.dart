import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() => runApp(JeepEZApp());

class JeepEZApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JeepEZ',
      theme: ThemeData(primarySwatch: Colors.blueGrey),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final String userName = 'Jeriel Solquia Celis';
  final String unitId = 'UNIT 20';
  final DateTime today = DateTime(2006, 6, 6, 0, 0);
  final List<TimeLog> logs = [
    TimeLog(time: TimeOfDay(hour: 7, minute: 20), label: 'Dispatch time'),
    TimeLog(time: TimeOfDay(hour: 9, minute: 0), label: 'Arrival time'),
  ];

  String get formattedDate {
    final dateFmt = DateFormat('MM/dd/yy');
    final weekday = DateFormat('EEEE').format(today);
    return 'Today | $weekday | ${dateFmt.format(today)}';
  }

  void _onNavTap(int idx) {
    setState(() => _selectedIndex = idx);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/logo.png'),
        ),
        title: Text('JeepEZ'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: AssetImage('assets/profile.jpg'),
                ),
                SizedBox(width: 12),
                Text(
                  userName,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
              ],
            ),

            SizedBox(height: 24),

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formattedDate,
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                    SizedBox(height: 8),
                    Text(
                      unitId,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            Text(
              'Time Logs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            ...logs.map(
              (log) => Card(
                child: ListTile(
                  leading: Icon(Icons.access_time, color: Colors.blueGrey),
                  title: Text(
                    log.label,
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  trailing: Text(
                    log.time.format(context),
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
        selectedItemColor: Colors.blueGrey,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.description), label: 'Docs'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class TimeLog {
  final TimeOfDay time;
  final String label;
  TimeLog({required this.time, required this.label});
}
