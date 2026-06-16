import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../../../core/models/models.dart';
import '../../../core/providers/global_providers.dart';
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

class _HomeScreenRadarPainter extends CustomPainter {
  final double pulseValue;
  final List<Offset> pinOffsets;
  final int? selectedIndex;

  _HomeScreenRadarPainter({
    required this.pulseValue,
    required this.pinOffsets,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = min(size.width, size.height) / 2;

    // Background Grid Rings
    final ringPaint = Paint()
      ..color = const Color(0xFF6366F1).withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(center, maxRadius * (i / 4.0), ringPaint);
    }

    // Grid crosshairs
    final linePaint = Paint()
      ..color = const Color(0xFF6366F1).withOpacity(0.05)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), linePaint);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), linePaint);

    // Pulsing scanning wave
    final scanPaint = Paint()
      ..color = const Color(0xFF6366F1).withOpacity(0.12 * (1.0 - pulseValue))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, maxRadius * pulseValue, scanPaint);

    // User center marker
    final userPaint = Paint()..color = const Color(0xFF6366F1);
    final pulsePaint = Paint()
      ..color = const Color(0xFF6366F1).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(center, maxRadius * 0.08 * (1.0 - pulseValue), pulsePaint);
    canvas.drawCircle(center, 6, userPaint);

    // Render provider pins
    final pinPaint = Paint()
      ..color = const Color(0xFF06B6D4)
      ..style = PaintingStyle.fill;

    final selectedPinPaint = Paint()
      ..color = const Color(0xFFF43F5E)
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    for (int i = 0; i < pinOffsets.length; i++) {
      final pin = pinOffsets[i];
      final isSelected = selectedIndex == i;

      // Draw shadow
      canvas.drawCircle(pin + const Offset(0, 2), isSelected ? 9 : 7, shadowPaint);

      // Draw pin
      canvas.drawCircle(pin, isSelected ? 8 : 6, isSelected ? selectedPinPaint : pinPaint);

      // Outer ring for selected
      if (isSelected) {
        final borderPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(pin, 8, borderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HomeScreenRadarPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue ||
        oldDelegate.pinOffsets != pinOffsets ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}

class _MapViewScreenState extends ConsumerState<MapViewScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  int? _selectedProviderIndex;
  List<ProviderProfile> _providers = [];
  List<Offset> _pinOffsets = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _loadProviders();
  }

  void _loadProviders() async {
    final dbSvc = ref.read(databaseServiceProvider);
    final list = await dbSvc.getNearbyProviders(widget.userLat, widget.userLng, widget.category);
    
    // Generate radial layouts relative to center for mock radar representation
    final random = Random();
    List<Offset> offsets = [];

    for (var p in list) {
      // Scale lat/lng distance into radar coordinate system
      // Standard distance limit is 8km (maxRadius).
      double angle = random.nextDouble() * 2 * pi;
      double radiusScale = min(p.distance / 8.0, 0.9); // max out at 90% radius
      
      // Calculate layout coordinates
      double dx = radiusScale * sin(angle);
      double dy = radiusScale * cos(angle);
      offsets.add(Offset(dx, dy));
    }

    setState(() {
      _providers = list;
      _pinOffsets = offsets;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.isEmpty ? "Radar Map View" : "${widget.category} Map"),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final center = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
          final maxRadius = min(constraints.maxWidth, constraints.maxHeight) / 2;

          // Compute absolute screen offsets for drawing and hit testing
          final absoluteOffsets = _pinOffsets.map((off) {
            return Offset(
              center.dx + (off.dx * maxRadius),
              center.dy + (off.dy * maxRadius),
            );
          }).toList();

          return Stack(
            children: [
              // Radar Painter Canvas
              GestureDetector(
                onTapUp: (details) {
                  final tapPos = details.localPosition;
                  int? clickedIndex;
                  double minDistance = 25.0; // Click threshold in pixels

                  for (int i = 0; i < absoluteOffsets.length; i++) {
                    final pin = absoluteOffsets[i];
                    final dist = (tapPos - pin).distance;
                    if (dist < minDistance) {
                      minDistance = dist;
                      clickedIndex = i;
                    }
                  }

                  setState(() {
                    _selectedProviderIndex = clickedIndex;
                  });
                },
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: _HomeScreenRadarPainter(
                        pulseValue: _pulseController.value,
                        pinOffsets: absoluteOffsets,
                        selectedIndex: _selectedProviderIndex,
                      ),
                    );
                  },
                ),
              ),

              // Scanning radius message banner
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color?.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Scanning up to 8 km radius • ${_providers.length} providers found",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom card sheet if a provider is clicked
              if (_selectedProviderIndex != null && _selectedProviderIndex! < _providers.length)
                Positioned(
                  bottom: 24,
                  left: 20,
                  right: 20,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _pulseController,
                      curve: Curves.easeOut,
                    )), // Static layout fallback handles position
                    child: Card(
                      elevation: 8,
                      shadowColor: Colors.black26,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.person_rounded,
                                color: Theme.of(context).colorScheme.primary,
                                size: 28,
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
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "${_providers[_selectedProviderIndex!].category} • ${_providers[_selectedProviderIndex!].experienceYears} yrs exp",
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 14),
                                      const SizedBox(width: 2),
                                      Text(
                                        "${_providers[_selectedProviderIndex!].rating}",
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        "${_providers[_selectedProviderIndex!].distance.toStringAsFixed(2)} km away",
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ProviderDetailScreen(
                                      provider: _providers[_selectedProviderIndex!],
                                    ),
                                  ),
                                );
                              },
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
