import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/global_providers.dart';
import 'chat_screen.dart';

class ChatListScreen extends ConsumerWidget {
  final String currentUserId;
  const ChatListScreen({super.key, required this.currentUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbSvc = ref.watch(databaseServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Direct Messages"),
      ),
      body: StreamBuilder<List<AppUser>>(
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
                  Icon(Icons.question_answer_outlined, size: 48, color: Colors.grey.withOpacity(0.4)),
                  const SizedBox(height: 8),
                  const Text("No active chats yet.", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 4),
                  const Text("Contact a service provider to start a chat.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: partners.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final partner = partners[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: Text(
                    partner.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                  ),
                ),
                title: Text(partner.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Role: ${partner.role.name.toUpperCase()}"),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        senderId: currentUserId,
                        receiverId: partner.uid,
                        partnerName: partner.name,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
