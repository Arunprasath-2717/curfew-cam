import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_bar_widget.dart';
import '../../widgets/input_field.dart';
import '../../widgets/primary_button.dart';

class RequestStep1Screen extends StatefulWidget {
  const RequestStep1Screen({super.key});

  @override
  State<RequestStep1Screen> createState() => _RequestStep1ScreenState();
}

class _RequestStep1ScreenState extends State<RequestStep1Screen> {
  final _reasonCtrl = TextEditingController(text: 'Medical');
  final _destinationCtrl = TextEditingController();
  final _exitDateCtrl = TextEditingController();
  final _exitTimeCtrl = TextEditingController(text: '14:00');
  final _returnDateCtrl = TextEditingController();
  final _returnTimeCtrl = TextEditingController(text: '20:00');

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _destinationCtrl.dispose();
    _exitDateCtrl.dispose();
    _exitTimeCtrl.dispose();
    _returnDateCtrl.dispose();
    _returnTimeCtrl.dispose();
    super.dispose();
  }

  void _next() {
    final now = DateTime.now();
    final dateStr = _exitDateCtrl.text.isNotEmpty
        ? _exitDateCtrl.text
        : '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final returnDateStr = _returnDateCtrl.text.isNotEmpty ? _returnDateCtrl.text : dateStr;
    Navigator.pushNamed(context, '/request-step2', arguments: {
      'outpass_type': 'REGULAR',
      'reason': _reasonCtrl.text.trim().isEmpty ? 'Personal' : _reasonCtrl.text.trim(),
      'destination': _destinationCtrl.text.trim(),
      'exit_date': dateStr,
      'exit_time': _exitTimeCtrl.text.trim().isEmpty ? '14:00:00' : '${_exitTimeCtrl.text.trim()}:00',
      'expected_return_date': returnDateStr,
      'expected_return_time': _returnTimeCtrl.text.trim().isEmpty ? '20:00:00' : '${_returnTimeCtrl.text.trim()}:00',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBarWidget(title: 'New Outpass Request', showBackButton: true),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    InputField(label: 'Purpose of Visit', hintText: 'e.g. Medical', icon: Icons.edit, controller: _reasonCtrl),
                    const SizedBox(height: 16),
                    InputField(label: 'Destination Address', hintText: 'Enter full address', icon: Icons.location_on, controller: _destinationCtrl),
                    const SizedBox(height: 16),
                    InputField(label: 'Leave Date', hintText: 'YYYY-MM-DD', icon: Icons.calendar_today, controller: _exitDateCtrl),
                    const SizedBox(height: 16),
                    InputField(label: 'Departure Time', hintText: 'HH:MM', icon: Icons.schedule, controller: _exitTimeCtrl),
                    const SizedBox(height: 16),
                    InputField(label: 'Return Date', hintText: 'YYYY-MM-DD', icon: Icons.calendar_today, controller: _returnDateCtrl),
                    const SizedBox(height: 16),
                    InputField(label: 'Expected Return Time', hintText: 'HH:MM', icon: Icons.schedule, controller: _returnTimeCtrl),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: PrimaryButton(label: 'Next', icon: Icons.arrow_forward, onPressed: _next),
            ),
          ],
        ),
      ),
    );
  }
}
