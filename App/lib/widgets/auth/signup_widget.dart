import 'dart:io'; // Import for File
import 'package:bluealert/providers/auth_provider.dart';
import 'package:bluealert/screens/auth/verify_email_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:bluealert/constants/app_constants.dart';
import 'package:image_picker/image_picker.dart'; // Import for ImagePicker

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
  String _selectedRole = 'Citizen';
  bool _isLoading = false;
  File? _avatarFile; // State variable to hold the selected image file

  // --- Function to show detailed error dialog ---
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('An Error Occurred'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  // --- Function to pick an image from the gallery ---
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // Compress image to reduce size
    );

    if (pickedFile != null) {
      setState(() {
        _avatarFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
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
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const VerifyEmailScreen()));
    } catch (error) {
      // This will now show the specific error message from the backend
      String errorMessage = error.toString();
      if (errorMessage.startsWith("Exception: ")) {
        errorMessage = errorMessage.substring(11); // Clean up the error message
      }
      _showErrorDialog(errorMessage);
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
          // --- NEW: Avatar Picker UI ---
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage: _avatarFile != null
                    ? FileImage(_avatarFile!)
                    : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                backgroundColor: kLightColor,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
                  onTap: _pickImage,
                  child: const CircleAvatar(
                    radius: 20,
                    backgroundColor: kPrimaryColor,
                    child: Icon(Icons.edit, color: Colors.white, size: 20),
                  ),
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
          TextFormField(controller: _passwordController, decoration: kDefaultInputDecoration(hintText: 'Password'), obscureText: true, validator: (v) => v!.length < 6 ? 'Min 6 characters' : null),
          const SizedBox(height: kDefaultPadding),
          // --- MODIFIED: Added 'Analyst' role ---
          DropdownButtonFormField<String>(
            value: _selectedRole,
            decoration: kDefaultInputDecoration(hintText: 'Register as'),
            items: ['Citizen', 'Analyst'].map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
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
                style: ElevatedButton.styleFrom(backgroundColor: kSecondaryColor, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kDefaultBorderRadius))),
                child: const Text('Create Account', style: kButtonTextStyle),
              ),
            ),
        ],
      ),
    );
  }
}