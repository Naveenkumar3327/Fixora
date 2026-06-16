import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/global_providers.dart';
import '../../../core/theme/theme.dart';
import '../../../core/theme/logo.dart';
import 'auth_screen.dart';

class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRole = ref.watch(registrationRoleProvider);

    return Scaffold(
      body: PremiumBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                // Premium Animated Logo
                const Center(
                  child: FixoraLogo(size: 100),
                ),
                const SizedBox(height: 16),
                
                // Greeting Headers
                Text(
                  "Welcome to Fixora",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    fontSize: 28,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack),
                
                const SizedBox(height: 8),
                
                Text(
                  "Choose how you want to use the marketplace",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 400.ms),
                
                const SizedBox(height: 36),

                // Role selection cards
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildRoleCard(
                        context: context,
                        role: UserRole.customer,
                        icon: Icons.person_rounded,
                        title: "I am a Customer",
                        description: "Find local professionals, check ratings, and book instant repairs.",
                        isSelected: selectedRole == UserRole.customer,
                        onTap: () => ref.read(registrationRoleProvider.notifier).state = UserRole.customer,
                        accentColor: AppTheme.primaryColor,
                      )
                          .animate()
                          .fadeIn(delay: 100.ms, duration: 450.ms)
                          .slideX(begin: -0.1, end: 0, curve: Curves.easeOutQuad),
                      const SizedBox(height: 16),
                      
                      _buildRoleCard(
                        context: context,
                        role: UserRole.provider,
                        icon: Icons.business_center_rounded,
                        title: "I am a Service Provider",
                        description: "Register your business, accept local bookings, and track earnings.",
                        isSelected: selectedRole == UserRole.provider,
                        onTap: () => ref.read(registrationRoleProvider.notifier).state = UserRole.provider,
                        accentColor: AppTheme.secondaryColor,
                      )
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 450.ms)
                          .slideX(begin: -0.1, end: 0, curve: Curves.easeOutQuad),
                      const SizedBox(height: 16),
                      
                      _buildRoleCard(
                        context: context,
                        role: UserRole.admin,
                        icon: Icons.admin_panel_settings_rounded,
                        title: "I am an Admin",
                        description: "Approve business listings, resolve disputes, and view analytics.",
                        isSelected: selectedRole == UserRole.admin,
                        onTap: () => ref.read(registrationRoleProvider.notifier).state = UserRole.admin,
                        accentColor: AppTheme.warningColor,
                      )
                          .animate()
                          .fadeIn(delay: 300.ms, duration: 450.ms)
                          .slideX(begin: -0.1, end: 0, curve: Curves.easeOutQuad),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),

                // Action Continue button
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => const AuthScreen(),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(1, 0),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
                            child: child,
                          );
                        },
                        transitionDuration: const Duration(milliseconds: 400),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: selectedRole == UserRole.customer
                            ? [AppTheme.primaryColor, AppTheme.secondaryColor]
                            : selectedRole == UserRole.provider
                                ? [AppTheme.secondaryColor, const Color(0xFFC084FC)]
                                : [AppTheme.warningColor, const Color(0xFFFDBA74)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (selectedRole == UserRole.customer
                                  ? AppTheme.primaryColor
                                  : selectedRole == UserRole.provider
                                      ? AppTheme.secondaryColor
                                      : AppTheme.warningColor)
                              .withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Continue",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 400.ms)
                    .scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required UserRole role,
    required IconData icon,
    required String title,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
    required Color accentColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutQuad,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withOpacity(0.08)
              : AppTheme.darkCard.withOpacity(0.4),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? accentColor : Colors.white.withOpacity(0.08),
            width: isSelected ? 2.0 : 1.2,
          ),
          // Neo-Brutalism Offset Shadow style mixed with glass elevation
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withOpacity(0.25),
                    offset: const Offset(3, 4),
                    blurRadius: 0,
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? accentColor.withOpacity(0.15) : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? accentColor.withOpacity(0.3) : Colors.transparent,
                ),
              ),
              child: Icon(
                icon,
                color: isSelected ? accentColor : AppTheme.textSecondary,
                size: 28,
              ),
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
                      fontSize: 16,
                      color: isSelected ? accentColor : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? AppTheme.textPrimary.withOpacity(0.8) : AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

