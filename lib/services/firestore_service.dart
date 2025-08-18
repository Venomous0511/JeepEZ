import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  Future<AppUser?> getUser(String uid) async {
    var doc = await _db.collection("users").doc(uid).get();
    if (doc.exists) {
      return AppUser.fromMap(doc.id, doc.data()!);
    }
    return null;
  }

  Future<void> createUser(String uid, String email, String role) async {
    await _db.collection("users").doc(uid).set({"email": email, "role": role});
  }
}
