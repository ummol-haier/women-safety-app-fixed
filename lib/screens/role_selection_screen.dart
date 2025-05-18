import 'package:flutter/material.dart';
import 'user/user_login_screen.dart';
import 'guardian/guardian_login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  void navigateToUserLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UserLoginScreen()),
    );
  }

  void navigateToGuardianLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GuardianLoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Role')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Who are you?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => navigateToUserLogin(context),
              icon: const Icon(Icons.person),
              label: const Text('I am a User'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => navigateToGuardianLogin(context),
              icon: const Icon(Icons.security),
              label: const Text('I am a Guardian'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
