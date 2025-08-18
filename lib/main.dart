import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/dashboards/admin_dashboard.dart';
import 'screens/dashboards/super_admin_dashboard.dart';
import 'screens/dashboards/driver_dashboard.dart';
import 'screens/dashboards/conductor_dashboard.dart';
import 'screens/dashboards/inspector_dashboard.dart';
import 'models/app_user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const JeepezApp());
}

class JeepezApp extends StatelessWidget {
  const JeepezApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jeepez',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginScreen(),
    );
  }
}

// Handles role-based navigation after login
class RoleBasedDashboard extends StatelessWidget {
  final AppUser user;
  const RoleBasedDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    switch (user.role) {
      case "super_admin":
        return SuperAdminDashboard(user: user);
      case "admin":
        return AdminDashboard(user: user);
      case "driver":
        return DriverDashboard(user: user);
      case "conductor":
        return ConductorDashboard(user: user);
      case "inspector":
        return InspectorDashboard(user: user);
      default:
        return const Scaffold(body: Center(child: Text("Unknown role")));
    }
  }
}
