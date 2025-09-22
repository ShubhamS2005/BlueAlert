import 'dart:async';
import 'dart:io';
import 'package:bluealert/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bluealert/constants/app_constants.dart';

class LoginWidget extends StatefulWidget {
  final VoidCallback onSwitchToSignup;
  const LoginWidget({super.key, required this.onSwitchToSignup});

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordHidden = true;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);

    try {
      await Provider.of<AuthProvider>(context, listen: false).login(
        _emailController.text,
        _passwordController.text,
      );
    } catch (error) {
      if (mounted) {
        // --- FIX: Improved Error Handling ---
        String errorMessage = "An unknown error occurred.";
        if (error is TimeoutException) {
          errorMessage = "The connection timed out. Please check your internet and try again.";
        } else if (error is SocketException) {
          errorMessage = "No internet connection. Please check your network.";
        } else {
          errorMessage = error.toString().replaceFirst("Exception: ", "");
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
        // --- END FIX ---
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            decoration: kDefaultInputDecoration(hintText: 'Email', icon: Icons.email_outlined),
            keyboardType: TextInputType.emailAddress,
            validator: (v) => (v == null || !v.contains('@')) ? 'Please enter a valid email' : null,
          ),
          const SizedBox(height: kDefaultPadding),
          TextFormField(
            controller: _passwordController,
            obscureText: _isPasswordHidden,
            decoration: kDefaultInputDecoration(hintText: 'Password', icon: Icons.lock_outline).copyWith(
              suffixIcon: IconButton(
                icon: Icon(_isPasswordHidden ? Icons.visibility_off : Icons.visibility, color: kPrimaryColor),
                onPressed: () => setState(() => _isPasswordHidden = !_isPasswordHidden),
              ),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Please enter your password' : null,
          ),
          const SizedBox(height: kDefaultPadding * 2),
          if (_isLoading)
            const CircularProgressIndicator()
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kDefaultBorderRadius)),
                ),
                child: const Text('Login', style: kButtonTextStyle),
              ),
            ),
        ],
      ),
    );
  }
}