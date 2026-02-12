import 'package:flutter_test/flutter_test.dart';
import 'package:alarm_app/models/alarm.dart';

void main() {
  group('Alarm Model Tests', () {
    test('Alarm should be created with correct values', () {
      final alarm = Alarm(
        id: '1',
        hour: 7,
        minute: 30,
        label: 'Wake up',
        isEnabled: true,
        repeatDays: [1, 2, 3, 4, 5],
      );

      expect(alarm.hour, 7);
      expect(alarm.minute, 30);
      expect(alarm.label, 'Wake up');
      expect(alarm.isEnabled, true);
      expect(alarm.repeatDays, [1, 2, 3, 4, 5]);
    });

    test('timeString should format time correctly', () {
      final morningAlarm = Alarm(
        id: '1',
        hour: 7,
        minute: 30,
      );
      expect(morningAlarm.timeString, '7:30 AM');

      final afternoonAlarm = Alarm(
        id: '2',
        hour: 14,
        minute: 15,
      );
      expect(afternoonAlarm.timeString, '2:15 PM');

      final midnightAlarm = Alarm(
        id: '3',
        hour: 0,
        minute: 0,
      );
      expect(midnightAlarm.timeString, '12:00 AM');
    });

    test('repeatText should return correct descriptions', () {
      final oneTimeAlarm = Alarm(id: '1', hour: 7, minute: 0);
      expect(oneTimeAlarm.repeatText, 'One time');

      final weekdayAlarm = Alarm(
        id: '2',
        hour: 7,
        minute: 0,
        repeatDays: [1, 2, 3, 4, 5],
      );
      expect(weekdayAlarm.repeatText, 'Weekdays');

      final weekendAlarm = Alarm(
        id: '3',
        hour: 9,
        minute: 0,
        repeatDays: [6, 7],
      );
      expect(weekendAlarm.repeatText, 'Weekends');

      final everydayAlarm = Alarm(
        id: '4',
        hour: 6,
        minute: 0,
        repeatDays: [1, 2, 3, 4, 5, 6, 7],
      );
      expect(everydayAlarm.repeatText, 'Every day');
    });

    test('toJson and fromJson should work correctly', () {
      final alarm = Alarm(
        id: '1',
        hour: 8,
        minute: 45,
        label: 'Morning Alarm',
        isEnabled: true,
        repeatDays: [1, 3, 5],
      );

      final json = alarm.toJson();
      final recreatedAlarm = Alarm.fromJson(json);

      expect(recreatedAlarm.id, alarm.id);
      expect(recreatedAlarm.hour, alarm.hour);
      expect(recreatedAlarm.minute, alarm.minute);
      expect(recreatedAlarm.label, alarm.label);
      expect(recreatedAlarm.isEnabled, alarm.isEnabled);
      expect(recreatedAlarm.repeatDays, alarm.repeatDays);
    });
  });
}
