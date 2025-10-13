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
  String _employmentType = ""; // Add this variable

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
      final employmentType =
          userData['employmentType'] as String?; // Fetch employment type

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
        // Trim underscores and set employment type
        _employmentType = _trimUnderscores(employmentType ?? "Not specified");
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching schedule: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Method to trim underscores from employment type
  String _trimUnderscores(String employmentType) {
    return employmentType.replaceAll('_', ' ').trim();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

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
                      child: const Text(
                        "Your Schedule",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Blue Container with Schedule
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isMobile ? 16 : 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D2364), // BLUE CONTAINER
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Unit number - UPDATED WITH WHITE TEXT
                          Text(
                            'UNIT ${_vehicleId ?? "N/A"}',
                            style: TextStyle(
                              color: Colors.white, // WHITE TEXT
                              fontSize: isMobile ? 20 : 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Employment Type - ADDED
                          Text(
                            _employmentType.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white, // WHITE TEXT
                              fontSize: isMobile ? 16 : 18,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // SCHEDULE SECTION
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Schedule Title
                                const SizedBox(height: 12),

                                // Schedule entries
                                if (_scheduleDays.isEmpty)
                                  Text(
                                    "No schedule found",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: isMobile ? 14 : 16,
                                    ),
                                  )
                                else
                                  Column(
                                    children: _scheduleDays.map((day) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                day,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: isMobile ? 14 : 16,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                              ],
                            ),
                          ),
                        ],
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
