import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import '../models/alarm.dart';
import 'alarm_storage.dart';

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for Android
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _isInitialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) async {
    // Play alarm sound when notification is tapped
    await playAlarmSound();
  }

  Future<void> scheduleAlarm(Alarm alarm) async {
    if (!alarm.isEnabled) return;

    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      alarm.hour,
      alarm.minute,
    );

    // If time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Convert to TZDateTime for scheduling
    final location = tz.local;
    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, location);

    const androidDetails = AndroidNotificationDetails(
      'alarm_channel',
      'Alarms',
      channelDescription: 'Channel for alarm notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    if (alarm.repeatDays.isEmpty) {
      // One-time alarm
      await _notifications.zonedSchedule(
        alarm.id.hashCode,
        'Alarm',
        alarm.label.isEmpty ? 'Time to wake up! ⏰' : alarm.label,
        tzScheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } else {
      // Repeating alarm - schedule for each day
      for (int day in alarm.repeatDays) {
        var nextAlarm = _getNextAlarmDate(alarm.hour, alarm.minute, day);
        final location = tz.local;
        final tzNextAlarm = tz.TZDateTime.from(nextAlarm, location);

        await _notifications.zonedSchedule(
          '${alarm.id}_$day'.hashCode,
          'Alarm',
          alarm.label.isEmpty ? 'Time to wake up! ⏰' : alarm.label,
          tzNextAlarm,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    }
  }

  DateTime _getNextAlarmDate(int hour, int minute, int targetDay) {
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

    // Find next occurrence of the target day
    while (scheduledDate.weekday != targetDay ||
        scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  Future<void> cancelAlarm(String alarmId) async {
    final alarm = await AlarmStorage().getAlarm(alarmId);
    
    if (alarm != null && alarm.repeatDays.isEmpty) {
      await _notifications.cancel(alarmId.hashCode);
    } else if (alarm != null) {
      for (int day in alarm.repeatDays) {
        await _notifications.cancel('${alarmId}_$day'.hashCode);
      }
    } else {
      // Fallback if alarm not found
      await _notifications.cancel(alarmId.hashCode);
    }
  }

  Future<void> playAlarmSound() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('sounds/alarm_sound.mp3'));
    } catch (e) {
      // Fallback if sound file doesn't exist - app will use system notification sound
      // Error: $e
    }
  }

  Future<void> stopAlarmSound() async {
    await _audioPlayer.stop();
  }

  Future<void> rescheduleAllAlarms() async {
    final alarms = await AlarmStorage().loadAlarms();
    for (var alarm in alarms) {
      if (alarm.isEnabled) {
        await scheduleAlarm(alarm);
      }
    }
  }
}
