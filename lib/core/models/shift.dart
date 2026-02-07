// shift.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum ShiftStatus { open, ongoing, completed, cancelled, noshow }

class Shift {
  final String id;

  final int shiftNo;
  final String shiftCode;

  final String title;
  final String employer;     // company
  final String employerId;

  final String location;

  final DateTime date;
  final TimeOfDay start;
  final TimeOfDay end;

  final int hourlyRate;      // payPerHour
  final int urgency;         // urgency
  final int points;          // rewardPoints

  final List<String> skills; // requiredSkills

  final int slotsTotal;      // capacity
  final int slotsBooked;     // bookedCount

  final ShiftStatus status;  // status
  final String? thumbnailPath; // imageURL (asset path or url)

  const Shift({
    required this.id,
    required this.shiftNo,
    required this.shiftCode,
    required this.title,
    required this.employer,
    required this.employerId,
    required this.location,
    required this.date,
    required this.start,
    required this.end,
    required this.hourlyRate,
    required this.urgency,
    required this.points,
    required this.skills,
    required this.slotsTotal,
    required this.slotsBooked,
    required this.status,
    this.thumbnailPath,
  });

  static ShiftStatus _strToStatus(String s) {
    final v = s.toLowerCase().trim();
    switch (v) {
      case 'open':
        return ShiftStatus.open;
      case 'ongoing':
        return ShiftStatus.ongoing;
      case 'completed':
        return ShiftStatus.completed;
      case 'cancelled':
      case 'canceled':
        return ShiftStatus.cancelled;
      case 'noshow':
      case 'no-show':
      case 'no_show':
        return ShiftStatus.noshow;
      default:
        return ShiftStatus.open;
    }
  }

  static DateTime _readDate(dynamic x) {
    if (x is Timestamp) return x.toDate();
    if (x is DateTime) return x;
    return DateTime.now();
  }

  Map<String, dynamic> toFirestoreMap() {
    final endDt = DateTime(date.year, date.month, date.day, end.hour, end.minute);

    return {
      "shiftNo": shiftNo,
      "shiftCode": shiftCode,
      "title": title,
      "company": employer,
      "employerId": employerId,
      "location": location,
      "date": Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
      "endTime": Timestamp.fromDate(endDt),
      "payPerHour": hourlyRate,
      "urgency": urgency,
      "rewardPoints": points,
      "requiredSkills": skills,
      "capacity": slotsTotal,
      "bookedCount": slotsBooked,
      "status": status.name,
      "imageURL": thumbnailPath,
    };
  }

  static Shift fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};

final dateDt  = _readDate(d["date"]);
final startDt = _readDate(d["startTime"]);
final endDt   = _readDate(d["endTime"]);


    final no = (d["shiftNo"] as num?)?.toInt() ?? 0;
    final code = (d["shiftCode"] as String?) ?? (no > 0 ? "S$no" : doc.id);

    return Shift(
      id: doc.id,
      shiftNo: no,
      shiftCode: code,
      title: (d["title"] ?? "") as String,
      employer: (d["company"] ?? "") as String,
      employerId: (d["employerId"] ?? "") as String,
      location: (d["location"] ?? "") as String,
      date: dateDt,
      start: TimeOfDay.fromDateTime(startDt),
      end: TimeOfDay.fromDateTime(endDt),
      hourlyRate: (d["payPerHour"] as num?)?.toInt() ?? 0,
      urgency: (d["urgency"] as num?)?.toInt() ?? 0,
      points: (d["rewardPoints"] as num?)?.toInt() ?? 0,
      skills: List<String>.from((d["requiredSkills"] ?? const <String>[]) as List),
      slotsTotal: (d["capacity"] as num?)?.toInt() ?? 0,
      slotsBooked: (d["bookedCount"] as num?)?.toInt() ?? 0,
      status: _strToStatus((d["status"] ?? "open") as String),
      thumbnailPath: d["imageURL"] as String?,
    );
  }

  Shift copyWith({
    String? title,
    String? location,
    DateTime? date,
    TimeOfDay? start,
    TimeOfDay? end,
    int? hourlyRate,
    int? urgency,
    int? points,
    List<String>? skills,
    int? slotsTotal,
    int? slotsBooked,
    ShiftStatus? status,
    String? thumbnailPath,
  }) {
    return Shift(
      id: id,
      shiftNo: shiftNo,
      shiftCode: shiftCode,
      title: title ?? this.title,
      employer: employer,
      employerId: employerId,
      location: location ?? this.location,
      date: date ?? this.date,
      start: start ?? this.start,
      end: end ?? this.end,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      urgency: urgency ?? this.urgency,
      points: points ?? this.points,
      skills: skills ?? this.skills,
      slotsTotal: slotsTotal ?? this.slotsTotal,
      slotsBooked: slotsBooked ?? this.slotsBooked,
      status: status ?? this.status,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    );
  }
}
