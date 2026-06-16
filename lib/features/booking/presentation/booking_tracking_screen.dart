import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/global_providers.dart';

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
    final start = Offset(size.width * 0.15, size.height * 0.7);
    final end = Offset(size.width * 0.85, size.height * 0.3);

    // Route line paint
    final routePaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Travelled route paint
    final travelledPaint = Paint()
      ..color = const Color(0xFF6366F1)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw route background line
    canvas.drawLine(start, end, routePaint);

    // Calculate provider movement progress based on status
    double progress = 0.0;
    if (status == BookingStatus.onTheWay) {
      progress = 0.1 + (animationProgress * 0.4); // starts moving
    } else if (status == BookingStatus.inProgress) {
      progress = 0.6 + (animationProgress * 0.35); // arrived, working
    } else if (status == BookingStatus.completed) {
      progress = 1.0;
    }

    if (progress > 0.0) {
      final currentOffset = Offset(
        start.dx + (end.dx - start.dx) * progress,
        start.dy + (end.dy - start.dy) * progress,
      );
      canvas.drawLine(start, currentOffset, travelledPaint);

      // Draw provider/vehicle marker
      final markerPaint = Paint()..color = const Color(0xFF06B6D4);
      final pulsePaint = Paint()
        ..color = const Color(0xFF06B6D4).withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(currentOffset, 12 * (1.0 + animationProgress * 0.3), pulsePaint);
      canvas.drawCircle(currentOffset, 7, markerPaint);
    }

    // Draw Customer Marker
    final custPaint = Paint()..color = const Color(0xFFF43F5E);
    canvas.drawCircle(end, 8, custPaint);

    // Label customer house
    final textPainter = TextPainter(
      text: const TextSpan(
        text: "YOU",
        style: TextStyle(color: Color(0xFFF43F5E), fontWeight: FontWeight.bold, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, end + const Offset(-10, -22));
  }

  @override
  bool shouldRepaint(covariant _TrackerPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress || oldDelegate.status != status;
  }
}

class _BookingTrackingScreenState extends ConsumerState<BookingTrackingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
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
      appBar: AppBar(
        title: const Text("Track Provider"),
      ),
      body: StreamBuilder<Booking?>(
        stream: dbSvc.getBookingStream(widget.bookingId),
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
              // Interactive Animated Progress Map
              Expanded(
                flex: 3,
                child: Container(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
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
                        top: 20,
                        left: 20,
                        right: 20,
                        child: Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, color: Color(0xFF6366F1)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _getInstructionMessage(booking.status),
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Sheet with Status Timeline
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
                    ],
                  ),
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
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Category: ${booking.category}",
                                style: const TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text("EST. DURATION", style: TextStyle(fontSize: 10, color: Colors.grey)),
                              Text(
                                _getEtaValue(booking.status),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),

                      const Text("Booking Timeline", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 12),

                      // List representation of status timeline
                      Expanded(
                        child: ListView.builder(
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
            ],
          );
        },
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
    final primary = Theme.of(context).colorScheme.primary;

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
                  color: isCompleted ? null : Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }
}
