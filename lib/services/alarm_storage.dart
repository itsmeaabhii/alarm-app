import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm.dart';

class AlarmStorage {
  static const String _key = 'alarms';

  Future<List<Alarm>> loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final String? alarmsJson = prefs.getString(_key);
    
    if (alarmsJson == null) {
      return [];
    }

    final List<dynamic> decoded = jsonDecode(alarmsJson);
    return decoded.map((json) => Alarm.fromJson(json)).toList();
  }

  Future<void> saveAlarms(List<Alarm> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(
      alarms.map((alarm) => alarm.toJson()).toList(),
    );
    await prefs.setString(_key, encoded);
  }

  Future<void> addAlarm(Alarm alarm) async {
    final alarms = await loadAlarms();
    alarms.add(alarm);
    await saveAlarms(alarms);
  }

  Future<void> updateAlarm(Alarm alarm) async {
    final alarms = await loadAlarms();
    final index = alarms.indexWhere((a) => a.id == alarm.id);
    if (index != -1) {
      alarms[index] = alarm;
      await saveAlarms(alarms);
    }
  }

  Future<void> deleteAlarm(String id) async {
    final alarms = await loadAlarms();
    alarms.removeWhere((a) => a.id == id);
    await saveAlarms(alarms);
  }
}
