import 'package:cloud_firestore/cloud_firestore.dart';

class ShiftCompletionService {
  static Future<void> markCompletedShifts(String userId) async {
    final now = Timestamp.now();

    final query = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('bookedShifts')
        .where('status', isEqualTo: 'upcoming')
        .where('endTime', isLessThan: now)
        .get();

    final batch = FirebaseFirestore.instance.batch();

    for (final doc in query.docs) {
      batch.update(doc.reference, {
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }
}
