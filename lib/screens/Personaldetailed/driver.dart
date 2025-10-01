import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../screens/login_screen.dart';

class PersonalDetails extends StatefulWidget {
  final AppUser user;
  const PersonalDetails({super.key, required this.user});

  @override
  State<PersonalDetails> createState() => _PersonalDetailsState();
}

class _PersonalDetailsState extends State<PersonalDetails> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoggingOut = false;

  /// ---------------- SIGN OUT  ----------------
  Future<void> _signOut() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);

    try {
      // show loading for 3 seconds before signing out
      await Future.delayed(const Duration(seconds: 3));
      await AuthService().logout();

      // After logout, navigate to login screen and clear navigation stack
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(),
        ), // Use your actual LoginScreen widget
        (Route<dynamic> route) => false, // This removes all previous routes
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to sign out: $e')));
      setState(() => _isLoggingOut = false);
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Log Out"),
          content: const Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                _signOut();
              },
              child: _isLoggingOut
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text("Log Out"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String employeeId = "000001";
    final String jobTitle = "Driver";
    final String workStatus = "Part time";
    final String name = widget.user.name ?? "Ashu";
    final String address = "Sapang Palay Proper City of San Jose Del Monte";
    final String phone = "09920367481";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2364),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Header Container - SIMPLIFIED without any icons
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D2364),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: const Text(
                  "Personal Details",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),

              // Main Content Container
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withAlpha(3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: Colors.grey.shade300, width: 1.0),
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      // Personal Details Section
                      _buildSection(
                        title: "Personal Details",
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Employee ID: $employeeId",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Job Title and Work Status
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoItem(
                                  label: "Job Title:",
                                  value: jobTitle,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildInfoItem(
                                  label: "Work Status:",
                                  value: workStatus,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Other Information Section
                      _buildSection(
                        title: "Other Information",
                        children: [
                          _buildInfoItem(
                            label: "Address:",
                            value: address,
                            crossAlignment: CrossAxisAlignment.start,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoItem(label: "Phone:", value: phone),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Change Password Section
                      _buildSection(
                        title: "Change Password",
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey.shade400,
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: TextField(
                              controller: _currentPasswordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: "Current Password",
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(12.0),
                                hintText: "Enter your current password",
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey.shade400,
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: TextField(
                              controller: _newPasswordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: "New Password",
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(12.0),
                                hintText: "Enter your new password",
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Buttons
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 50,
                                  child: OutlinedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          8.0,
                                        ),
                                      ),
                                      side: BorderSide(
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                    child: const Text(
                                      "Cancel",
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SizedBox(
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (_currentPasswordController
                                              .text
                                              .isNotEmpty &&
                                          _newPasswordController
                                              .text
                                              .isNotEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Password changed successfully!",
                                            ),
                                          ),
                                        );
                                        Navigator.pop(context);
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Please fill in all fields",
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0D2364),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          8.0,
                                        ),
                                      ),
                                    ),
                                    child: const Text(
                                      "Change Password",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Log Out Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoggingOut
                              ? null
                              : _showLogoutConfirmation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          child: _isLoggingOut
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  "Log out",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D2364),
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoItem({
    required String label,
    required String value,
    CrossAxisAlignment crossAlignment = CrossAxisAlignment.start,
  }) {
    return Column(
      crossAxisAlignment: crossAlignment,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: Colors.grey.shade700)),
      ],
    );
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }
}
