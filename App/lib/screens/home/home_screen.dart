import 'package:bluealert/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'tabs/citizen/citizen_create_report_tab.dart';
import 'tabs/analyst/analyst_reports_feed_tab.dart';
import 'tabs/citizen/citizen_profile_tab.dart';
import 'tabs/shared/reports_feed_tab.dart';
import 'tabs/shared/hotspot_tab.dart'; // <-- IMPORT the renamed HotspotTab

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

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

    // Updated page lists to include HotspotTab
    final List<Widget> pages = isCitizen
        ? [
      const ReportsFeedTab(role: 'Citizen'),
      const CitizenCreateReportTab(),
      const HotspotTab(), // <-- Use HotspotTab
      const CitizenProfileTab(),
    ]
        : [
      const AnalystReportsFeedTab(),
      const HotspotTab(), // <-- Use HotspotTab
      const CitizenProfileTab(),
    ];

    // Updated navigation items with the new label
    final List<BottomNavigationBarItem> navItems = isCitizen
        ? [
      const BottomNavigationBarItem(icon: Icon(Icons.view_list_outlined), label: 'View Reports'),
      const BottomNavigationBarItem(icon: Icon(Icons.add_comment_outlined), label: 'Create Report'),
      const BottomNavigationBarItem(icon: Icon(Icons.local_fire_department_outlined), label: 'Hotspots'), // <-- New Label
      const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
    ]
        : [
      const BottomNavigationBarItem(icon: Icon(Icons.fact_check_outlined), label: 'Verify Reports'),
      const BottomNavigationBarItem(icon: Icon(Icons.local_fire_department_outlined), label: 'Hotspots'), // <-- New Label
      const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('BlueAlert - ${user?.role ?? ''}'),
        actions: [
          if (authProvider.isOffline)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Tooltip(message: 'Offline Mode', child: Icon(Icons.cloud_off, color: Colors.yellowAccent)),
            )
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: navItems,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}