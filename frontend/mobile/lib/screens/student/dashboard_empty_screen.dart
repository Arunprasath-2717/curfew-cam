import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_bar_widget.dart';
import '../../widgets/bottom_nav_student.dart';
import '../../widgets/primary_button.dart';

class DashboardEmptyScreen extends StatefulWidget {
  const DashboardEmptyScreen({super.key});

  @override
  State<DashboardEmptyScreen> createState() => _DashboardEmptyScreenState();
}

class _DashboardEmptyScreenState extends State<DashboardEmptyScreen> {
  int _currentIndex = 0;

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
    if (index == 1) {
      Navigator.pushNamed(context, '/request-step1');
      setState(() => _currentIndex = 0);
    } else if (index == 2) {
      Navigator.pushNamed(context, '/history');
      setState(() => _currentIndex = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBarWidget(
        title: 'CurfewCam',
        showBackButton: true,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Illustration Layer
              SizedBox(
                width: double.infinity,
                height: 280,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background blur
                    Container(
                      width: 250, height: 250,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.05), blurRadius: 40, spreadRadius: 20),
                        ],
                      ),
                    ),
                    
                    // Box
                    Container(
                      width: 192, height: 192,
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        border: Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_2, size: 64, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey).withOpacity(0.3)),
                          const SizedBox(height: 16),
                          Container(height: 6, width: 96, decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(3))),
                          const SizedBox(height: 8),
                          Container(height: 6, width: 64, decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(3))),
                        ],
                      ),
                    ),
                    
                    // Avatar image overlay
                    Positioned(
                      bottom: 0, right: 40,
                      child: SizedBox(
                        width: 128, height: 128,
                        child: Image.network(
                          'https://lh3.googleusercontent.com/aida-public/AB6AXuDP9_fBnujBJxt6dLO5h2empBFOg-w6ABJJnTmHnyz0zqzPcBfAW72o6mEz3KL-s9gJ1g3GnPb1WtAWXsEqIlvYGAdJfpXK1FsXXnyqBdC4W6BJor-uglbSWnz27kiDN8-FzEaI7Sbve60TCFH2TKz_hMzAH0IO9CLw5LQl51EVnQobkG0GITlc83fZ7fDbweBSdDtTjb9K2TC9v4FqOakXagBhutHT81ZkF3y9h4HpwV68C9CxQB_W9g7K3twUZ-Y4CSqm4A8FqF4',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    
                    // Floating icons
                    Positioned(
                      top: 10, right: 30,
                      child: Icon(Icons.lock_open, color: Theme.of(context).colorScheme.secondary, size: 36),
                    ),
                    Positioned(
                      bottom: 20, left: 20,
                      child: Icon(Icons.verified_user, color: Theme.of(context).primaryColor.withOpacity(0.2), size: 48),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              
              Text('No Active Outpass', style: AppTextStyles.sectionHeader),
              const SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Request a new outpass to get started with your next off-campus visit. Your warden will review it shortly.',
                  style: AppTextStyles.bodySecondary.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),
              
              PrimaryButton(
                label: 'Request Outpass',
                icon: Icons.add_circle,
                onPressed: () => Navigator.pushNamed(context, '/request-step1'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavStudent(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
