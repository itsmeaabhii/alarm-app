import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
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

    // Set device's local timezone so alarms fire at the correct local time
    try {
      // getLocalTimezone() returns IANA timezone string (e.g. "Asia/Kolkata")
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      if (timeZoneName.isNotEmpty &&
          tz.timeZoneDatabase.locations.containsKey(timeZoneName)) {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      }
    } catch (_) {
      // Keep default (UTC) if device timezone cannot be determined
    }

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

    // Create Android alarm channel with sound so the notification actually rings
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'alarm_channel',
          'Alarms',
          description: 'Channel for alarm notifications',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          showBadge: true,
        ),
      );
    }

    await androidPlugin?.requestNotificationsPermission();
    _isInitialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) async {
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

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

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
      category: AndroidNotificationCategory.alarm,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    if (alarm.repeatDays.isEmpty) {
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
        await _notifications.cancel('${alarm.id}_$day'.hashCode);
      }
    } else {
      await _notifications.cancel(alarmId.hashCode);
    }
  }

  Future<void> playAlarmSound() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('sounds/alarm_sound.mp3'));
    } catch (_) {}
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
