import 'package:flutter/material.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_textfield.dart';
import 'user_home_screen.dart';
import 'user_signup_screen.dart';
import '../../../database/user_db.dart';

class UserLoginScreen extends StatelessWidget {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

   UserLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("User Login")),
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
                final users = await UserDB.getUsers();
                User? user;
                for (final u in users) {
                  if (u.phone == phoneController.text.trim()) {
                    user = u;
                    break;
                  }
                }
                if (user != null) {
                  await UserDB.setLoggedIn(user.id!);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const UserHomeScreen()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid credentials')),
                  );
                }
              },
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserSignupScreen()),
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
