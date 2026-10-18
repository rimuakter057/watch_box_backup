import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/prefs/pref_manager.dart';
import '../../core/theme/app_colors.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _progressValue = 0.0;

  @override
  void initState() {
    super.initState();
    
    // Animation for rotating background gears
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Progress bar simulation (2 seconds)
    _simulateLoading();
  }

  void _simulateLoading() async {
    const steps = 20;
    const stepDuration = Duration(milliseconds: 100);
    
    for (int i = 1; i <= steps; i++) {
      await Future.delayed(stepDuration);
      if (mounted) {
        setState(() {
          _progressValue = i / steps;
        });
      }
    }
    
    _navigateNext();
  }

  void _navigateNext() {
    final pref = Get.find<PrefManager>();
    if (!pref.hasCompletedOnboarding) {
      Get.offAllNamed('/onboarding');
    } else if (pref.hasToken) {
      Get.offAllNamed('/home');
    } else {
      debugPrint("❌ [AUTH ERROR] Not authorized: No access token found. Navigating to /login. No fallback.");
      Get.offAllNamed('/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashBg,
      body: Stack(
        children: [
          // Background gears watermark
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: GearsWatermarkPainter(_controller.value * 2 * pi),
                child: Container(),
              );
            },
          ),
          
          // Foreground Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glowing Watch Badge in Center
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.splashBg,
                    border: Border.all(color: Colors.white24, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.3),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Lottie.asset(
                      'assets/animations/gears.json',
                      width: 68,
                      height: 68,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                
                // Bold Main Title
                const Text(
                  "THE WATCH BOX",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Subtitle
                Text(
                  "YOUR WORLD OF HOROLOGY",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.6),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 48),
                
                // Custom Progress Indicator (Track & Fill matching Design)
                SizedBox(
                  width: 200,
                  height: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: Stack(
                      children: [
                        // Track
                        Container(color: Colors.white12),
                        // Fill
                        FractionallySizedBox(
                          widthFactor: _progressValue,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.accent, Colors.white],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for Faint Rotating Gears in Background
class GearsWatermarkPainter extends CustomPainter {
  final double rotationAngle;

  GearsWatermarkPainter(this.rotationAngle);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.splashGears.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final center = Offset(size.width / 2, size.height / 2);

    // Draw center big gear
    _drawGear(canvas, center, 140, 24, rotationAngle, paint);

    // Draw smaller interlocking gear top-left
    _drawGear(canvas, Offset(center.dx - 120, center.dy - 120), 80, 16, -rotationAngle * 1.5, paint);

    // Draw smaller gear bottom-right
    _drawGear(canvas, Offset(center.dx + 130, center.dy + 110), 90, 18, -rotationAngle * 1.3, paint);
  }

  void _drawGear(Canvas canvas, Offset center, double radius, int teethCount, double rotation, Paint paint) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    // Main circles
    canvas.drawCircle(Offset.zero, radius, paint);
    canvas.drawCircle(Offset.zero, radius - 15, paint);
    canvas.drawCircle(Offset.zero, 15, paint);

    // Spoke lines
    for (int i = 0; i < 4; i++) {
      double angle = i * pi / 2;
      canvas.drawLine(
        Offset(15 * cos(angle), 15 * sin(angle)),
        Offset((radius - 15) * cos(angle), (radius - 15) * sin(angle)),
        paint,
      );
    }

    // Gear teeth
    final path = Path();
    for (int i = 0; i < teethCount; i++) {
      double angle = i * 2 * pi / teethCount;
      double x1 = radius * cos(angle - 0.05);
      double y1 = radius * sin(angle - 0.05);
      double x2 = (radius + 12) * cos(angle - 0.03);
      double y2 = (radius + 12) * sin(angle - 0.03);
      double x3 = (radius + 12) * cos(angle + 0.03);
      double y3 = (radius + 12) * sin(angle + 0.03);
      double x4 = radius * cos(angle + 0.05);
      double y4 = radius * sin(angle + 0.05);

      path.moveTo(x1, y1);
      path.lineTo(x2, y2);
      path.lineTo(x3, y3);
      path.lineTo(x4, y4);
      path.close();
    }
    canvas.drawPath(path, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant GearsWatermarkPainter oldDelegate) {
    return oldDelegate.rotationAngle != rotationAngle;
  }
}
