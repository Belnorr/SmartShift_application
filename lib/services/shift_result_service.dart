import 'package:cloud_firestore/cloud_firestore.dart';

class ShiftResultService {
  static Future<void> cancelShift({
    required String userId,
    required String shiftDocId,
    int penaltyPoints = 50,
  }) async {
    final db = FirebaseFirestore.instance;
    final userRef = db.collection('users').doc(userId);
    final shiftRef = userRef.collection('bookedShifts').doc(shiftDocId);

    await db.runTransaction((tx) async {
      final userSnap = await tx.get(userRef);
      final shiftSnap = await tx.get(shiftRef);

      if (!userSnap.exists || !shiftSnap.exists) return;

      final shiftData = shiftSnap.data()!;
      if (shiftData['status'] == 'cancelled') return;

      final userData = userSnap.data()!;
      final int currentPoints = (userData['points'] as num?)?.toInt() ?? 0;
      final int reliability = (userData['reliability'] as num?)?.toInt() ?? 0;

      //update user
      tx.update(userRef, {
        'points': currentPoints - penaltyPoints,
        'reliability': (reliability - 5).clamp(0, 100),
        'stats.lateCancellations': FieldValue.increment(1),
        'latePenalties': FieldValue.increment(1),
      });

      //update shift
      tx.update(shiftRef, {
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      //log history
      final logRef = userRef.collection('rewardHistory').doc();
      tx.set(logRef, {
        'type': 'cancel_penalty',
        'points': -penaltyPoints,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  static Future<void> completeShift({
    required String userId,
    required String shiftDocId,
    required int rewardPoints,
  }) async {
    final db = FirebaseFirestore.instance;
    final userRef = db.collection('users').doc(userId);
    final shiftRef = userRef.collection('bookedShifts').doc(shiftDocId);

    await db.runTransaction((tx) async {
      final userSnap = await tx.get(userRef);
      final shiftSnap = await tx.get(shiftRef);

      if (!userSnap.exists || !shiftSnap.exists) return;

      final userData = userSnap.data()!;
      final shiftData = shiftSnap.data()!;

      // prevent double reward
      if (shiftData['rewardAwarded'] == true) return;
      final int currentPoints = (userData['points'] as num?)?.toInt() ?? 0;
      final int reliability = (userData['reliability'] as num?)?.toInt() ?? 0;

      tx.update(userRef, {
        'points': currentPoints + rewardPoints,
        'reliability': (reliability + 5).clamp(0, 100),
        'stats.shiftsCompleted': FieldValue.increment(1),
      });

      tx.update(shiftRef, {
        'status': 'completed',
        'rewardAwarded': true,
        'completedAt': FieldValue.serverTimestamp(),
      });

      final logRef = userRef.collection('rewardHistory').doc();
      tx.set(logRef, {
        'type': 'shift_complete',
        'points': rewardPoints,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
