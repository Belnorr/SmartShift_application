import 'package:cloud_firestore/cloud_firestore.dart';

class ShiftCompletionService {
  static Future<void> markCompletedShifts(String userId) async {
    final db = FirebaseFirestore.instance;
    final now = Timestamp.now();
    final userRef = db.collection('users').doc(userId);

    print('DEBUG: markCompletedShifts start userId=$userId now=${now.toDate()}');

    // ✅ Fetch ALL booked shifts (avoid Firestore where() type/index issues)
    final query = await userRef.collection('bookedShifts').get();

    print('DEBUG: bookedShifts total docs=${query.docs.length}');
    for (final d in query.docs) {
      final data = d.data();
      print(
        'DEBUG: candidate id=${d.id} '
        'endTime=${data['endTime']} date=${data['date']} '
        'status=${data['status']} rewardAwarded=${data['rewardAwarded']} '
        'rewardPoints=${data['rewardPoints']}',
      );
    }

    if (query.docs.isEmpty) return;

    int totalEarned = 0;
    int newlyCompleted = 0;

    final batch = db.batch();

    for (final doc in query.docs) {
      final data = doc.data();

      // ✅ ended-check MUST be inside loop (doc exists here)
      final endRaw = data['endTime'];
      final startRaw = data['date'];

      final Timestamp? endTs = endRaw is Timestamp ? endRaw : null;
      final Timestamp? startTs = startRaw is Timestamp ? startRaw : null;

      final ended = endTs != null
          ? endTs.compareTo(now) < 0
          : (startTs != null && startTs.compareTo(now) < 0);

      if (!ended) {
        print(
          'DEBUG SKIP ${doc.id}: not ended yet (endTime=$endRaw date=$startRaw)',
        );
        continue;
      }

      // status gate
      final status = (data['status'] ?? '').toString().trim().toLowerCase();
      final allowed =
          status == 'upcoming' || status == 'booked' || status == 'completed';

      if (!allowed) {
        print('DEBUG SKIP ${doc.id}: status not allowed ($status)');
        continue;
      }

      // rewardAwarded gate (handles bool OR string)
      final ra = data['rewardAwarded'];
      final alreadyAwarded =
          ra == true || ra?.toString().toLowerCase() == 'true';

      if (alreadyAwarded) {
        print('DEBUG SKIP ${doc.id}: already awarded');
        continue;
      }

      // rewardPoints parse (handles num OR string)
      final rp = data['rewardPoints'];
      final reward = rp is num
          ? rp.toInt()
          : int.tryParse(rp?.toString() ?? '0') ?? 0;

      print(
        'DEBUG AWARD ${doc.id}: status=$status rewardPoints=$rp parsedReward=$reward',
      );

      // update booked shift doc
      batch.update(doc.reference, {
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'rewardAwarded': true,
      });

      // ✅ one rewardHistory entry per shift
      final historyRef = userRef.collection('rewardHistory').doc();
      batch.set(historyRef, {
        'type': 'shift_complete',
        'shiftDocId': doc.id,
        'title': (data['title'] ?? '').toString(),
        'company': (data['company'] ?? '').toString(),
        'pointsAdded': reward,
        'createdAt': FieldValue.serverTimestamp(),
      });

      totalEarned += reward;
      newlyCompleted += 1;
    }

    print('DEBUG SUMMARY: newlyCompleted=$newlyCompleted totalEarned=$totalEarned');

    if (newlyCompleted == 0) {
      print('DEBUG: no newlyCompleted shifts to award');
      return;
    }

    // update user totals
    batch.update(userRef, {
      'points': FieldValue.increment(totalEarned),
      'stats.shiftsCompleted': FieldValue.increment(newlyCompleted),
      'shiftsCompleted': FieldValue.increment(newlyCompleted),
    });

    try {
      await batch.commit();
      print('DEBUG: batch commit OK (earned=$totalEarned, count=$newlyCompleted)');
    } catch (e, st) {
      print('DEBUG: batch commit FAILED: $e');
      print('DEBUG: stack:\n$st');
      rethrow;
    }
  }
}
