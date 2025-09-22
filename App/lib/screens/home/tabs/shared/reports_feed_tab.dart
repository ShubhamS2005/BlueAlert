import 'package:bluealert/providers/auth_provider.dart';
import 'package:bluealert/screens/home/report_detail_screen.dart';
import 'package:bluealert/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ReportsFeedTab extends StatefulWidget {
  final String role;
  const ReportsFeedTab({super.key, required this.role});

  @override
  State<ReportsFeedTab> createState() => _ReportsFeedTabState();
}

class _ReportsFeedTabState extends State<ReportsFeedTab> {
  String _filterStatus = 'All';
  List<dynamic> _allReports = [];
  List<dynamic> _filteredReports = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      if (widget.role == 'Citizen') {
        final locationStatus = await Permission.location.request();
        if (!locationStatus.isGranted) {
          throw Exception("Location permission is required to find nearby reports.");
        }
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final reports = await ApiService().listReports(
        token: authProvider.token!,
        role: authProvider.user!.role,
      );
      _allReports = reports;
      _applyFilter();
    } catch (e) {
      if(mounted) {
        setState(() {
          _error = e.toString().replaceFirst("Exception: ", "");
        });
      }
    } finally {
      if(mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilter() {
    if (_filterStatus == 'All') {
      _filteredReports = List.from(_allReports);
    } else if (_filterStatus == 'Verified') {
      _filteredReports = _allReports.where((report) => report['status'] == 'Verified').toList();
    } else if (_filterStatus == 'Pending') {
      _filteredReports = _allReports.where((report) {
        return report['status'] == 'Pending' || report['status'] == 'Needs Verification';
      }).toList();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_error.isNotEmpty) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error: $_error\n\nPull down to try again.', textAlign: TextAlign.center),
        ),
      );
    } else if (_filteredReports.isEmpty) {
      content = Center(
        child: Text(
          'No reports available for this filter.',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
        ),
      );
    } else {
      content = ListView.builder(
        itemCount: _filteredReports.length,
        itemBuilder: (context, index) {
          final report = _filteredReports[index];
          final status = report['status'] ?? 'Unknown';
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Icon(
                status == 'Verified' ? Icons.verified_user_outlined :
                status == 'Needs Verification' ? Icons.error_outline : Icons.hourglass_empty_outlined,
                color: status == 'Verified' ? Colors.green :
                status == 'Needs Verification' ? Colors.redAccent : Colors.orangeAccent,
              ),
              title: Text(report['text'], maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text('Status: $status'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                final result = await Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => ReportDetailScreen(report: report),
                ));
                if (result == true) {
                  _fetchReports();
                }
              },
            ),
          );
        },
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SegmentedButton<String>(
            segments: const <ButtonSegment<String>>[
              ButtonSegment<String>(value: 'All', label: Text('All'), icon: Icon(Icons.list)),
              ButtonSegment<String>(value: 'Verified', label: Text('Verified'), icon: Icon(Icons.check_circle_outline)),
              ButtonSegment<String>(value: 'Pending', label: Text('Pending'), icon: Icon(Icons.hourglass_top_outlined)),
            ],
            selected: <String>{_filterStatus},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                _filterStatus = newSelection.first;
                _applyFilter();
              });
            },
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchReports,
            child: content,
          ),
        ),
      ],
    );
  }
}