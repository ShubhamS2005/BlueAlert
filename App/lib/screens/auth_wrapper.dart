import 'package:bluealert/providers/auth_provider.dart';
import 'package:bluealert/screens/auth/auth_screen.dart';
import 'package:bluealert/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Use a Consumer widget. This is the most reliable way to listen for
    // changes from a Provider. When authProvider.notifyListeners() is called,
    // only this part of the widget tree will rebuild.
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // The logic is simple: if the user is authenticated, show the HomeScreen.
        if (authProvider.isAuthenticated) {
          return const HomeScreen();
        }
        // Otherwise, show the AuthScreen (for login/signup).
        else {
          return const AuthScreen();
        }
      },
    );
  }
}