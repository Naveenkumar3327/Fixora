import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/global_providers.dart';
import '../../../core/theme/theme.dart';
import '../../auth/presentation/role_selection_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  Map<String, dynamic> _stats = {
    'totalUsers': 0,
    'totalProviders': 0,
    'activeBookings': 0,
    'revenue': 0.0,
  };
  List<ProviderProfile> _unverified = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  void _loadAdminData() async {
    setState(() { _loading = true; });
    final dbSvc = ref.read(databaseServiceProvider);
    
    final stats = await dbSvc.getAdminStats();
    final unverified = await dbSvc.getUnverifiedProviders();

    setState(() {
      _stats = stats;
      _unverified = unverified;
      _loading = false;
    });
  }

  void _approve(String providerId) async {
    final dbSvc = ref.read(databaseServiceProvider);
    await dbSvc.approveProvider(providerId);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.successColor,
          content: const Row(
            children: [
              Icon(Icons.verified, color: Colors.white),
              SizedBox(width: 8),
              Text(
                "Service provider approved and listed on marketplace!",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
      _loadAdminData(); // Reload stats and lists
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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text("Admin Operations"),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: AppTheme.primaryColor),
              onPressed: _loadAdminData,
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              onPressed: _logout,
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppTheme.textSecondary,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: const [
                    Tab(text: "Market Overview"),
                    Tab(text: "Approve Listings"),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: PremiumBackground(
          maxWidth: 800,
          child: SafeArea(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  )
                : TabBarView(
                    children: [
                      _buildOverviewTab(),
                      _buildApproveTab(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                "Fixora Marketplace Stats",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Total counts metrics grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.25,
            children: [
              _buildAdminMetricCard(
                "Total Customers",
                "${_stats['totalUsers']}",
                Icons.people,
                AppTheme.primaryColor,
                [AppTheme.primaryColor.withOpacity(0.15), Colors.blue.withOpacity(0.15)],
              ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.1, end: 0),
              _buildAdminMetricCard(
                "Total Partners",
                "${_stats['totalProviders']}",
                Icons.storefront,
                AppTheme.successColor,
                [AppTheme.successColor.withOpacity(0.15), Colors.teal.withOpacity(0.15)],
              ).animate().fadeIn(duration: 400.ms, delay: 150.ms).slideY(begin: 0.1, end: 0),
              _buildAdminMetricCard(
                "Active Bookings",
                "${_stats['activeBookings']}",
                Icons.library_books_outlined,
                AppTheme.warningColor,
                [AppTheme.warningColor.withOpacity(0.15), Colors.orange.withOpacity(0.15)],
              ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.1, end: 0),
              _buildAdminMetricCard(
                "Platform Comm. (10%)",
                "₹${(_stats['revenue'] as double).toInt()}",
                Icons.account_balance_wallet_outlined,
                AppTheme.secondaryColor,
                [AppTheme.secondaryColor.withOpacity(0.15), Colors.purple.withOpacity(0.15)],
              ).animate().fadeIn(duration: 400.ms, delay: 250.ms).slideY(begin: 0.1, end: 0),
            ],
          ),

          const SizedBox(height: 32),
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.secondaryColor, AppTheme.primaryColor],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                "Platform Activity Log",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildActivityItem("New plumber listing requested by Amit Verma.", "3 mins ago")
              .animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(begin: 0.1, end: 0),
          _buildActivityItem("Booking book_498f3 completed. Platform earned 10% commission.", "2 hrs ago")
              .animate().fadeIn(duration: 400.ms, delay: 350.ms).slideY(begin: 0.1, end: 0),
          _buildActivityItem("Customer customer@fixora.com submitted a 5-star review.", "3 hrs ago")
              .animate().fadeIn(duration: 400.ms, delay: 400.ms).slideY(begin: 0.1, end: 0),
          _buildActivityItem("Provider Rajesh Sharma registered business location coordinates.", "Yesterday")
              .animate().fadeIn(duration: 400.ms, delay: 450.ms).slideY(begin: 0.1, end: 0),
        ],
      ),
    );
  }

  Widget _buildApproveTab() {
    if (_unverified.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.successColor.withOpacity(0.1),
                border: Border.all(color: AppTheme.successColor.withOpacity(0.2)),
              ),
              child: const Icon(Icons.check_circle_outline, size: 48, color: AppTheme.successColor),
            ),
            const SizedBox(height: 16),
            const Text(
              "All provider profiles are verified and active!",
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ).animate().fadeIn(duration: 450.ms),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _unverified.length,
      itemBuilder: (context, index) {
        final prov = _unverified[index];
        return GlassCard(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    prov.businessName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      prov.category.toUpperCase(),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.warningColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    "Owner: ${prov.ownerName} • Exp: ${prov.experienceYears} Years",
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      prov.address,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Hourly Starting Price:",
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    Text(
                      "₹${prov.startingPrice.toInt()}",
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppTheme.darkCard,
                            content: const Text("Application placed on hold.", style: TextStyle(color: AppTheme.textPrimary)),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("Hold App", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _approve(prov.providerId),
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
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 14, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              "Approve",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
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
    );
  }

  Widget _buildAdminMetricCard(
    String label,
    String val,
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
                val,
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

  Widget _buildActivityItem(String text, String time) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryColor.withOpacity(0.1),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
            ),
            child: const Icon(Icons.bolt, size: 14, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
