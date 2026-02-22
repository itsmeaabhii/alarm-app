import 'package:flutter/material.dart';
import '../models/alarm.dart';
import '../services/alarm_storage.dart';
import '../services/alarm_service.dart';
import 'add_edit_alarm_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AlarmStorage _storage = AlarmStorage();
  List<Alarm> _alarms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlarms();
  }

  Future<void> _loadAlarms() async {
    setState(() => _isLoading = true);
    final alarms = await _storage.loadAlarms();
    setState(() {
      _alarms = alarms
        ..sort((a, b) {
          final aTime = a.hour * 60 + a.minute;
          final bTime = b.hour * 60 + b.minute;
          return aTime.compareTo(bTime);
        });
      _isLoading = false;
    });
  }

  Future<void> _toggleAlarm(Alarm alarm) async {
    final updatedAlarm = alarm.copyWith(isEnabled: !alarm.isEnabled);
    await _storage.updateAlarm(updatedAlarm);

    if (updatedAlarm.isEnabled) {
      await AlarmService().scheduleAlarm(updatedAlarm);
    } else {
      await AlarmService().cancelAlarm(updatedAlarm.id);
    }

    await _loadAlarms();
  }

  Future<void> _deleteAlarm(String id) async {
    await AlarmService().cancelAlarm(id);
    await _storage.deleteAlarm(id);
    await _loadAlarms();
  }

  Future<void> _navigateToAddEdit({Alarm? alarm}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditAlarmScreen(alarm: alarm),
      ),
    );
    if (result == true) {
      await _loadAlarms();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Alarms',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: const Color(0xFF0F172A),
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _alarms.isEmpty
                              ? 'No alarms set'
                              : '${_alarms.length} alarm${_alarms.length == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ),
              )
            else if (_alarms.isEmpty)
              SliverFillRemaining(
                child: _EmptyState(onAddAlarm: () => _navigateToAddEdit()),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final alarm = _alarms[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _AlarmCard(
                          alarm: alarm,
                          onToggle: () => _toggleAlarm(alarm),
                          onEdit: () => _navigateToAddEdit(alarm: alarm),
                          onDelete: () => _deleteAlarm(alarm.id),
                        ),
                      );
                    },
                    childCount: _alarms.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddEdit(),
        icon: const Icon(Icons.add_rounded, size: 24),
        label: const Text(
          'Add alarm',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddAlarm;

  const _EmptyState({required this.onAddAlarm});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.schedule_rounded,
                size: 64,
                color: const Color(0xFF6366F1).withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'No alarms yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 22,
                    color: const Color(0xFF0F172A),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Tap the button below to create your first alarm and wake up on time.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onAddAlarm,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Add alarm'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlarmCard extends StatelessWidget {
  final Alarm alarm;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AlarmCard({
    required this.alarm,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = alarm.isEnabled;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.08),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alarm.timeString,
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1,
                        color: enabled ? const Color(0xFF0F172A) : Colors.grey.shade400,
                        height: 1.1,
                      ),
                    ),
                    if (alarm.label.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        alarm.label,
                        style: TextStyle(
                          fontSize: 16,
                          color: enabled ? Colors.grey.shade700 : Colors.grey.shade400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: enabled
                            ? const Color(0xFF6366F1).withOpacity(0.12)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        alarm.repeatText,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: enabled
                              ? const Color(0xFF6366F1)
                              : Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Switch(
                    value: enabled,
                    onChanged: (_) => onToggle(),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.grey.shade400,
                      size: 22,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: const Text('Delete alarm?'),
                          content: const Text(
                            'This alarm will be removed. You can add it again anytime.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(
                                'Cancel',
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                            ),
                            FilledButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                onDelete();
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.red.shade400,
                              ),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
