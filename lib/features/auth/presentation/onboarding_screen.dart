import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/theme.dart';
import '../../../core/providers/global_providers.dart';
import '../../../core/models/models.dart';
import 'role_selection_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../../provider/presentation/provider_dashboard_screen.dart';
import '../../admin/presentation/admin_dashboard_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<OnboardingData> _slides = [
    OnboardingData(
      title: "Find Trusted Professionals Nearby",
      description: "Instantly scan and locate certified local technicians, plumbers, and mechanics with verified reviews in your area.",
      graphicPainter: const _RadarGraphicPainter(),
    ),
    OnboardingData(
      title: "Book Services Instantly",
      description: "Select, schedule, and book appointments within seconds. Customize your requests and view upfront, transparent pricing.",
      graphicPainter: const _CalendarGraphicPainter(),
    ),
    OnboardingData(
      title: "Track Jobs in Real Time",
      description: "Watch your professional's route on our interactive grid. Get real-time updates as work starts and completes.",
      graphicPainter: const _RouteGraphicPainter(),
    ),
  ];

  void _onNext() {
    if (_currentIndex < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() {
    final currentUser = ref.read(authStateProvider);
    Widget target;
    if (currentUser == null) {
      target = const RoleSelectionScreen();
    } else {
      switch (currentUser.role) {
        case UserRole.customer:
          target = const HomeScreen();
          break;
        case UserRole.provider:
          target = const ProviderDashboardScreen();
          break;
        case UserRole.admin:
          target = const AdminDashboardScreen();
          break;
      }
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => target,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PremiumBackground(
        child: Column(
          children: [
            // Top skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 16, 24, 0),
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    "Skip",
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
            
            // Onboarding pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Glass Card Graphic Panel
                        GlassCard(
                          height: 250,
                          borderRadius: 24,
                          padding: const EdgeInsets.all(24),
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: slide.graphicPainter,
                          )
                              .animate(key: ValueKey(index))
                              .fadeIn(duration: 600.ms)
                              .scale(begin: const Offset(0.95, 0.95), duration: 600.ms, curve: Curves.easeOutBack),
                        ),
                        const SizedBox(height: 48),
                        
                        // Text Title
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        )
                            .animate(key: ValueKey("title_$index"))
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
                        
                        const SizedBox(height: 16),
                        
                        // Text Description
                        Text(
                          slide.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            height: 1.5,
                            fontSize: 14.5,
                          ),
                        )
                            .animate(key: ValueKey("desc_$index"))
                            .fadeIn(duration: 600.ms)
                            .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Bottom navigation panel
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 16, 32, 48),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page Indicators
                  Row(
                    children: List.generate(_slides.length, (index) {
                      final bool isSelected = _currentIndex == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        width: isSelected ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                                )
                              : null,
                          color: isSelected ? null : Colors.white.withOpacity(0.15),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withOpacity(0.3),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  )
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),
                  
                  // Next / Get Started button
                  GestureDetector(
                    onTap: _onNext,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentIndex == _slides.length - 1 ? "Get Started" : "Next",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _currentIndex == _slides.length - 1
                                ? Icons.rocket_launch_rounded
                                : Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate(key: ValueKey("btn_state_$_currentIndex"))
                      .scale(begin: const Offset(0.95, 0.95), duration: 200.ms),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final CustomPainter graphicPainter;

  OnboardingData({
    required this.title,
    required this.description,
    required this.graphicPainter,
  });
}

// 1. Vector Painter for slide 1: Radar Nearby Search
class _RadarGraphicPainter extends CustomPainter {
  const _RadarGraphicPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2.2;

    // Pulse circles
    final ringPaint = Paint()
      ..color = AppTheme.primaryColor.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    canvas.drawCircle(center, maxRadius * 0.4, ringPaint);
    canvas.drawCircle(center, maxRadius * 0.75, ringPaint);
    canvas.drawCircle(center, maxRadius * 1.0, ringPaint);

    // Grid axes
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), gridPaint);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), gridPaint);

    // Glowing user center
    final glowPaint = Paint()
      ..color = AppTheme.primaryColor.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(center, 18, glowPaint);
    
    final centerPaint = Paint()..color = AppTheme.primaryColor;
    canvas.drawCircle(center, 8, centerPaint);

    // Scatter nodes (representing nearby professionals)
    final nodePaint = Paint()
      ..color = AppTheme.secondaryColor
      ..style = PaintingStyle.fill;
    
    final pinPaint = Paint()
      ..color = AppTheme.successColor
      ..style = PaintingStyle.fill;

    // Node 1
    canvas.drawCircle(Offset(center.dx - maxRadius * 0.5, center.dy - maxRadius * 0.4), 6, nodePaint);
    // Node 2
    canvas.drawCircle(Offset(center.dx + maxRadius * 0.6, center.dy - maxRadius * 0.25), 7, pinPaint);
    // Node 3
    canvas.drawCircle(Offset(center.dx - maxRadius * 0.35, center.dy + maxRadius * 0.5), 5, nodePaint);
    // Node 4
    canvas.drawCircle(Offset(center.dx + maxRadius * 0.4, center.dy + maxRadius * 0.6), 6, nodePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 2. Vector Painter for slide 2: Booking Details / Stepper Calendar
class _CalendarGraphicPainter extends CustomPainter {
  const _CalendarGraphicPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Draw stylized Calendar Card backdrop
    final cardRect = Rect.fromCenter(center: center, width: size.width * 0.65, height: size.height * 0.7);
    final cardRRect = RRect.fromRectAndRadius(cardRect, const Radius.circular(16));
    
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(cardRRect.shift(const Offset(0, 4)), shadowPaint);

    final cardPaint = Paint()
      ..color = const Color(0xFF1E293B).withOpacity(0.6)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(cardRRect, cardPaint);

    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(cardRRect, borderPaint);

    // Calendar Header (Gradient top bar)
    final headerRect = Rect.fromLTWH(cardRect.left, cardRect.top, cardRect.width, cardRect.height * 0.25);
    final headerRRect = RRect.fromRectAndCorners(
      headerRect,
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
    );
    final headerPaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
      ).createShader(headerRect);
    canvas.drawRRect(headerRRect, headerPaint);

    // Draw little circles in Calendar Grid
    final gridCirclePaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final selectCirclePaint = Paint()
      ..color = AppTheme.successColor
      ..style = PaintingStyle.fill;

    double gridTop = cardRect.top + cardRect.height * 0.35;
    double gridLeft = cardRect.left + cardRect.width * 0.15;
    double cellSpacingX = cardRect.width * 0.18;
    double cellSpacingY = cardRect.height * 0.16;

    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 4; col++) {
        Offset pos = Offset(gridLeft + col * cellSpacingX, gridTop + row * cellSpacingY);
        if (row == 1 && col == 2) {
          canvas.drawCircle(pos, 6, selectCirclePaint);
          // Glow around selection
          final selectGlow = Paint()
            ..color = AppTheme.successColor.withOpacity(0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
          canvas.drawCircle(pos, 9, selectGlow);
        } else {
          canvas.drawCircle(pos, 5, gridCirclePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 3. Vector Painter for slide 3: Live Map Path Routing
class _RouteGraphicPainter extends CustomPainter {
  const _RouteGraphicPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Coordinate nodes
    final start = Offset(size.width * 0.25, size.height * 0.7);
    final mid = Offset(size.width * 0.5, size.height * 0.4);
    final end = Offset(size.width * 0.75, size.height * 0.6);

    // Grid dots
    final dotPaint = Paint()..color = Colors.white.withOpacity(0.04);
    for (double x = 20; x < size.width; x += 30) {
      for (double y = 20; y < size.height; y += 30) {
        canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
      }
    }

    // Path route
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(mid.dx, mid.dy, end.dx, end.dy);

    // Background dashed line
    final bgLinePaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, bgLinePaint);

    // Active travel path
    final activePaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
      ).createShader(Rect.fromPoints(start, end))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, activePaint);

    // Glowing Markers
    final markerGlow = Paint()
      ..color = AppTheme.primaryColor.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    
    // Start node glow and marker
    canvas.drawCircle(start, 12, markerGlow);
    canvas.drawCircle(start, 6, Paint()..color = AppTheme.primaryColor);

    // End node glow and marker
    final endGlow = Paint()
      ..color = AppTheme.successColor.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(end, 14, endGlow);
    canvas.drawCircle(end, 8, Paint()..color = AppTheme.successColor);

    // Dynamic car marker in transit (along bezier curve approximation at 60% progress)
    final progressPos = Offset(
      start.dx * 0.16 + mid.dx * 0.48 + end.dx * 0.36,
      start.dy * 0.16 + mid.dy * 0.48 + end.dy * 0.36,
    );
    canvas.drawCircle(progressPos, 14, Paint()..color = AppTheme.secondaryColor.withOpacity(0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    canvas.drawCircle(progressPos, 7, Paint()..color = AppTheme.secondaryColor);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
