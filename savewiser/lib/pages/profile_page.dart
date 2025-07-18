import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'update_profile.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

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

  String _goalDate = '';
  String _targetAmount = '';
  String _savingsPurpose = '';

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

    final goalDateIso = prefs.getString('goalDate');
    final targetAmount = prefs.getString('amount') ?? '';
    final purpose = prefs.getString('purpose') ?? '';

    String formattedDob = '';
    if (dobIso != null && dobIso.isNotEmpty) {
      try {
        final dt = DateTime.parse(dobIso);
        formattedDob =
            '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      } catch (_) {
        formattedDob = '';
      }
    }

    String goalDate = '';
    if (goalDateIso != null && goalDateIso.isNotEmpty) {
      try {
        final dt = DateTime.parse(goalDateIso);
        goalDate =
            '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      } catch (_) {}
    }

    setState(() {
      _fullName = name;
      _dob = formattedDob;
      _location = location;
      _phoneNumber = phone;
      _gender = gender;
      _goalDate = goalDate;
      _targetAmount = targetAmount;
      _savingsPurpose = purpose;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F2EE),
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          'SAVEWISER',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.indigo[900],
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 10),
                const ProfileImagePicker(),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(32),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Row(
                      //   children: const [
                      //     CircleAvatar(
                      //       radius: 24,
                      //       backgroundColor: Colors.white,
                      //       child: Icon(
                      //         Icons.person,
                      //         size: 30,
                      //         color: Colors.grey,
                      //       ),
                      //     ),
                      //     SizedBox(width: 12),
                      //     Text(
                      //       'Your Profile',
                      //       style: TextStyle(
                      //         fontSize: 20,
                      //         fontWeight: FontWeight.bold,
                      //         color: Colors.black87,
                      //       ),
                      //     ),
                      //   ],
                      // ),
                      const SizedBox(height: 30),
                      _buildField("Full Name", _fullName),
                      _buildField("Gender", _gender),
                      _buildField("DOB (DD/MM/YYYY)", _dob),
                      _buildField("Location", _location),
                      _buildField("Phone Number", _phoneNumber),
                      const SizedBox(height: 30),
                      _buildField("Goal Date", _goalDate),
                      _buildField("Target Savings", _targetAmount),
                      _buildField("Savings Purpose", _savingsPurpose),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UpdateProfilePage(),
                            ),
                          ).then((_) => _loadProfile());
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
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text("Save and Exit"),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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

class ProfileImagePicker extends StatefulWidget {
  const ProfileImagePicker({super.key});

  @override
  State<ProfileImagePicker> createState() => _ProfileImagePickerState();
}

class _ProfileImagePickerState extends State<ProfileImagePicker> {
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _loadSavedImage();
  }

  Future<void> _loadSavedImage() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('profile_image_path');
    if (path != null && File(path).existsSync()) {
      setState(() {
        _imageFile = File(path);
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final savedImage = await File(
        picked.path,
      ).copy('${appDir.path}/profile_picture.png');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_path', savedImage.path);

      setState(() {
        _imageFile = savedImage;
      });
    }
  }

  Future<void> _deleteImage() async {
    if (_imageFile != null && await _imageFile!.exists()) {
      try {
        await _imageFile!.delete();
      } catch (e) {
        debugPrint('Error deleting profile image: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('profile_image_path');

    setState(() {
      _imageFile = null;
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[300],
              backgroundImage: _imageFile != null
                  ? FileImage(_imageFile!)
                  : null,
              child: _imageFile == null
                  ? const Icon(Icons.person, size: 60, color: Colors.white)
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 4,
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.indigo,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_imageFile != null)
          TextButton.icon(
            onPressed: _deleteImage,
            icon: const Icon(Icons.delete, color: Colors.red),
            label: const Text(
              "Remove Photo",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
            ),
          )
        else
          const Text(
            "No profile photo set",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
      ],
    );
  }
}
