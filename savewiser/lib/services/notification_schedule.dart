import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import '../services/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> requestExactAlarmPermission() async {
  final android = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  if (android != null) {
    try {
      print("[DEBUG] Requesting exact alarm permission...");
      await android.requestExactAlarmsPermission();
      print("[DEBUG] Exact alarm permission requested.");
    } catch (e) {
      print("[ERROR] requestExactAlarmsPermission failed: $e");
    }
  } else {
    print("[ERROR] Android implementation not available.");
  }
}

Future<void> scheduleDailySpendingNotification() async {
  await requestExactAlarmPermission();
  final prefs = await SharedPreferences.getInstance();
  final bool enabled = prefs.getBool('homeNotifications') ?? true;
  if (!enabled) return;

  int hour = prefs.getInt('alertHour') ?? 8;
  int minute = prefs.getInt('alertMinute') ?? 0;
  String period = prefs.getString('alertPeriod') ?? 'AM';

  // Convert to 24-hour
  if (period == 'PM' && hour != 12) hour += 12;
  if (period == 'AM' && hour == 12) hour = 0;

  final now = tz.TZDateTime.now(tz.local);
  var scheduled = tz.TZDateTime(
    tz.local,
    now.year,
    now.month,
    now.day,
    hour,
    minute,
  );

  if (scheduled.isBefore(now)) {
    scheduled = scheduled.add(const Duration(days: 1));
    print("[DEBUG] Scheduled time was before now. Scheduling for tomorrow.");
  }

  print("[DEBUG] Scheduling notification at: $scheduled");

  await NotificationService().schedule(
    id: 200,
    title: "Spending Alert",
    body: "Don't forget to track your spending today!",
    scheduledDate: scheduled,
    repeatDaily: true,
    enabled: true,
  );

  print("[DEBUG] Notification scheduled successfully.");
}
