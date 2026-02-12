class Alarm {
  final String id;
  final int hour;
  final int minute;
  final String label;
  final bool isEnabled;
  final List<int> repeatDays; // 1-7 for Monday-Sunday, empty for one-time

  Alarm({
    required this.id,
    required this.hour,
    required this.minute,
    this.label = '',
    this.isEnabled = true,
    this.repeatDays = const [],
  });

  String get timeString {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final minuteString = minute.toString().padLeft(2, '0');
    return '$displayHour:$minuteString $period';
  }

  String get repeatText {
    if (repeatDays.isEmpty) return 'One time';
    if (repeatDays.length == 7) return 'Every day';
    if (repeatDays.length == 5 && 
        repeatDays.contains(1) && 
        repeatDays.contains(2) && 
        repeatDays.contains(3) && 
        repeatDays.contains(4) && 
        repeatDays.contains(5)) {
      return 'Weekdays';
    }
    if (repeatDays.length == 2 && 
        repeatDays.contains(6) && 
        repeatDays.contains(7)) {
      return 'Weekends';
    }
    
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return repeatDays.map((d) => days[d - 1]).join(', ');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hour': hour,
      'minute': minute,
      'label': label,
      'isEnabled': isEnabled,
      'repeatDays': repeatDays,
    };
  }

  factory Alarm.fromJson(Map<String, dynamic> json) {
    return Alarm(
      id: json['id'] as String,
      hour: json['hour'] as int,
      minute: json['minute'] as int,
      label: json['label'] as String? ?? '',
      isEnabled: json['isEnabled'] as bool? ?? true,
      repeatDays: (json['repeatDays'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
    );
  }

  Alarm copyWith({
    String? id,
    int? hour,
    int? minute,
    String? label,
    bool? isEnabled,
    List<int>? repeatDays,
  }) {
    return Alarm(
      id: id ?? this.id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      label: label ?? this.label,
      isEnabled: isEnabled ?? this.isEnabled,
      repeatDays: repeatDays ?? this.repeatDays,
    );
  }
}
