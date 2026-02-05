import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { employer, worker }

class AuthService {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// LOGIN + ROLE FETCH
  Future<UserRole> login({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = cred.user!.uid;

    final snap = await _db.collection('users').doc(uid).get();
    if (!snap.exists) {
      throw Exception("User profile not found");
    }

    final role = snap.data()!['role'];

    if (role == 'employer') return UserRole.employer;
    if (role == 'worker') return UserRole.worker;

    throw Exception("Invalid role");
  }

  /// FORGOT PASSWORD (already used by your UI)
  Future<void> resetPassword({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }
}