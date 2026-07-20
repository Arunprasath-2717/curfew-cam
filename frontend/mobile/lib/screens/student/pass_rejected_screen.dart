import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/primary_button.dart';

class PassRejectedScreen extends StatelessWidget {
  const PassRejectedScreen({super.key});

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
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Status Indicator
              Container(
                width: 96, height: 96,
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.error.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.cancel, size: 64, color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 24),
              Text('REQUEST STATUS', style: AppTextStyles.badgeCaps.copyWith(color: Theme.of(context).colorScheme.error, letterSpacing: 2)),
              const SizedBox(height: 8),
              Text('Request Rejected', style: AppTextStyles.greeting.copyWith(color: Theme.of(context).primaryColor)),
              const SizedBox(height: 8),
              Text('Your outpass request for 12 Oct 2023 was not approved by the Warden.', style: AppTextStyles.bodyMain.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)), textAlign: TextAlign.center),
              const SizedBox(height: 32),
              
              // Detail Card
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: Theme.of(context).dividerColor)),
                child: Column(children: [
                  Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor, shape: BoxShape.circle,
                        image: DecorationImage(image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuB-FFH1dLzOBg71QNLAk4K3BebuS7SXMGVQhZ4GtEnbZWVGL7kJG5p5pn_JWHTaK4JQe6-CCJ4N1B6-_ZLJgEZLQqt8YUqKQkfB6sx8Ki5O_1V0gm0fHC1kfjVoDyYmvfn6MhL3tjwO8VXZoXDD9mY58ZJovaSN4wSC3FJjIc-sUcZk5s6T1IGtuR6XnjB-LIWWMPe_OXTGMFbirWqx9lwD3w6M3q0nTpBvyU0rVw1kDNnBNqgnkdJqJUorzT99zmabGQtg3Megrc8'), fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Chief Warden', style: AppTextStyles.cardTitle.copyWith(fontSize: 14)),
                      Text('Hostel Block A', style: AppTextStyles.bodySecondary.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
                    ]),
                  ]),
                  const SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(12), border: Border(left: BorderSide(color: Theme.of(context).colorScheme.error, width: 4))),
                    child: Text('"Late entry requests for local outings are not allowed on weekdays."', style: AppTextStyles.bodyMain.copyWith(fontStyle: FontStyle.italic)),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Theme.of(context).dividerColor),
                  const SizedBox(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Rejected at 04:30 PM', style: AppTextStyles.bodySecondary.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
                    Row(children: [
                      Icon(Icons.history, size: 18, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)),
                      const SizedBox(width: 4),
                      Text('View Log', style: AppTextStyles.bodySecondary.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
                    ]),
                  ]),
                ]),
              ),
              const SizedBox(height: 32),
              
              PrimaryButton(label: 'Request Again', icon: Icons.refresh, onPressed: () => Navigator.pushReplacementNamed(context, '/request-step1')),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {},
                icon: Icon(Icons.chat),
                label: Text('Contact Warden'),
                style: OutlinedButton.styleFrom(minimumSize: Size(double.infinity, 48), foregroundColor: Theme.of(context).primaryColor, side: BorderSide(color: Theme.of(context).primaryColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              ),
              const SizedBox(height: 32),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.info, size: 16, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)),
                const SizedBox(width: 4),
                Text('Check the Hostel Handbook for curfew guidelines.', style: AppTextStyles.bodySecondary.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
