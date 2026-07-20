import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class ScanInvalidScreen extends StatelessWidget {
  const ScanInvalidScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Theme.of(context).scaffoldBackgroundColor, title: Row(children: [Icon(Icons.security, size: 20), SizedBox(width: 8), Text('GateControl', style: TextStyle(fontWeight: FontWeight.bold))])),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 80, height: 80, decoration: BoxDecoration(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(Icons.cancel, color: Theme.of(context).colorScheme.error, size: 56)),
                const SizedBox(height: 16),
                Text('INVALID PASS ✗', style: AppTextStyles.greeting.copyWith(color: Theme.of(context).colorScheme.error, letterSpacing: 1)),
                Text('Pass Expired', style: AppTextStyles.sectionHeader.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
                const SizedBox(height: 24),
                // Faded Student Info Card
                Opacity(
                  opacity: 0.6,
                  child: Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: Theme.of(context).dividerColor)),
                    child: Column(
                      children: [
                        Row(children: [
                          Container(width: 64, height: 64, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Theme.of(context).colorScheme.surface, image: DecorationImage(image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuCAQmRhqDi1uJoivd3tp7gNAqli0eG7UPlZBUY201mdfb_kukt9gAPXlYiTavGNyzSTL6OGLPgWhJGfeU6pi_n7cY5kbvGYlHW4nA86IcWoPDDHzHvN_YyKPHnPAM57BjiU5xO5fCTaqbFWy-0UVR60K9VntvA3N0E2ySZIrg-1UN2NYfSdjuZzVN-IbFQ-x_9sIToqvlesDZV6JAgzyQNSVqAILVFlAtqiu9pIpQdKj4h_2wj7TeUpLCFIJehQ1EXIzouJdfNR_gE'), fit: BoxFit.cover))),
                          const SizedBox(width: 16),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Arjun Malhotra', style: AppTextStyles.cardTitle), Text('ID: 2021BCS042', style: AppTextStyles.bodySecondary.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)))]),
                        ]),
                        const SizedBox(height: 16),
                        Divider(),
                        const SizedBox(height: 12),
                        Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('DEPARTURE', style: AppTextStyles.badgeCaps.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))), Text('Oct 24, 18:30', style: AppTextStyles.bodyMain)])), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('DEADLINE', style: AppTextStyles.badgeCaps.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))), Text('Oct 24, 21:00', style: AppTextStyles.bodyMain)]))]),
                        const SizedBox(height: 16),
                        Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(8)), child: Row(children: [Icon(Icons.warning, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)), SizedBox(width: 12), Expanded(child: Text('This pass expired 2 hours ago. Automatic notification sent to warden office.', style: AppTextStyles.bodySecondary.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))))])),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(onPressed: () => Navigator.pop(context), icon: Icon(Icons.refresh), label: Text('Try Again'), style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 48), backgroundColor: Theme.of(context).primaryColor, foregroundColor: Theme.of(context).scaffoldBackgroundColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                const SizedBox(height: 12),
                TextButton.icon(onPressed: () {}, icon: Icon(Icons.flag, size: 20), label: Text('Report Issue'), style: TextButton.styleFrom(foregroundColor: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
