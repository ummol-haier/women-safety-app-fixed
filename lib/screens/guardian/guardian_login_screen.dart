import 'package:flutter/material.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_textfield.dart';
import 'guardian_home_screen.dart';
import 'guardian_signup_screen.dart';

class GuardianLoginScreen extends StatelessWidget {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

   GuardianLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Guardian Login")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomTextField(
              controller: phoneController,
              labelText: "Phone Number",
              keyboardType: TextInputType.phone, hintText: '', obscureText: false,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: passwordController,
              labelText: "Password",
              obscureText: true,
              keyboardType: TextInputType.text, hintText: '',
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: "Login",
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const GuardianHomeScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GuardianSignupScreen()),
                );
              },
              child: const Text("Don't have an account? Sign Up"),
            )
          ],
        ),
      ),
    );
  }
}
