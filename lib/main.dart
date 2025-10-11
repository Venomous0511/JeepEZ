import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/dashboards/admin_dashboard.dart';
import 'screens/dashboards/super_admin_dashboard.dart';
import 'screens/dashboards/legal_officer_dashboard.dart';
import 'screens/dashboards/driver_dashboard.dart';
import 'screens/dashboards/conductor_dashboard.dart';
import 'screens/dashboards/inspector_dashboard.dart';
import 'models/app_user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );
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
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            // Is User Logged In
            return FutureBuilder(
              future: FirebaseFirestore.instance
                  .collection("users")
                  .doc(snapshot.data!.uid)
                  .get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  FirebaseAuth.instance.signOut();
                  return const LoginScreen();
                }

                if (!userSnapshot.data!.exists) {
                  return const Scaffold(
                    body: Center(child: Text("User profile not found. Please contact admin.")),
                  );
                }

                final doc = userSnapshot.data!;
                final data = doc.data() ?? {};

                AppUser user = AppUser.fromMap(snapshot.data!.uid, data);

                return RoleBasedDashboard(user: user);
              },
            );
          }

          if (snapshot.hasError) {
            return Scaffold(
              body: Center(child: Text("Error: ${snapshot.error}")),
            );
          }

          return const LoginScreen();
        },
      ),
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
      case "legal_officer":
        return LegalOfficerDashboardScreen(user: user);
      case "driver":
        return DriverDashboard(user: user);
      case "inspector":
        return InspectorDashboard(user: user);
      case "conductor":
        return ConductorDashboard(user: user);
      default:
        return const Scaffold(body: Center(child: Text("Unknown role")));
    }
  }
}
