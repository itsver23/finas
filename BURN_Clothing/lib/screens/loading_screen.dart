import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/store_service.dart';
import 'screens.dart';

/// Animated loading circle aligned to the original BURN loading artwork.
/// The static circle has been removed from assets/loading.png.
class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    store.load();
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Shell()),
      );
    });
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        body: LayoutBuilder(
          builder: (context, constraints) {
            // Match the contained artwork so the spinner stays aligned on different phones.
            const imageWidth = 941.0;
            const imageHeight = 1672.0;
            const centerX = 470.0;
            const centerY = 1185.0;
            const diameter = 82.0;
            final scale = math.min(
              constraints.maxWidth / imageWidth,
              constraints.maxHeight / imageHeight,
            );
            final offsetX = (constraints.maxWidth - imageWidth * scale) / 2;
            final offsetY = (constraints.maxHeight - imageHeight * scale) / 2;
            final size = diameter * scale;
            return Stack(
              fit: StackFit.expand,
              children: [
                const Image(
                  image: AssetImage('assets/loading.png'),
                  fit: BoxFit.contain,
                ),
                Positioned(
                  left: offsetX + centerX * scale - size / 2,
                  top: offsetY + centerY * scale - size / 2,
                  width: size,
                  height: size,
                  child: RotationTransition(
                    turns: _spin,
                    child: CustomPaint(
                      painter: _BurnSpinnerPainter(),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
}

class _BurnSpinnerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.095;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    final track = Paint()
      ..color = const Color(0xFF242424)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final red = Paint()
      ..color = const Color(0xFFEC002A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 1.35, false, red);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
