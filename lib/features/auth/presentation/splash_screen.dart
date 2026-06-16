import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/theme.dart';
import '../../../core/theme/logo.dart';
import '../../../core/providers/global_providers.dart';
import '../../../core/models/models.dart';
import '../../home/presentation/home_screen.dart';
import '../../admin/presentation/admin_dashboard_screen.dart';
import '../../provider/presentation/provider_dashboard_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _particleController;
  final List<Particle> _particles = [];
  final int _particleCount = 45;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    
    // Setup particle animation controller
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Initialize random particles
    for (int i = 0; i < _particleCount; i++) {
      _particles.add(
        Particle(
          x: _random.nextDouble() * 400,
          y: _random.nextDouble() * 800,
          speed: 0.2 + _random.nextDouble() * 0.8,
          theta: _random.nextDouble() * 2 * math.pi,
          radius: 1 + _random.nextDouble() * 3,
          opacity: 0.1 + _random.nextDouble() * 0.5,
        ),
      );
    }

    // Delayed navigation checking persistent user login after 5 seconds
    Future.delayed(const Duration(seconds: 5), () async {
      if (!mounted) return;

      try {
        final prefs = await SharedPreferences.getInstance();
        final savedUid = prefs.getString('loggedInUid');

        if (savedUid != null) {
          final dbSvc = ref.read(databaseServiceProvider);
          final user = await dbSvc.getUser(savedUid);
          
          if (user != null && mounted) {
            ref.read(authStateProvider.notifier).state = user;
            
            Widget target;
            if (user.role == UserRole.admin) {
              target = const AdminDashboardScreen();
            } else if (user.role == UserRole.provider) {
              target = const ProviderDashboardScreen();
            } else {
              target = const HomeScreen();
            }
            
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => target),
            );
            return;
          }
        }
      } catch (e) {
        debugPrint("Error reading persistent auth: $e");
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const OnboardingScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Stack(
        children: [
          // 1. Ambient Background Orbs
          const PremiumBackground(child: SizedBox.expand()),
          
          // 2. Interactive Background Particles
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: ParticlePainter(
                  particles: _particles,
                  animationValue: _particleController.value,
                ),
              );
            },
          ),
          
          // 3. Central Brand Identity with 3D Animations
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glowing vector logo with custom floating and reflection sweep
                FixoraLogo(size: 150)
                    .animate()
                    .fadeIn(duration: 800.ms, curve: Curves.easeOut)
                    .scale(
                      begin: const Offset(0.3, 0.3),
                      end: const Offset(1.0, 1.0),
                      duration: 1200.ms,
                      curve: Curves.elasticOut,
                    ),
                const SizedBox(height: 32),
                
                // Animated App Name
                Text(
                  "Fixora",
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    fontSize: 42,
                    shadows: [
                      Shadow(
                        color: AppTheme.primaryColor.withOpacity(0.5),
                        offset: const Offset(0, 4),
                        blurRadius: 10,
                      ),
                      Shadow(
                        color: AppTheme.secondaryColor.withOpacity(0.3),
                        offset: const Offset(0, -2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 600.ms)
                    .slideY(begin: 0.3, end: 0, curve: Curves.easeOutQuad),
                
                const SizedBox(height: 8),
                
                // Animated Tagline
                Text(
                  "Trusted Professionals, Just Around the Corner",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 4),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 900.ms, duration: 600.ms)
                    .slideY(begin: 0.4, end: 0, curve: Curves.easeOutQuad),
              ],
            ),
          ),
          
          // 4. Premium Loading Dot Tracker
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Stack(
                  children: [
                    Container(
                      width: 16,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                        ),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.5),
                            blurRadius: 5,
                            spreadRadius: 1,
                          )
                        ],
                      ),
                    )
                        .animate(onPlay: (controller) => controller.repeat())
                        .moveX(
                          begin: -16,
                          end: 48,
                          duration: 1800.ms,
                          curve: Curves.easeInOut,
                        ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Particle {
  double x;
  double y;
  double speed;
  double theta;
  double radius;
  double opacity;

  Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.theta,
    required this.radius,
    required this.opacity,
  });

  void update(Size size) {
    x += speed * math.cos(theta);
    y += speed * math.sin(theta);
    if (x < 0 || x > size.width || y < 0 || y > size.height) {
      x = math.Random().nextDouble() * size.width;
      y = math.Random().nextDouble() * size.height;
    }
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;

  ParticlePainter({required this.particles, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var p in particles) {
      p.update(size);
      paint.color = AppTheme.primaryColor.withOpacity(p.opacity * 0.25);
      canvas.drawCircle(Offset(p.x, p.y), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => true;
}
