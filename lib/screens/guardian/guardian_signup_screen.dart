import 'package:flutter/material.dart';
import 'guardian_home_screen.dart';
import '../../database/guardian_db.dart';

class GuardianSignupScreen extends StatefulWidget {
  const GuardianSignupScreen({super.key});

  @override
  State<GuardianSignupScreen> createState() => _GuardianSignupScreenState();
}

class _GuardianSignupScreenState extends State<GuardianSignupScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedGender;
  final _formKey = GlobalKey<FormState>();

  String normalizePhone(String phone) {
    String p = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (p.startsWith('0')) {
      p = '+88' + p.substring(1);
    } else if (!p.startsWith('+88')) {
      p = '+88' + p;
    }
    return p;
  }

  void _signup() async {
    print('Signup button pressed');
    final name = _nameController.text.trim();
    final phone = normalizePhone(_phoneController.text.trim());
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    print('Guardian signup phone (normalized): ' + phone);
    if (name.isEmpty || phone.isEmpty || email.isEmpty || password.isEmpty || _selectedGender == null) {
      print('Validation failed');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select gender')),
      );
      return;
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      print('Email validation failed');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }
    // Save to DB
    final guardian = Guardian(
      userName: name,
      userPhone: phone,
      note: '',
      isPrimary: false,
      isBlocked: false,
      email: email,
      password: password,
      isLoggedIn: true,
    );
    try {
      final id = await GuardianDB.insertGuardian(guardian);
      print('Guardian inserted with id: ' + id.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signup successful!')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const GuardianHomeScreen(),
        ),
      );
    } catch (e) {
      print('DB insert error: ' + e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup failed: ' + e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guardian Signup')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                items: const [
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedGender = val;
                  });
                },
                decoration: const InputDecoration(labelText: 'Gender'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _signup,
                child: const Text('Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
