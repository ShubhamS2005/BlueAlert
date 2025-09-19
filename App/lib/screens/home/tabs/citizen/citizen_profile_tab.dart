import 'package:bluealert/providers/auth_provider.dart';
import 'package:bluealert/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CitizenProfileTab extends StatelessWidget {
  const CitizenProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(user?.avatarUrl ?? ''),
            backgroundColor: Colors.grey.shade200,
          ),
          const SizedBox(height: 16),
          Text(
            '${user?.firstname ?? ''} ${user?.lastname ?? ''}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(user?.email ?? '', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Chip(
            label: Text(user?.role ?? ''),
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          ),
          const Divider(height: 40),

          // Dark Mode Toggle
          ListTile(
            leading: Icon(themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode),
            title: const Text('Dark Mode'),
            trailing: Switch(
              value: themeProvider.isDarkMode,
              onChanged: (value) {
                themeProvider.toggleTheme(value);
              },
            ),
          ),

          // Sign Out Button
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
          )
        ],
      ),
    );
  }
}