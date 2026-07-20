import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/primary_button.dart';

class LateWarningScreen extends StatelessWidget {
  const LateWarningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text('CurfewCam', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status Alert', style: AppTextStyles.screenTitle),
              const SizedBox(height: 8),
              Text('Your current outpass status requires immediate action.', style: AppTextStyles.bodySecondary.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
              const SizedBox(height: 24),
              // Warning Banner
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.error, borderRadius: BorderRadius.circular(16)),
                child: Row(children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.warning, color: Theme.of(context).scaffoldBackgroundColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('CRITICAL ALERT', style: AppTextStyles.badgeCaps.copyWith(color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8))),
                    Text('You are LATE!', style: AppTextStyles.cardTitle.copyWith(color: Theme.of(context).scaffoldBackgroundColor)),
                  ])),
                ]),
              ),
              const SizedBox(height: 24),
              // Time Comparison
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: Theme.of(context).dividerColor)),
                child: Column(children: [
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('DEADLINE', style: AppTextStyles.badgeCaps.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
                      Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                        Text('09:00', style: AppTextStyles.greeting.copyWith(color: Theme.of(context).primaryColor)),
                        const SizedBox(width: 4),
                        Text('PM', style: AppTextStyles.bodySecondary.copyWith(fontWeight: FontWeight.bold, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
                      ]),
                    ])),
                    Container(width: 1, height: 40, color: Theme.of(context).dividerColor),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('CURRENT TIME', style: AppTextStyles.badgeCaps.copyWith(color: Theme.of(context).colorScheme.error)),
                      Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                        Text('09:45', style: AppTextStyles.greeting.copyWith(color: Theme.of(context).colorScheme.error)),
                        const SizedBox(width: 4),
                        Text('PM', style: AppTextStyles.bodySecondary.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.error)),
                      ]),
                    ])),
                  ]),
                  const SizedBox(height: 24),
                  Divider(color: Theme.of(context).dividerColor),
                  const SizedBox(height: 24),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Row(children: [
                      Icon(Icons.schedule, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)),
                      const SizedBox(width: 8),
                      Text.rich(TextSpan(text: 'Overdue by ', style: AppTextStyles.bodyMain.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)), children: [
                        TextSpan(text: '45 minutes', style: AppTextStyles.bodyMain.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                      ])),
                    ]),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.error.withOpacity(0.1), border: Border.all(color: Theme.of(context).colorScheme.error.withOpacity(0.2)), borderRadius: BorderRadius.circular(9999)),
                      child: Text('PENALTY APPLIED', style: AppTextStyles.badgeCaps.copyWith(fontSize: 10, color: Theme.of(context).colorScheme.error)),
                    ),
                  ]),
                ]),
              ),
              const SizedBox(height: 24),
              // Image card
              Container(
                height: 192, width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Theme.of(context).dividerColor),
                  image: const DecorationImage(image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuCYCA46A70DcomAUpbvZSTsLY0mA5OoRGO8fmT1wxt4_TpqaH7C7vQZjQFfRYTlgjGDkNaM952Jo45jyYrM0FzK1XhT7yUV9HvwDmSnHg1sLKQJ0SSz6UsdyUo-pipGySGz-KQqVeXxmVc3pptcm2E7JJWu8Z-dNvjFd1MqG9lS52LlqwhgZseRFJOqR0dFONOMZfxxPqvYG6oU9dWQE7qLT9X8k03QGhXuqmS8fZlyQfk2GH8PiIqrlBuwpGvWhirbBgwHyzjPZss'), fit: BoxFit.cover),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withOpacity(0.6), Colors.transparent]),
                  ),
                  padding: EdgeInsets.all(16),
                  alignment: Alignment.bottomLeft,
                  child: Row(children: [
                    Icon(Icons.location_on, color: Theme.of(context).scaffoldBackgroundColor, size: 20),
                    const SizedBox(width: 8),
                    Text('Main Hostel Gate • Block A', style: AppTextStyles.bodySecondary.copyWith(color: Theme.of(context).scaffoldBackgroundColor)),
                  ]),
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(label: 'Mark Return', icon: Icons.qr_code_scanner, onPressed: () {}),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {},
                icon: Icon(Icons.support_agent),
                label: Text('Contact Warden'),
                style: OutlinedButton.styleFrom(minimumSize: Size(double.infinity, 48), foregroundColor: Theme.of(context).primaryColor, side: BorderSide(color: Theme.of(context).primaryColor, width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              ),
              const SizedBox(height: 16),
              Text('Please proceed to the nearest security kiosk immediately to resolve this status.', style: AppTextStyles.bodySecondary.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
