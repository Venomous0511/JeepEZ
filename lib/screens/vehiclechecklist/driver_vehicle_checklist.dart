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
  String _currentPriority = '';

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
          setState(() {
            _assignedVehicle = userDoc['assignedVehicle'].toString();
            _isLoadingVehicle = false;
          });
        } else {
          setState(() => _isLoadingVehicle = false);
        }
      }
    } catch (e) {
      setState(() => _isLoadingVehicle = false);
      debugPrint('Error fetching vehicle: $e');
    }
  }

  String _determinePriority(String defectText) {
    final lower = defectText.toLowerCase();

    // High Priority Issues
    if (lower.contains('brake') ||
        lower.contains('engine') ||
        lower.contains('tire') ||
        lower.contains('steering')) {
      return 'HIGH';
    }

    // Medium Priority Issues
    if (lower.contains('oil') ||
        lower.contains('water') ||
        lower.contains('battery') ||
        lower.contains('light')) {
      return 'MEDIUM';
    }

    // Default to Low
    return 'LOW';
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

  final List<ChecklistItem> _checklistItems = [];
  String? _selectedItem;
  final TextEditingController _defectsController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _addItem() {
    if (_selectedItem != null &&
        !_checklistItems.any((item) => item.title == _selectedItem)) {
      setState(() {
        _checklistItems.add(
          ChecklistItem(title: _selectedItem!, checked: false),
        );
        _selectedItem = null;

        // Auto-scroll to bottom after adding item
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      });
    } else if (_selectedItem != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item already added to checklist')),
      );
    }
  }

  void _removeItem(int index) {
    setState(() {
      _checklistItems.removeAt(index);
    });
  }

  void _submitForm() async {
    if (_checklistItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add items to the checklist')),
      );
      return;
    }

    final defects = _defectsController.text.trim();

    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in.')),
        );
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

      // If there are defects, add maintenance record
      if (defects.isNotEmpty) {
        final priority = _determinePriority(defects);

        await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(vehicleId)
            .collection('maintenance')
            .add({
          'vehicleId': int.parse(vehicleId),
          'title': defects,
          'priority': priority,
          'issueDate': FieldValue.serverTimestamp(),
          'createdBy': user.email,
          'checklistItems': _checklistItems.map((e) => e.title).toList(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Checklist submitted successfully!')),
        );
      }

      setState(() {
        _checklistItems.clear();
        _defectsController.clear();
      });

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting: $e')),
        );
      }
    }
  }


  @override
  void dispose() {
    _defectsController.dispose();
    _scrollController.dispose();
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
          controller: _scrollController,
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
              else if (_assignedVehicle != null)
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
                const Text(
                  'No assigned vehicle found.',
                  style: TextStyle(color: Colors.red),
                ),

              SizedBox(height: isMobile ? 5 : 20),

              // Dropdown Section
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
                      'Select Inspection Item:',
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey.shade400,
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedItem,
                                hint: Text(
                                  'Choose an item...',
                                  style: TextStyle(
                                    fontSize: isMobile ? 13 : 14,
                                  ),
                                ),
                                isExpanded: true,
                                items: _inspectionItems.map((String item) {
                                  return DropdownMenuItem<String>(
                                    value: item,
                                    child: Text(
                                      item,
                                      style: TextStyle(
                                        fontSize: isMobile ? 13 : 14,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedItem = newValue;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _addItem,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D2364),
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 16 : 20,
                              vertical: isMobile ? 12 : 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          child: Text(
                            'Add',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isMobile ? 13 : 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: isMobile ? 16 : 20),

              // Checklist Container
              Container(
                width: double.infinity,
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
                  children: [
                    // Table Header - UPDATED: Changed "Actions" to "Remove"
                    Container(
                      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12.0),
                          topRight: Radius.circular(12.0),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Inspection Item',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 14 : 16,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Remove',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 14 : 16,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Checklist Items - UPDATED: Removed checkbox, changed delete to 'x'
                    _checklistItems.isEmpty
                        ? SizedBox(
                            height: 120,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Text(
                                  'No items added yet.\nSelect an item from dropdown above.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: isMobile ? 13 : 14,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Column(
                            children: _checklistItems.asMap().entries.map((
                              entry,
                            ) {
                              final index = entry.key;
                              final item = entry.value;
                              return Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: index < _checklistItems.length - 1
                                        ? BorderSide(
                                            color: Colors.grey.shade300,
                                            width: 1.0,
                                          )
                                        : BorderSide.none,
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(
                                    isMobile ? 12.0 : 16.0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: TextStyle(
                                            fontSize: isMobile ? 14 : 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      // UPDATED: Removed checkbox, changed to simple 'x' button
                                      Container(
                                        width: isMobile ? 32 : 40,
                                        height: isMobile ? 32 : 40,
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: Colors.red.shade200,
                                            width: 1.0,
                                          ),
                                        ),
                                        child: IconButton(
                                          icon: Icon(
                                            Icons.close,
                                            size: isMobile ? 16 : 18,
                                            color: Colors.red,
                                          ),
                                          padding: EdgeInsets.zero,
                                          onPressed: () => _removeItem(index),
                                          tooltip: 'Remove item',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
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

                      child: TextField(
                        controller: _defectsController,
                        onChanged: (value) {
                          setState(() {
                            _currentPriority = _determinePriority(value);
                          });
                        },
                        maxLines: 3,
                        style: TextStyle(fontSize: isMobile ? 13 : 14),
                        decoration: InputDecoration(
                          hintText:
                              'Describe any defects found during inspection...',
                          hintStyle: TextStyle(fontSize: isMobile ? 13 : 14),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(12.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 8),
              if (_defectsController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Priority: $_currentPriority',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _currentPriority == 'HIGH'
                          ? Colors.red
                          : _currentPriority == 'MEDIUM'
                          ? Colors.orange
                          : Colors.green,
                    ),
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
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D2364),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Text(
                        'Save & Submit',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 14 : 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Extra space at the bottom to prevent overflow
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

class ChecklistItem {
  String title;
  bool checked;

  ChecklistItem({required this.title, required this.checked});
}
