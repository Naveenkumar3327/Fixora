import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/global_providers.dart';
import '../../../core/theme/theme.dart';

class BookingTrackingScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const BookingTrackingScreen({super.key, required this.bookingId});

  @override
  ConsumerState<BookingTrackingScreen> createState() => _BookingTrackingScreenState();
}

class _TrackerPainter extends CustomPainter {
  final double animationProgress;
  final BookingStatus status;

  _TrackerPainter({required this.animationProgress, required this.status});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Grid Backdrop
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final start = Offset(size.width * 0.15, size.height * 0.7);
    final end = Offset(size.width * 0.85, size.height * 0.3);

    // Route line paint
    final routePaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw route background line
    canvas.drawLine(start, end, routePaint);

    // Calculate provider movement progress based on status
    double progress = 0.0;
    if (status == BookingStatus.onTheWay) {
      progress = 0.1 + (animationProgress * 0.4); 
    } else if (status == BookingStatus.inProgress) {
      progress = 0.6 + (animationProgress * 0.35); 
    } else if (status == BookingStatus.completed) {
      progress = 1.0;
    }

    if (progress > 0.0) {
      final currentOffset = Offset(
        start.dx + (end.dx - start.dx) * progress,
        start.dy + (end.dy - start.dy) * progress,
      );

      // Travelled route paint
      final travelledPaint = Paint()
        ..shader = const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
        ).createShader(Rect.fromPoints(start, end))
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawLine(start, currentOffset, travelledPaint);

      // Draw pulsing waves under vehicle marker
      final pulsePaint = Paint()
        ..color = AppTheme.primaryColor.withOpacity(0.25 * (1.0 - animationProgress))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(currentOffset, 18 * (1.0 + animationProgress * 0.4), pulsePaint);

      // Draw provider/vehicle marker
      final markerPaint = Paint()..color = AppTheme.primaryColor;
      canvas.drawCircle(currentOffset, 8, markerPaint);

      final markerBorder = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(currentOffset, 8, markerBorder);
    }

    // Draw Customer Marker
    final custGlow = Paint()
      ..color = AppTheme.successColor.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(end, 14, custGlow);

    final custPaint = Paint()..color = AppTheme.successColor;
    canvas.drawCircle(end, 8, custPaint);

    final custBorder = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(end, 8, custBorder);

    // Label customer house
    final textPainter = TextPainter(
      text: const TextSpan(
        text: "YOU",
        style: TextStyle(color: AppTheme.successColor, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, end + const Offset(-10, -24));
  }

  @override
  bool shouldRepaint(covariant _TrackerPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress || oldDelegate.status != status;
  }
}

class _BookingTrackingScreenState extends ConsumerState<BookingTrackingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Stream<Booking?> _bookingStream;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    final dbSvc = ref.read(databaseServiceProvider);
    _bookingStream = dbSvc.getBookingStream(widget.bookingId);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dbSvc = ref.watch(databaseServiceProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Track Provider"),
      ),
      body: PremiumBackground(
        child: StreamBuilder<Booking?>(
          stream: _bookingStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final booking = snapshot.data;
            if (booking == null) {
              return const Center(child: Text("Booking details not found."));
            }

            return Column(
              children: [
                const SizedBox(height: 100),
                // Cyber Progress Map Tracker
                Expanded(
                  flex: 3,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        children: [
                          AnimatedBuilder(
                            animation: _animController,
                            builder: (context, child) {
                              return CustomPaint(
                                size: Size.infinite,
                                painter: _TrackerPainter(
                                  animationProgress: _animController.value,
                                  status: booking.status,
                                ),
                              );
                            },
                          ),
                          Positioned(
                            top: 16,
                            left: 16,
                            right: 16,
                            child: GlassCard(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              borderRadius: 14,
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline, color: AppTheme.primaryColor),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _getInstructionMessage(booking.status),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Booking Timeline steps sheet
                Expanded(
                  flex: 4,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: GlassCard(
                      borderRadius: 24,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    booking.providerBusinessName,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Category: ${booking.category}",
                                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text("EST. DURATION", style: TextStyle(fontSize: 9, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text(
                                    _getEtaValue(booking.status),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 24, color: Colors.white12),

                          const Text("Booking Timeline", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary)),
                          const SizedBox(height: 16),

                          Expanded(
                            child: ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: booking.statusTimeline.length,
                              itemBuilder: (context, index) {
                                final log = booking.statusTimeline[index];
                                final isLast = index == booking.statusTimeline.length - 1;
                                return _buildTimelineNode(
                                  context,
                                  title: log.split(': ').first,
                                  subtitle: "Logged at ${log.split(': ').length > 1 ? log.split(': ')[1] : ''}",
                                  isCompleted: true,
                                  isLastNode: isLast,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _getInstructionMessage(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return "Waiting for provider to accept appointment request.";
      case BookingStatus.accepted:
        return "Provider accepted the job. Preparing tools.";
      case BookingStatus.onTheWay:
        return "Provider is driving to your address. Track on map.";
      case BookingStatus.inProgress:
        return "Provider is working on resolving the reported issue.";
      case BookingStatus.completed:
        return "Job is complete! Please rate and review the provider.";
      case BookingStatus.cancelled:
        return "This booking was cancelled.";
    }
  }

  String _getEtaValue(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending: return "--";
      case BookingStatus.accepted: return "15 mins";
      case BookingStatus.onTheWay: return "8 mins";
      case BookingStatus.inProgress: return "Active";
      case BookingStatus.completed: return "Done";
      case BookingStatus.cancelled: return "N/A";
    }
  }

  Widget _buildTimelineNode(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isLastNode,
  }) {
    final primary = AppTheme.successColor;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: isCompleted ? primary : Colors.grey.withOpacity(0.3),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: isCompleted
                    ? [BoxShadow(color: primary.withOpacity(0.4), blurRadius: 6)]
                    : null,
              ),
            ),
            if (!isLastNode)
              Container(
                width: 2,
                height: 35,
                color: isCompleted ? primary : Colors.grey.withOpacity(0.3),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isCompleted ? AppTheme.textPrimary : AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}

