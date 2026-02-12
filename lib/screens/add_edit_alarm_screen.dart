import 'package:flutter/material.dart';
import '../models/alarm.dart';
import '../services/alarm_storage.dart';

class AddEditAlarmScreen extends StatefulWidget {
  final Alarm? alarm;

  const AddEditAlarmScreen({super.key, this.alarm});

  @override
  State<AddEditAlarmScreen> createState() => _AddEditAlarmScreenState();
}

class _AddEditAlarmScreenState extends State<AddEditAlarmScreen> {
  final AlarmStorage _storage = AlarmStorage();
  final TextEditingController _labelController = TextEditingController();
  
  late TimeOfDay _selectedTime;
  late Set<int> _selectedDays;
  bool _isEnabled = true;

  @override
  void initState() {
    super.initState();
    if (widget.alarm != null) {
      _selectedTime = TimeOfDay(
        hour: widget.alarm!.hour,
        minute: widget.alarm!.minute,
      );
      _labelController.text = widget.alarm!.label;
      _selectedDays = Set.from(widget.alarm!.repeatDays);
      _isEnabled = widget.alarm!.isEnabled;
    } else {
      final now = TimeOfDay.now();
      _selectedTime = TimeOfDay(hour: now.hour, minute: now.minute + 1);
      _selectedDays = {};
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.deepPurple,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _toggleDay(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  Future<void> _saveAlarm() async {
    final alarm = Alarm(
      id: widget.alarm?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      hour: _selectedTime.hour,
      minute: _selectedTime.minute,
      label: _labelController.text.trim(),
      isEnabled: _isEnabled,
      repeatDays: _selectedDays.toList()..sort(),
    );

    if (widget.alarm != null) {
      await _storage.updateAlarm(alarm);
    } else {
      await _storage.addAlarm(alarm);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          widget.alarm != null ? 'Edit Alarm' : 'Add Alarm',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saveAlarm,
            child: const Text(
              'SAVE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time Picker Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                onTap: _pickTime,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: Colors.deepPurple,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Time',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedTime.format(context),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Label Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _labelController,
                  decoration: const InputDecoration(
                    labelText: 'Label',
                    hintText: 'Wake up, Meeting, etc.',
                    border: InputBorder.none,
                    prefixIcon: Icon(
                      Icons.label_outline,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Repeat Days Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.repeat,
                          color: Colors.deepPurple,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Repeat',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _DayButton(
                          day: 'Mon',
                          dayNumber: 1,
                          isSelected: _selectedDays.contains(1),
                          onTap: () => _toggleDay(1),
                        ),
                        _DayButton(
                          day: 'Tue',
                          dayNumber: 2,
                          isSelected: _selectedDays.contains(2),
                          onTap: () => _toggleDay(2),
                        ),
                        _DayButton(
                          day: 'Wed',
                          dayNumber: 3,
                          isSelected: _selectedDays.contains(3),
                          onTap: () => _toggleDay(3),
                        ),
                        _DayButton(
                          day: 'Thu',
                          dayNumber: 4,
                          isSelected: _selectedDays.contains(4),
                          onTap: () => _toggleDay(4),
                        ),
                        _DayButton(
                          day: 'Fri',
                          dayNumber: 5,
                          isSelected: _selectedDays.contains(5),
                          onTap: () => _toggleDay(5),
                        ),
                        _DayButton(
                          day: 'Sat',
                          dayNumber: 6,
                          isSelected: _selectedDays.contains(6),
                          onTap: () => _toggleDay(6),
                        ),
                        _DayButton(
                          day: 'Sun',
                          dayNumber: 7,
                          isSelected: _selectedDays.contains(7),
                          onTap: () => _toggleDay(7),
                        ),
                      ],
                    ),
                    if (_selectedDays.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'One-time alarm',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Quick preset buttons
            const Text(
              'Quick Presets',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _PresetButton(
                  label: 'Weekdays',
                  onTap: () => setState(() => _selectedDays = {1, 2, 3, 4, 5}),
                ),
                _PresetButton(
                  label: 'Weekends',
                  onTap: () => setState(() => _selectedDays = {6, 7}),
                ),
                _PresetButton(
                  label: 'Every day',
                  onTap: () => setState(() => _selectedDays = {1, 2, 3, 4, 5, 6, 7}),
                ),
                _PresetButton(
                  label: 'Clear',
                  onTap: () => setState(() => _selectedDays = {}),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DayButton extends StatelessWidget {
  final String day;
  final int dayNumber;
  final bool isSelected;
  final VoidCallback onTap;

  const _DayButton({
    required this.day,
    required this.dayNumber,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple : Colors.grey[200],
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            day[0],
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black54,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PresetButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.deepPurple,
        side: const BorderSide(color: Colors.deepPurple),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(label),
    );
  }
}
