import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/thousand_separator_input.dart';
import 'package:flutter/services.dart';

class UpdateProfilePage extends StatefulWidget {
  const UpdateProfilePage({Key? key}) : super(key: key);

  @override
  State<UpdateProfilePage> createState() => _UpdateProfilePageState();
}

class _UpdateProfilePageState extends State<UpdateProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fullNameCtrl;
  late TextEditingController _dobCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _phoneCtrl;

  late TextEditingController _goalDateCtrl;
  late TextEditingController _savingCtrl;
  late TextEditingController _targetCtrl;

  DateTime? _selectedDob;
  DateTime? _goalDate;
  String _gender = 'Male';
  final List<String> _genders = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _fullNameCtrl = TextEditingController();
    _dobCtrl = TextEditingController();
    _locationCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();

    _goalDateCtrl = TextEditingController();
    _savingCtrl = TextEditingController();
    _targetCtrl = TextEditingController();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final fullName = prefs.getString('name');
    final dobIso = prefs.getString('dob');
    final location = prefs.getString('location');
    final phone = prefs.getString('phone');
    final gender = prefs.getString('gender');
    final goalDateIso = prefs.getString('goalDate');
    final saving = prefs.getString('amount');
    final target = prefs.getString('purpose');

    if (fullName != null) _fullNameCtrl.text = fullName;
    if (dobIso != null) {
      try {
        _selectedDob = DateTime.parse(dobIso);
        _dobCtrl.text =
            '${_selectedDob!.day.toString().padLeft(2, '0')}/'
            '${_selectedDob!.month.toString().padLeft(2, '0')}/'
            '${_selectedDob!.year}';
      } catch (_) {}
    }
    if (location != null) _locationCtrl.text = location;
    if (phone != null) _phoneCtrl.text = phone;
    if (gender != null && _genders.contains(gender)) {
      _gender = gender;
    }
    if (goalDateIso != null) {
      try {
        _goalDate = DateTime.parse(goalDateIso);
        _goalDateCtrl.text =
            '${_goalDate!.day.toString().padLeft(2, '0')}/'
            '${_goalDate!.month.toString().padLeft(2, '0')}/'
            '${_goalDate!.year}';
      } catch (_) {}
    }
    if (saving != null) _savingCtrl.text = saving;
    if (target != null) _targetCtrl.text = target;

    setState(() {});
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final initial = _selectedDob ?? DateTime(now.year - 20);
    final dt = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (dt != null) {
      _selectedDob = dt;
      _dobCtrl.text =
          '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}';
      setState(() {});
    }
  }

  Future<void> _pickGoalDate() async {
    final now = DateTime.now();
    final initial = _goalDate ?? now;
    final dt = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 5)),
      lastDate: DateTime(now.year + 10),
    );
    if (dt != null) {
      _goalDate = dt;
      _goalDateCtrl.text =
          '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}';
      setState(() {});
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your date of birth')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', _fullNameCtrl.text.trim());
    await prefs.setString('dob', _selectedDob!.toIso8601String());
    await prefs.setString('location', _locationCtrl.text.trim());
    await prefs.setString('phone', _phoneCtrl.text.trim());
    await prefs.setString('gender', _gender);

    await prefs.setString('goalDate', _goalDate!.toIso8601String());
    await prefs.setString('amount', _savingCtrl.text.trim());
    await prefs.setString('purpose', _targetCtrl.text.trim());

    if (!mounted) return;
    Navigator.pop(context); // 👈 Return to previous screen
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _dobCtrl.dispose();
    _locationCtrl.dispose();
    _phoneCtrl.dispose();
    _goalDateCtrl.dispose();
    _savingCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Profile'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          color: Colors.grey.shade200,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Update your information',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Full Name
                  TextFormField(
                    controller: _fullNameCtrl,
                    decoration: _inputDecoration('Full Name'),
                    maxLength: 50,
                    buildCounter:
                        (
                          _, {
                          required currentLength,
                          required isFocused,
                          maxLength,
                        }) => null,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  // DOB picker
                  GestureDetector(
                    onTap: _pickDob,
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: _dobCtrl,
                        decoration: _inputDecoration('Date of Birth'),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Location
                  TextFormField(
                    controller: _locationCtrl,
                    decoration: _inputDecoration('Location'),
                    maxLength: 50,
                    buildCounter:
                        (
                          _, {
                          required currentLength,
                          required isFocused,
                          maxLength,
                        }) => null,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Phone
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDecoration('Phone Number'),
                    maxLength: 15,
                    buildCounter:
                        (
                          _, {
                          required currentLength,
                          required isFocused,
                          maxLength,
                        }) => null,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Gender dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _gender,
                      items: _genders
                          .map(
                            (g) => DropdownMenuItem(value: g, child: Text(g)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _gender = v!),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Saving Goal',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Goal Date picker
                  GestureDetector(
                    onTap: _pickGoalDate,
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: _goalDateCtrl,
                        decoration: _inputDecoration('Goal Date'),
                        buildCounter:
                            (
                              _, {
                              required currentLength,
                              required isFocused,
                              maxLength,
                            }) => null,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Saving
                  TextFormField(
                    controller: _savingCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('Target Savings'),
                    maxLength: 18,
                    buildCounter:
                        (
                          _, {
                          required currentLength,
                          required isFocused,
                          maxLength,
                        }) => null,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      ThousandsSeparatorInputFormatter(), // or 'en'
                    ],
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Target
                  TextFormField(
                    controller: _targetCtrl,
                    decoration: _inputDecoration('Savings Purpose'),
                    maxLength: 50,
                    buildCounter:
                        (
                          _, {
                          required currentLength,
                          required isFocused,
                          maxLength,
                        }) => null,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 24),

                  Center(
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }
}
