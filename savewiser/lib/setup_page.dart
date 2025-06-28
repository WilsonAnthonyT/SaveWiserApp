// File: lib/screens/setup_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_nav.dart';

class SetupPage extends StatelessWidget {
  const SetupPage({super.key});

  Future<void> completeSetup(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isSetupDone', true);

    if (!context.mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MainNavigation()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Welcome to SaveWiser')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => completeSetup(context),
          child: Text('Complete Setup'),
        ),
      ),
    );
  }
}
