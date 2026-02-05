import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class GoogleSignInService {
  GoogleSignInService._();
  static final GoogleSignInService instance = GoogleSignInService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Updated to accept an optional role (defaults to 'worker')
  Future<UserCredential?> signInWithGoogle({String role = 'worker'}) async {
    try {
      final googleProvider = GoogleAuthProvider();
      final UserCredential userCred = await _auth.signInWithPopup(googleProvider);

      final user = userCred.user;
      if (user == null) return null;

      final userRef = _db.collection('users').doc(user.uid);
      final snap = await userRef.get();

      if (!snap.exists) {
        await userRef.set({
          'name': user.displayName ?? 'New User',
          'email': user.email,
          'role': role, // Now uses the role passed from the UI
          'points': 0,
          'reliability': 100,
          'createdAt': FieldValue.serverTimestamp(),
          'savedShifts': [],
        });
      }

      return userCred;
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}