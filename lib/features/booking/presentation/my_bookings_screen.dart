import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/global_providers.dart';
import 'booking_tracking_screen.dart';
import '../../chat/presentation/chat_screen.dart';

class MyBookingsScreen extends ConsumerStatefulWidget {
  final String customerId;
  const MyBookingsScreen({super.key, required this.customerId});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen> {
  late Stream<List<Booking>> _bookingsStream;

  @override
  void initState() {
    super.initState();
    final dbSvc = ref.read(databaseServiceProvider);
    _bookingsStream = dbSvc.getCustomerBookingsStream(widget.customerId);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("My Bookings"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Active Bookings"),
              Tab(text: "History"),
            ],
          ),
        ),
        body: StreamBuilder<List<Booking>>(
          stream: _bookingsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text("Error loading bookings: ${snapshot.error}"));
            }

            final bookings = snapshot.data ?? [];
            final activeBookings = bookings.where((b) => 
              b.status != BookingStatus.completed && b.status != BookingStatus.cancelled
            ).toList();
            final historyBookings = bookings.where((b) => 
              b.status == BookingStatus.completed || b.status == BookingStatus.cancelled
            ).toList();

            // Sort by most recent
            activeBookings.sort((a, b) => b.dateTime.compareTo(a.dateTime));
            historyBookings.sort((a, b) => b.dateTime.compareTo(a.dateTime));

            return TabBarView(
              children: [
                _buildBookingsList(context, ref, activeBookings, isActive: true),
                _buildBookingsList(context, ref, historyBookings, isActive: false),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBookingsList(BuildContext context, WidgetRef ref, List<Booking> list, {required bool isActive}) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? Icons.event_busy : Icons.history, size: 48, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 8),
            Text(
              isActive ? "No active bookings at the moment" : "No booking history found",
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final booking = list[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Provider Business Name + Category
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        booking.providerBusinessName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    _buildStatusChip(context, booking.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  booking.category,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(height: 24),

                // Date, Time Slot, and Cost details
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      "${booking.dateTime.day}/${booking.dateTime.month}/${booking.dateTime.year}",
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        booking.timeSlot,
                        style: const TextStyle(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.payments_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      "Amount: ₹${booking.cost.toInt()}",
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "Issue: ${booking.description}",
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),

                // Buttons depending on status
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Chat option
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              senderId: booking.customerId,
                              receiverId: booking.providerId,
                              partnerName: booking.providerBusinessName,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline, size: 16),
                      label: const Text("Chat"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Active actions
                    if (isActive) ...[
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => BookingTrackingScreen(bookingId: booking.id),
                            ),
                          );
                        },
                        icon: const Icon(Icons.track_changes, size: 16),
                        label: const Text("Track"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                    ],

                    // History reviews action
                    if (!isActive && booking.status == BookingStatus.completed) ...[
                      booking.reviewRating != null
                          ? Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  "Rated: ${booking.reviewRating}",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            )
                          : ElevatedButton.icon(
                              onPressed: () => _showReviewDialog(context, ref, booking.id),
                              icon: const Icon(Icons.rate_review_outlined, size: 16),
                              label: const Text("Write Review"),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                            ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(BuildContext context, BookingStatus status) {
    Color color = Colors.grey;
    String label = status.name.toUpperCase();

    switch (status) {
      case BookingStatus.pending:
        color = Colors.orange;
        label = "PENDING";
        break;
      case BookingStatus.accepted:
        color = Colors.blue;
        label = "ACCEPTED";
        break;
      case BookingStatus.onTheWay:
        color = Colors.cyan;
        label = "ON THE WAY";
        break;
      case BookingStatus.inProgress:
        color = Colors.indigo;
        label = "IN PROGRESS";
        break;
      case BookingStatus.completed:
        color = Colors.green;
        label = "COMPLETED";
        break;
      case BookingStatus.cancelled:
        color = Colors.red;
        label = "CANCELLED";
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  void _showReviewDialog(BuildContext context, WidgetRef ref, String bookingId) {
    double selectedStars = 5.0;
    final reviewTextController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Rate Service"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("How was your service experience?"),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  double starVal = index + 1.0;
                  return IconButton(
                    icon: Icon(
                      selectedStars >= starVal ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        selectedStars = starVal;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reviewTextController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Write your feedback here (optional)...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final dbSvc = ref.read(databaseServiceProvider);
                await dbSvc.addBookingReview(
                  bookingId,
                  selectedStars,
                  reviewTextController.text.trim(),
                );
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Review submitted. Thank you!")),
                  );
                }
              },
              child: const Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }
}
