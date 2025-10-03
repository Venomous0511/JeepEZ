import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class WorkScheduleScreen extends StatefulWidget {
  const WorkScheduleScreen({super.key});

  @override
  State<WorkScheduleScreen> createState() => _WorkScheduleScreenState();
}

class _WorkScheduleScreenState extends State<WorkScheduleScreen> {
  String? _vehicleId;
  List<String> _scheduleDays = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserScheduleAndVehicle();
  }

  final PageController _pageController = PageController();

  Future<void> _fetchUserScheduleAndVehicle() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // 1. Fetch user data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (!userDoc.exists) {
        throw Exception("User not found in Firestore");
      }

      final userData = userDoc.data()!;
      final assignedVehicle = userData['assignedVehicle']?.toString();
      final scheduleStr = userData['schedule'] as String?;

      // 2. Convert schedule string to list of days
      List<String> scheduleDays = [];
      if (scheduleStr != null && scheduleStr.isNotEmpty) {
        scheduleDays = scheduleStr
            .split(',')
            .map((d) => d.trim().toUpperCase())
            .toList();
      }

      // 3. Optionally fetch vehicle details
      String? vehicleId;
      if (assignedVehicle != null) {
        final vehicleDoc = await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(assignedVehicle)
            .get();
        if (vehicleDoc.exists) {
          vehicleId = vehicleDoc.id;
        }
      }

      setState(() {
        _vehicleId = vehicleId;
        _scheduleDays = scheduleDays;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching schedule: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: const Color(0xFF0D2364)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D2364),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Text(
                        "Your Schedule",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withAlpha(50),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1.0,
                          ),
                        ),
                        child: _scheduleDays.isEmpty
                            ? const Center(child: Text("No schedule found."))
                            : ListView.builder(
                                itemCount: _scheduleDays.length,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                    title: Text(
                                      _scheduleDays[index],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    trailing: Text(
                                      "UNIT: ${_vehicleId ?? "-"}",
                                      style: const TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
