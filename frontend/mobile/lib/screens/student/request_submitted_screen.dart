import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';

class RequestSubmittedScreen extends StatefulWidget {
  const RequestSubmittedScreen({super.key});

  @override
  State<RequestSubmittedScreen> createState() => _RequestSubmittedScreenState();
}

class _RequestSubmittedScreenState extends State<RequestSubmittedScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    
    _controller.forward();
    
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _CheckmarkPainter(progress: _animation.value, color: Colors.green),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            Text('Request submitted!', style: AppTextStyles.greeting.copyWith(color: Theme.of(context).primaryColor)),
          ],
        ),
      ),
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CheckmarkPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - paint.strokeWidth;

    // Draw Circle
    final circleProgress = (progress * 2).clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708, // -90 degrees
      6.2832 * circleProgress, // 360 degrees * progress
      false,
      paint,
    );

    // Draw Checkmark
    if (progress > 0.5) {
      final checkProgress = ((progress - 0.5) * 2).clamp(0.0, 1.0);
      final path = Path();
      
      final start = Offset(size.width * 0.25, size.height * 0.5);
      final middle = Offset(size.width * 0.45, size.height * 0.7);
      final end = Offset(size.width * 0.75, size.height * 0.35);

      path.moveTo(start.dx, start.dy);
      
      if (checkProgress < 0.5) {
        final midProgress = checkProgress * 2;
        path.lineTo(
          start.dx + (middle.dx - start.dx) * midProgress,
          start.dy + (middle.dy - start.dy) * midProgress,
        );
      } else {
        path.lineTo(middle.dx, middle.dy);
        final endProgress = (checkProgress - 0.5) * 2;
        path.lineTo(
          middle.dx + (end.dx - middle.dx) * endProgress,
          middle.dy + (end.dy - middle.dy) * endProgress,
        );
      }
      
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
