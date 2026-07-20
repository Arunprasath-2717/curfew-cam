import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class ScanNotFoundScreen extends StatelessWidget {
  const ScanNotFoundScreen({super.key});

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
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: Theme.of(context).dividerColor)),
                  child: Column(
                    children: [
                      // Error Header
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 32),
                        decoration: BoxDecoration(color: Theme.of(context).colorScheme.error, borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
                        child: Column(
                          children: [
                            Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle), child: Icon(Icons.person_off, color: Theme.of(context).scaffoldBackgroundColor, size: 48)),
                            const SizedBox(height: 8),
                            Text('NOT FOUND ✗', style: AppTextStyles.screenTitle.copyWith(color: Theme.of(context).scaffoldBackgroundColor, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Text('No matching student record', style: AppTextStyles.sectionHeader),
                            const SizedBox(height: 8),
                            Text('The QR code scanned does not correspond to any active student in the GateControl database. Please check the ID or try a manual search.', style: AppTextStyles.bodySecondary.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)), textAlign: TextAlign.center),
                            const SizedBox(height: 24),
                            // Visual QR placeholder
                            Container(width: 192, height: 192, decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.error, width: 2), borderRadius: BorderRadius.circular(16), color: Theme.of(context).colorScheme.surface), child: Center(child: Icon(Icons.qr_code_2, size: 120, color: Theme.of(context).dividerColor))),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(onPressed: () => Navigator.pushNamed(context, '/manual-verification'), icon: Icon(Icons.search), label: Text('Manual Lookup'), style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 48), backgroundColor: Theme.of(context).primaryColor, foregroundColor: Theme.of(context).scaffoldBackgroundColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(onPressed: () => Navigator.pop(context), icon: Icon(Icons.refresh), label: Text('Scan Again'), style: OutlinedButton.styleFrom(minimumSize: Size(double.infinity, 48), foregroundColor: Theme.of(context).primaryColor, side: BorderSide(color: Theme.of(context).primaryColor, width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor)),
                  child: Row(children: [Icon(Icons.info, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)), SizedBox(width: 12), Expanded(child: Text('Issue persists? Contact the Administrator for database verification.', style: AppTextStyles.bodySecondary.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))))]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
