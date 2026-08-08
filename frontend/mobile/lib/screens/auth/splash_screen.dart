import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _rotateAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _irisAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500));

    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.4, curve: Curves.elasticOut)),
    );
    _rotateAnim = Tween<double>(begin: -0.5, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.3, 0.6, curve: Curves.easeIn)),
    );
    
    // Iris out effect (expanding circle)
    _irisAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.7, 1.0, curve: Curves.easeInExpo)),
    );

    _ctrl.forward().then((_) {
      // Loop the logo pulse if needed, but for now we hold the final state
      // Actually, if we hold the final state the screen will be fully covered by the iris.
      // Since it's a splash, covering it in the app's background color is a perfect transition.
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Background blobs
              Positioned(
                top: -50, left: -50,
                child: Container(
                  width: 300, height: 300,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.02)),
                ),
              ),
              Positioned(
                bottom: -50, right: -50,
                child: Container(
                  width: 300, height: 300,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.02)),
                ),
              ),
              
              // Logo & Text
              Opacity(
                opacity: _irisAnim.value > 0.3 ? (1.0 - (_irisAnim.value * 2).clamp(0.0, 1.0)) : _fadeAnim.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform.rotate(
                      angle: _rotateAnim.value * math.pi,
                      child: Transform.scale(
                        scale: _scaleAnim.value,
                        child: Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
                            ],
                          ),
                          child: Icon(Icons.security, size: 48, color: Theme.of(context).primaryColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'CurfewCam',
                      style: AppTextStyles.screenTitle.copyWith(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        fontSize: 32, fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Smart Hostel Outpass Management',
                      style: AppTextStyles.bodySecondary.copyWith(
                        color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Progress Bar
              Positioned(
                bottom: 64, left: 0, right: 0,
                child: Opacity(
                  opacity: _irisAnim.value > 0.1 ? 0.0 : _fadeAnim.value,
                  child: Column(
                    children: [
                      SizedBox(
                        width: 140,
                        child: LinearProgressIndicator(
                          backgroundColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).scaffoldBackgroundColor),
                          minHeight: 4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'INITIALIZING SYSTEM',
                        style: AppTextStyles.badgeCaps.copyWith(color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.4)),
                      ),
                    ],
                  ),
                ),
              ),

              // Iris Out Effect (Centered)
              if (_irisAnim.value > 0)
                Transform.scale(
                  scale: _irisAnim.value * 25, // expand to cover the whole screen
                  child: Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).scaffoldBackgroundColor,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
