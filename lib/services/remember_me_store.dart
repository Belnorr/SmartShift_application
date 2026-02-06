import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SavedAccount {
  final String email;
  final int lastUsedAt;

  const SavedAccount({
    required this.email,
    required this.lastUsedAt,
  });

  Map<String, dynamic> toJson() => {
        "email": email,
        "lastUsedAt": lastUsedAt,
      };

  factory SavedAccount.fromJson(Map<String, dynamic> json) {
    return SavedAccount(
      email: (json["email"] ?? "").toString(),
      lastUsedAt: (json["lastUsedAt"] is int)
          ? json["lastUsedAt"] as int
          : int.tryParse(json["lastUsedAt"]?.toString() ?? "") ?? 0,
    );
  }
}

class RememberMeStore {
  RememberMeStore._();
  static final RememberMeStore instance = RememberMeStore._();

  static const _kKey = "smartshift_saved_emails";
  static const _maxSaved = 8;

  Future<List<SavedAccount>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKey);
    if (raw == null || raw.trim().isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];

      final items = decoded
          .whereType<Map>()
          .map((m) => SavedAccount.fromJson(m.cast<String, dynamic>()))
          .where((a) => a.email.trim().isNotEmpty)
          .toList();

      items.sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
      return items;
    } catch (_) {
      return [];
    }
  }

  Future<void> upsertEmail(String email) async {
    final e = email.trim().toLowerCase();
    if (e.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final list = await load();

    list.removeWhere((a) => a.email.trim().toLowerCase() == e);

    list.insert(
      0,
      SavedAccount(email: e, lastUsedAt: DateTime.now().millisecondsSinceEpoch),
    );

    final capped = list.take(_maxSaved).toList();

    await prefs.setString(
      _kKey,
      jsonEncode(capped.map((a) => a.toJson()).toList()),
    );
  }

  Future<void> removeEmail(String email) async {
    final e = email.trim().toLowerCase();
    final prefs = await SharedPreferences.getInstance();
    final list = await load();
    list.removeWhere((a) => a.email.trim().toLowerCase() == e);

    await prefs.setString(
      _kKey,
      jsonEncode(list.map((a) => a.toJson()).toList()),
    );
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kKey);
  }
}
