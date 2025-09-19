import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // This widget is now just for UI.
    // The logic to decide where to navigate is handled in main.dart.
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Your logo
            Image(
              image: AssetImage('assets/images/foreground.png'),
              width: 150,
            ),
            SizedBox(height: 30),
            // A loading indicator to show work is being done
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}