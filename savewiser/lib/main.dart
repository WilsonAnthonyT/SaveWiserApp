import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'setup_page.dart';
import 'main_nav.dart';

// Plugin instance (make sure it's initialized in main.dart)
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request notification permission for Android 13+ (POST_NOTIFICATIONS)
  await _requestNotificationPermission();

  // Create the notification channel for Android 8.0+
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'test_channel_id', // Channel ID
    'Test Notifications', // Channel Name
    description: 'This channel is used for test notifications',
    importance: Importance.max,
    playSound: true,
  );

  // Initialize plugin settings for Android
  const AndroidInitializationSettings androidInitialization =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: androidInitialization,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Create the notification channel
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  runApp(SaveWiserApp());
}

Future<bool> _requestNotificationPermission() async {
  PermissionStatus status = await Permission.notification.request();
  return status.isGranted;
}

class SaveWiserApp extends StatelessWidget {
  const SaveWiserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SaveWiser',
      theme: ThemeData(primarySwatch: Colors.green),
      home: InitialScreenDecider(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class InitialScreenDecider extends StatefulWidget {
  const InitialScreenDecider({super.key});

  @override
  State<InitialScreenDecider> createState() => _InitialScreenDeciderState();
}

class _InitialScreenDeciderState extends State<InitialScreenDecider> {
  bool? isSetupDone;

  @override
  void initState() {
    super.initState();
    checkSetupStatus();
  }

  Future<void> checkSetupStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool('isSetupDone') ?? false;
    setState(() {
      isSetupDone = done;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isSetupDone == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return isSetupDone! ? MainNavigation() : SetupPage();
  }
}
