import 'package:flutter/material.dart';
import 'terms_and_conditions.dart';
import 'faq_pages.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/notification_service.dart';
import '../services/notification_schedule.dart';
import 'dart:async'; // for Timer

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
    "How to see my monthly spending?",
    "How to check my progress?",
    "How to restart the app?",
    "What is the savings goal?",
    "How do I set up my target?",
    "What is the monthly savings percentage?",
    "How do I add a new expense?",
    "Where can I view my detailed savings?",
    "What is the Guardian Control feature?",
    "How to set up daily spending alert?",
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
  String _approvalMethod = 'SMS';
  int _autoLockPct = 10;

  @override
  void initState() {
    super.initState();
    // Initialize filtered FAQs with all FAQs
    filteredFaqs = List.from(allFaqs);

    // Listen to the search text changes
    searchController.addListener(_filterFaqs);

    _loadPreferences(); // Start the countdown on init
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
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
      _approvalMethod = prefs.getString('approvalMethod') ?? 'SMS';
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
  Future<void> _enableGuardSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('guardianEnabled', _guardianEnabled);
    await prefs.setString('guardianName', _guardianNameCtrl.text);
    await prefs.setString('guardianPhone', _guardianPhoneCtrl.text);
    await prefs.setString('approvalMethod', _approvalMethod);
    await prefs.setInt('autoLockPct', _autoLockPct);
  }

  void _openFaq(BuildContext context, String title, String content) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FaqDetailPage(title: title, content: content),
      ),
    );
  }

  void _openTerms(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TermsPage()),
    );
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
                TextField(
                  controller: _guardianNameCtrl,
                  decoration: const InputDecoration(labelText: "Guardian Name"),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _guardianPhoneCtrl,
                  decoration: const InputDecoration(
                    labelText: "Guardian Phone",
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 8),

                // 🔐 Auto-lock Percentage Dropdown
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
                  items: ['SMS', 'Email', 'App']
                      .map(
                        (method) => DropdownMenuItem(
                          value: method,
                          child: Text(method),
                        ),
                      )
                      .toList(),
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
              _supportText("Phone", "+65 8871 8268"),
              _supportText("Email", "support@savewiser.com"),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: const Text("Live Chat: Available 24/7"),
                subtitle: const Text(
                  "Click Here and wait for one of our staff to address your concerns",
                ),
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
        // Navigate to FAQ details
        // You can define your FaqDetailPage route or logic here
        _openFaq(context, title, 'Content for $title');
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
