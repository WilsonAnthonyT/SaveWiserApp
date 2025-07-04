import 'package:flutter/material.dart';
import 'otp_verification.dart'; // ✅ you'll create this next

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Terms & Conditions")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Expanded(
              child: SingleChildScrollView(
                child: Text(
                  "Here are the privacy policy and terms...",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OtpVerificationPage(),
                  ),
                );
              },
              child: const Text("Agree and Verify Phone"),
            ),
          ],
        ),
      ),
    );
  }
}
