import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import '../../../core/models/models.dart';
import '../../../core/providers/global_providers.dart';
import '../../../core/theme/theme.dart';
import '../../booking/presentation/provider_detail_screen.dart';

class MapViewScreen extends ConsumerStatefulWidget {
  final double userLat;
  final double userLng;
  final String category;

  const MapViewScreen({
    super.key,
    required this.userLat,
    required this.userLng,
    required this.category,
  });

  @override
  ConsumerState<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends ConsumerState<MapViewScreen> with TickerProviderStateMixin {
  late AnimationController _sweepController;
  late AnimationController _bounceController;
  late AnimationController _routeController;
  
  int? _selectedProviderIndex;
  List<ProviderProfile> _providers = [];
  List<Offset> _pinOffsets = [];
  
  // Simulated Camera offset for panning effect
  Offset _cameraOffset = Offset.zero;
  Offset _targetCameraOffset = Offset.zero;
  late AnimationController _cameraController;

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _routeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _cameraController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _loadProviders();
  }

  void _loadProviders() async {
    final dbSvc = ref.read(databaseServiceProvider);
    final list = await dbSvc.getNearbyProviders(widget.userLat, widget.userLng, widget.category);
    
    // Distribute providers at stylized coordinate offsets
    final math.Random random = math.Random(101); // constant seed for uniform distribution
    List<Offset> offsets = [];

    for (var p in list) {
      double angle = random.nextDouble() * 2 * math.pi;
      double radiusScale = math.min(p.distance / 8.0, 0.85); // up to 85% radius
      
      double dx = radiusScale * math.cos(angle);
      double dy = radiusScale * math.sin(angle);
      offsets.add(Offset(dx, dy));
    }

    setState(() {
      _providers = list;
      _pinOffsets = offsets;
    });
  }

  void _onSelectProvider(int index) {
    setState(() {
      _selectedProviderIndex = index;
      
      // Center camera relative to the selected provider (pan in opposite direction)
      final pin = _pinOffsets[index];
      _targetCameraOffset = Offset(-pin.dx * 0.4, -pin.dy * 0.4);
    });

    _routeController.forward(from: 0.0);
    
    // Smooth camera transition
    _cameraController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _sweepController.dispose();
    _bounceController.dispose();
    _routeController.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.category.isEmpty ? "Provider Radar" : "${widget.category} Grid"),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final center = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
          final maxRadius = math.min(constraints.maxWidth, constraints.maxHeight) / 2.2;

          // Process current camera panning position
          return AnimatedBuilder(
            animation: _cameraController,
            builder: (context, child) {
              final currentCam = Offset.lerp(
                _cameraOffset,
                _targetCameraOffset,
                Curves.fastOutSlowIn.transform(_cameraController.value),
              )!;
              
              if (_cameraController.isCompleted) {
                _cameraOffset = _targetCameraOffset;
              }

              // Compute coordinates
              final animatedCenter = Offset(
                center.dx + currentCam.dx * maxRadius,
                center.dy + currentCam.dy * maxRadius,
              );

              final absoluteOffsets = _pinOffsets.map((off) {
                return Offset(
                  animatedCenter.dx + (off.dx * maxRadius),
                  animatedCenter.dy + (off.dy * maxRadius),
                );
              }).toList();

              return Stack(
                children: [
                  // Cyber Map Canvas
                  GestureDetector(
                    onTapUp: (details) {
                      final tapPos = details.localPosition;
                      int? clickedIndex;
                      double minDistance = 25.0; // Click threshold

                      for (int i = 0; i < absoluteOffsets.length; i++) {
                        final pin = absoluteOffsets[i];
                        final dist = (tapPos - pin).distance;
                        if (dist < minDistance) {
                          minDistance = dist;
                          clickedIndex = i;
                        }
                      }

                      if (clickedIndex != null) {
                        _onSelectProvider(clickedIndex);
                      } else {
                        // Reset
                        setState(() {
                          _selectedProviderIndex = null;
                          _targetCameraOffset = Offset.zero;
                        });
                        _cameraController.forward(from: 0.0);
                      }
                    },
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_sweepController, _bounceController, _routeController]),
                      builder: (context, child) {
                        return CustomPaint(
                          size: Size(constraints.maxWidth, constraints.maxHeight),
                          painter: _CyberMapPainter(
                            center: animatedCenter,
                            maxRadius: maxRadius,
                            sweepValue: _sweepController.value,
                            bounceValue: _bounceController.value,
                            routeProgress: _routeController.value,
                            pinOffsets: absoluteOffsets,
                            selectedIndex: _selectedProviderIndex,
                          ),
                        );
                      },
                    ),
                  ),

                  // Scanning status bubble
                  Positioned(
                    top: 100,
                    left: 20,
                    right: 20,
                    child: GlassCard(
                      borderRadius: 30,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppTheme.successColor,
                              shape: BoxShape.circle,
                            ),
                          )
                              .animate(onPlay: (controller) => controller.repeat())
                              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.3, 1.3), duration: 1000.ms, curve: Curves.easeInOut)
                              .then()
                              .scale(begin: const Offset(1.3, 1.3), end: const Offset(0.8, 0.8), duration: 1000.ms),
                          const SizedBox(width: 10),
                          Text(
                            "SCANNING RADAR • ${_providers.length} ACTIVE PROVIDERS NEARBY",
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: AppTheme.primaryColor),
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: -0.2, end: 0),

                  // Selected Provider Details Glass Card
                  if (_selectedProviderIndex != null && _selectedProviderIndex! < _providers.length)
                    Positioned(
                      bottom: 32,
                      left: 20,
                      right: 20,
                      child: GlassCard(
                        borderRadius: 24,
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(
                                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                                ),
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _providers[_selectedProviderIndex!].businessName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "${_providers[_selectedProviderIndex!].category} • ${_providers[_selectedProviderIndex!].experienceYears} yrs experience",
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 14),
                                      const SizedBox(width: 2),
                                      Text(
                                        "${_providers[_selectedProviderIndex!].rating}",
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        "${_providers[_selectedProviderIndex!].distance.toStringAsFixed(1)} km away",
                                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            
                            // Glowing CTA button
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ProviderDetailScreen(
                                      provider: _providers[_selectedProviderIndex!],
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryColor,
                                      blurRadius: 10,
                                      offset: Offset(0, 2),
                                    )
                                  ],
                                ),
                                child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                              ),
                            )
                          ],
                        ),
                      )
                          .animate(key: ValueKey(_selectedProviderIndex))
                          .fadeIn(duration: 350.ms)
                          .slideY(begin: 0.15, end: 0, curve: Curves.easeOutQuad),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _CyberMapPainter extends CustomPainter {
  final Offset center;
  final double maxRadius;
  final double sweepValue;
  final double bounceValue;
  final double routeProgress;
  final List<Offset> pinOffsets;
  final int? selectedIndex;

  _CyberMapPainter({
    required this.center,
    required this.maxRadius,
    required this.sweepValue,
    required this.bounceValue,
    required this.routeProgress,
    required this.pinOffsets,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Grid Background (Futuristic cyber lines)
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1;
    
    double step = 30.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Concentric Scanning Circles
    final circlePaint = Paint()
      ..color = AppTheme.primaryColor.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(center, maxRadius * 0.35, circlePaint);
    canvas.drawCircle(center, maxRadius * 0.7, circlePaint);
    canvas.drawCircle(center, maxRadius * 1.0, circlePaint);

    // Crosshairs
    final axisPaint = Paint()
      ..color = AppTheme.primaryColor.withOpacity(0.08)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), axisPaint);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), axisPaint);

    // 3. Rotating Sweep Gradient radar scan
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          AppTheme.primaryColor.withOpacity(0.12),
          AppTheme.primaryColor.withOpacity(0.0),
        ],
        center: Alignment.center,
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius))
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(sweepValue * 2 * math.pi);
    canvas.drawCircle(Offset.zero, maxRadius, sweepPaint);
    canvas.restore();

    // 4. Draw User Location Beacon
    final beaconGlow = Paint()
      ..color = AppTheme.primaryColor.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(center, 20, beaconGlow);

    final beaconPaint = Paint()..color = AppTheme.primaryColor;
    canvas.drawCircle(center, 7, beaconPaint);
    
    final beaconBorder = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, 7, beaconBorder);

    // 5. Draw Animated Path Route to Selected Provider
    if (selectedIndex != null && selectedIndex! < pinOffsets.length) {
      final target = pinOffsets[selectedIndex!];
      
      final routePath = Path()
        ..moveTo(center.dx, center.dy)
        ..quadraticBezierTo(
          (center.dx + target.dx) / 2 - 30,
          (center.dy + target.dy) / 2 - 30,
          target.dx,
          target.dy,
        );

      // Background route path
      final routeBg = Paint()
        ..color = Colors.white.withOpacity(0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(routePath, routeBg);

      // Glowing animated tracing overlay
      final routeActive = Paint()
        ..shader = const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
        ).createShader(Rect.fromPoints(center, target))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;

      // Draw path up to progress value
      final pathMetrics = routePath.computeMetrics();
      for (var metric in pathMetrics) {
        final extract = metric.extractPath(0.0, metric.length * routeProgress);
        canvas.drawPath(extract, routeActive);
      }
    }

    // 6. Draw Provider pins with bounce animations
    final shadowPaint = Paint()
      ..color = Colors.black38
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    for (int i = 0; i < pinOffsets.length; i++) {
      final pin = pinOffsets[i];
      final isSelected = selectedIndex == i;
      
      // Calculate dynamic bounce height offset for pin
      double bounce = 0.0;
      if (isSelected) {
        bounce = math.sin(bounceValue * 2 * math.pi) * 8.0 - 8.0; // bounces up
      }

      final pinPosition = Offset(pin.dx, pin.dy + bounce);

      // Shadow on ground
      canvas.drawCircle(pin + const Offset(0, 4), isSelected ? 8 : 6, shadowPaint);

      // Glow backing
      final pinGlow = Paint()
        ..color = (isSelected ? AppTheme.secondaryColor : AppTheme.primaryColor).withOpacity(0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawCircle(pinPosition, isSelected ? 12 : 9, pinGlow);

      // Pin body
      final pinPaint = Paint()
        ..color = isSelected ? AppTheme.secondaryColor : AppTheme.primaryColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pinPosition, isSelected ? 8 : 6, pinPaint);

      // Pin center border
      final pinCenter = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(pinPosition, isSelected ? 8 : 6, pinCenter);
    }
  }

  @override
  bool shouldRepaint(covariant _CyberMapPainter oldDelegate) {
    return oldDelegate.sweepValue != sweepValue ||
        oldDelegate.bounceValue != bounceValue ||
        oldDelegate.routeProgress != routeProgress ||
        oldDelegate.center != center ||
        oldDelegate.pinOffsets != pinOffsets ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}

