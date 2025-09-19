import 'package:bluealert/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'tabs/citizen/citizen_report_tab.dart';
import 'tabs/citizen/citizen_map_tab.dart';
import 'tabs/citizen/citizen_profile_tab.dart';
import 'tabs/analyst/analyst_reports_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // --- WIDGETS FOR CITIZEN ---
  static const List<Widget> _citizenPages = <Widget>[
    CitizenReportTab(),
    CitizenMapTab(),
    CitizenProfileTab(),
  ];

  // --- WIDGETS FOR ANALYST ---
  static const List<Widget> _analystPages = <Widget>[
    AnalystReportsTab(),
    CitizenMapTab(), // Can reuse the map tab UI
    CitizenProfileTab(), // Can reuse the profile tab UI
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isCitizen = user?.role == 'Citizen';

    final List<Widget> pages = isCitizen ? _citizenPages : _analystPages;
    final List<BottomNavigationBarItem> navItems = isCitizen
        ? [
      const BottomNavigationBarItem(icon: Icon(Icons.report), label: 'Report'),
      const BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
      const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
    ]
        : [
      const BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Reports'),
      const BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
      const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${user?.firstname ?? ''}'),
        actions: [
          if (authProvider.isOffline)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Icon(Icons.cloud_off, color: Colors.yellow),
            )
        ],
      ),
      body: Center(
        child: pages.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: navItems,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Good for 3+ items
      ),
    );
  }
}