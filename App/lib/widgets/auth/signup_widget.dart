import 'dart:async';
import 'dart:io';
import 'package:bluealert/providers/auth_provider.dart';
import 'package:bluealert/screens/auth/verify_email_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:bluealert/constants/app_constants.dart';
import 'package:image_picker/image_picker.dart';

class SignupWidget extends StatefulWidget {
  final VoidCallback onSwitchToLogin;
  const SignupWidget({super.key, required this.onSwitchToLogin});

  @override
  State<SignupWidget> createState() => _SignupWidgetState();
}

class _SignupWidgetState extends State<SignupWidget> {
  final _formKey = GlobalKey<FormState>();
  final _fnameController = TextEditingController();
  final _lnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedRole = 'Citizen';
  bool _isLoading = false;
  File? _avatarFile;
  bool _isPasswordHidden = true;
  bool _isConfirmPasswordHidden = true;

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registration Failed'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('Okay'),
            onPressed: () => Navigator.of(ctx).pop(),
          )
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      setState(() {
        _avatarFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) { return; }
    if (_avatarFile == null) {
      _showErrorDialog('Please select an avatar image.');
      return;
    }
    setState(() => _isLoading = true);

    try {
      await Provider.of<AuthProvider>(context, listen: false).register(
        firstname: _fnameController.text,
        lastname: _lnameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        password: _passwordController.text,
        role: _selectedRole,
        avatarFile: _avatarFile!,
      );
      if(mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const VerifyEmailScreen()));
      }
    } catch (error) {
      String errorMessage = "An unknown error occurred.";
      if (error is TimeoutException) {
        errorMessage = "The connection timed out. Please check your internet and try again.";
      } else if (error is SocketException) {
        errorMessage = "No internet connection. Please check your network.";
      } else {
        errorMessage = error.toString().replaceFirst("Exception: ", "");
      }
      _showErrorDialog(errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _fnameController.dispose();
    _lnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage: _avatarFile != null ? FileImage(_avatarFile!) : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                backgroundColor: kLightColor,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
                  onTap: _pickImage,
                  child: const CircleAvatar(radius: 20, backgroundColor: kPrimaryColor, child: Icon(Icons.edit, color: Colors.white, size: 20)),
                ),
              ),
            ],
          ),
          const SizedBox(height: kDefaultPadding),
          TextFormField(controller: _fnameController, decoration: kDefaultInputDecoration(hintText: 'First Name'), validator: (v) => v!.isEmpty ? 'Required' : null),
          const SizedBox(height: kDefaultPadding),
          TextFormField(controller: _lnameController, decoration: kDefaultInputDecoration(hintText: 'Last Name'), validator: (v) => v!.isEmpty ? 'Required' : null),
          const SizedBox(height: kDefaultPadding),
          TextFormField(controller: _emailController, decoration: kDefaultInputDecoration(hintText: 'Email'), keyboardType: TextInputType.emailAddress, validator: (v) => v!.isEmpty || !v.contains('@') ? 'Invalid Email' : null),
          const SizedBox(height: kDefaultPadding),
          TextFormField(controller: _phoneController, decoration: kDefaultInputDecoration(hintText: 'Phone Number'), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: (v) => v!.length != 10 ? 'Must be 10 digits' : null),
          const SizedBox(height: kDefaultPadding),
          TextFormField(
              controller: _passwordController,
              obscureText: _isPasswordHidden,
              decoration: kDefaultInputDecoration(hintText: 'Password').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_isPasswordHidden ? Icons.visibility_off : Icons.visibility, color: kPrimaryColor),
                  onPressed: () => setState(() => _isPasswordHidden = !_isPasswordHidden),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) { return 'Please enter a password'; }
                return null;
              }
          ),
          const SizedBox(height: kDefaultPadding),
          TextFormField(
              controller: _confirmPasswordController,
              obscureText: _isConfirmPasswordHidden,
              decoration: kDefaultInputDecoration(hintText: 'Confirm Password').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_isConfirmPasswordHidden ? Icons.visibility_off : Icons.visibility, color: kPrimaryColor),
                  onPressed: () => setState(() => _isConfirmPasswordHidden = !_isConfirmPasswordHidden),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) { return 'Please confirm your password'; }
                if (value != _passwordController.text) { return 'Passwords do not match'; }
                return null;
              }
          ),
          const SizedBox(height: kDefaultPadding),
          DropdownButtonFormField<String>(
            value: _selectedRole,
            decoration: kDefaultInputDecoration(hintText: 'Register as'),
            items: ['Citizen', 'Analyst'].map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
            onChanged: (newValue) => setState(() => _selectedRole = newValue!),
          ),
          const SizedBox(height: kDefaultPadding),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("I already have an account."),
              TextButton(onPressed: widget.onSwitchToLogin, child: const Text('Login', style: TextStyle(color: kBlueLinkColor, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: kDefaultPadding),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kDefaultBorderRadius))
                ),
                child: const Text('Create Account', style: kButtonTextStyle),
              ),
            ),
        ],
      ),
    );
  }
}