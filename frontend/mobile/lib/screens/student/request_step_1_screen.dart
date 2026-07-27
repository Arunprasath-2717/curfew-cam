import 'package:flutter/material.dart';

import '../../widgets/app_bar_widget.dart';
import '../../widgets/input_field.dart';
import '../../widgets/primary_button.dart';

class RequestStep1Screen extends StatefulWidget {
  const RequestStep1Screen({super.key});

  @override
  State<RequestStep1Screen> createState() => _RequestStep1ScreenState();
}

class _RequestStep1ScreenState extends State<RequestStep1Screen> {
  final _formKey = GlobalKey<FormState>();
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

  Future<void> _pickDate(TextEditingController controller, {DateTime? initialDate, DateTime? firstDate, DateTime? lastDate}) async {
    final DateTime now = DateTime.now();
    final DateTime picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: firstDate ?? DateTime(now.year, now.month, now.day),
      lastDate: lastDate ?? now.add(const Duration(days: 30)),
    ) ?? initialDate ?? now;
    
    if (mounted) {
      setState(() {
        controller.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
        // Auto-validate form on change to clear errors
        _formKey.currentState?.validate();
      });
    }
  }

  Future<void> _pickTime(TextEditingController controller, {TimeOfDay? initialTime}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        controller.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        _formKey.currentState?.validate();
      });
    }
  }

  void _next() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    Navigator.pushNamed(context, '/request-step2', arguments: {
      'outpass_type': 'REGULAR',
      'reason': _reasonCtrl.text.trim().isEmpty ? 'Personal' : _reasonCtrl.text.trim(),
      'destination': _destinationCtrl.text.trim(),
      'exit_date': _exitDateCtrl.text.trim(),
      'exit_time': '${_exitTimeCtrl.text.trim()}:00',
      'expected_return_date': _returnDateCtrl.text.trim(),
      'expected_return_time': '${_returnTimeCtrl.text.trim()}:00',
    });
  }

  DateTime? _parseDate(String dateStr) {
    if (dateStr.isEmpty) return null;
    return DateTime.tryParse(dateStr);
  }

  TimeOfDay? _parseTime(String timeStr) {
    if (timeStr.isEmpty || !timeStr.contains(':')) return null;
    final parts = timeStr.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      InputField(
                        label: 'Purpose of Visit', 
                        hintText: 'e.g. Medical', 
                        icon: Icons.edit, 
                        controller: _reasonCtrl,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Purpose is required' : null,
                      ),
                      const SizedBox(height: 16),
                      InputField(
                        label: 'Destination Address', 
                        hintText: 'Enter full address', 
                        icon: Icons.location_on, 
                        controller: _destinationCtrl,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Destination is required' : null,
                      ),
                      const SizedBox(height: 16),
                      InputField(
                        label: 'Leave Date', 
                        hintText: 'YYYY-MM-DD', 
                        icon: Icons.calendar_today, 
                        controller: _exitDateCtrl,
                        readOnly: true,
                        onTap: () => _pickDate(_exitDateCtrl),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Leave date is required';
                          final d = _parseDate(v);
                          if (d == null) return 'Invalid date';
                          final now = DateTime.now();
                          final today = DateTime(now.year, now.month, now.day);
                          if (d.isBefore(today)) return 'Leave date cannot be in the past';
                          if (d.difference(today).inDays > 30) return 'Cannot book more than 30 days in advance';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      InputField(
                        label: 'Departure Time', 
                        hintText: 'HH:MM', 
                        icon: Icons.schedule, 
                        controller: _exitTimeCtrl,
                        readOnly: true,
                        onTap: () {
                          final initial = _parseTime(_exitTimeCtrl.text);
                          _pickTime(_exitTimeCtrl, initialTime: initial);
                        },
                        validator: (v) => v == null || v.isEmpty ? 'Departure time is required' : null,
                      ),
                      const SizedBox(height: 16),
                      InputField(
                        label: 'Return Date', 
                        hintText: 'YYYY-MM-DD', 
                        icon: Icons.calendar_today, 
                        controller: _returnDateCtrl,
                        readOnly: true,
                        onTap: () {
                          final leaveD = _parseDate(_exitDateCtrl.text);
                          _pickDate(
                            _returnDateCtrl, 
                            initialDate: leaveD, 
                            firstDate: leaveD, 
                            lastDate: leaveD?.add(const Duration(days: 7)),
                          );
                        },
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Return date is required';
                          final retD = _parseDate(v);
                          final leaveD = _parseDate(_exitDateCtrl.text);
                          if (retD == null || leaveD == null) return null; // handled by other validator
                          if (retD.isBefore(leaveD)) return 'Return date cannot be before leave date';
                          if (retD.difference(leaveD).inDays > 7) return 'Outpass duration cannot exceed 7 days';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      InputField(
                        label: 'Expected Return Time', 
                        hintText: 'HH:MM', 
                        icon: Icons.schedule, 
                        controller: _returnTimeCtrl,
                        readOnly: true,
                        onTap: () {
                          final initial = _parseTime(_returnTimeCtrl.text);
                          _pickTime(_returnTimeCtrl, initialTime: initial);
                        },
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Return time is required';
                          final retD = _parseDate(_returnDateCtrl.text);
                          final leaveD = _parseDate(_exitDateCtrl.text);
                          if (retD != null && leaveD != null && retD.isAtSameMomentAs(leaveD)) {
                            final retT = _parseTime(v);
                            final leaveT = _parseTime(_exitTimeCtrl.text);
                            if (retT != null && leaveT != null) {
                              final retMins = retT.hour * 60 + retT.minute;
                              final leaveMins = leaveT.hour * 60 + leaveT.minute;
                              if (retMins <= leaveMins) {
                                return 'Return time must be after departure time on the same day';
                              }
                            }
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
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
