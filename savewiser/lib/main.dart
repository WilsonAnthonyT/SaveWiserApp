import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

// Your own files
import 'setup_page.dart';
import 'main_nav.dart';
import 'services/notification_service.dart'; // 👈 Add this

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _requestNotificationPermission();
  await _initializeTimeZone();
  await NotificationService().init(); // 👈 Use your new service

  runApp(SaveWiserApp());
}

Future<bool> _requestNotificationPermission() async {
  PermissionStatus status = await Permission.notification.request();
  return status.isGranted;
}

Future<void> _initializeTimeZone() async {
  tz.initializeTimeZones();
  try {
    final String timeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZone));
  } catch (e) {
    print("Timezone error: $e. Falling back to UTC.");
    tz.setLocalLocation(tz.getLocation('UTC'));
  }
}

class SaveWiserApp extends StatelessWidget {
  const SaveWiserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SaveWiser',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const InitialScreenDecider(),
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return isSetupDone! ? const MainNavigation() : const SetupStep1();
  }
}
