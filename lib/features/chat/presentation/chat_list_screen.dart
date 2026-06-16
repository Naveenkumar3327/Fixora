import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/global_providers.dart';
import '../../../core/theme/theme.dart';
import 'chat_screen.dart';

class ChatListScreen extends ConsumerWidget {
  final String currentUserId;
  const ChatListScreen({super.key, required this.currentUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbSvc = ref.watch(databaseServiceProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Direct Messages"),
      ),
      body: PremiumBackground(
        child: StreamBuilder<List<AppUser>>(
          stream: dbSvc.getActiveChatPartnersStream(currentUserId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final partners = snapshot.data ?? [];

            if (partners.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.question_answer_outlined, size: 48, color: AppTheme.textSecondary.withOpacity(0.4)),
                    const SizedBox(height: 8),
                    const Text("No active chats yet.", style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("Contact a service provider to start a chat.", style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              );
            }

            return ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 100),
              itemCount: partners.length,
              itemBuilder: (context, index) {
                final partner = partners[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    borderRadius: 16,
                    padding: const EdgeInsets.all(8),
                    child: ListTile(
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                          ),
                          boxShadow: [
                            BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 6)
                          ],
                        ),
                        child: Center(
                          child: Text(
                            partner.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                      title: Text(partner.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                      subtitle: Text("Role: ${partner.role.name.toUpperCase()}", style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right, color: AppTheme.primaryColor),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              senderId: currentUserId,
                              partnerName: partner.name,
                              receiverId: partner.uid,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 350.ms)
                    .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad);
              },
            );
          },
        ),
      ),
    );
  }
}

