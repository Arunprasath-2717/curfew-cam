import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Stack(
        children: [
          // Background blobs
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.02),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.02),
              ),
            ),
          ),
          
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.security,
                    size: 48,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'CurfewCam',
                  style: AppTextStyles.screenTitle.copyWith(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Smart Hostel Outpass Management',
                  style: AppTextStyles.bodySecondary.copyWith(
                    color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          
          Positioned(
            bottom: 64,
            left: 0,
            right: 0,
            child: Column(
              children: [
                SizedBox(
                  width: 140,
                  child: LinearProgressIndicator(
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).scaffoldBackgroundColor),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'INITIALIZING SYSTEM',
                  style: AppTextStyles.badgeCaps.copyWith(
                    color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
