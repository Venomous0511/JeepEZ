import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class VehicleChecklistScreen extends StatefulWidget {
  const VehicleChecklistScreen({super.key});

  @override
  State<VehicleChecklistScreen> createState() => _VehicleChecklistScreenState();
}

class _VehicleChecklistScreenState extends State<VehicleChecklistScreen> {
  String? _assignedVehicle;
  bool _isLoadingVehicle = true;

  @override
  void initState() {
    super.initState();
    _fetchAssignedVehicle();
  }

  Future<void> _fetchAssignedVehicle() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists && userDoc.data()!.containsKey('assignedVehicle')) {
          final vehicleId = userDoc['assignedVehicle']?.toString() ?? 'N/A';
          setState(() {
            _assignedVehicle = vehicleId;
            _isLoadingVehicle = false;
          });
        } else {
          setState(() {
            _assignedVehicle = 'N/A';
            _isLoadingVehicle = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _assignedVehicle = 'N/A';
        _isLoadingVehicle = false;
      });
      debugPrint('Error fetching vehicle: $e');
    }
  }

  final List<String> _inspectionItems = [
    'Battery',
    'Lights',
    'Oil',
    'Water',
    'Brakes',
    'Air',
    'Gas',
    'Engine',
    'Tires',
  ];

  final Map<String, bool> _checklistItems = {};
  final TextEditingController _defectsController = TextEditingController();

  void _toggleItem(String item) {
    setState(() {
      _checklistItems[item] = !(_checklistItems[item] ?? false);
    });
  }

  void _submitForm() async {
    if (_checklistItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please check at least one item in the checklist'),
        ),
      );
      return;
    }

    final defects = _defectsController.text.trim();
    final hasDefects = defects.isNotEmpty;

    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('You must be logged in.')));
        return;
      }

      // Get assigned vehicle from user document
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists || !userDoc.data()!.containsKey('assignedVehicle')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No assigned vehicle found.')),
          );
        }
        return;
      }

      final vehicleId = userDoc['assignedVehicle'].toString();

      // Get checked items
      final checkedItems = _checklistItems.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      // Prepare maintenance data
      final maintenanceData = {
        'vehicleId': int.parse(vehicleId),
        'title': hasDefects ? defects : 'No issues found',
        'issueDate': FieldValue.serverTimestamp(),
        'createdBy': user.email,
        'reportedBy': user.displayName,
        'checklistItems': checkedItems,
        'hasDefects': hasDefects,
        'status': 'pending',
      };

      // Add maintenance record
      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(vehicleId)
          .collection('maintenance')
          .add(maintenanceData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Checklist submitted successfully!')),
        );
      }

      // Reset form
      setState(() {
        _checklistItems.clear();
        _defectsController.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error submitting: $e')));
      }
    }
  }

  @override
  void dispose() {
    _defectsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2364),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
          child: Column(
            children: [
              // Header Container
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D2364),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Vehicle Checklist",
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Kindly perform the Pre-Trip Inspection to ensure the vehicle is safe to use.",
                      style: TextStyle(
                        fontSize: isMobile ? 13 : 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: isMobile ? 10 : 20),

              if (_isLoadingVehicle)
                const CircularProgressIndicator()
              else if (_assignedVehicle != null && _assignedVehicle != 'N/A')
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    'Assigned Vehicle: $_assignedVehicle',
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    '⚠️ No vehicle assigned. Please contact admin.',
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.red[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              SizedBox(height: isMobile ? 5 : 20),

              // Multi-Checkbox Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withAlpha(1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade300, width: 1.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Inspection Items:',
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Multi-checkbox grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isMobile ? 2 : 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: isMobile ? 3 : 4,
                      ),
                      itemCount: _inspectionItems.length,
                      itemBuilder: (context, index) {
                        final item = _inspectionItems[index];
                        final isChecked = _checklistItems[item] ?? false;

                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isChecked
                                  ? const Color(0xFF0D2364)
                                  : Colors.grey.shade400,
                              width: isChecked ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: isChecked
                                ? const Color(0xFF0D2364).withAlpha(1)
                                : Colors.transparent,
                          ),
                          child: CheckboxListTile(
                            title: Text(
                              item,
                              style: TextStyle(
                                fontSize: isMobile ? 13 : 14,
                                fontWeight: FontWeight.w500,
                                color: isChecked
                                    ? const Color(0xFF0D2364)
                                    : Colors.black87,
                              ),
                            ),
                            value: isChecked,
                            onChanged: (bool? value) {
                              _toggleItem(item);
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: isMobile ? 16 : 20),

              // Defects Section Container
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isMobile ? 12.0 : 20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withAlpha(1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade300, width: 1.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Any Defects:',
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.shade400,
                          width: 1.0,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          TextField(
                            controller: _defectsController,
                            maxLength: 100, // Character limit
                            maxLines: 3,
                            style: TextStyle(fontSize: isMobile ? 13 : 14),
                            decoration: InputDecoration(
                              hintText:
                                  'Describe any defects found. If none, please indicate "No defects found".',
                              hintStyle: TextStyle(
                                fontSize: isMobile ? 13 : 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(12.0),
                              counterText: "", // Hide default counter
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              right: 12.0,
                              bottom: 8.0,
                            ),
                            child: Text(
                              '${_defectsController.text.length}/100',
                              style: TextStyle(
                                fontSize: 12,
                                color: _defectsController.text.length > 100
                                    ? Colors.red
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 8),
              if (_defectsController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_defectsController.text.length > 100)
                        Text(
                          'Character limit exceeded!',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),

              SizedBox(height: isMobile ? 16 : 20),

              // Buttons Section
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: isMobile ? 45 : 50,
                    child: ElevatedButton(
                      onPressed: _defectsController.text.length <= 100 &&
                          _assignedVehicle != null &&
                          _assignedVehicle != 'N/A'
                          ? _submitForm
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _defectsController.text.length <= 100 &&
                            _assignedVehicle != null &&
                            _assignedVehicle != 'N/A'
                            ? const Color(0xFF0D2364)
                            : Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Text(
                        _assignedVehicle == 'N/A' || _assignedVehicle == null
                            ? 'No Vehicle Assigned'
                            : 'Save & Submit',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 14 : 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(height: isMobile ? 20 : 30),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
