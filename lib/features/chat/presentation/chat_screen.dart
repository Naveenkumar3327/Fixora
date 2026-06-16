import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/global_providers.dart';
import '../../../core/theme/theme.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String senderId;
  final String receiverId;
  final String partnerName;

  const ChatScreen({
    super.key,
    required this.senderId,
    required this.receiverId,
    required this.partnerName,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  late Stream<List<ChatMessage>> _chatStream;

  @override
  void initState() {
    super.initState();
    final dbSvc = ref.read(databaseServiceProvider);
    _chatStream = dbSvc.getChatMessagesStream(widget.senderId, widget.receiverId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    final dbSvc = ref.read(databaseServiceProvider);
    
    final message = ChatMessage(
      id: "msg_${const Uuid().v4().substring(0, 8)}",
      senderId: widget.senderId,
      receiverId: widget.receiverId,
      text: text,
      timestamp: DateTime.now(),
    );

    await dbSvc.sendChatMessage(message);
    _scrollToBottom();

    // Mock automatic reply simulation for realism
    Future.delayed(const Duration(seconds: 2), () async {
      String replyText = "Understood. I am looking into this right now!";
      if (text.toLowerCase().contains("where") || text.toLowerCase().contains("reach")) {
        replyText = "I have started driving. I'll reach your location in about 10 minutes.";
      } else if (text.toLowerCase().contains("cost") || text.toLowerCase().contains("price")) {
        replyText = "The starting charge is as mentioned. The final quote will be provided after visual inspection.";
      } else if (text.toLowerCase().contains("photo") || text.toLowerCase().contains("image")) {
        replyText = "Received. Thank you, that helps me prepare the required tools.";
      }

      final reply = ChatMessage(
        id: "msg_${const Uuid().v4().substring(0, 8)}",
        senderId: widget.receiverId,
        receiverId: widget.senderId,
        text: replyText,
        timestamp: DateTime.now(),
      );

      await dbSvc.sendChatMessage(reply);
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dbSvc = ref.watch(databaseServiceProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                ),
              ),
              child: Center(
                child: Text(
                  widget.partnerName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.partnerName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const Text("Online", style: TextStyle(fontSize: 11, color: AppTheme.successColor, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: PremiumBackground(
        child: Column(
          children: [
            const SizedBox(height: 100),
            // Messages Board
            Expanded(
              child: StreamBuilder<List<ChatMessage>>(
                stream: _chatStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data ?? [];
                  
                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 48, color: AppTheme.textSecondary.withOpacity(0.4)),
                          const SizedBox(height: 8),
                          Text("No messages yet. Send a message to start.", style: TextStyle(color: AppTheme.textSecondary)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg.senderId == widget.senderId;

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            gradient: isMe
                                ? const LinearGradient(
                                    colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: isMe ? null : AppTheme.darkCard.withOpacity(0.55),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                              bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                            ),
                            border: Border.all(
                              color: isMe ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.08),
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg.text,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.5,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    "${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}",
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: Colors.white60,
                                    ),
                                  ),
                                  if (isMe) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.done_all, size: 12, color: AppTheme.primaryColor),
                                  ]
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Message Input bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: GlassCard(
                borderRadius: 24,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add_photo_alternate_outlined, color: AppTheme.textSecondary),
                      onPressed: () {
                        _messageController.text = "[Attachment]: Uploaded diagnostic image.";
                        _sendMessage();
                      },
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: TextField(
                          controller: _messageController,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          decoration: const InputDecoration(
                            hintText: "Type your message here...",
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryColor,
                        ),
                        child: const Icon(Icons.send, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

