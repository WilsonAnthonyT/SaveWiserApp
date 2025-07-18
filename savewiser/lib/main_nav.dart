import 'package:flutter/material.dart';
import 'package:savewiser/pages/future_statistics.dart';
import 'package:savewiser/pages/home.dart';
import 'package:savewiser/pages/current_savings.dart';
import 'package:savewiser/pages/plannings.dart';
import 'package:savewiser/pages/profile_page.dart';
import 'package:savewiser/pages/settings.dart';
// import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

String _getAppBarTitle(int index) {
  switch (index) {
    case 0:
      return 'Future Statistics';
    case 1:
      return 'Current Savings';
    case 2:
      return 'Home';
    case 3:
      return 'Plannings';
    case 4:
      return 'Settings';
    default:
      return '';
  }
}

class MainNavigation extends StatefulWidget {
  final int initialIndex;

  const MainNavigation({super.key, this.initialIndex = 0});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _selectedIndex;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _loadProfileImage();
  }

  final List<Widget> _pages = [
    FutureStatisticsPage(),
    CurrentSavingsPage(),
    HomePage(),
    PlanningsPage(),
    SettingsPage(),
  ];

  Future<void> _loadProfileImage() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/profile_picture.png');
    if (await file.exists()) {
      setState(() {
        _profileImage = file;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: (Text(_getAppBarTitle(_selectedIndex))),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: _profileImage != null
                ? CircleAvatar(
                    backgroundImage: FileImage(_profileImage!),
                    radius: 14,
                  )
                : const Icon(Icons.account_circle),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );

              if (result == true && mounted) {
                _loadProfileImage(); // 👈 Refresh image after coming back
                if (_selectedIndex == 1) {
                  setState(() {
                    _pages[1] = CurrentSavingsPage(key: UniqueKey());
                  });
                }
              }
            },
          ),
        ],
      ),

      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Future Statistics',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Savings'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Plannings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
