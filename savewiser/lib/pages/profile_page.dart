import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'update_profile.dart';

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
        formattedDob =
            '${dt.day.toString().padLeft(2, '0')}/'
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
      backgroundColor: const Color(0xFFF6F2EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F2EE),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            Navigator.pop(context); // 👈 Go back
          },
        ),
        centerTitle: true,
        title: Text(
          'SAVEWISER',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.indigo[900],
          ),
        ),
      ), // Light beige background
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),

            // Profile Card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(32),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: const [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.person,
                              size: 30,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Your Profile',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      _buildField("Full Name", _fullName),
                      _buildField("Gender", _gender),
                      _buildField("DOB (DD/MM/YYYY)", _dob),
                      _buildField("Location", _location),
                      _buildField("Phone Number", _phoneNumber),
                      const Spacer(),

                      // Update Profile Button
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UpdateProfilePage(),
                            ),
                          ).then(
                            (_) => _loadProfile(),
                          ); // 👈 Reload profile when returning
                        },

                        child: const Text(
                          '+ Update your profile',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.indigo,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              '$label:',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value.isNotEmpty ? value : '- -',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
