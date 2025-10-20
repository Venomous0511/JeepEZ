import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../main.dart';
import '../settings_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool loading = false;
  String error = "";
  bool showPassword = false;
  bool isMaintenanceMode = false;
  bool isCheckingMaintenance = true;
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _setupEnterKeyListeners();
    _checkMaintenanceMode();
  }

  Future<void> _checkMaintenanceMode() async {
    final mode = await SettingsService.getMaintenanceMode();
    setState(() {
      isMaintenanceMode = mode;
      isCheckingMaintenance = false;
    });
  }

  void _setupEnterKeyListeners() {
    emailCtrl.addListener(() {});
    passCtrl.addListener(() {});
  }

  void _performLogin() async {
    if (loading) return;

    setState(() {
      loading = true;
      error = "";
    });

    final email = emailCtrl.text.trim();
    final password = passCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = "Please enter both email and password.";
      });
      return;
    }

    try {
      // Sign in with Firebase Auth directly to check email verification
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Login failed');
      }

      // Reload user to get latest emailVerified status
      await firebaseUser.reload();
      final updatedUser = FirebaseAuth.instance.currentUser;

      // Check if email is verified (skip for super_admin)
      if (updatedUser != null && !updatedUser.emailVerified) {
        // Get user role from Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(updatedUser.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final userRole = userData['role'] as String?;

          // Only super_admin can bypass email verification
          if (userRole != 'super_admin') {
            // Sign out the user
            await FirebaseAuth.instance.signOut();

            if (mounted) {
              setState(() => loading = false);
              _showEmailVerificationDialog(updatedUser);
            }
            return;
          }
        }
      }

      // Update Firestore with email verified status and last login
      await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .update({
            'emailVerified': true,
            'lastLogin': FieldValue.serverTimestamp(),
          });

      // Get user data from your auth service
      final user = await AuthService().login(email, password);

      if (!mounted) return;

      if (user != null) {
        // Check if account is active
        if (user.status == false) {
          await FirebaseAuth.instance.signOut();
          setState(() {
            loading = false;
            error =
                "Your account has been deactivated. Please contact the administrator.";
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error), backgroundColor: Colors.red),
            );
          }
          return;
        }

        // Allow admin users to bypass maintenance mode
        if (isMaintenanceMode && user.role != 'super_admin') {
          await FirebaseAuth.instance.signOut();
          setState(() {
            loading = false;
            error = "System is under maintenance. Please try again later.";
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error), backgroundColor: Colors.orange),
            );
          }
          return;
        }

        // Check if using temporary password
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;

          if (userData['tempPassword'] != null) {
            // Redirect to change password screen
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangePasswordScreen(
                    user: firebaseUser,
                    userData: userData,
                    isFirstLogin: true,
                  ),
                ),
              );
            }
            return;
          }
        }

        // Navigate to dashboard
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => RoleBasedDashboard(user: user)),
          );
        }
      } else {
        setState(() {
          error = "Invalid email or password.";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String errorMessage = 'Login failed';

      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many failed attempts. Please try again later';
          break;
        case 'invalid-credential':
          errorMessage = 'Invalid email or password';
          break;
        default:
          errorMessage = e.message ?? 'Login failed';
      }

      setState(() {
        error = errorMessage;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = "Login failed: ${e.toString()}";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  void _showEmailVerificationDialog(User user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.mail_outline, color: Colors.orange[700], size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Email Verification Required',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your email address has not been verified yet.',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 16),
              const Text(
                'Please check your email inbox and click the verification link we sent you.',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            "Didn't receive the email?",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• Check your spam/junk folder\n'
                      '• Make sure the email address is correct\n'
                      '• Click "Resend Email" below',
                      style: TextStyle(fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                await user.sendEmailVerification();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Verification email sent! Please check your inbox.',
                      ),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to send email: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.send, size: 18, color: Colors.white),
            label: const Text(
              'Resend Email',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D2364),
            ),
          ),
        ],
      ),
    );
  }

  void _showAdminBypassDialog() {
    final adminCodeCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Admin Access"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Enter admin code to bypass maintenance mode:"),
              const SizedBox(height: 16),
              TextField(
                controller: adminCodeCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Admin Code",
                  border: OutlineInputBorder(),
                  hintText: "Enter code",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D2364),
              ),
              onPressed: () {
                if (adminCodeCtrl.text.trim() == "SuperAdmin#123456") {
                  Navigator.of(context).pop();
                  setState(() {
                    isMaintenanceMode = false;
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Invalid admin code"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text(
                "Verify",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 30),
            color: const Color(0xFF0D2364),
            child: Column(
              children: [
                Image.asset(
                  'assets/images/a47c2721-58f7-4dc7-a395-082ab4b753e0.jpg',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Center(
                child: isCheckingMaintenance
                    ? const CircularProgressIndicator()
                    : isMaintenanceMode
                    ? _buildMaintenanceView()
                    : _buildLoginForm(),
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Text(
              "JeepEZ",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceView() {
    return Container(
      width: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.construction, size: 80, color: Colors.orange[700]),
          const SizedBox(height: 24),
          Text(
            'Under Maintenance',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.orange[700],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'We are currently performing scheduled maintenance to improve your experience.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 24),
          const Text(
            'Please check back later.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text('Retry', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D2364),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            ),
            onPressed: () {
              setState(() {
                isCheckingMaintenance = true;
              });
              _checkMaintenanceMode();
            },
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _showAdminBypassDialog,
            child: const Text(
              'Admin Access',
              style: TextStyle(
                color: Color(0xFF0D2364),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return SingleChildScrollView(
      child: Container(
        width: 400,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailCtrl,
              focusNode: _emailFocusNode,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
              ),
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.emailAddress,
              onSubmitted: (value) {
                FocusScope.of(context).requestFocus(_passwordFocusNode);
              },
            ),
            const SizedBox(height: 16),

            TextField(
              controller: passCtrl,
              focusNode: _passwordFocusNode,
              obscureText: !showPassword,
              decoration: InputDecoration(
                labelText: "Password",
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    showPassword ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      showPassword = !showPassword;
                    });
                  },
                ),
              ),
              textInputAction: TextInputAction.go,
              onSubmitted: (value) {
                _performLogin();
              },
            ),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  _showForgotPasswordDialog(context);
                },
                child: const Text(
                  "Forgot Password?",
                  style: TextStyle(
                    color: Color(0xFF0D2364),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (loading)
              const CircularProgressIndicator()
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D2364),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _performLogin,
                  child: const Text(
                    "Login",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),

            if (error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  error,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 16),

            // Info box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'New users must verify their email before logging in',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final emailController = TextEditingController();
    final FocusNode dialogEmailFocusNode = FocusNode();
    bool sending = false;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.lock_reset, color: Colors.blue[700], size: 28),
                  const SizedBox(width: 12),
                  const Expanded(child: Text("Reset Password")),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Enter your email address and we'll send you a link to reset your password.",
                      style: TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 20),

                    TextField(
                      controller: emailController,
                      focusNode: dialogEmailFocusNode,
                      decoration: const InputDecoration(
                        labelText: "Email Address",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                        hintText: "Enter your email",
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      enabled: !sending,
                      onSubmitted: (value) {
                        if (!sending && value.trim().isNotEmpty) {
                          _sendResetLink(
                            emailController.text.trim(),
                            dialogContext,
                            setDialogState,
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 20),

                    // Information box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'What happens next?',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '1. Check your email inbox (and spam folder)\n'
                            '2. Click the password reset link\n'
                            '3. Create a new password\n'
                            '4. Return to login with new password',
                            style: TextStyle(fontSize: 13, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: sending
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text("Cancel"),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D2364),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onPressed: sending
                      ? null
                      : () async {
                          final email = emailController.text.trim();
                          if (email.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Please enter your email address",
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          setDialogState(() {
                            sending = true;
                          });

                          await _sendResetLinkAsync(email, dialogContext);
                        },
                  icon: sending
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.send, size: 18, color: Colors.white),
                  label: Text(
                    sending ? "Sending..." : "Send Reset Link",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      // Refocus on email field when dialog closes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          FocusScope.of(context).requestFocus(_emailFocusNode);
        }
      });
    });
  }

  Future<void> _sendResetLinkAsync(
    String email,
    BuildContext dialogContext,
  ) async {
    // Validate email format
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(email)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please enter a valid email address"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (context.mounted) {
        Navigator.of(dialogContext).pop();
        _showPasswordResetSuccessDialog(email);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Failed to send reset email';

      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email address';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address format';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many requests. Please try again later';
          break;
        default:
          errorMessage = e.message ?? 'Failed to send reset email';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _sendResetLink(
    String email,
    BuildContext dialogContext,
    Function setDialogState,
  ) async {
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter your email address"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate email format
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid email address"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setDialogState(() {
      // This will trigger the UI to show loading state
    });

    try {
      // 🔥 Send password reset email using Firebase Auth
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (context.mounted) {
        Navigator.of(dialogContext).pop();

        _showPasswordResetSuccessDialog(email);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Failed to send reset email';

      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email address';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address format';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many requests. Please try again later';
          break;
        default:
          errorMessage = e.message ?? 'Failed to send reset email';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      setDialogState(() {
        // Reset loading state
      });
    }
  }

  void _showPasswordResetSuccessDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[700], size: 28),
            const SizedBox(width: 12),
            const Expanded(child: Text('Email Sent Successfully')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Password reset instructions have been sent to:',
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.email, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        email,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Next Steps:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Check your email inbox (and spam folder)\n'
                      '2. Click the password reset link in the email\n'
                      '3. Create a new secure password\n'
                      '4. Return here and log in with your new password',
                      style: TextStyle(fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      color: Colors.grey[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'The password reset link will expire in 1 hour',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.yellow.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.yellow.shade700),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.yellow[800],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Didn\'t receive the email? Check your spam folder or click "Forgot Password" again to resend.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D2364),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Got It', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }
}

// Placeholder - Create this screen or import from your existing code
class ChangePasswordScreen extends StatefulWidget {
  final User user;
  final Map<String, dynamic> userData;
  final bool isFirstLogin;

  const ChangePasswordScreen({
    super.key,
    required this.user,
    required this.userData,
    required this.isFirstLogin,
  });

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;

  // Password strength indicators
  bool _hasMinLength = false;
  bool _hasUpperCase = false;
  bool _hasLowerCase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

  @override
  void initState() {
    super.initState();
    _newPasswordCtrl.addListener(_checkPasswordStrength);
  }

  void _checkPasswordStrength() {
    final password = _newPasswordCtrl.text;
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUpperCase = password.contains(RegExp(r'[A-Z]'));
      _hasLowerCase = password.contains(RegExp(r'[a-z]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
  }

  bool get _isPasswordStrong {
    return _hasMinLength &&
        _hasUpperCase &&
        _hasLowerCase &&
        _hasNumber &&
        _hasSpecialChar;
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isPasswordStrong) {
      _showErrorSnackBar('Please meet all password requirements');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentPassword = _currentPasswordCtrl.text.trim();
      final newPassword = _newPasswordCtrl.text.trim();

      // Re-authenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: widget.user.email!,
        password: currentPassword,
      );

      await widget.user.reauthenticateWithCredential(credential);

      // Update password
      await widget.user.updatePassword(newPassword);

      // Remove tempPassword flag from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .update({
            'tempPassword': FieldValue.delete(),
            'passwordChangedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      // Show success dialog
      await _showSuccessDialog();

      // Navigate to dashboard
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .get();

      if (!userDoc.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: User data not found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final user = AppUser.fromMap(widget.user.uid, userDoc.data() ?? {});
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => RoleBasedDashboard(user: user)),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Failed to change password';

      switch (e.code) {
        case 'wrong-password':
          errorMessage = 'Current password is incorrect';
          break;
        case 'weak-password':
          errorMessage = 'The new password is too weak';
          break;
        case 'requires-recent-login':
          errorMessage = 'Please log in again and try changing your password';
          break;
        default:
          errorMessage = e.message ?? 'Failed to change password';
      }

      _showErrorSnackBar(errorMessage);
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _showSuccessDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[700], size: 28),
            const SizedBox(width: 12),
            const Text('Password Changed'),
          ],
        ),
        content: const Text(
          'Your password has been successfully changed. You can now use your new password to log in.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D2364),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Continue',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Change Password'),
        backgroundColor: const Color(0xFF0D2364),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: !widget.isFirstLogin,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    if (widget.isFirstLogin) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange[700]),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'You are using a temporary password. Please set a new secure password to continue.',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Current Password
                    TextFormField(
                      controller: _currentPasswordCtrl,
                      obscureText: !_showCurrentPassword,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showCurrentPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _showCurrentPassword = !_showCurrentPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your current password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // New Password
                    TextFormField(
                      controller: _newPasswordCtrl,
                      obscureText: !_showNewPassword,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showNewPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _showNewPassword = !_showNewPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a new password';
                        }
                        if (value == _currentPasswordCtrl.text) {
                          return 'New password must be different from current password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password Requirements
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Password Requirements:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildRequirement(
                            'At least 8 characters',
                            _hasMinLength,
                          ),
                          _buildRequirement(
                            'Contains uppercase letter (A-Z)',
                            _hasUpperCase,
                          ),
                          _buildRequirement(
                            'Contains lowercase letter (a-z)',
                            _hasLowerCase,
                          ),
                          _buildRequirement(
                            'Contains number (0-9)',
                            _hasNumber,
                          ),
                          _buildRequirement(
                            'Contains special character (!@#\$%^&*)',
                            _hasSpecialChar,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Confirm Password
                    TextFormField(
                      controller: _confirmPasswordCtrl,
                      obscureText: !_showConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _showConfirmPassword = !_showConfirmPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your new password';
                        }
                        if (value != _newPasswordCtrl.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _changePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D2364),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Change Password',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    // Cancel button (only if not first login)
                    if (!widget.isFirstLogin) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.pop(context),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Color(0xFF0D2364),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: isMet ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: isMet ? Colors.green[700] : Colors.grey[700],
                fontWeight: isMet ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }
}
