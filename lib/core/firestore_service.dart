import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String get uid => _auth.currentUser!.uid;

  static DocumentReference get currentUserRef =>
      _db.collection('users').doc(uid);

  static CollectionReference get shiftsRef =>
      _db.collection('shifts');

  static Stream<QuerySnapshot> openShiftsStream() {
    return shiftsRef
        .where('status', isEqualTo: 'open')
        .snapshots();
  }

  static Future<void> bookShift(String shiftId) async {
    final shiftRef = shiftsRef.doc(shiftId);

    await _db.runTransaction((transaction) async {
      final shiftSnap = await transaction.get(shiftRef);
      final userSnap = await transaction.get(currentUserRef);

      final int bookedCount = shiftSnap['bookedCount'];
      final int capacity = shiftSnap['capacity'];

      if (bookedCount >= capacity) {
        throw Exception('Shift is full');
      }

      transaction.update(shiftRef, {
        'bookedCount': bookedCount + 1,
        'status': bookedCount + 1 == capacity ? 'booked' : 'open',
      });

      transaction.update(currentUserRef, {
        'bookedShifts': FieldValue.arrayUnion([shiftId]),
      });
    });
  }
}
