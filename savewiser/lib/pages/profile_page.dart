// File: lib/screens/profile_page.dart

import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  final String fullName = 'Budi Untung';
  final String dob = '18/08/1998';
  final String location = 'Surabaya, Indonesia';
  final String phoneNumber = '+62 8188888888';
  final String gender = 'Male';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Your Profile')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfo('Full Name', fullName),
            _buildInfo('DOB', dob),
            _buildInfo('Location', location),
            _buildInfo('Phone Number', phoneNumber),
            _buildInfo('Gender', gender),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // You can add logic to open an edit screen here
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Update Profile Clicked')),
                  );
                },
                child: Text('Update Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          SizedBox(height: 5),
          Text(value, style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
