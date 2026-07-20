import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/primary_button.dart';

class ForgotSuccessScreen extends StatelessWidget {
  const ForgotSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text('CurfewCam', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(icon: Icon(Icons.notifications), onPressed: () {}),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(32),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: Theme.of(context).dividerColor)),
                child: Column(
                  children: [
                    Container(
                      width: 96, height: 96,
                      decoration: BoxDecoration(color: const Color(0xFF22C55E).withOpacity(0.1), shape: BoxShape.circle),
                      child: Icon(Icons.check_circle, size: 64, color: const Color(0xFF22C55E)),
                    ),
                    const SizedBox(height: 24),
                    Text('Password Updated!', style: AppTextStyles.screenTitle.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Login with your new password to access CurfewCam.', style: AppTextStyles.bodyMain.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)), textAlign: TextAlign.center),
                    const SizedBox(height: 32),
                    PrimaryButton(label: 'Back to Login', onPressed: () => Navigator.pushReplacementNamed(context, '/login')),
                    const SizedBox(height: 16),
                    Text('Securely managed by CurfewCam Protocol', style: AppTextStyles.bodySecondary.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.verified_user, size: 18, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)),
                const SizedBox(width: 8),
                Text('END-TO-END ENCRYPTED', style: AppTextStyles.badgeCaps.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey), letterSpacing: 2)),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
