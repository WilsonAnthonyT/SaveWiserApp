// File: lib/screens/setup_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'main_nav.dart';

// class SetupPage extends StatelessWidget {
//   const SetupPage({super.key});

//   Future<void> completeSetup(BuildContext context) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool('isSetupDone', true);

//     if (!context.mounted) return;

//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (context) => MainNavigation()),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Welcome to SaveWiser')),
//       body: Center(
//         child: ElevatedButton(
//           onPressed: () => completeSetup(context),
//           child: Text('Complete Setup'),
//         ),
//       ),
//     );
//   }
// }

class SetupStep1 extends StatefulWidget {
  const SetupStep1({super.key});
  @override
  State<SetupStep1> createState() => _SetupStep1State();
}

class _SetupStep1State extends State<SetupStep1> {
  // dropdown data
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _purposeCtrl;
  late TextEditingController _amountCtrl;

  final _months = const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  late List<String> _years;
  late String _selMonth, _selYear;

  // calendar
  late DateTime _focusedDate, _selectedDate;

  // form inputs
  String _purpose = '';
  String _amount = '';

  int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

  Future<void> initShared() async {
    final prefs = await SharedPreferences.getInstance();

    // load date
    final dateStr = prefs.getString('goalDate');
    if (dateStr != null) {
      final dt = DateTime.tryParse(dateStr);
      if (dt != null) {
        _selectedDate = dt;
        _focusedDate = dt;
        _selMonth = _months[dt.month - 1];
        _selYear = dt.year.toString();
      }
    }

    // load purpose
    final savedPurpose = prefs.getString('purpose');
    if (savedPurpose != null) {
      _purpose = savedPurpose;
      _purposeCtrl.text = savedPurpose;
    } else {
      _purposeCtrl.text = _purpose;
    }

    // load amount
    final savedAmount = prefs.getString('amount');
    if (savedAmount != null) {
      _amount = savedAmount;
      _amountCtrl.text = savedAmount;
    } else {
      _amountCtrl.text = _amount;
    }

    setState(() {});
  }

  @override
  void dispose() {
    _purposeCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _purposeCtrl = TextEditingController();
    _amountCtrl = TextEditingController();

    final now = DateTime.now();
    _focusedDate = now;
    _selectedDate = now;
    _selMonth = _months[now.month - 1];
    _years = List.generate(5, (i) => (now.year + i).toString());
    _selYear = now.year.toString();

    initShared();
  }

  Future<void> _goNext() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_purpose == "" || _amount == "") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Let us set your goal first before we continue'),
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('goalDate', _selectedDate.toIso8601String());
    await prefs.setString('purpose', _purpose);
    await prefs.setString('amount', _amount);

    if (!mounted) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SetupStep2()));
  }

  @override
  Widget build(BuildContext context) {
    final int currentYear = DateTime.now().year;
    final int currentMonth = DateTime.now().month;
    final allowedMonths = (_selYear == currentYear.toString())
        ? _months.sublist(currentMonth - 1)
        : _months;

    return Scaffold(
      // transparent appbar with SAVEWISER
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'SAVEWISER',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.blueAccent),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Card container
            Card(
              color: Colors.grey.shade200,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          "Budi’s Target",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text(
                                'Reach Goal By',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Month/Year dropdowns
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(32),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    DropdownButton<String>(
                                      underline: const SizedBox(),
                                      value: _selMonth,
                                      items: allowedMonths
                                          .map(
                                            (m) => DropdownMenuItem(
                                              value: m,
                                              child: Text(m),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (m) {
                                        if (m == null) return;
                                        final idx = _months.indexOf(m) + 1;
                                        final y = int.parse(_selYear);
                                        final origDay = _selectedDate.day;
                                        final maxDay = daysInMonth(y, idx);
                                        final newDay = origDay <= maxDay
                                            ? origDay
                                            : maxDay;
                                        setState(() {
                                          _selMonth = m;
                                          _selectedDate = DateTime(
                                            y,
                                            idx,
                                            newDay,
                                          );
                                          _focusedDate = _selectedDate;
                                        });
                                      },
                                    ),
                                    const SizedBox(width: 16),
                                    DropdownButton<String>(
                                      underline: const SizedBox(),
                                      value: _selYear,
                                      items: _years
                                          .map(
                                            (y) => DropdownMenuItem(
                                              value: y,
                                              child: Text(y),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (y) {
                                        if (y == null) return;
                                        setState(() {
                                          _selYear = y;
                                          _focusedDate = DateTime(
                                            int.parse(y),
                                            _focusedDate.month,
                                            _focusedDate.day,
                                          );
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Calendar
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: Theme.of(context).colorScheme
                                        .copyWith(primary: Colors.green),
                                  ),
                                  child: CalendarDatePicker(
                                    key: ValueKey(
                                      '${_focusedDate.year}-${_focusedDate.month}',
                                    ),
                                    initialDate: _focusedDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 365 * 50),
                                    ),
                                    currentDate: _selectedDate,
                                    onDateChanged: (dt) {
                                      setState(() {
                                        _selectedDate = dt;
                                        _focusedDate = dt;
                                        _selMonth = _months[dt.month - 1];
                                        _selYear = dt.year.toString();
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Purpose row
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'I am saving for:',
                              style: TextStyle(fontStyle: FontStyle.italic),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _purposeCtrl,
                                decoration: const InputDecoration.collapsed(
                                  hintText: 'Tuition Fees',
                                ),
                                onChanged: (v) => _purpose = v,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      Container(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'How much do you want to save?',
                              style: TextStyle(fontStyle: FontStyle.italic),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                // Static currency label
                                Text(
                                  'Rp',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // The actual input field
                                Expanded(
                                  child: TextFormField(
                                    controller: _amountCtrl,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                      border: InputBorder.none,
                                      hintText: '20.000.000,00',
                                      hintStyle: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    onChanged: (v) => _amount = v,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Next button
                      ElevatedButton(
                        onPressed: _goNext,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Next →'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class SetupStep2 extends StatefulWidget {
  const SetupStep2({super.key});
  @override
  State<SetupStep2> createState() => _SetupStep2State();
}

class _SetupStep2State extends State<SetupStep2> {
  // define the checklist items
  final Map<String, bool> _needs = {
    'Breakfast': false,
    'Lunch': false,
    'Dinner': false,
    'Utility Bills': false,
    'Transport': false,
    'Rent': false,
    'Insurance': false,
    'Education': false,
    'Clothing': false,
    'Others': false,
  };
  final Map<String, bool> _wants = {
    'Subscriptions': false,
    'Eating Out/Drinks': false,
    'Travel/Vacations': false,
    'Entertainment': false,
    'Others': false,
  };

  @override
  void initState() {
    super.initState();
    _loadSavedSelections();
  }

  Future<void> _persistSelections() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'needs',
      _needs.entries.where((e) => e.value).map((e) => e.key).toList(),
    );
    await prefs.setStringList(
      'wants',
      _wants.entries.where((e) => e.value).map((e) => e.key).toList(),
    );
  }

  Future<bool> _onWillPop() async {
    // save before popping
    await _persistSelections();
    return true; // allow the pop
  }

  Future<void> _loadSavedSelections() async {
    final prefs = await SharedPreferences.getInstance();

    // rehydrate "needs"
    final savedNeeds = prefs.getStringList('needs') ?? [];
    for (final key in savedNeeds) {
      if (_needs.containsKey(key)) {
        _needs[key] = true;
      }
    }

    // rehydrate "wants"
    final savedWants = prefs.getStringList('wants') ?? [];
    for (final key in savedWants) {
      if (_wants.containsKey(key)) {
        _wants[key] = true;
      }
    }

    setState(() {});
  }

  Future<void> _goNext() async {
    final hasNeed = _needs.values.any((v) => v);
    final hasWant = _wants.values.any((v) => v);
    if (!hasNeed || !hasWant) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please check at least one item under Needs and one under Wants.',
          ),
        ),
      );
      return;
    }

    await _persistSelections();
    if (!mounted) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SetupStep3()));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        await _persistSelections();
      },
      child: Scaffold(
        // same AppBar style as your other steps
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'SAVEWISER',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.person, color: Colors.blueAccent),
              onPressed: () {},
            ),
          ],
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Spending Checklist',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Needs section
                  Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Needs',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._needs.entries.map((e) {
                            return CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(e.key),
                              value: e.value,
                              onChanged: (checked) {
                                setState(() {
                                  _needs[e.key] = checked ?? false;
                                });
                              },
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Wants section
                  Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Wants',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._wants.entries.map((e) {
                            return CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(e.key),
                              value: e.value,
                              onChanged: (checked) {
                                setState(() {
                                  _wants[e.key] = checked ?? false;
                                });
                              },
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Next button
                  Center(
                    child: ElevatedButton(
                      onPressed: _goNext,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Next →'),
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
}

class SetupStep3 extends StatefulWidget {
  const SetupStep3({super.key});
  @override
  State<SetupStep3> createState() => _SetupStep3State();
}

class _SetupStep3State extends State<SetupStep3> {
  // prefs keys
  static const _kAlertHour = 'alertHour';
  static const _kAlertMinute = 'alertMinute';
  static const _kAlertPeriod = 'alertPeriod';
  static const _kHomeNotifs = 'homeNotifications';
  static const _kGuardEnable = 'guardianEnabled';
  static const _kAutoLockPct = 'autoLockPct';
  static const _kGuardName = 'guardianName';
  static const _kGuardPhone = 'guardianPhone';
  static const _kApprovalMeth = 'approvalMethod';

  // state
  int _hour = 8;
  int _minute = 0;
  String _period = 'AM';
  bool _homeNotifications = true;
  bool _guardianEnabled = false;
  int _autoLockPct = 10;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _approvalMethod = 'SMS';

  // dropdown options
  final _hours = List.generate(12, (i) => i + 1);
  final _minutes = List.generate(60, (i) => i);
  final _periods = ['AM', 'PM'];
  final _lockPcts = [5, 10, 15, 20, 25, 30];
  final _approvalMethods = ['SMS', 'Email', 'App'];
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> _triggerNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'home_notifications_channel',
          'Home Notifications',
          //description: 'Notifications for home screen alerts.',
          importance: Importance.high,
          priority: Priority.high,
        );
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      'Home Notification Enabled', // Title
      'You will receive notifications on your home screen', // Body
      platformDetails,
    );
  }

  Future<void> _cancelNotification() async {
    await flutterLocalNotificationsPlugin.cancel(0); // Cancel the notification
  }

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _persistStep3Prefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kAlertHour, _hour);
    await prefs.setInt(_kAlertMinute, _minute);
    await prefs.setString(_kAlertPeriod, _period);
    await prefs.setBool(_kHomeNotifs, _homeNotifications);
    await prefs.setBool(_kGuardEnable, _guardianEnabled);
    await prefs.setInt(_kAutoLockPct, _autoLockPct);
    await prefs.setString(_kGuardName, _nameCtrl.text);
    await prefs.setString(_kGuardPhone, _phoneCtrl.text);
    await prefs.setString(_kApprovalMeth, _approvalMethod);
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hour = prefs.getInt(_kAlertHour) ?? _hour;
      _minute = prefs.getInt(_kAlertMinute) ?? _minute;
      _period = prefs.getString(_kAlertPeriod) ?? _period;
      _homeNotifications = prefs.getBool(_kHomeNotifs) ?? _homeNotifications;
      _guardianEnabled = prefs.getBool(_kGuardEnable) ?? _guardianEnabled;
      _autoLockPct = prefs.getInt(_kAutoLockPct) ?? _autoLockPct;
      _nameCtrl.text = prefs.getString(_kGuardName) ?? '';
      _phoneCtrl.text = prefs.getString(_kGuardPhone) ?? '';
      _approvalMethod = prefs.getString(_kApprovalMeth) ?? _approvalMethod;
    });
  }

  Future<void> _finishSetup() async {
    if (_guardianEnabled) {
      if (_nameCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter both guardian name and phone number.'),
          ),
        );
        return;
      }
    }

    _persistStep3Prefs();

    // mark setup done and go home
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isSetupDone', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigation()),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        await _persistStep3Prefs();
      },

      child: Scaffold(
        // transparent AppBar like other steps
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'SAVEWISER',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.person, color: Colors.blueAccent),
              onPressed: () {},
            ),
          ],
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Preferences',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Daily Spending Alert Time
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Daily Spending Alert Time',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // hour
                            DropdownButton<int>(
                              value: _hour,
                              items: _hours
                                  .map(
                                    (h) => DropdownMenuItem(
                                      value: h,
                                      child: Text(h.toString().padLeft(2, '0')),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(() => _hour = v!),
                            ),
                            const Text(' : '),
                            // minute
                            DropdownButton<int>(
                              value: _minute,
                              items: _minutes
                                  .map(
                                    (m) => DropdownMenuItem(
                                      value: m,
                                      child: Text(m.toString().padLeft(2, '0')),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(() => _minute = v!),
                            ),
                            const SizedBox(width: 12),
                            // AM/PM
                            DropdownButton<String>(
                              value: _period,
                              items: _periods
                                  .map(
                                    (p) => DropdownMenuItem(
                                      value: p,
                                      child: Text(p),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(() => _period = v!),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Home-screen Notifications
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Home-screen Notifications',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ),
                        Switch(
                          value: _homeNotifications,
                          activeColor: Colors.green, // ← make thumb green
                          onChanged: (value) async {
                            setState(() {
                              _homeNotifications = value;
                            });

                            // Save preference
                            await _persistStep3Prefs();

                            // Trigger notification or cancel based on the switch state
                            if (_homeNotifications) {
                              await _triggerNotification();
                            } else {
                              await _cancelNotification();
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // the switch row
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Enable Guardian Control',
                                style: TextStyle(fontStyle: FontStyle.italic),
                              ),
                            ),
                            Switch(
                              value: _guardianEnabled,
                              activeColor: Colors.green, // ← make thumb green
                              onChanged: (v) =>
                                  setState(() => _guardianEnabled = v),
                            ),
                          ],
                        ),

                        if (_guardianEnabled) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Lock a portion of savings and require guardian approval to unlock',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Auto-lock %
                          Row(
                            children: [
                              const Text('Auto-lock Percentage of Income:'),
                              const Spacer(),
                              DropdownButton<int>(
                                value: _autoLockPct,
                                items: _lockPcts
                                    .map(
                                      (pct) => DropdownMenuItem(
                                        value: pct,
                                        child: Text('$pct%'),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _autoLockPct = v!),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Guardian Name
                          TextField(
                            controller: _nameCtrl,
                            decoration: InputDecoration(
                              hintText: 'Guardian Name',
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Phone Number
                          TextField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              hintText: 'Phone Number',
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Approval Method
                          Row(
                            children: [
                              const Text('Approval Method:'),
                              const Spacer(),
                              DropdownButton<String>(
                                value: _approvalMethod,
                                items: _approvalMethods
                                    .map(
                                      (m) => DropdownMenuItem(
                                        value: m,
                                        child: Text(m),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _approvalMethod = v!),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  Center(
                    child: ElevatedButton(
                      onPressed: _finishSetup,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Finish Setup'),
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
}
