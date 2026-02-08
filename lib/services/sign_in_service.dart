import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class GoogleSignInService {
  GoogleSignInService._();
  static final GoogleSignInService instance = GoogleSignInService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<UserCredential> signInWithGoogle({String role = 'worker'}) async {
    try {
      final googleProvider = GoogleAuthProvider();

      final UserCredential userCred =
          await _auth.signInWithPopup(googleProvider);

      final user = userCred.user;
      if (user == null) {
        throw Exception('Google sign-in returned null user');
      }

      final userRef = _db.collection('users').doc(user.uid);
      final snap = await userRef.get();

      if (!snap.exists) {
        await userRef.set({
          'name': user.displayName ?? 'New User',
          'email': user.email,
          'role': role,
          'points': 0,
          'reliability': 100,
          'skills': role == 'worker' ? ['Barista'] : [],
          'stats': {'lateCancellations': 0, 'shiftsCompleted': 0},
          'createdAt': FieldValue.serverTimestamp(),
          'savedShifts': [],
        });
      }

      return userCred;
    } catch (e, st) {
      debugPrint('Google Sign-In Error: $e');
      debugPrint('$st');
      rethrow; 
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
