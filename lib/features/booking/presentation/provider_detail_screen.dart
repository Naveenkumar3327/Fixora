import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/global_providers.dart';
import '../../../core/theme/theme.dart';
import 'booking_form_screen.dart';
import '../../chat/presentation/chat_screen.dart';

class ProviderDetailScreen extends ConsumerWidget {
  final ProviderProfile provider;

  const ProviderDetailScreen({super.key, required this.provider});

  void _callProvider(BuildContext context) async {
    final Uri url = Uri.parse("tel:${provider.phone}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Cannot call ${provider.phone} directly.")),
      );
    }
  }

  void _whatsappProvider(BuildContext context) async {
    final Uri url = Uri.parse("https://wa.me/${provider.whatsapp.replaceAll('+', '')}?text=Hello%20${provider.ownerName},%20I%20found%20you%20on%20Fixora.");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("WhatsApp is not installed on this device.")),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);

    return Scaffold(
      body: PremiumBackground(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Elegant Header Image & Verification Badge
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: AppTheme.darkBg,
              iconTheme: const IconThemeData(color: Colors.white),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  provider.businessName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1))],
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.handyman_rounded,
                          size: 80,
                          color: Colors.white.withOpacity(0.18),
                        ),
                      ),
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, AppTheme.darkBg],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Verification Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                          ),
                          child: Text(
                            provider.category.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (provider.isVerified)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.successColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.successColor.withOpacity(0.2)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified, color: AppTheme.successColor, size: 12),
                                SizedBox(width: 4),
                                Text(
                                  "VERIFIED PRO",
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.successColor),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Key Details Row (Experience, Rating, Starting Price) inside glass container
                    GlassCard(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      borderRadius: 18,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildDetailMetric(context, "${provider.experienceYears}+ Yrs", "Experience"),
                          _buildDetailMetric(context, "${provider.rating} ⭐", "${provider.reviewsCount} Reviews"),
                          _buildDetailMetric(context, "₹${provider.startingPrice.toInt()}", "Starts at"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
          
                    // About & Services details
                    const Text(
                      "Service Provider Details",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      borderRadius: 16,
                      child: Column(
                        children: [
                          _buildProfileItem(Icons.person, "Owner Name", provider.ownerName),
                          const Divider(color: Colors.white12, height: 16),
                          _buildProfileItem(Icons.location_on, "Business Center", provider.address),
                          const Divider(color: Colors.white12, height: 16),
                          _buildProfileItem(Icons.access_time, "Working Hours", provider.workingHours),
                          const Divider(color: Colors.white12, height: 16),
                          _buildProfileItem(Icons.near_me, "Service Radius", provider.serviceArea),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
          
                    // Contact shortcuts row
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _callProvider(context),
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: AppTheme.darkCard.withOpacity(0.5),
                                border: Border.all(color: Colors.white.withOpacity(0.08)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.call, color: AppTheme.primaryColor, size: 18),
                                  SizedBox(width: 8),
                                  Text("Call Phone", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _whatsappProvider(context),
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: AppTheme.successColor.withOpacity(0.12),
                                border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.chat, color: AppTheme.successColor, size: 18),
                                  SizedBox(width: 8),
                                  Text("WhatsApp", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successColor)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Chat in app trigger
                    if (user != null && user.uid != provider.providerId)
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                senderId: user.uid,
                                receiverId: provider.providerId,
                                partnerName: provider.businessName,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(
                              colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.message_outlined, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text("Message Provider In-App", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                        ),
                      )
                          .animate()
                          .scale(begin: const Offset(0.98, 0.98), duration: 200.ms),
                    
                    const SizedBox(height: 32),
                    
                    // Reviews Section title
                    const Text("Customer Reviews", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    const SizedBox(height: 12),
                    
                    // List of Reviews mock
                    if (provider.reviewsCount == 0)
                      Text("No reviews yet. Be the first to book and rate!", style: TextStyle(color: AppTheme.textSecondary, fontSize: 13))
                    else ...[
                      _buildReviewCard("Ramesh Kumar", 5.0, "Excellent work! Resolved my short-circuit issue in 15 minutes. Very polite."),
                      _buildReviewCard("Sita Gupta", 4.0, "Great experience, very knowledgeable and came on time. Pricing is reasonable."),
                    ],
                    
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: user == null
          ? Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.darkBg,
              child: const Text(
                "Please sign in to book services",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold),
              ),
            )
          : provider.providerId == user.uid
              ? null
              : Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard.withOpacity(0.65),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => BookingFormScreen(provider: provider),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Book Appointment Now"),
                  ),
                ),
    );
  }

  Widget _buildDetailMetric(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildProfileItem(IconData icon, String title, String val) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(String reviewer, double rating, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(14.0),
        borderRadius: 14,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(reviewer, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 12),
                    const SizedBox(width: 2),
                    Text("$rating", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(text, style: TextStyle(fontSize: 12, color: AppTheme.textPrimary.withOpacity(0.9), height: 1.4)),
          ],
        ),
      ),
    );
  }
}

