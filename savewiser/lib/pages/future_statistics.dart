// import 'package:flutter/material.dart';

// class FutureStatisticsPage extends StatelessWidget {
//   const FutureStatisticsPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Center(child: Text('Future Statistic Page'));
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Plugin instance (make sure it's initialized in main.dart)
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class FutureStatisticsPage extends StatelessWidget {
  const FutureStatisticsPage({super.key});

  // Method to show test notification
  void _showTestNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'test_channel_id', // Channel ID
          'Test Notifications', // Channel name
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      'Test Notification',
      'This is a test notification from FutureStatisticsPage!',
      platformDetails,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: _showTestNotification,
        child: const Text('Test Notification'),
      ),
    );
  }
}
