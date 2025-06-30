import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../services/notification_service.dart'; // 👈 your service

class FutureStatisticsPage extends StatefulWidget {
  const FutureStatisticsPage({super.key});

  @override
  State<FutureStatisticsPage> createState() => _FutureStatisticsPageState();
}

class _FutureStatisticsPageState extends State<FutureStatisticsPage> {
  bool _homeNotifications = true;
  TimeOfDay? _pickedTime;
  Duration? _countdownDuration;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _homeNotifications = prefs.getBool('homeNotifications') ?? true;
    });
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _pickedTime = picked);
      final now = tz.TZDateTime.now(tz.local);
      var next = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        picked.hour,
        picked.minute,
      );
      if (next.isBefore(now)) next = next.add(const Duration(days: 1));
      _startCountdown(next);
    }
  }

  void _startCountdown(tz.TZDateTime targetTime) {
    _countdownTimer?.cancel();
    setState(() {
      _countdownDuration = targetTime.difference(tz.TZDateTime.now(tz.local));
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = tz.TZDateTime.now(tz.local);
      final remaining = targetTime.difference(now);
      if (remaining.isNegative) {
        timer.cancel();
        setState(() => _countdownDuration = Duration.zero);
      } else {
        setState(() => _countdownDuration = remaining);
      }
    });
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  void _scheduleNotification() async {
    if (!_homeNotifications || _pickedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pick time and enable notifications first'),
        ),
      );
      return;
    }

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      _pickedTime!.hour,
      _pickedTime!.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    print('[DEBUG] Home notifications enabled: $_homeNotifications');
    print('[DEBUG] Scheduling for: $scheduledDate');
    print('[DEBUG] Now: ${tz.TZDateTime.now(tz.local)}');

    await NotificationService().schedule(
      id: 1,
      title: "Reminder",
      body: "Scheduled Notif bozo!",
      scheduledDate: scheduledDate,
      enabled: _homeNotifications,
    );

    _startCountdown(scheduledDate);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Notification scheduled at ${_pickedTime!.format(context)}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () => NotificationService().showNow(
              id: 0,
              title: 'Test Notification',
              body: 'Triggered immediately!',
              enabled: _homeNotifications,
            ),
            child: const Text('Test Notification'),
          ),
          ElevatedButton(
            onPressed: () => _pickTime(context),
            child: const Text('Pick Notification Time'),
          ),
          if (_pickedTime != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text('Picked Time: ${_pickedTime!.format(context)}'),
            ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _scheduleNotification,
            child: const Text('Schedule Notification'),
          ),
          const SizedBox(height: 20),
          if (_countdownDuration != null)
            Text(
              'Next notification in: ${_formatDuration(_countdownDuration!)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }
}
