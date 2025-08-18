import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../main.dart';
import '../models/app_user.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Jeepez Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 20),
            if (loading) const CircularProgressIndicator(),
            if (!loading)
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    loading = true;
                    error = "";
                  });
                  try {
                    AppUser? user = await AuthService().login(
                      emailCtrl.text.trim(),
                      passCtrl.text.trim(),
                    );
                    if (user != null && context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RoleBasedDashboard(user: user),
                        ),
                      );
                    } else {
                      setState(() => error = "User not found");
                    }
                  } catch (e) {
                    setState(() => error = e.toString());
                  } finally {
                    setState(() => loading = false);
                  }
                },
                child: const Text("Login"),
              ),
            if (error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(error, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}
