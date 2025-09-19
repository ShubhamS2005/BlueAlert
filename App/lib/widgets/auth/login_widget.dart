import 'package:bluealert/providers/auth_provider.dart';
import 'package:bluealert/screens/auth/forgot_password_screen.dart';
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
  String _selectedRole = 'Citizen';
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
      // Navigation will be handled by the splash/main screen logic
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString()), backgroundColor: Colors.red),
      );
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
          // Role Selector
          DropdownButtonFormField<String>(
            value: _selectedRole,
            decoration: kDefaultInputDecoration(hintText: 'Select Role'),
            items: ['Citizen', 'Analyst', 'Admin'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                _selectedRole = newValue!;
              });
            },
          ),
          const SizedBox(height: kDefaultPadding),

          // Email Field
          TextFormField(
            controller: _emailController,
            decoration: kDefaultInputDecoration(hintText: 'Email', icon: Icons.email_outlined),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || !value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: kDefaultPadding),

          // Password Field
          TextFormField(
            controller: _passwordController,
            obscureText: _isPasswordHidden,
            decoration: kDefaultInputDecoration(hintText: 'Password', icon: Icons.lock_outline).copyWith(
              suffixIcon: IconButton(
                icon: Icon(_isPasswordHidden ? Icons.visibility_off : Icons.visibility, color: kPrimaryColor),
                onPressed: () => setState(() => _isPasswordHidden = !_isPasswordHidden),
              ),
            ),
            validator: (value) {
              if (value == null || value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: kDefaultPadding / 2),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ForgotPasswordScreen())),
              child: const Text('Forgot Password?', style: TextStyle(color: kBlueLinkColor)),
            ),
          ),
          const SizedBox(height: kDefaultPadding),

          // Login Button
          if (_isLoading)
            const CircularProgressIndicator()
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kSecondaryColor,
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