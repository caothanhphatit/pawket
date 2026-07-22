import 'package:flutter/material.dart';

import '../../../app/theme/pawket_theme.dart';
import '../data/daily_reminder_service.dart';

class DailyReminderScreen extends StatefulWidget {
  const DailyReminderScreen({super.key});

  @override
  State<DailyReminderScreen> createState() => _DailyReminderScreenState();
}

class _DailyReminderScreenState extends State<DailyReminderScreen> {
  final service = DailyReminderService();
  DailyReminderSettings? settings;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    service.load().then((value) {
      if (mounted) setState(() => settings = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final current = settings;
    return Scaffold(
      appBar: AppBar(title: const Text('Daily reminder')),
      body: current == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              children: [
                Text(
                  'A gentle nudge, once a day.',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pawket reminds you locally on this phone. No pet data is sent for reminders.',
                  style: TextStyle(color: PawketColors.inkMuted, fontSize: 16),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        value: current.enabled,
                        onChanged: saving ? null : _setEnabled,
                        title: const Text('Remember today'),
                        subtitle: const Text('One notification every day'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        enabled: !saving,
                        leading: const Icon(Icons.schedule_outlined),
                        title: const Text('Reminder time'),
                        trailing: Text(
                          TimeOfDay(
                            hour: current.hour,
                            minute: current.minute,
                          ).format(context),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        onTap: _chooseTime,
                      ),
                    ],
                  ),
                ),
                if (saving) ...[
                  const SizedBox(height: 18),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
    );
  }

  Future<void> _setEnabled(bool enabled) async {
    final current = settings!;
    setState(() => saving = true);
    try {
      if (enabled) {
        final granted = await service.enable(
          hour: current.hour,
          minute: current.minute,
        );
        if (!granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Allow notifications in Settings to enable reminders.',
                ),
              ),
            );
          }
          return;
        }
      } else {
        await service.disable(hour: current.hour, minute: current.minute);
      }
      if (mounted) {
        setState(() {
          settings = DailyReminderSettings(
            enabled: enabled,
            hour: current.hour,
            minute: current.minute,
          );
        });
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _chooseTime() async {
    final current = settings!;
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (selected == null || !mounted) return;
    setState(() => saving = true);
    try {
      if (current.enabled) {
        await service.enable(hour: selected.hour, minute: selected.minute);
      } else {
        await service.disable(hour: selected.hour, minute: selected.minute);
      }
      if (mounted) {
        setState(() {
          settings = DailyReminderSettings(
            enabled: current.enabled,
            hour: selected.hour,
            minute: selected.minute,
          );
        });
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}
