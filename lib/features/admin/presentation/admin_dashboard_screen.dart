import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/global_providers.dart';
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
        const SnackBar(content: Text("Service provider approved and listed on marketplace!")),
      );
      _loadAdminData(); // Reload stats and lists
    }
  }

  void _logout() {
    ref.read(authStateProvider.notifier).state = null;
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
        appBar: AppBar(
          title: const Text("Admin Operations"),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadAdminData,
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              onPressed: _logout,
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: "Market Overview"),
              Tab(text: "Approve Listings"),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildOverviewTab(),
                  _buildApproveTab(),
                ],
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
          const Text("Fixora Marketplace Stats", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Total counts metrics grid
          Row(
            children: [
              Expanded(child: _buildAdminMetricCard("Total Customers", "${_stats['totalUsers']}", Icons.people, Colors.blue)),
              const SizedBox(width: 16),
              Expanded(child: _buildAdminMetricCard("Total Partners", "${_stats['totalProviders']}", Icons.storefront, Colors.teal)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildAdminMetricCard("Active Bookings", "${_stats['activeBookings']}", Icons.library_books_outlined, Colors.orange)),
              const SizedBox(width: 16),
              Expanded(child: _buildAdminMetricCard("Platform Commission (10%)", "₹${(_stats['revenue'] as double).toInt()}", Icons.account_balance_wallet_outlined, Colors.purple)),
            ],
          ),

          const SizedBox(height: 32),
          const Text("Platform Activity Log", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildActivityItem("New plumber listing requested by Amit Verma.", "3 mins ago"),
          _buildActivityItem("Booking book_498f3 completed. Platform earned 10% commission.", "2 hrs ago"),
          _buildActivityItem("Customer customer@fixora.com submitted a 5-star review.", "3 hrs ago"),
          _buildActivityItem("Provider Rajesh Sharma registered business location coordinates.", "Yesterday"),
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
            Icon(Icons.check_circle_outline, size: 54, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 12),
            const Text("All provider profiles are verified and active!", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _unverified.length,
      itemBuilder: (context, index) {
        final prov = _unverified[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(prov.businessName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        prov.category.toUpperCase(),
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text("Owner: ${prov.ownerName} • Exp: ${prov.experienceYears} Years", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text("Address: ${prov.address}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                Text("Hourly starting charges: ₹${prov.startingPrice.toInt()}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        // Quick reject/hold
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Application placed on hold.")),
                        );
                      },
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text("Hold Application"),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => _approve(prov.providerId),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      child: const Text("Approve & Verify"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdminMetricCard(String label, String val, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 12),
            Text(val, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String text, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.bolt, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          Text(time, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}
