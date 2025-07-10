import 'package:flutter/material.dart';
import 'terms_and_conditions.dart';
// import 'faq_pages.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/notification_service.dart';
import '../services/notification_schedule.dart';
import 'dart:async'; // for Timer

// Optional: Create a mapping of questions to answers
final Map<String, String> faqContents = {
  "Why is 10% of my income locked?":
      "It’s auto-locked to help you save consistently, similar to Singapore’s CPF system. This will help you build good saving habits and ensures you always have emergency funds.",
  "Can I use the locked savings anytime? ":
      "Yes, but only with guardian approval. You’ll need your guardian to approve spending from locked savings so you reflect before using it. ",
  "How is my daily spending calculated?":
      " It is based on your income, expenses, and saving goals. The app uses budgeting rules, specifically the 50-30-20 rule to split your money into needs, wants, and savings. ",
  "What is the savings goal?":
      "It’s the monthly amount you want to save — you set this during setup.",
  "What happens if I overspend for the day?":
      "You’ll get a warning and adjusted limits for the rest of the week. This prevents you from building a habit of overspending and helps you stay on track monthly.",
  "Can I change my financial goals later?":
      "Yes, anytime in your settings. You can update your goal amount, deadline, or purpose if your priorities change. ",
  "What’s the difference between ‘needs’ and ‘wants’?":
      "Needs are essentials (e.g., food, rent); wants are extras (e.g., bubble tea, games). Separating them helps you avoid spending too much on things that aren’t urgent. ",
  "How does the app know the cost of living in my area?":
      "We use average prices based on your location. This helps you budget more realistically depending on where you live. ",
  "What if my income changes?":
      "Just update it in your profile, your budget will adjust automatically. This keeps your spending and saving recommendations accurate and flexible. ",
  "Can I use this app even if I don’t earn a salary?":
      "Yes! You can track allowance or set a fixed budget. The app is useful for students too as it helps you manage pocket money wisely. ",
  "Is my financial data safe? ":
      "Yes, your data is securely stored and only visible to you (and your guardian if enabled). We use encryption and privacy settings to protect your financial information.",
};

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // List of all FAQs
  final List<String> allFaqs = [
    "Why is 10% of my income locked?",
    "Can I use the locked savings anytime? ",
    "How is my daily spending calculated?",
    "What is the savings goal?",
    "What happens if I overspend for the day?",
    "Can I change my financial goals later?",
    "What’s the difference between ‘needs’ and ‘wants’?",
    "How does the app know the cost of living in my area?",
    "What if my income changes?",
    "Can I use this app even if I don’t earn a salary?",
    "Is my financial data safe? ",
  ];

  // List of filtered FAQs based on search
  List<String> filteredFaqs = [];

  // Controller for the search field
  TextEditingController searchController = TextEditingController();

  // keys1
  bool _homeNotifications = true;
  bool _isLoading = true;
  // keys2
  int _alertHour = 8;
  int _alertMinute = 0;
  String _alertPeriod = 'AM';
  final List<int> _hours = List.generate(12, (i) => i + 1);
  final List<int> _minutes = List.generate(60, (i) => i);
  final List<String> _periods = ['AM', 'PM'];
  // keys3
  bool _guardianEnabled = false;
  final TextEditingController _guardianNameCtrl = TextEditingController();
  final TextEditingController _guardianPhoneCtrl = TextEditingController();
  final TextEditingController _passcodeCtrl = TextEditingController();
  bool _passcodeLocked = false;
  bool _isConfirmEnabled = false;

  String _approvalMethod = 'Passcode';
  int _autoLockPct = 10;

  @override
  void initState() {
    super.initState();
    filteredFaqs = List.from(allFaqs);
    searchController.addListener(_filterFaqs);

    _loadPreferences();
    _passcodeCtrl.addListener(() {
      final text = _passcodeCtrl.text;
      setState(() {
        _isConfirmEnabled = text.length >= 4 && !_passcodeLocked;
      });
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    //await prefs.setString('approvalMethod', 'Passcode');
    setState(() {
      _homeNotifications = prefs.getBool('homeNotifications') ?? true;
      _isLoading = false;
      //alarm
      _alertHour = prefs.getInt('alertHour') ?? 8;
      _alertMinute = prefs.getInt('alertMinute') ?? 0;
      _alertPeriod = prefs.getString('alertPeriod') ?? 'AM';
      //enable cpf
      _autoLockPct = prefs.getInt('autoLockPct') ?? 10;
      _guardianEnabled = prefs.getBool('guardianEnabled') ?? false;
      _guardianNameCtrl.text = prefs.getString('guardianName') ?? '';
      _guardianPhoneCtrl.text = prefs.getString('guardianPhone') ?? '';
      _approvalMethod = prefs.getString('approvalMethod') ?? 'Passcode';
      _passcodeCtrl.text = prefs.getString('guardianPasscode') ?? '';
      _passcodeLocked = _passcodeCtrl.text.isNotEmpty;
      _isConfirmEnabled = _passcodeCtrl.text.length >= 4 && !_passcodeLocked;
    });
  }

  Future<void> _updateNotificationPref(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _homeNotifications = value;
    });
    await prefs.setBool('homeNotifications', value);

    // Optional: trigger or cancel a sample notification
    if (value) {
      await scheduleDailySpendingNotification();
      //await _showNotification();
    } else {
      await _cancelNotification();
    }
  }

  Future<void> _cancelNotification() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  // Function to filter the FAQ list based on search query
  void _filterFaqs() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredFaqs = allFaqs
          .where((faq) => faq.toLowerCase().contains(query))
          .toList();
    });
  }

  //ALARM
  Future<void> _saveAlertSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('alertHour', _alertHour);
    await prefs.setInt('alertMinute', _alertMinute);
    await prefs.setString('alertPeriod', _alertPeriod);
    await scheduleDailySpendingNotification(); // Restart the countdown after saving
  }

  //cpf thing
  Future<void> _saveGuardSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('guardianName', _guardianNameCtrl.text);
    await prefs.setString('guardianPhone', _guardianPhoneCtrl.text);
    await prefs.setString('approvalMethod', 'Passcode');
    await prefs.setInt('autoLockPct', _autoLockPct);
    await prefs.setString('guardianPasscode', _passcodeCtrl.text);
  }

  void _openFaq(BuildContext context, String title, String content) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(content, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  void _openTerms(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TermsPage()),
    );
  }

  Future<String> _showVerifyOldPasscodeDialog(BuildContext context) async {
    final TextEditingController oldCtrl = TextEditingController();

    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verify Old Passcode'),
        content: TextField(
          controller: oldCtrl,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(
            hintText: 'Enter current passcode',
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(''),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(oldCtrl.text.trim());
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    ).then((value) => value ?? '');
  }

  Future<String> _showNewPasscodeDialog(BuildContext context) async {
    final TextEditingController newCtrl = TextEditingController();

    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter New Passcode'),
        content: TextField(
          controller: newCtrl,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(
            hintText: 'New 4-6 digit passcode',
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(''),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final pass = newCtrl.text.trim();
              if (pass.length >= 4) {
                Navigator.of(context).pop(pass);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ).then((value) => value ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
      child: Column(
        children: [
          // Top Branding (logo and profile icon handled in main_nav)
          Center(
            child: Text(
              'SAVEWISER',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[900],
              ),
            ),
          ),

          const SizedBox(height: 15),
          _sectionCard(
            title: "Notifications",
            children: [
              //ALARM================================================================
              const Text(
                'Daily Spending Alert Time',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  DropdownButton<int>(
                    value: _alertHour,
                    items: _hours
                        .map(
                          (h) => DropdownMenuItem(
                            value: h,
                            child: Text(h.toString().padLeft(2, '0')),
                          ),
                        )
                        .toList(),
                    onChanged: (v) async {
                      if (v != null) {
                        setState(() => _alertHour = v);
                        await _saveAlertSettings();
                      }
                    },
                  ),
                  const Text(" : "),
                  DropdownButton<int>(
                    value: _alertMinute,
                    items: _minutes
                        .map(
                          (m) => DropdownMenuItem(
                            value: m,
                            child: Text(m.toString().padLeft(2, '0')),
                          ),
                        )
                        .toList(),
                    onChanged: (v) async {
                      if (v != null) {
                        setState(() => _alertMinute = v);
                        await _saveAlertSettings();
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _alertPeriod,
                    items: _periods
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (v) async {
                      if (v != null) {
                        setState(() => _alertPeriod = v);
                        await _saveAlertSettings();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              //====ENABLE NOTIF=====================================
              SwitchListTile(
                title: const Text("Enable Home-screen Notifications"),
                value: _homeNotifications,
                onChanged: _isLoading ? null : _updateNotificationPref,
              ),
              ElevatedButton(
                onPressed: _homeNotifications
                    ? () async {
                        await NotificationService().showNow(
                          id: 101,
                          title: 'Test Notification',
                          body:
                              'This is a test notification from SettingsPage.',
                          enabled: _homeNotifications,
                        );

                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Test notification sent'),
                          ),
                        );
                      }
                    : null,
                child: const Text('Send Test Notification'),
              ),
            ],
          ),
          const SizedBox(height: 30),

          //ENABLE GUARDIAN
          _sectionCard(
            title: "Guardian Control",
            children: [
              SwitchListTile(
                title: const Text("Enable Guardian Control"),
                value: _guardianEnabled,
                onChanged: (value) async {
                  setState(() => _guardianEnabled = value);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('guardianEnabled', value);
                },
              ),
              if (_guardianEnabled) ...[
                const Divider(),
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    "Guardian Details",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                TextField(
                  controller: _guardianNameCtrl,
                  maxLength: 50,
                  buildCounter:
                      (
                        _, {
                        required currentLength,
                        required isFocused,
                        maxLength,
                      }) => null,
                  decoration: const InputDecoration(
                    labelText: "Guardian Name",
                    hintText: "e.g. Jane Doe",
                  ),
                  onChanged: (value) => _saveGuardSettings(),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _guardianPhoneCtrl,
                  maxLength: 15,
                  buildCounter:
                      (
                        _, {
                        required currentLength,
                        required isFocused,
                        maxLength,
                      }) => null,
                  decoration: const InputDecoration(
                    labelText: "Guardian Phone",
                    hintText: "e.g. +62 812-3456-7890",
                  ),
                  keyboardType: TextInputType.phone,
                  onChanged: (value) => _saveGuardSettings(),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    "Approval Settings",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DropdownButtonFormField<int>(
                  value: _autoLockPct,
                  items: [5, 10, 15, 20, 25, 30].map((pct) {
                    return DropdownMenuItem(value: pct, child: Text('$pct%'));
                  }).toList(),
                  onChanged: (value) async {
                    if (value == null) return;
                    setState(() => _autoLockPct = value);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setInt('autoLockPct', value);
                  },
                  decoration: const InputDecoration(
                    labelText: "Auto-lock Percentage",
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _approvalMethod,
                  items: ['Passcode'].map((method) {
                    return DropdownMenuItem(value: method, child: Text(method));
                  }).toList(),
                  onChanged: (method) async {
                    if (method == null) return;
                    setState(() => _approvalMethod = method);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('approvalMethod', method);
                  },
                  decoration: const InputDecoration(
                    labelText: "Approval Method",
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _passcodeCtrl,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        enabled: !_passcodeLocked,
                        decoration: const InputDecoration(
                          labelText: 'Guardian Passcode',
                          hintText: 'Set passcode (once only)',
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _isConfirmEnabled
                          ? () async {
                              await _saveGuardSettings();
                              setState(() {
                                _passcodeLocked = true;
                                _isConfirmEnabled = false;
                              });

                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Passcode saved')),
                              );
                            }
                          : null,
                      child: const Text('Confirm'),
                    ),
                  ],
                ),

                if (_passcodeLocked)
                  TextButton(
                    onPressed: () async {
                      final old = await _showVerifyOldPasscodeDialog(context);
                      if (old == _passcodeCtrl.text) {
                        final newPass = await _showNewPasscodeDialog(context);
                        if (newPass.isNotEmpty) {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('guardianPasscode', newPass);
                          setState(() {
                            _passcodeCtrl.text = newPass;
                            _passcodeLocked = true;
                          });
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Passcode updated successfully'),
                            ),
                          );
                        }
                      } else if (old.isNotEmpty) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Incorrect passcode')),
                        );
                      }
                    },
                    child: const Text('Change Passcode?'),
                  ),
              ],
            ],
          ),

          const SizedBox(height: 30),

          // FAQ Section
          _sectionCard(
            title: "FAQ (Frequently Asked Questions)",
            children: [_searchField(), ..._faqList()],
          ),
          const SizedBox(height: 20),

          // Support Section
          _sectionCard(
            title: "Helpline / Support",
            children: [
              _supportText("Phone", "Not Available"),
              _supportText("Email", "support@savewiser.com"),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: const Text("Live Chat: Currently Not Available"),
                subtitle: const Text("Service Not Available"),
                onTap: () {
                  // trigger live chat action or navigation
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Terms Button
          GestureDetector(
            onTap: () => _openTerms(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(
                child: Text(
                  'Privacy Policy and Terms & Conditions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Builds the search bar
  Widget _searchField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: searchController,
        decoration: const InputDecoration(
          hintText: 'Type here to search..',
          prefixIcon: Icon(Icons.search),
          suffixIcon: Icon(Icons.close),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  // Builds the FAQ list
  List<Widget> _faqList() {
    if (filteredFaqs.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: const Text('No results found', style: TextStyle(fontSize: 14)),
        ),
      ];
    }

    return filteredFaqs.map((faq) {
      return _faqButton(faq);
    }).toList();
  }

  // FAQ button to display and navigate
  Widget _faqButton(String title) {
    return GestureDetector(
      onTap: () {
        final content = faqContents[title] ?? 'Answer coming soon...';
        _openFaq(context, title, content);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(title, style: const TextStyle(fontSize: 14)),
      ),
    );
  }

  // Section Card for encapsulating different sections (like FAQ)
  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              decoration: TextDecoration.underline,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  // Support Text widget
  Widget _supportText(String label, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text("$label: $content", style: const TextStyle(fontSize: 14)),
    );
  }
}
