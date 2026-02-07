import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/models/shift.dart';
import '../core/models/user_profile.dart';

class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _shifts =>
      _db.collection('shifts');
  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _db.collection('users');

  // -------------------- SHIFTS --------------------

  Stream<List<Shift>> getAllShifts({bool onlyWithVacancy = false}) {
    final q = _shifts.orderBy('date');
    return q.snapshots().map((snap) {
      final list = snap.docs.map(Shift.fromFirestore).toList();
      final visible = list.where((s) =>
          s.status == ShiftStatus.open || s.status == ShiftStatus.ongoing);
      final result = visible.toList();
      if (!onlyWithVacancy) return result;
      return result.where((s) => s.slotsBooked < s.slotsTotal).toList();
    });
  }

  Stream<List<Shift>> getEmployerShifts() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _shifts.where('employerId', isEqualTo: uid).snapshots().map((snap) {
      final list = snap.docs.map(Shift.fromFirestore).toList();
      list.sort((a, b) => a.date.compareTo(b.date));
      return list;
    });
  }

  Future<void> createShift({
    required String title,
    required String location,
    required DateTime date,
    required TimeOfDay start,
    required TimeOfDay end,
    required int urgency,
    required int points,
    required List<String> skills,
    required int slotsTotal,
    String? thumbnailPath,
    required int payPerHour,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("Not logged in");

    final udoc = await _usersCol.doc(uid).get();
    final employerName = (udoc.data()?['name'] as String?) ?? 'Employer';

    final shiftNo = await _nextShiftNo();
    final shiftCode = "S$shiftNo";

    final shift = Shift(
      id: '',
      shiftNo: shiftNo,
      shiftCode: shiftCode,
      title: title,
      employer: employerName,
      employerId: uid,
      location: location,
      date: date,
      start: start,
      end: end,
      hourlyRate: payPerHour,
      urgency: urgency,
      points: points,
      skills: skills,
      slotsTotal: slotsTotal,
      slotsBooked: 0,
      status: ShiftStatus.open,
      thumbnailPath: thumbnailPath,
    );

    final ref = _shifts.doc();
    await ref.set({
      ...shift.toFirestoreMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteShift({required String shiftId}) async {
    await _shifts.doc(shiftId).delete();
  }

  Future<void> updateShift({required Shift shift}) async {
    await _shifts.doc(shift.id).update({
      ...shift.toFirestoreMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // -------------------- AUTO NUMBERING --------------------
  Future<int> _nextShiftNo() async {
    final ref = _db.collection('counters').doc('shifts');

    return _db.runTransaction<int>((tx) async {
      final snap = await tx.get(ref);
      final current = (snap.data()?['nextNo'] as num?)?.toInt() ?? 3001;
      tx.set(ref, {'nextNo': current + 1}, SetOptions(merge: true));
      return current;
    });
  }

  // -------------------- USERS (unchanged) --------------------

  Future<UserProfile> getUser({required String uid}) async {
    final doc = await _usersCol.doc(uid).get();
    if (!doc.exists) {
      final profile = UserProfile(
        uid: uid,
        name: 'User',
        email: '',
        role: UserRole.worker,
        points: 0,
        reliability: 100,
        skills: const [],
        shiftsCompleted: 0,
        latePenalties: 0,
      );
      await createUser(profile: profile);
      return profile;
    }

    final d = doc.data()!;
    return UserProfile(
      uid: uid,
      name: (d['name'] ?? 'User') as String,
      email: (d['email'] ?? '') as String,
      role: ((d['role'] ?? 'worker') as String) == 'employer'
          ? UserRole.employer
          : UserRole.worker,
      points: (d['points'] ?? 0) as int,
      reliability: (d['reliability'] ?? 100) as int,
      skills: List<String>.from((d['skills'] ?? const <String>[]) as List),
      shiftsCompleted: (d['shiftsCompleted'] ?? 0) as int,
      latePenalties: (d['latePenalties'] ?? 0) as int,
    );
  }

  Future<void> createUser({required UserProfile profile}) async {
    await _usersCol.doc(profile.uid).set({
      'name': profile.name,
      'email': profile.email,
      'role': profile.role == UserRole.employer ? 'employer' : 'worker',
      'points': profile.points,
      'reliability': profile.reliability,
      'skills': profile.skills,
      'shiftsCompleted': profile.shiftsCompleted,
      'latePenalties': profile.latePenalties,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
