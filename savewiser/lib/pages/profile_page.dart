import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _fullName = '';
  String _dob = '';
  String _location = '';
  String _phoneNumber = '';
  String _gender = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('name') ?? '';
    final dobIso = prefs.getString('dob');
    final location = prefs.getString('location') ?? '';
    final phone = prefs.getString('phone') ?? '';
    final gender = prefs.getString('gender') ?? '';

    String formattedDob = '';
    if (dobIso != null && dobIso.isNotEmpty) {
      try {
        final dt = DateTime.parse(dobIso);
        formattedDob = '${dt.day.toString().padLeft(2, '0')}/'
            '${dt.month.toString().padLeft(2, '0')}/'
            '${dt.year}';
      } catch (_) {
        formattedDob = '';
      }
    }

    setState(() {
      _fullName = name;
      _dob = formattedDob;
      _location = location;
      _phoneNumber = phone;
      _gender = gender;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Profile')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfo('Full Name', _fullName),
            _buildInfo('DOB', _dob),
            _buildInfo('Location', _location),
            _buildInfo('Phone Number', _phoneNumber),
            _buildInfo('Gender', _gender),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Add logic to open an edit screen or dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Update Profile Clicked')),
                  );
                },
                child: const Text('Update Profile'),
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
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 5),
          Text(
            value.isNotEmpty ? value : '- -',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
