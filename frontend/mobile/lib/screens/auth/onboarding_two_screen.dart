import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class OnboardingTwoScreen extends StatelessWidget {
  const OnboardingTwoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 48.0),
          child: Column(
            children: [
              // Illustration Container
              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          color: Theme.of(context).dividerColor.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                      // Mock UI card
                      Container(
                        width: 240,
                        height: 320,
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: Theme.of(context).dividerColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.vertical(top: Radius.circular(31)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(width: 24, height: 24, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle)),
                                  Text('WARDEN PORTAL', style: AppTextStyles.badgeCaps.copyWith(color: Theme.of(context).scaffoldBackgroundColor, fontSize: 10)),
                                  Icon(Icons.account_circle, color: Theme.of(context).scaffoldBackgroundColor, size: 20),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  _buildMockItem(context, const Color(0xFF22C55E), Icons.check),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Theme.of(context).primaryColor, width: 2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(width: 32, height: 32, decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary, shape: BoxShape.circle)),
                                        const SizedBox(width: 12),
                                        Expanded(child: Container(height: 8, color: Theme.of(context).primaryColor)),
                                        const SizedBox(width: 12),
                                        Container(width: 28, height: 28, decoration: BoxDecoration(color: Theme.of(context).colorScheme.error, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.close, color: Colors.white, size: 16)),
                                        const SizedBox(width: 4),
                                        Container(width: 32, height: 28, decoration: BoxDecoration(color: Theme.of(context).primaryColor, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.touch_app, color: Colors.white, size: 16)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildMockItem(context, Colors.transparent, null),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 20,
                        right: 20,
                        child: Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary, borderRadius: BorderRadius.circular(16)),
                          child: Icon(Icons.verified, color: Colors.white, size: 32),
                        ),
                      ),
                      Positioned(
                        bottom: 40,
                        left: 10,
                        child: Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(color: const Color(0xFF22C55E), shape: BoxShape.circle),
                          child: Icon(Icons.bolt, color: Colors.white, size: 28),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              Text(
                'Wardens Approve in One Tap',
                style: AppTextStyles.screenTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Streamlined workflows for staff to review, track, and manage student movements with enterprise-grade efficiency.',
                  style: AppTextStyles.bodyMain.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 32),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: Theme.of(context).dividerColor, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Container(width: 24, height: 8, decoration: BoxDecoration(color: Theme.of(context).primaryColor, borderRadius: BorderRadius.circular(4))),
                ],
              ),
              
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('onboardingCompleted', true);
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Continue'),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              TextButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('onboardingCompleted', true);
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                  }
                },
                child: Text(
                  'Skip to Dashboard',
                  style: AppTextStyles.bodyMain.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMockItem(BuildContext context, Color actionColor, IconData? icon) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 8, color: Theme.of(context).primaryColor.withOpacity(0.2))),
          const SizedBox(width: 12),
          if (icon != null)
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: actionColor, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 16),
            ),
        ],
      ),
    );
  }
}
