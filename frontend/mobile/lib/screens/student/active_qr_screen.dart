import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_bar_widget.dart';
import '../../widgets/bottom_nav_student.dart';
import '../../providers/auth_service.dart';
import '../../providers/outpass_provider.dart';

class ActiveQrScreen extends StatefulWidget {
  const ActiveQrScreen({super.key});

  @override
  State<ActiveQrScreen> createState() => _ActiveQrScreenState();
}

class _ActiveQrScreenState extends State<ActiveQrScreen> {
  Timer? _countdownTimer;
  Map<String, dynamic>? _outpass;
  String _studentName = '';
  String _rollNo = '';
  bool _loading = true;
  String _qrPayload = '';
  OutpassQrToken? _token;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final meRes = await AuthService.getMe();
    if (meRes['success'] == true && meRes['data'] != null) {
      _studentName = meRes['data']['full_name'] ?? meRes['data']['first_name'] ?? '';
      _rollNo = meRes['data']['student_profile']?['register_number'] ?? '';
    }

    final provider = OutpassProvider();
    final currentRes = await provider.getCurrentOutpass();
    if (currentRes['success'] == true && currentRes['data'] != null) {
      final op = currentRes['data'];
      if (op['status'] == 'APPROVED' || op['status'] == 'ACTIVE') {
        _outpass = op;
        _token = await provider.generateToken(op['id'].toString());
        if (_token != null) {
          _qrPayload = jsonEncode(_token!.toQrPayload());
        }
      }
    }

    _startCountdown();

    if (mounted) setState(() => _loading = false);
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _getTokenExpiryText() {
    if (_outpass == null || _outpass!['expected_return_date'] == null) return '';
    final dateStr = _outpass!['expected_return_date'];
    final timeStr = _outpass!['expected_return_time'];
    final returnTime = DateTime.tryParse('$dateStr $timeStr');
    if (returnTime == null) return '';
    
    final diff = returnTime.difference(DateTime.now());
    if (diff.isNegative) {
      return 'Time Expired - Overdue';
    }
    
    final hours = diff.inHours.toString().padLeft(2, '0');
    final minutes = (diff.inMinutes.remainder(60)).toString().padLeft(2, '0');
    final seconds = (diff.inSeconds.remainder(60)).toString().padLeft(2, '0');
    
    if (_outpass!['status'] == 'APPROVED') {
      return 'Exit allowed. Return time: $timeStr';
    }
    
    return 'Time remaining: $hours:$minutes:$seconds';
  }

  String _getOverdueText() {
    if (_outpass == null || _outpass!['expected_return_date'] == null) return '';
    final dateStr = _outpass!['expected_return_date'];
    final timeStr = _outpass!['expected_return_time'];
    final returnTime = DateTime.tryParse('$dateStr $timeStr');
    if (returnTime == null) return '';
    
    final diff = returnTime.difference(DateTime.now());
    if (diff.isNegative) {
      return 'OVERDUE BY ${diff.abs().inHours}h ${diff.abs().inMinutes.remainder(60)}m';
    }
    return '${diff.inHours}h ${diff.inMinutes.remainder(60)}m remaining';
  }

  @override
  Widget build(BuildContext context) {
    final isOverdue = _getOverdueText().startsWith('OVERDUE');
    final isExit = _outpass != null && _outpass!['status'] == 'APPROVED';
    final actionText = isExit ? 'Scan at Gate to Exit' : 'Scan at Gate to Return';
    
    return Scaffold(
      appBar: AppBarWidget(title: 'Gate Pass', showBackButton: false),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _outpass == null
              ? const Center(child: Text('No approved or active outpass found.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          actionText,
                          style: AppTextStyles.cardTitle.copyWith(color: Theme.of(context).primaryColor),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Theme.of(context).primaryColor, width: 2),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: _qrPayload.isEmpty 
                          ? const SizedBox(width: 220, height: 220, child: Center(child: CircularProgressIndicator()))
                          : QrImageView(data: _qrPayload, size: 220),
                      ),
                      const SizedBox(height: 16),
                      Text(_getTokenExpiryText(), style: AppTextStyles.bodySecondary.copyWith(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Text(_studentName, style: AppTextStyles.cardTitle),
                      Text('Reg: $_rollNo', style: AppTextStyles.bodySecondary),
                      const SizedBox(height: 16),
                      Text('Dest: ${_outpass!['destination'] ?? ''}', style: AppTextStyles.bodyMain),
                      
                      if (_outpass!['status'] == 'ACTIVE') ...[
                        const SizedBox(height: 24),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isOverdue ? Colors.red.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isOverdue ? Colors.red : Colors.blue),
                          ),
                          child: Text(
                            _getOverdueText(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isOverdue ? Colors.red : Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
      bottomNavigationBar: BottomNavStudent(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) Navigator.of(context).popUntil((route) => route.isFirst);
          if (index == 2) Navigator.pushReplacementNamed(context, '/history');
        },
        hasApprovedRequest: true,
      ),
    );
  }
}
