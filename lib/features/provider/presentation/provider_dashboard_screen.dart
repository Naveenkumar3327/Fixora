import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/global_providers.dart';
import '../../auth/presentation/role_selection_screen.dart';
import '../../chat/presentation/chat_list_screen.dart';
import '../../chat/presentation/chat_screen.dart';

class ProviderDashboardScreen extends ConsumerStatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  ConsumerState<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends ConsumerState<ProviderDashboardScreen> {
  bool _updatingStatus = false;

  void _logout() {
    ref.read(authStateProvider.notifier).state = null;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
      (route) => false,
    );
  }

  void _toggleAvailability(ProviderProfile profile) async {
    setState(() { _updatingStatus = true; });
    final dbSvc = ref.read(databaseServiceProvider);
    
    final updated = profile.copyWith(isAvailable: !profile.isAvailable);
    await dbSvc.createOrUpdateProviderProfile(updated);
    
    if (mounted) {
      setState(() { _updatingStatus = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(updated.isAvailable ? "You are now online" : "You are now offline")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Not authenticated")));
    }

    final dbSvc = ref.watch(databaseServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Provider Console"),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => ChatListScreen(currentUserId: user.uid)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _logout,
          ),
        ],
      ),
      body: FutureBuilder<ProviderProfile?>(
        future: dbSvc.getProviderProfile(user.uid),
        builder: (context, profileSnapshot) {
          if (profileSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = profileSnapshot.data;
          // Fallback if provider was registered without a profile (e.g. mock login fallback)
          final activeProfile = profile ?? ProviderProfile(
            providerId: user.uid,
            businessName: "${user.name} Services",
            ownerName: user.name,
            category: "Mechanic",
            rating: 5.0,
            reviewsCount: 0,
            address: "New Delhi Central Area",
            phone: user.phone ?? '+919999999999',
            whatsapp: user.phone ?? '+919999999999',
            email: user.email,
            latitude: 28.6304,
            longitude: 77.2177,
            isVerified: true,
            startingPrice: 200,
            experienceYears: 5,
            workingHours: "9:00 AM - 6:00 PM",
            serviceArea: "Within 5 km",
          );

          return StreamBuilder<List<Booking>>(
            stream: dbSvc.getProviderBookingsStream(user.uid),
            builder: (context, bookingsSnapshot) {
              final bookings = bookingsSnapshot.data ?? [];
              
              // Compute earnings metrics
              double totalEarnings = 0.0;
              int completedJobs = 0;
              for (var b in bookings) {
                if (b.status == BookingStatus.completed) {
                  totalEarnings += b.cost;
                  completedJobs++;
                }
              }

              final pendingJobs = bookings.where((b) => b.status == BookingStatus.pending).toList();
              final activeJobs = bookings.where((b) => 
                b.status != BookingStatus.pending && b.status != BookingStatus.completed && b.status != BookingStatus.cancelled
              ).toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Provider Welcome Card
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          child: Text(
                            user.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Welcome back,",
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                              Text(
                                user.name,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        // Online availability switch
                        Row(
                          children: [
                            Text(
                              activeProfile.isAvailable ? "Online" : "Offline",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: activeProfile.isAvailable ? Colors.green : Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 4),
                            _updatingStatus
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : Switch(
                                    value: activeProfile.isAvailable,
                                    onChanged: (_) => _toggleAvailability(activeProfile),
                                  ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Analytics Summary Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            context,
                            "₹${totalEarnings.toInt()}",
                            "Total Earnings",
                            Icons.currency_rupee,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildMetricCard(
                            context,
                            "$completedJobs",
                            "Completed Jobs",
                            Icons.check_circle_outline,
                            Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            context,
                            "${activeProfile.rating} ★",
                            "Average Rating",
                            Icons.star_outline,
                            Colors.amber,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildMetricCard(
                            context,
                            "${bookings.length}",
                            "Total Bookings",
                            Icons.assignment_outlined,
                            Colors.indigo,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Section: Booking Requests (Pending)
                    const Text(
                      "New Booking Requests",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    if (pendingJobs.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: Text(
                              "No pending appointment requests",
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: pendingJobs.length,
                        itemBuilder: (context, index) {
                          final job = pendingJobs[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        job.customerName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      Text(
                                        "₹${job.cost.toInt()}",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Date: ${job.dateTime.day}/${job.dateTime.month}/${job.dateTime.year} • ${job.timeSlot}",
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Problem: ${job.description}",
                                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton(
                                        onPressed: () async {
                                          await dbSvc.updateBookingStatus(job.id, BookingStatus.cancelled);
                                        },
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          side: const BorderSide(color: Colors.red),
                                        ),
                                        child: const Text("Decline"),
                                      ),
                                      const SizedBox(width: 12),
                                      ElevatedButton(
                                        onPressed: () async {
                                          await dbSvc.updateBookingStatus(job.id, BookingStatus.accepted);
                                        },
                                        child: const Text("Accept"),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 32),

                    // Section: Active & Ongoing Jobs
                    const Text(
                      "Active / Ongoing Jobs",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    if (activeJobs.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: Text(
                              "No active jobs in progress",
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: activeJobs.length,
                        itemBuilder: (context, index) {
                          final job = activeJobs[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        job.customerName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          job.status.name.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Schedule: ${job.dateTime.day}/${job.dateTime.month}/${job.dateTime.year} • ${job.timeSlot}",
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.message_outlined, color: Colors.grey),
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => ChatScreen(
                                                senderId: job.providerId,
                                                receiverId: job.customerId,
                                                partnerName: job.customerName,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      const Spacer(),
                                      // Multi-stage completions
                                      if (job.status == BookingStatus.accepted)
                                        ElevatedButton.icon(
                                          onPressed: () async {
                                            await dbSvc.updateBookingStatus(job.id, BookingStatus.onTheWay);
                                          },
                                          icon: const Icon(Icons.departure_board, size: 16),
                                          label: const Text("Start Driving"),
                                        ),
                                      if (job.status == BookingStatus.onTheWay)
                                        ElevatedButton.icon(
                                          onPressed: () async {
                                            await dbSvc.updateBookingStatus(job.id, BookingStatus.inProgress);
                                          },
                                          icon: const Icon(Icons.play_arrow, size: 16),
                                          label: const Text("Start Work"),
                                        ),
                                      if (job.status == BookingStatus.inProgress)
                                        ElevatedButton.icon(
                                          onPressed: () async {
                                            await dbSvc.updateBookingStatus(job.id, BookingStatus.completed);
                                          },
                                          icon: const Icon(Icons.check, size: 16),
                                          label: const Text("Mark Completed"),
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
