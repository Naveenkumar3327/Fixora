import 'package:flutter/material.dart';
import 'dart:math' as math;

class FixoraLogo extends StatefulWidget {
  final double size;
  final bool isAnimated;

  const FixoraLogo({
    super.key,
    this.size = 100,
    this.isAnimated = true,
  });

  @override
  State<FixoraLogo> createState() => _FixoraLogoState();
}

class _FixoraLogoState extends State<FixoraLogo> with TickerProviderStateMixin {
  late AnimationController _sweepController;
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    if (widget.isAnimated) {
      _sweepController.repeat();
      _floatController.repeat(reverse: true);
    }

    _floatAnimation = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(
        parent: _floatController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _sweepController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color cyanColor = Color(0xFF06B6D4);
    const Color purpleColor = Color(0xFF7C3AED);

    Widget logoContent = AnimatedBuilder(
      animation: _sweepController,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: HexagonLogoPainter(
            cyanColor: cyanColor,
            purpleColor: purpleColor,
            animationValue: _sweepController.value,
          ),
        );
      },
    );

    if (widget.isAnimated) {
      return AnimatedBuilder(
        animation: _floatAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _floatAnimation.value),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.002) // Perspective
                ..rotateY(0.02 * _floatAnimation.value) // Slight rotation in Y axis
                ..rotateX(-0.01 * _floatAnimation.value), // Slight rotation in X axis
              child: child,
            ),
          );
        },
        child: logoContent,
      );
    }

    return logoContent;
  }
}

class HexagonLogoPainter extends CustomPainter {
  final Color cyanColor;
  final Color purpleColor;
  final double animationValue;

  HexagonLogoPainter({
    required this.cyanColor,
    required this.purpleColor,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // 1. Draw soft glow behind logo
    final glowPaint = Paint()
      ..color = cyanColor.withOpacity(0.15)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.4);
    canvas.drawCircle(center, radius * 0.8, glowPaint);

    final glowPaint2 = Paint()
      ..color = purpleColor.withOpacity(0.15)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.4);
    canvas.drawCircle(center + const Offset(5, 5), radius * 0.8, glowPaint2);

    // 2. Draw Hexagon outline
    final hexPath = Path();
    for (int i = 0; i < 6; i++) {
      double angle = i * math.pi / 3 - math.pi / 6; // Start offset to point up
      double x = center.dx + radius * 0.85 * math.cos(angle);
      double y = center.dy + radius * 0.85 * math.sin(angle);
      if (i == 0) {
        hexPath.moveTo(x, y);
      } else {
        hexPath.lineTo(x, y);
      }
    }
    hexPath.close();

    final borderGradient = LinearGradient(
      colors: [cyanColor, purpleColor],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final borderPaint = Paint()
      ..shader = borderGradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.08
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(hexPath, borderPaint);

    // 3. Draw Stylized "F" Inside
    final fPath = Path();
    double stemWidth = radius * 0.16;
    double topBarLength = radius * 0.45;
    double midBarLength = radius * 0.32;
    double verticalHeight = radius * 0.95;

    double startX = center.dx - radius * 0.18;
    double startY = center.dy - radius * 0.48;

    // Construct the vector path for F
    fPath.moveTo(startX, startY);
    fPath.lineTo(startX + topBarLength, startY);
    fPath.lineTo(startX + topBarLength, startY + stemWidth);
    fPath.lineTo(startX + stemWidth, startY + stemWidth);
    fPath.lineTo(startX + stemWidth, startY + radius * 0.36);
    fPath.lineTo(startX + stemWidth + midBarLength, startY + radius * 0.36);
    fPath.lineTo(startX + stemWidth + midBarLength, startY + radius * 0.36 + stemWidth);
    fPath.lineTo(startX + stemWidth, startY + radius * 0.36 + stemWidth);
    fPath.lineTo(startX + stemWidth, startY + verticalHeight);
    fPath.lineTo(startX, startY + verticalHeight);
    fPath.close();

    final fGradient = LinearGradient(
      colors: [cyanColor, purpleColor],
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
    );

    final fPaint = Paint()
      ..shader = fGradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    // 3D Shadow overlay under "F"
    final fShadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawPath(fPath.shift(const Offset(3, 4)), fShadowPaint);

    canvas.drawPath(fPath, fPaint);

    // Dynamic reflection sweep overlay
    final sweepPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.35),
          Colors.white.withOpacity(0.0),
        ],
        stops: const [0.35, 0.5, 0.65],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    // Intersect letter F with sweep using clip path
    canvas.save();
    canvas.clipPath(fPath);
    double sweepOffset = -radius * 1.5 + (animationValue * radius * 3.0);
    canvas.drawRect(
      Rect.fromLTWH(startX + sweepOffset, startY - radius, radius * 0.6, radius * 3),
      sweepPaint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant HexagonLogoPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.cyanColor != cyanColor ||
        oldDelegate.purpleColor != purpleColor;
  }
}
