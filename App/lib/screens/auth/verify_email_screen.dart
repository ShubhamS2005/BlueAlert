import 'package:bluealert/screens/auth/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:bluealert/constants/app_constants.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(kDefaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_read_outlined, size: 100, color: kPrimaryColor),
            const SizedBox(height: 30),
            const Text(
              'Verify Your Email',
              style: kHeadlineTextStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            Text(
              'Your account has been successfully created. We have sent a verification link to your email address. Please check your inbox and follow the link to activate your account.',
              style: kSubheadlineTextStyle.copyWith(height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                        (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kSecondaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kDefaultBorderRadius)),
                ),
                child: const Text('Back to Login', style: kButtonTextStyle),
              ),
            )
          ],
        ),
      ),
    );
  }
}