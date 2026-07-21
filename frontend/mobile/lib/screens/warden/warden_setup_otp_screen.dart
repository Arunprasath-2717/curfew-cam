import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/primary_button.dart';
import '../../providers/auth_service.dart';

class WardenSetupOtpScreen extends StatefulWidget {
  const WardenSetupOtpScreen({super.key});

  @override
  State<WardenSetupOtpScreen> createState() => _WardenSetupOtpScreenState();
}

class _WardenSetupOtpScreenState extends State<WardenSetupOtpScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _handleVerify() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null || args['email'] == null || args['sessionToken'] == null) {
      setState(() => _errorMessage = 'Invalid session. Please restart setup.');
      return;
    }

    final code = _controllers.map((c) => c.text).join();
    if (code.length < 6) {
      setState(() => _errorMessage = 'Please enter the 6-digit code');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await AuthService.wardenSetupVerifyOtp(args['sessionToken'], code);
      if (!mounted) return;

      if (res['success'] == true) {
        Navigator.pushReplacementNamed(
          context, 
          '/warden-setup-confirm',
          arguments: {
            'email': args['email'], 
            'sessionToken': args['sessionToken'],
            'code': code,
          },
        );
      } else {
        setState(() => _errorMessage = res['error'] ?? res['message'] ?? 'Invalid OTP');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final email = args?['email'] as String? ?? 'your email';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text('CurfewCam', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
          child: Column(
            children: [
              // Header Image
              Container(
                height: 192, width: double.infinity,
                decoration: BoxDecoration(color: Theme.of(context).primaryColor, borderRadius: BorderRadius.circular(24)),
                alignment: Alignment.center,
                child: Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                  child: Icon(Icons.verified_user, color: Theme.of(context).scaffoldBackgroundColor, size: 36),
                ),
              ),
              const SizedBox(height: 32),
              
              Container(
                padding: EdgeInsets.all(32),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: Theme.of(context).dividerColor)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Enter Setup Code', style: AppTextStyles.screenTitle),
                    const SizedBox(height: 8),
                    Text.rich(TextSpan(text: 'Sent to ', style: AppTextStyles.bodySecondary.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)), children: [
                      TextSpan(text: email, style: AppTextStyles.bodySecondary.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                    ])),
                    const SizedBox(height: 24),
                    
                    if (_errorMessage != null)
                      Padding(
                        padding: EdgeInsets.only(bottom: 16.0),
                        child: Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) {
                        return SizedBox(
                          width: 40, height: 56,
                          child: TextField(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            onChanged: (value) => _onChanged(value, index),
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: Theme.of(context).scaffoldBackgroundColor,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2)),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Verify', 
                      isLoading: _isLoading,
                      onPressed: _handleVerify,
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        Text('Didn\'t receive the code?', style: AppTextStyles.bodySecondary.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
                        TextButton(
                          onPressed: () async {
                            await AuthService.wardenSetupRequest(email);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Setup code resent!')));
                            }
                          }, 
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Text('Resend Code', style: AppTextStyles.bodyMain.copyWith(fontWeight: FontWeight.bold, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
                          ])
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.support_agent, size: 18, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)),
                const SizedBox(width: 4),
                Text('Contact Support', style: AppTextStyles.bodySecondary.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

