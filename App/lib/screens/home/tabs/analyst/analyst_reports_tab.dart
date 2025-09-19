import 'package:flutter/material.dart';

class AnalystReportsTab extends StatelessWidget {
  const AnalystReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 10, // Placeholder
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.warning_amber_rounded),
            title: Text('Report from Citizen #${index + 1}'),
            subtitle: const Text('Status: Needs Verification\nLocation: 13.08° N, 80.27° E'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () { /* TODO: Implement navigation to detail screen */ },
          ),
        );
      },
    );
  }
}