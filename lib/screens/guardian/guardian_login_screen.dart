import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_textfield.dart';
import 'guardian_home_screen.dart';
import 'guardian_signup_screen.dart';
import '../../database/guardian_db.dart';

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
              onPressed: () async {
                final guardianPhone = phoneController.text.trim();
                final password = passwordController.text.trim();
                if (guardianPhone.isEmpty || password.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter both phone number and password.')),
                  );
                  return;
                }
                // Validate guardian credentials
                final guardian = await GuardianDB.checkGuardianLogin(guardianPhone, password);
                if (guardian != null) {
                  // Set logged in
                  await GuardianDB.setLoggedIn(guardian.id!);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('guardianPhone', guardianPhone);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const GuardianHomeScreen()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid phone number or password.')),
                  );
                }
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
