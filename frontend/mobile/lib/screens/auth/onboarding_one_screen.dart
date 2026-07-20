import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class OnboardingOneScreen extends StatelessWidget {
  const OnboardingOneScreen({super.key});

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
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 320),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Theme.of(context).dividerColor, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Image.network(
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuDy7GIbmnr0cgXDiTuxn1tgCePtE9pNaS8BsM2NfKYGhMTRKuKIVI6IzXzhrszsCTLMDw6XBdTG8Z3ZFYRU5_7CDXwPvO3dxAttbBJahWRMOUJuh9iF2K3MROhcHy-uHTTsvCU2LP8NvjwPYZKFn6xewXPNjTQqoeLFhSeQmNZCJnxFG2w9L9_LDrJqA-aMPQHD7EnML3_lfiaWxZouwp5VuZ79QLACLyl2S-JzZn3zWGbd-_na1TAvxIto2IKebnlcaAYBJZ9MZWw',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                        Positioned(
                          top: 24,
                          right: 24,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: Theme.of(context).scaffoldBackgroundColor, size: 16),
                                const SizedBox(width: 8),
                                Text('VERIFIED', style: AppTextStyles.badgeCaps.copyWith(color: Theme.of(context).scaffoldBackgroundColor)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Text Content
              Text(
                'Request Outpass Instantly',
                style: AppTextStyles.screenTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Submit your requests in seconds. No more long queues or manual registers at the warden office.',
                  style: AppTextStyles.bodyMain.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Indicators & Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 24, height: 8, decoration: BoxDecoration(color: Theme.of(context).primaryColor, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(width: 8),
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: Theme.of(context).dividerColor, shape: BoxShape.circle)),
                ],
              ),
              
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/onboarding2'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Next'),
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
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
                child: Text(
                  'SKIP',
                  style: AppTextStyles.bodySecondary.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
