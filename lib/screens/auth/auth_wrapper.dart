import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/auth_service.dart';
import '../main_navigation_screen.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Checking connection state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.scaffoldBg,
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          );
        }

        // If authenticated -> MainNavigationScreen (Home, Saved, Add, Profile)
        if (snapshot.hasData && snapshot.data != null) {
          return const MainNavigationScreen();
        }

        // If not authenticated -> LoginScreen
        return const LoginScreen();
      },
    );
  }
}
