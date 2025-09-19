import 'package:flutter/material.dart';
import 'package:bluealert/constants/app_constants.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kSecondaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(kDefaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reset Password',
              style: kHeadlineTextStyle,
            ),
            const SizedBox(height: 10),
            const Text(
              'Enter the email or mobile number associated with your account.',
              style: kSubheadlineTextStyle,
            ),
            const SizedBox(height: 30),
            TextFormField(
              decoration: kDefaultInputDecoration(
                hintText: 'Email or Mobile Number',
                icon: Icons.person_outline,
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                // --- MODIFICATION START ---
                // The button now does nothing when pressed.
                onPressed: () {
                  // TODO: Implement password reset logic here in the future.
                  // For now, the button is active but performs no action.
                },
                // --- MODIFICATION END ---
                style: ElevatedButton.styleFrom(
                  backgroundColor: kSecondaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(kDefaultBorderRadius),
                  ),
                ),
                child: const Text('Next', style: kButtonTextStyle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}