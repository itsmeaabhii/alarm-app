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

  String? get _nextEnabledAlarmSummary {
    final enabled = _alarms.where((a) => a.isEnabled).toList();
    if (enabled.isEmpty) return null;
    enabled.sort((a, b) {
      final aTime = a.hour * 60 + a.minute;
      final bTime = b.hour * 60 + b.minute;
      return aTime.compareTo(bTime);
    });
    final next = enabled.first;
    return '${next.timeString} • ${next.repeatText}';
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0A0F),
              Color(0xFF121212),
              Color(0xFF0F0F14),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alarms',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.2,
                              shadows: [
                                Shadow(
                                  color: const Color(0xFF6366F1).withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 0),
                                ),
                              ],
                            ),
                      ),
                      const SizedBox(height: 16),
                      Builder(
                        builder: (context) {
                          final next = _nextEnabledAlarmSummary;
                          final text = next ??
                              (_alarms.isEmpty
                                  ? 'No alarms set yet'
                                  : '${_alarms.length} alarm${_alarms.length == 1 ? '' : 's'} scheduled');
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF6366F1).withOpacity(0.2),
                                  const Color(0xFF8B5CF6).withOpacity(0.15),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFF6366F1).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1).withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    next != null
                                        ? Icons.schedule_rounded
                                        : Icons.notifications_none_rounded,
                                    size: 16,
                                    color: const Color(0xFFA5B4FC),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  text,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFE4E4E7),
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
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
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final alarm = _alarms[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
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
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _navigateToAddEdit(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add_rounded, size: 24),
          label: const Text(
            'Add alarm',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              letterSpacing: 0.3,
            ),
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
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6366F1).withOpacity(0.2),
                    const Color(0xFF8B5CF6).withOpacity(0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.schedule_rounded,
                size: 72,
                color: Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No alarms yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first alarm to wake up on time',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade400,
                height: 1.5,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: FilledButton.icon(
                onPressed: onAddAlarm,
                icon: const Icon(Icons.add_rounded, size: 22),
                label: const Text(
                  'Add alarm',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: 0.3,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
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
    return Container(
      decoration: BoxDecoration(
        gradient: enabled
            ? const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFF9333EA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(24),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Padding(
        padding: enabled ? const EdgeInsets.all(2) : EdgeInsets.zero,
        child: Container(
          decoration: BoxDecoration(
            color: enabled ? const Color(0xFF1A1A24) : const Color(0xFF16161B),
            borderRadius: BorderRadius.circular(22),
            border: enabled
                ? null
                : Border.all(
                    color: Colors.grey.shade800.withOpacity(0.3),
                    width: 1,
                  ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(22),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alarm.timeString,
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.5,
                              color: enabled ? Colors.white : Colors.grey.shade600,
                              height: 1.0,
                              shadows: enabled
                                  ? [
                                      Shadow(
                                        color: const Color(0xFF6366F1).withOpacity(0.5),
                                        blurRadius: 15,
                                        offset: const Offset(0, 0),
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          if (alarm.label.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              alarm.label,
                              style: TextStyle(
                                fontSize: 17,
                                color: enabled
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: enabled
                                  ? LinearGradient(
                                      colors: [
                                        const Color(0xFF6366F1).withOpacity(0.25),
                                        const Color(0xFF8B5CF6).withOpacity(0.2),
                                      ],
                                    )
                                  : null,
                              color: enabled ? null : Colors.grey.shade900,
                              borderRadius: BorderRadius.circular(10),
                              border: enabled
                                  ? Border.all(
                                      color: const Color(0xFF6366F1).withOpacity(0.4),
                                      width: 1,
                                    )
                                  : null,
                            ),
                            child: Text(
                              alarm.repeatText,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: enabled
                                    ? const Color(0xFFC4B5FD)
                                    : Colors.grey.shade500,
                                letterSpacing: 0.3,
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
                        const SizedBox(height: 4),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.grey.shade500,
                            size: 22,
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: const Color(0xFF1A1A24),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                title: const Text(
                                  'Delete alarm?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                content: Text(
                                  'This alarm will be removed. You can add it again anytime.',
                                  style: TextStyle(
                                    color: Colors.grey.shade300,
                                    height: 1.5,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(color: Colors.grey.shade400),
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.red.shade500,
                                          Colors.red.shade600,
                                        ],
                                      ),
                                    ),
                                    child: FilledButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        onDelete();
                                      },
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Delete'),
                                    ),
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
          ),
        ),
      ),
    );
  }
}
