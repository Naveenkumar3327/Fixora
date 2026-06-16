import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/global_providers.dart';
import '../../../core/theme/theme.dart';
import '../../../core/services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  late Stream<List<Booking>> _bookingsStream;

  @override
  void initState() {
    super.initState();
    final dbSvc = ref.read(databaseServiceProvider);
    final user = ref.read(authStateProvider);
    if (user != null) {
      _bookingsStream = dbSvc.getProviderBookingsStream(user.uid);
    } else {
      _bookingsStream = const Stream.empty();
    }
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('loggedInUid');
    ref.read(authStateProvider.notifier).state = null;
    if (!mounted) return;
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
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.darkCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              Icon(
                updated.isAvailable ? Icons.wifi : Icons.wifi_off,
                color: updated.isAvailable ? AppTheme.successColor : AppTheme.warningColor,
              ),
              const SizedBox(width: 8),
              Text(
                updated.isAvailable ? "You are now online" : "You are now offline",
                style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Provider Console"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: AppTheme.primaryColor),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => ChatListScreen(currentUserId: user.uid)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: _logout,
          ),
        ],
      ),
      body: PremiumBackground(
        child: SafeArea(
          child: FutureBuilder<ProviderProfile?>(
            future: dbSvc.getProviderProfile(user.uid),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                );
              }

              final profile = profileSnapshot.data;
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
                stream: _bookingsStream,
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
                        GlassCard(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryColor.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    )
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Colors.transparent,
                                  child: Text(
                                    user.name.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Welcome back,",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      user.name,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Online availability switch
                              Column(
                                children: [
                                  Text(
                                    activeProfile.isAvailable ? "ONLINE" : "OFFLINE",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                      color: activeProfile.isAvailable
                                          ? AppTheme.successColor
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  _updatingStatus
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                          ),
                                        )
                                      : _buildCustomToggle(activeProfile),
                                ],
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                        const SizedBox(height: 24),

                        // Analytics Summary Cards Grid
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.25,
                          children: [
                            _buildMetricCard(
                              context,
                              "₹${totalEarnings.toInt()}",
                              "Total Earnings",
                              Icons.currency_rupee,
                              AppTheme.successColor,
                              [AppTheme.successColor.withOpacity(0.15), AppTheme.primaryColor.withOpacity(0.15)],
                            ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.1, end: 0),
                            _buildMetricCard(
                              context,
                              "$completedJobs",
                              "Completed Jobs",
                              Icons.check_circle_outline,
                              AppTheme.primaryColor,
                              [AppTheme.primaryColor.withOpacity(0.15), AppTheme.secondaryColor.withOpacity(0.15)],
                            ).animate().fadeIn(duration: 400.ms, delay: 150.ms).slideY(begin: 0.1, end: 0),
                            _buildMetricCard(
                              context,
                              "${activeProfile.rating} ★",
                              "Average Rating",
                              Icons.star_outline,
                              Colors.amber,
                              [Colors.amber.withOpacity(0.15), AppTheme.warningColor.withOpacity(0.15)],
                            ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.1, end: 0),
                            _buildMetricCard(
                              context,
                              "${bookings.length}",
                              "Total Bookings",
                              Icons.assignment_outlined,
                              AppTheme.secondaryColor,
                              [AppTheme.secondaryColor.withOpacity(0.15), Colors.purple.withOpacity(0.15)],
                            ).animate().fadeIn(duration: 400.ms, delay: 250.ms).slideY(begin: 0.1, end: 0),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Section: Booking Requests (Pending)
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 16,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "New Booking Requests",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (pendingJobs.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.warningColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
                                ),
                                child: Text(
                                  "${pendingJobs.length}",
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.warningColor,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (pendingJobs.isEmpty)
                          GlassCard(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.notifications_off_outlined, color: AppTheme.textSecondary.withOpacity(0.5), size: 36),
                                const SizedBox(height: 8),
                                const Text(
                                  "No pending appointment requests",
                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 400.ms)
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: pendingJobs.length,
                            itemBuilder: (context, index) {
                              final job = pendingJobs[index];
                              return GlassCard(
                                margin: const EdgeInsets.only(bottom: 14),
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const CircleAvatar(
                                              radius: 14,
                                              backgroundColor: AppTheme.primaryColor,
                                              child: Icon(Icons.person, size: 14, color: Colors.white),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              job.customerName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                                          ),
                                          child: Text(
                                            "₹${job.cost.toInt()}",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today_outlined, size: 13, color: AppTheme.textSecondary),
                                        const SizedBox(width: 6),
                                        Text(
                                          "${job.dateTime.day}/${job.dateTime.month}/${job.dateTime.year} • ${job.timeSlot}",
                                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.03),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Problem Description",
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            job.description,
                                            style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () async {
                                              await dbSvc.updateBookingStatus(job.id, BookingStatus.cancelled);
                                            },
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.redAccent,
                                              side: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                            child: const Text("Decline", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: InkWell(
                                            onTap: () async {
                                              await dbSvc.updateBookingStatus(job.id, BookingStatus.accepted);
                                            },
                                            borderRadius: BorderRadius.circular(10),
                                            child: Container(
                                              alignment: Alignment.center,
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                                                ),
                                                borderRadius: BorderRadius.circular(10),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppTheme.primaryColor.withOpacity(0.2),
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ],
                                              ),
                                              child: const Text(
                                                "Accept",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
                            },
                          ),

                        const SizedBox(height: 32),

                        // Section: Active & Ongoing Jobs
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 16,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppTheme.secondaryColor, AppTheme.primaryColor],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "Active / Ongoing Jobs",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (activeJobs.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                                ),
                                child: Text(
                                  "${activeJobs.length}",
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (activeJobs.isEmpty)
                          GlassCard(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.work_outline, color: AppTheme.textSecondary.withOpacity(0.5), size: 36),
                                const SizedBox(height: 8),
                                const Text(
                                  "No active jobs in progress",
                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 400.ms)
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: activeJobs.length,
                            itemBuilder: (context, index) {
                              final job = activeJobs[index];
                              
                              Color statusColor;
                              String statusText;
                              IconData statusIcon;
                              
                              switch (job.status) {
                                case BookingStatus.accepted:
                                  statusColor = AppTheme.primaryColor;
                                  statusText = "Accepted";
                                  statusIcon = Icons.check_circle_outline;
                                  break;
                                case BookingStatus.onTheWay:
                                  statusColor = AppTheme.warningColor;
                                  statusText = "On The Way";
                                  statusIcon = Icons.directions_car_outlined;
                                  break;
                                case BookingStatus.inProgress:
                                  statusColor = AppTheme.secondaryColor;
                                  statusText = "In Progress";
                                  statusIcon = Icons.build_outlined;
                                  break;
                                default:
                                  statusColor = AppTheme.textSecondary;
                                  statusText = job.status.name.toUpperCase();
                                  statusIcon = Icons.info_outline;
                              }

                              return GlassCard(
                                margin: const EdgeInsets.only(bottom: 14),
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const CircleAvatar(
                                              radius: 14,
                                              backgroundColor: AppTheme.secondaryColor,
                                              child: Icon(Icons.person, size: 14, color: Colors.white),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              job.customerName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: statusColor.withOpacity(0.3)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(statusIcon, color: statusColor, size: 12),
                                              const SizedBox(width: 4),
                                              Text(
                                                statusText,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: statusColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today_outlined, size: 13, color: AppTheme.textSecondary),
                                        const SizedBox(width: 6),
                                        Text(
                                          "Schedule: ${job.dateTime.day}/${job.dateTime.month}/${job.dateTime.year} • ${job.timeSlot}",
                                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(10),
                                            color: Colors.white.withOpacity(0.05),
                                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                                          ),
                                          child: IconButton(
                                            icon: const Icon(Icons.message_outlined, color: AppTheme.primaryColor),
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
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildActionButtonForJob(job, dbSvc),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
                            },
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCustomToggle(ProviderProfile profile) {
    return GestureDetector(
      onTap: () => _toggleAvailability(profile),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 54,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: profile.isAvailable
              ? const LinearGradient(colors: [AppTheme.primaryColor, AppTheme.secondaryColor])
              : const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF0F172A)]),
          border: Border.all(
            color: profile.isAvailable ? AppTheme.primaryColor.withOpacity(0.5) : Colors.white.withOpacity(0.1),
            width: 1.2,
          ),
          boxShadow: profile.isAvailable ? [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ] : [],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 300),
          alignment: profile.isAvailable ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3.0),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String value,
    String label,
    IconData icon,
    Color color,
    List<Color> gradientColors,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(16.0),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(colors: gradientColors),
                  border: Border.all(
                    color: color.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Icon(Icons.trending_up, color: color.withOpacity(0.3), size: 16),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonForJob(Booking job, DatabaseService dbSvc) {
    if (job.status == BookingStatus.accepted) {
      return InkWell(
        onTap: () async {
          await dbSvc.updateBookingStatus(job.id, BookingStatus.onTheWay);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.directions_car_outlined, size: 16, color: Colors.white),
              SizedBox(width: 8),
              Text(
                "Start Driving",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    } else if (job.status == BookingStatus.onTheWay) {
      return InkWell(
        onTap: () async {
          await dbSvc.updateBookingStatus(job.id, BookingStatus.inProgress);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.warningColor, AppTheme.secondaryColor],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppTheme.warningColor.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_arrow_outlined, size: 16, color: Colors.white),
              SizedBox(width: 8),
              Text(
                "Start Work",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    } else if (job.status == BookingStatus.inProgress) {
      return InkWell(
        onTap: () async {
          await dbSvc.updateBookingStatus(job.id, BookingStatus.completed);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.successColor, AppTheme.primaryColor],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppTheme.successColor.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, size: 16, color: Colors.white),
              SizedBox(width: 8),
              Text(
                "Mark Completed",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox();
  }
}
