import 'package:flutter/material.dart';

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
                child: Text('''
Privacy Policy & Terms

1. **Data Collection**: This app collects only the data you provide directly. We do not hold user's data nor shared user's data with any third parties without consent.

2. **Purpose**: Your data is used solely for providing financial tracking and insights.

3. **Storage**: All data is stored securely on your device locally.

4. **Security**: We implement standard security measures, but users are responsible for keeping their login credentials private.

5. **No Liability**: We are not liable for any financial losses incurred due to reliance on app insights.

6. **Usage**: By using this app, you agree not to exploit or misuse it.

For more information, contact our support.

By tapping "Agree", you accept the above terms.
''', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true); // ✅ Return agreement result
              },
              child: const Text("Agree and Continue"),
            ),
          ],
        ),
      ),
    );
  }
}
