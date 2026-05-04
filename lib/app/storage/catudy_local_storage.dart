import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CatudyLocalStorage {
  const CatudyLocalStorage();

  static const _stateKey = 'catudy.offline_state.v1';

  Future<Map<String, dynamic>?> readState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_stateKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    return decoded;
  }

  Future<void> writeState(Map<String, dynamic> state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_stateKey, jsonEncode(state));
  }
}
