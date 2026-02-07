import 'package:cloud_firestore/cloud_firestore.dart';

class ShiftManageService {
  static Future<void> cancelShift({
    required String userId,
    required String shiftId,
  }) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    final DocumentReference userRef =
        firestore.collection('users').doc(userId);

    final DocumentReference shiftRef =
        userRef.collection('bookedShifts').doc(shiftId);

    await firestore.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userRef);
      final shiftSnapshot = await transaction.get(shiftRef);

      if (!userSnapshot.exists) {
        throw Exception('User not found');
      }

      if (!shiftSnapshot.exists) {
        throw Exception('Shift not found');
      }

      final shiftData = shiftSnapshot.data() as Map<String, dynamic>;

      if (shiftData['status'] != 'upcoming') {
        throw Exception('Only upcoming shifts can be cancelled');
      }

      final int currentPoints =
          (userSnapshot['points'] ?? 0) as int;

      final int currentReliability =
          (userSnapshot['reliability'] ?? 100) as int;

      final Map<String, dynamic> stats =
          (userSnapshot['stats'] ?? {}) as Map<String, dynamic>;

      final int lateCancellations =
          (stats['lateCancellations'] ?? 0) as int;

      transaction.update(shiftRef, {
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      transaction.update(userRef, {
        'points': currentPoints - 50,
        'reliability': (currentReliability - 5).clamp(0, 100),
        'stats.lateCancellations': lateCancellations + 1,
      });
    });
  }
}
