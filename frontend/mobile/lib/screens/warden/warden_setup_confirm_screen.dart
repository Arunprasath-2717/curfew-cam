import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/input_field.dart';
import '../../widgets/primary_button.dart';
import '../../providers/auth_service.dart';
import '../auth/login_screen.dart';

class WardenSetupConfirmScreen extends StatefulWidget {
  const WardenSetupConfirmScreen({super.key});

  @override
  State<WardenSetupConfirmScreen> createState() => _WardenSetupConfirmScreenState();
}

class _WardenSetupConfirmScreenState extends State<WardenSetupConfirmScreen> {
  String _password = '';
  String _confirmPassword = '';
  bool _isLoading = false;
  bool _isSuccess = false;
  String? _errorMessage;
  
  Color _getStrengthColor() {
    if (_password.isEmpty) return Theme.of(context).dividerColor;
    if (_password.length < 6) return Theme.of(context).colorScheme.error;
    if (_password.length < 8) return Theme.of(context).colorScheme.secondary;
    return const Color(0xFF22C55E);
  }
  
  String _getStrengthText() {
    if (_password.isEmpty) return '';
    if (_password.length < 6) return 'WEAK';
    if (_password.length < 8) return 'MODERATE';
    return 'STRONG';
  }
  
  double _getStrengthWidth() {
    if (_password.isEmpty) return 0;
    if (_password.length < 6) return 0.33;
    if (_password.length < 8) return 0.66;
    return 1.0;
  }

  Future<void> _handleReset() async {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (args == null || args['sessionToken'] == null || args['code'] == null) {
      setState(() => _errorMessage = 'Invalid session data');
      return;
    }

    if (_password.length < 8) {
      setState(() => _errorMessage = 'Password must be at least 8 characters');
      return;
    }
    
    if (_password != _confirmPassword) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await AuthService.wardenSetupConfirm(args['sessionToken'], args['code'], _password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response['success'] == true) {
      setState(() => _isSuccess = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 400),
            ),
            (route) => false,
          );
        }
      });
    } else {
      setState(() => _errorMessage = response['message'] ?? 'Failed to reset password');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text('CurfewCam', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(icon: Icon(Icons.help_outline), onPressed: () {}),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isSuccess 
            ? Center(
                key: const ValueKey('success'),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 96, height: 96,
                      decoration: BoxDecoration(color: const Color(0xFF22C55E).withOpacity(0.1), shape: BoxShape.circle),
                      child: Icon(Icons.check_circle, size: 64, color: const Color(0xFF22C55E)),
                    ),
                    const SizedBox(height: 24),
                    Text('Setup Complete!', style: AppTextStyles.screenTitle.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            : SingleChildScrollView(
                key: const ValueKey('form'),
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
                child: Column(
                  children: [
              Container(
                padding: EdgeInsets.all(32),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: Theme.of(context).dividerColor)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Set Password', style: AppTextStyles.screenTitle),
                    const SizedBox(height: 8),
                    Text('Your identity has been verified. Please set a secure password to access your Warden account.', style: AppTextStyles.bodySecondary.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
                    const SizedBox(height: 24),
                    
                    if (_errorMessage != null)
                      Padding(
                        padding: EdgeInsets.only(bottom: 16.0),
                        child: Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ),

                    InputField(
                      label: 'Set Password',
                      hintText: 'Enter new password',
                      isPassword: true,
                      onChanged: (val) => setState(() => _password = val),
                    ),
                    const SizedBox(height: 8),
                    // Strength Indicator
                    if (_password.isNotEmpty) ...[
                      Stack(
                        children: [
                          Container(height: 6, width: double.infinity, decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(3))),
                          FractionallySizedBox(
                            widthFactor: _getStrengthWidth(),
                            child: Container(height: 6, decoration: BoxDecoration(color: _getStrengthColor(), borderRadius: BorderRadius.circular(3))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_getStrengthText(), style: AppTextStyles.badgeCaps.copyWith(color: _getStrengthColor())),
                          Text('8+ characters', style: AppTextStyles.badgeCaps.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    InputField(
                      label: 'Confirm Password', 
                      hintText: 'Repeat new password', 
                      isPassword: true,
                      onChanged: (val) => setState(() => _confirmPassword = val),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Complete Setup', 
                      icon: Icons.lock_reset, 
                      isLoading: _isLoading,
                      onPressed: _handleReset,
                    ),
                    const SizedBox(height: 16),
                    Center(child: TextButton(onPressed: () => Navigator.pushReplacementNamed(context, '/login'), child: Text('Cancel and return to login', style: AppTextStyles.bodySecondary.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey), decoration: TextDecoration.underline)))),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.verified_user, size: 18, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)),
                const SizedBox(width: 8),
                Text('END-TO-END ENCRYPTED SESSION', style: AppTextStyles.badgeCaps.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey), letterSpacing: 2)),
              ]),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

