import 'package:flutter/material.dart';
import '../models/alarm.dart';
import '../services/alarm_storage.dart';
import '../services/alarm_service.dart';

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
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF6366F1),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: const Color(0xFF0F172A),
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
      await AlarmService().cancelAlarm(alarm.id);
      await _storage.updateAlarm(alarm);
    } else {
      await _storage.addAlarm(alarm);
    }

    if (alarm.isEnabled) {
      await AlarmService().scheduleAlarm(alarm);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(
          widget.alarm != null ? 'Edit alarm' : 'New alarm',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: Colors.grey.shade700),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _saveAlarm,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Color(0xFF6366F1),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time picker
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.06),
              child: InkWell(
                onTap: _pickTime,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.schedule_rounded,
                          color: Color(0xFF6366F1),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Time',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _selectedTime.format(context),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.grey.shade400,
                        size: 28,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Label
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.06),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: TextField(
                  controller: _labelController,
                  decoration: InputDecoration(
                    labelText: 'Label',
                    hintText: 'Wake up, Meeting…',
                    border: InputBorder.none,
                    prefixIcon: Icon(
                      Icons.label_outline_rounded,
                      color: Colors.grey.shade500,
                      size: 22,
                    ),
                    labelStyle: TextStyle(color: Colors.grey.shade600),
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Repeat
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.06),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.repeat_rounded,
                          color: Colors.grey.shade600,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Repeat',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _DayChip(day: 'M', dayNumber: 1, isSelected: _selectedDays.contains(1), onTap: () => _toggleDay(1)),
                        _DayChip(day: 'T', dayNumber: 2, isSelected: _selectedDays.contains(2), onTap: () => _toggleDay(2)),
                        _DayChip(day: 'W', dayNumber: 3, isSelected: _selectedDays.contains(3), onTap: () => _toggleDay(3)),
                        _DayChip(day: 'T', dayNumber: 4, isSelected: _selectedDays.contains(4), onTap: () => _toggleDay(4)),
                        _DayChip(day: 'F', dayNumber: 5, isSelected: _selectedDays.contains(5), onTap: () => _toggleDay(5)),
                        _DayChip(day: 'S', dayNumber: 6, isSelected: _selectedDays.contains(6), onTap: () => _toggleDay(6)),
                        _DayChip(day: 'S', dayNumber: 7, isSelected: _selectedDays.contains(7), onTap: () => _toggleDay(7)),
                      ],
                    ),
                    if (_selectedDays.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'One-time alarm',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Quick presets',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _PresetChip(
                  label: 'Weekdays',
                  onTap: () => setState(() => _selectedDays = {1, 2, 3, 4, 5}),
                ),
                _PresetChip(
                  label: 'Weekends',
                  onTap: () => setState(() => _selectedDays = {6, 7}),
                ),
                _PresetChip(
                  label: 'Every day',
                  onTap: () => setState(() => _selectedDays = {1, 2, 3, 4, 5, 6, 7}),
                ),
                _PresetChip(
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

class _DayChip extends StatelessWidget {
  final String day;
  final int dayNumber;
  final bool isSelected;
  final VoidCallback onTap;

  const _DayChip({
    required this.day,
    required this.dayNumber,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            day,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade600,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PresetChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.05),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6366F1),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
