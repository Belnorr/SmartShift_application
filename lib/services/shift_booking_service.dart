import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ShiftBookingService {
  static Future<void> applyForShift({
    required String shiftId,
    required Map<String, dynamic> shiftData,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final bookedRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('bookedShifts')
        .doc(shiftId);

    final existing = await bookedRef.get();
    if (existing.exists) {
      throw Exception('Shift already booked');
    }

    await bookedRef.set({
      'shiftId': shiftId,
      'title': shiftData['title'],
      'company': shiftData['company'],
      'location': shiftData['location'],
      'payPerHour': shiftData['payPerHour'],
      'rewardPoints': shiftData['rewardPoints'],
      'urgency': shiftData['urgency'],
      'date': shiftData['date'],
      'endTime': shiftData['endTime'],
      'status': 'upcoming',
      'bookedAt': FieldValue.serverTimestamp(),
    });
  }
}
