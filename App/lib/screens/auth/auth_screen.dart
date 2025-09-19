import 'package:bluealert/widgets/auth/login_widget.dart';
import 'package:bluealert/widgets/auth/signup_widget.dart';
import 'package:flutter/material.dart';
import 'package:bluealert/constants/app_constants.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoginView = true;

  void toggleView() {
    setState(() {
      _isLoginView = !_isLoginView;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(kDefaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // App Logo
              Image.asset('assets/images/foreground.png', height: 80),
              const SizedBox(height: 40),

              // Toggle Buttons
              _buildAuthToggle(),
              const SizedBox(height: 30),

              // Animated switcher for a smooth transition between Login and Signup
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: _isLoginView
                    ? LoginWidget(onSwitchToSignup: toggleView)
                    : SignupWidget(onSwitchToLogin: toggleView),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthToggle() {
    return Container(
      decoration: BoxDecoration(
        color: kLightColor,
        borderRadius: BorderRadius.circular(kDefaultBorderRadius),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildToggleButton('Login', _isLoginView),
          _buildToggleButton('Sign Up', !_isLoginView),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String text, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if ((text == 'Login' && !_isLoginView) || (text == 'Sign Up' && _isLoginView)) {
            toggleView();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? kPrimaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(kDefaultBorderRadius),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : kSecondaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}