import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../screens/login_screen.dart';
import '../dashboards/driver_dashboard.dart';

class PersonalDetails extends StatefulWidget {
  final AppUser user;
  const PersonalDetails({super.key, required this.user});

  @override
  State<PersonalDetails> createState() => _PersonalDetailsState();
}

class _PersonalDetailsState extends State<PersonalDetails> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TrackingService _trackingService = TrackingService();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _isLoggingOut = false;
  bool _isChangingPassword = false;

  bool _showCurrentPassword = false;
  bool _showNewPassword = false;

  String employeeId = "";
  String name = "";
  String jobTitle = "";
  String workStatus = "";

  @override
  void initState() {
    super.initState();
    _loadDriverInfo();
  }

  /// ---------------- LOAD USER DETAILS ----------------
  Future<void> _loadDriverInfo() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          employeeId = data['employeeId']?.toString() ?? '';
          name = data['name'] ?? '';
          jobTitle = data['role'] ?? 'Driver';
          workStatus = data['employmentType'] ?? 'Part time';
        });
      }
    }
  }

  /// ---------------- CHANGE PASSWORD ----------------
  Future<void> _changePassword() async {
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final user = _auth.currentUser;

    if (currentPassword.isEmpty || newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    setState(() => _isChangingPassword = true);

    try {
      // Re-authenticate user with current password
      final cred = EmailAuthProvider.credential(
        email: user!.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(cred);

      // Update password
      await user.updatePassword(newPassword);

      // Optional: update a flag in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'lastPasswordChange': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password changed successfully!")),
      );

      _currentPasswordController.clear();
      _newPasswordController.clear();
    } on FirebaseAuthException catch (e) {
      String message = "Password change failed";
      if (e.code == 'wrong-password') {
        message = "Current password is incorrect";
      } else if (e.code == 'weak-password') {
        message = "New password is too weak";
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isChangingPassword = false);
    }
  }

  /// ---------------- SIGN OUT  ----------------
  Future<void> _signOut() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);

    try {
      // show loading for 3 seconds before signing out
      await Future.delayed(const Duration(seconds: 3));

      final user = _auth.currentUser;

      if (user != null) {
        // Stop location tracking first
        await _trackingService.stopTracking();

        // Remove GPS marker from Firestore using your instance
        if (employeeId.isNotEmpty) {
          await _firestore
              .collection('vehicles_locations')
              .doc(employeeId)
              .delete();
        }

        // Firebase logout
        await _auth.signOut();
      }

      if (!mounted) return;

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

  /// ---------------- CONFIRMATION SIGN OUT ----------------
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

  /// ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2364),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
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

              // Main Content
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withAlpha(30),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListView(
                    children: [
                      _buildSection(
                        title: "Personal Details",
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text("Employee ID: $employeeId"),
                          const SizedBox(height: 16),
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

                      // Change Password Section
                      _buildSection(
                        title: "Change Password",
                        children: [
                          _buildPasswordField(
                            controller: _currentPasswordController,
                            label: "Current Password",
                            showPassword: _showCurrentPassword,
                            onToggle: () {
                              setState(() {
                                _showCurrentPassword = !_showCurrentPassword;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildPasswordField(
                            controller: _newPasswordController,
                            label: "New Password",
                            showPassword: _showNewPassword,
                            onToggle: () {
                              setState(() {
                                _showNewPassword = !_showNewPassword;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _isChangingPassword
                                ? null
                                : _changePassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D2364),
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            child: _isChangingPassword
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  )
                                : const Text(
                                    "Change Password",
                                    style: TextStyle(
                                      color: Color(0xffffffff),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Logout Button
                      ElevatedButton(
                        onPressed: _isLoggingOut
                            ? null
                            : _showLogoutConfirmation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: _isLoggingOut
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
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

  Widget _buildInfoItem({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: Colors.grey.shade700)),
      ],
    );
  }

  // Updated _buildPasswordField with show/hide functionality
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool showPassword,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: !showPassword,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        suffixIcon: IconButton(
          icon: Icon(
            showPassword ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _trackingService.stopTracking();
    super.dispose();
  }
}
