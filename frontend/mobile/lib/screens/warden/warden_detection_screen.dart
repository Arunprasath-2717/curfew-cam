import 'dart:async';
import 'package:flutter/material.dart';
import '../../providers/warden_service.dart';
import '../../theme/app_text_styles.dart';

class WardenDetectionScreen extends StatefulWidget {
  const WardenDetectionScreen({super.key});

  @override
  State<WardenDetectionScreen> createState() => _WardenDetectionScreenState();
}

class _WardenDetectionScreenState extends State<WardenDetectionScreen> {
  List<dynamic> _cameras = [];
  List<dynamic> _alerts = [];
  bool _isLoading = true;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _pollingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      _fetchData(showLoading: false);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() => _isLoading = true);
    }
    
    try {
      final camerasFuture = WardenService.getCameraStatus();
      final alertsFuture = WardenService.getDetectionAlerts();
      
      final results = await Future.wait([camerasFuture, alertsFuture]);
      
      if (!mounted) return;
      
      final camRes = results[0];
      final alertRes = results[1];
      
      setState(() {
        if (camRes['success'] == true && camRes['data'] != null) {
          _cameras = List.from(camRes['data']);
        }
        if (alertRes['success'] == true && alertRes['data'] != null) {
          _alerts = List.from(alertRes['data']);
        }
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _acknowledgeAlert(String alertId) async {
    final res = await WardenService.acknowledgeAlert(alertId);
    if (res['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alert acknowledged')),
        );
        _fetchData(showLoading: false);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed to acknowledge')),
        );
      }
    }
  }

  Color _getAlertColor(String level) {
    switch (level.toUpperCase()) {
      case 'CRITICAL': return Colors.red;
      case 'WARNING': return Colors.orange;
      case 'INFO':
      default: return Colors.blue;
    }
  }

  Widget _buildCamerasSection() {
    if (_cameras.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text('Camera Status', style: AppTextStyles.cardTitle),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            itemCount: _cameras.length,
            itemBuilder: (context, index) {
              final cam = _cameras[index];
              final isOnline = cam['status'] == 'ONLINE';
              
              return Container(
                width: 140,
                margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isOnline ? Colors.green : Colors.red,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            cam['name'] ?? 'Unknown',
                            style: AppTextStyles.bodyMain.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      cam['location'] ?? 'No Location',
                      style: AppTextStyles.bodySecondary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAlertsSection() {
    if (_alerts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.security, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No alerts found',
                style: AppTextStyles.cardTitle.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Text(
                'All clear for now.',
                style: AppTextStyles.bodyMain.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }
    
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.all(16.0),
      itemCount: _alerts.length,
      itemBuilder: (context, index) {
        final alert = _alerts[index];
        final level = alert['level'] ?? 'INFO';
        final status = alert['status'] ?? 'ACTIVE';
        final color = _getAlertColor(level);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_rounded, color: color, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          level,
                          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                    if (status != 'ACTIVE')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  alert['title'] ?? 'Alert',
                  style: AppTextStyles.cardTitle,
                ),
                const SizedBox(height: 4),
                Text(
                  alert['message'] ?? '',
                  style: AppTextStyles.bodyMain,
                ),
                if (status == 'ACTIVE') ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _acknowledgeAlert(alert['id'].toString()),
                      child: const Text('Acknowledge'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Detections'),
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchData(showLoading: false),
        child: _isLoading && _cameras.isEmpty && _alerts.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildCamerasSection(),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('Recent Alerts', style: AppTextStyles.cardTitle),
                    ),
                    _buildAlertsSection(),
                  ],
                ),
              ),
      ),
    );
  }
}
