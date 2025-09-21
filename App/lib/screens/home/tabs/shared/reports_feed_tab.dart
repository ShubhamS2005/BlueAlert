import 'package:bluealert/providers/auth_provider.dart';
import 'package:bluealert/screens/home/report_detail_screen.dart';
import 'package:bluealert/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ReportsFeedTab extends StatefulWidget {
  final String role;
  const ReportsFeedTab({super.key, required this.role});

  @override
  State<ReportsFeedTab> createState() => _ReportsFeedTabState();
}

class _ReportsFeedTabState extends State<ReportsFeedTab> {
  late Future<List<dynamic>> _reportsFuture;
  String _filterStatus = 'All'; // Default filter for Analysts

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  // This method now serves both initial fetch and refresh
  Future<void> _fetchReports() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Using setState here is key for the FutureBuilder to re-run on refresh
    setState(() {
      _reportsFuture = ApiService().listReports(
        token: authProvider.token!,
        role: authProvider.user!.role,
        status: widget.role == 'Analyst' ? _filterStatus : null, // Status filter only for Analyst
      );
    });
    return _reportsFuture; // Return the future for the RefreshIndicator
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // The filter is only shown for Analysts
        if (widget.role == 'Analyst')
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SegmentedButton<String>(
              segments: const <ButtonSegment<String>>[
                ButtonSegment<String>(value: 'All', label: Text('All')),
                ButtonSegment<String>(value: 'Verified', label: Text('Verified')),
                ButtonSegment<String>(value: 'Pending', label: Text('Pending')),
              ],
              selected: <String>{_filterStatus},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _filterStatus = newSelection.first;
                  _fetchReports(); // Re-fetch reports when filter changes
                });
              },
            ),
          ),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _reportsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Error: ${snapshot.error}\n\nPull down to try again.'),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No reports found.'));
              }

              final reports = snapshot.data!;

              // --- FIX: Added RefreshIndicator ---
              return RefreshIndicator(
                onRefresh: _fetchReports,
                child: ListView.builder(
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    final status = report['status'] ?? 'Unknown';
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: Icon(
                          status == 'Verified' ? Icons.verified_user_outlined : Icons.hourglass_empty_outlined,
                          color: status == 'Verified' ? Colors.green : Colors.orange,
                        ),
                        title: Text(report['text'], maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Text('Status: $status'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () async {
                          // Navigate and wait for a potential pop result
                          final result = await Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => ReportDetailScreen(report: report),
                          ));
                          // If the analyst verified a report, refresh the list
                          if (result == true) {
                            _fetchReports();
                          }
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}