import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../firebase_options.dart';
import '../../models/app_user.dart';

class SuperAdminDashboard extends StatefulWidget {
  final AppUser user; // typed
  const SuperAdminDashboard({super.key, required this.user});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  final emailCtrl = TextEditingController();
  final passCtrl  = TextEditingController();
  final nameCtrl  = TextEditingController();
  String role = 'driver';
  bool loading = false;

  Future<FirebaseApp> _getOrCreateSecondaryApp() async {
    try {
      return Firebase.app('adminSecondary');
    } catch (_) {
      return await Firebase.initializeApp(
        name: 'adminSecondary',
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }

  Future<void> _createUser() async {
    if (emailCtrl.text.trim().isEmpty || passCtrl.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter email and 6+ char password')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      // secondary app/auth so primary stays signed in as super_admin
      final secondaryApp  = await _getOrCreateSecondaryApp();
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      // 1) Create Auth account (in secondary)
      final newCred = await secondaryAuth.createUserWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
      );
      final newUid = newCred.user!.uid;

      // 2) Create Firestore user doc (runs as primary super_admin)
      await FirebaseFirestore.instance.collection('users').doc(newUid).set({
        'uid': newUid,
        'email': emailCtrl.text.trim(),
        'name': nameCtrl.text.trim(),
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': widget.user.email,
      });

      // optional: sign out the secondary user
      await secondaryAuth.signOut();

      // optional: clear inputs
      emailCtrl.clear();
      passCtrl.clear();
      nameCtrl.clear();
      setState(() => role);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User created as $role')),
      );
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'email-already-in-use' => 'Email already in use',
        'invalid-email'        => 'Invalid email',
        'weak-password'        => 'Weak password (min 6)',
        _                      => 'Auth error: ${e.code}',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } on FirebaseException catch (e) {
      // Firestore permission errors show here
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Firestore error: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Super Admin Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text('Create User', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: role,
              items: const ['admin','driver','conductor','inspector']
                  .map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (v) => setState(() => role = v ?? 'driver'),
              decoration: const InputDecoration(labelText: 'Role'),
            ),
            const SizedBox(height: 16),
            loading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
              onPressed: _createUser,
              icon: const Icon(Icons.person_add),
              label: const Text('Create User'),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            const Text('Existing Users', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // simple list of users
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ));
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('No users yet.'),
                  );
                }
                return Column(
                  children: snap.data!.docs.map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(data['email'] ?? ''),
                      subtitle: Text((data['name'] ?? '') + ' • ' + (data['role'] ?? '')),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
