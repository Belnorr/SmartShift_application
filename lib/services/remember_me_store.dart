import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RememberMeStore {
  RememberMeStore._();
  static final RememberMeStore instance = RememberMeStore._();

  static const _prefsKey = 'saved_logins_v1';
  static const _securePrefix = 'saved_login_pw_'; // key: saved_login_pw_<email>

  final _secure = const FlutterSecureStorage();

  Future<List<SavedLogin>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return [];

    final list = (jsonDecode(raw) as List)
        .map((e) => SavedLogin.fromJson(e as Map<String, dynamic>))
        .toList();

    // sort most recent first
    list.sort((a, b) => (b.lastUsed ?? 0).compareTo(a.lastUsed ?? 0));
    return list;
  }

  Future<void> save({required String email, required String password}) async {
    final e = email.trim().toLowerCase();
    if (e.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final current = await load();

    // upsert entry
    final now = DateTime.now().millisecondsSinceEpoch;
    final idx = current.indexWhere((x) => x.email == e);
    if (idx >= 0) {
      current[idx] = current[idx].copyWith(lastUsed: now);
    } else {
      current.add(SavedLogin(email: e, lastUsed: now));
    }

    await prefs.setString(_prefsKey, jsonEncode(current.map((x) => x.toJson()).toList()));
    await _secure.write(key: '$_securePrefix$e', value: password);
  }

  Future<String?> readPassword(String email) async {
    final e = email.trim().toLowerCase();
    if (e.isEmpty) return null;
    return _secure.read(key: '$_securePrefix$e');
  }

  Future<void> remove(String email) async {
    final e = email.trim().toLowerCase();
    final prefs = await SharedPreferences.getInstance();
    final current = await load();

    current.removeWhere((x) => x.email == e);

    await prefs.setString(_prefsKey, jsonEncode(current.map((x) => x.toJson()).toList()));
    await _secure.delete(key: '$_securePrefix$e');
  }
}

class SavedLogin {
  final String email;
  final int? lastUsed;

  SavedLogin({required this.email, this.lastUsed});

  factory SavedLogin.fromJson(Map<String, dynamic> j) {
    return SavedLogin(
      email: (j['email'] ?? '') as String,
      lastUsed: (j['lastUsed'] as num?)?.toInt(),
    );
    }

  Map<String, dynamic> toJson() => {
    'email': email,
    'lastUsed': lastUsed,
  };

  SavedLogin copyWith({int? lastUsed}) => SavedLogin(
    email: email,
    lastUsed: lastUsed ?? this.lastUsed,
  );
}
