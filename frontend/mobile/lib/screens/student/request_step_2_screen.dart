import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_bar_widget.dart';
import '../../widgets/primary_button.dart';
import '../../providers/outpass_provider.dart';

class RequestStep2Screen extends StatefulWidget {
  final Map<String, dynamic>? requestData;
  const RequestStep2Screen({super.key, this.requestData});

  @override
  State<RequestStep2Screen> createState() => _RequestStep2ScreenState();
}

class _RequestStep2ScreenState extends State<RequestStep2Screen> {
  bool _isSubmitting = false;
  final _outpassProvider = OutpassProvider();

  Future<void> _submitRequest() async {
    if (widget.requestData == null) return;
    
    setState(() => _isSubmitting = true);
    
    final res = await _outpassProvider.requestOutpass(widget.requestData!);
    
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    
    if (res['success'] == true) {
      Navigator.pushNamed(context, '/request-submitted');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Failed to submit request'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.requestData ?? {};
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBarWidget(title: 'Review Request', showBackButton: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Request Summary', style: AppTextStyles.sectionHeader),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryRow('Purpose', data['reason'] ?? 'N/A'),
                    const Divider(height: 32),
                    _buildSummaryRow('Destination', data['destination'] ?? 'N/A'),
                    const Divider(height: 32),
                    _buildSummaryRow('Departure', '${data['exit_date'] ?? ''} at ${data['exit_time'] ?? ''}'),
                    const Divider(height: 32),
                    _buildSummaryRow('Return', '${data['expected_return_date'] ?? ''} at ${data['expected_return_time'] ?? ''}'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Edit Details'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: PrimaryButton(
                      label: 'Submit Request',
                      icon: Icons.send,
                      onPressed: _isSubmitting ? null : _submitRequest,
                      isLoading: _isSubmitting,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTextStyles.badgeCaps.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.bodyMain),
      ],
    );
  }
}
