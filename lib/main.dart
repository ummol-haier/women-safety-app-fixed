import 'package:ally/theme/colors.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'database/user_db.dart';
import 'database/guardian_db.dart';
import 'screens/role_selection_screen.dart';
import 'screens/user/user_home_screen.dart';
import 'screens/guardian/guardian_home_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _getInitialScreen() async {
    final user = await UserDB.getLoggedInUser();
    if (user != null) {
      return const UserHomeScreen();
    }
    final guardian = await GuardianDB.getLoggedInGuardian();
    if (guardian != null) {
      return const GuardianHomeScreen();
    }
    return const RoleSelectionScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Women Safety App',
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: AppColors.primary,
          secondary: AppColors.accent,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(
            color: AppColors.text,
            fontSize: 16,
          ),
          bodyMedium: TextStyle(
            color: AppColors.text,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.button,
            foregroundColor: AppColors.buttonText,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<Widget>(
        future: _getInitialScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator()); // Show loading indicator
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: \\${snapshot.error}'), // Show error message
            );
          } else if (snapshot.hasData) {
            return snapshot.data!; // Proceed to the main app
          } else {
            return const Center(
              child: Text('Unexpected error occurred'), // Fallback for unexpected cases
            );
          }
        },
      ),
    );
  }
}
