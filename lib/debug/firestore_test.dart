import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> testFirestore() async {
  try {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .limit(1)
        .get();

    print('Firestore OK: ${snap.docs.length}');
  } catch (e) {
    print('Firestore ERROR: $e');
  }
}
