import 'package:flutter/material.dart';
import '../shared/reports_feed_tab.dart';

class AnalystReportsFeedTab extends StatelessWidget {
  const AnalystReportsFeedTab({super.key});

  @override
  Widget build(BuildContext context) {
    // This widget simply uses the reusable ReportsFeedTab, passing 'Analyst' as the role.
    return const ReportsFeedTab(role: 'Analyst');
  }
}