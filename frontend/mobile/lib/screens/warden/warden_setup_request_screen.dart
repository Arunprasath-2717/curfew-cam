import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_bar_widget.dart';
import '../../widgets/input_field.dart';
import '../../widgets/primary_button.dart';
import '../../providers/auth_service.dart';

class WardenSetupRequestScreen extends StatefulWidget {
  const WardenSetupRequestScreen({super.key});

  @override
  State<WardenSetupRequestScreen> createState() => _WardenSetupRequestScreenState();
}

class _WardenSetupRequestScreenState extends State<WardenSetupRequestScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final response = await AuthService.wardenSetupRequest(email);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (response['success'] == true) {
      setState(() => _successMessage = response['message']);
      final sessionToken = response['data']?['reset_session'];
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pushNamed(context, '/warden-setup-otp', arguments: {
            'email': email,
            'sessionToken': sessionToken,
          });
        }
      });
    } else {
      setState(() => _errorMessage = response['message'] ?? 'Failed to send OTP');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const AppBarWidget(
        title: '',
        showBackButton: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              
              // Icon anchor
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Icon(Icons.lock_reset, color: Theme.of(context).scaffoldBackgroundColor, size: 24),
              ),
              const SizedBox(height: 24),
              
              // Text Content
              Text(
                'Warden Setup',
                style: AppTextStyles.screenTitle.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your email to receive an onboarding verification code.',
                style: AppTextStyles.bodyMain.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)),
              ),
              
              const SizedBox(height: 32),
              
              // Error Message
              if (_errorMessage != null)
                Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              if (_successMessage != null)
                Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: Text(_successMessage!, style: TextStyle(color: const Color(0xFF22C55E))),
                ),

              // Form
              InputField(
                label: 'Email Address',
                hintText: 'e.g. student@university.edu',
                icon: Icons.mail_outline,
                controller: _emailController,
              ),
              
              const SizedBox(height: 32),
              
              PrimaryButton(
                label: 'Send OTP',
                icon: Icons.arrow_forward,
                isLoading: _isLoading,
                onPressed: _handleSendOtp,
              ),
              
              const Spacer(),
              
              // Footer
              Padding(
                padding: EdgeInsets.only(bottom: 32.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already setup? ',
                      style: AppTextStyles.bodySecondary.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        'Log in',
                        style: AppTextStyles.bodySecondary.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

