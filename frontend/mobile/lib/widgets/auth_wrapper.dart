import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/onboarding_one_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/student/dashboard_screen.dart';
import '../screens/warden/warden_dashboard_screen.dart';
import '../screens/watchman/watchman_dashboard_screen.dart';

/// Root widget that reactively renders the correct screen based on auth state.
/// Works like Firebase's `StreamBuilder(stream: authStateChanges())`.
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _checkedOnboarding = false;
  bool _needsOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkOnboardingAndInit();
  }

  Future<void> _checkOnboardingAndInit() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool('onboardingCompleted') ?? false;
    if (mounted) {
      setState(() {
        _checkedOnboarding = true;
        _needsOnboarding = !completed;
      });
    }

    // Kick off the auth check
    if (!_needsOnboarding) {
      if (!mounted) return;
      // Only initialize auth after onboarding is done
      final authProvider = context.read<AuthProvider>();
      await authProvider.initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Still checking onboarding preference
    if (!_checkedOnboarding) {
      return const SplashScreen();
    }

    // Needs onboarding first
    if (_needsOnboarding) {
      return const OnboardingOneScreen();
    }

    // Listen to auth state reactively
    final authStatus = context.watch<AuthProvider>().status;
    final authProvider = context.read<AuthProvider>();

    switch (authStatus) {
      case AuthStatus.initial:
        return const SplashScreen();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
      case AuthStatus.authenticated:
        switch (authProvider.userRole) {
          case 'warden':
          case 'admin_warden':
            return const WardenDashboardScreen();
          case 'watchman':
            return const WatchmanDashboardScreen();
          case 'student':
          default:
            return const StudentDashboardScreen();
        }
    }
  }
}
