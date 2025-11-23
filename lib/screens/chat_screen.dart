import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../providers/providers.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String playlistId;
  final String playlistName;
  const ChatScreen({super.key, required this.playlistId, required this.playlistName});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProviderInstance.notifier).loadMessages(widget.playlistId);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ref.read(chatProviderInstance.notifier).loadMessages(widget.playlistId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(authProviderInstance).currentUser;
    if (user == null) return;

    await ref.read(chatProviderInstance.notifier).sendMessage(
      playlistId: widget.playlistId,
      playlistName: widget.playlistName,
      userId: user.uid,
      displayName: user.displayName,
      profilePicture: user.profilePicture,
      messageText: text,
    );

    _messageController.clear();
    _scrollToBottom();
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(dateTime);
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProviderInstance).messages;
    final currentUser = ref.watch(authProviderInstance).currentUser;

    // Auto-scroll when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.playlistName),
            Text(
              '${messages.length} messages',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 80,
                          color: AppTheme.textTertiary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start the conversation!',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isCurrentUser = currentUser?.uid == message.userId;
                      final showAvatar = index == 0 ||
                          messages[index - 1].userId != message.userId;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: isCurrentUser
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            if (!isCurrentUser && showAvatar) ...[
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppTheme.surfaceColor,
                                backgroundImage: message.profilePicture != null
                                    ? CachedNetworkImageProvider(message.profilePicture!)
                                    : null,
                                child: message.profilePicture == null
                                    ? Text(
                                        message.displayName[0].toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textPrimary,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 8),
                            ] else if (!isCurrentUser)
                              const SizedBox(width: 40),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: isCurrentUser
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  if (showAvatar && !isCurrentUser)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        message.displayName,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppTheme.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isCurrentUser
                                          ? AppTheme.primaryColor
                                          : AppTheme.surfaceColor,
                                      borderRadius: BorderRadius.circular(20).copyWith(
                                        bottomLeft: isCurrentUser
                                            ? const Radius.circular(20)
                                            : const Radius.circular(4),
                                        bottomRight: isCurrentUser
                                            ? const Radius.circular(4)
                                            : const Radius.circular(20),
                                      ),
                                    ),
                                    child: Text(
                                      message.message,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: isCurrentUser
                                            ? Colors.white
                                            : AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTime(message.timestamp),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textTertiary,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isCurrentUser && showAvatar) ...[
                              const SizedBox(width: 8),
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppTheme.surfaceColor,
                                backgroundImage: currentUser?.profilePicture != null
                                    ? CachedNetworkImageProvider(currentUser!.profilePicture!)
                                    : null,
                                child: currentUser?.profilePicture == null
                                    ? Text(
                                        currentUser?.displayName[0].toUpperCase() ?? 'U',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textPrimary,
                                        ),
                                      )
                                    : null,
                              ),
                            ] else if (isCurrentUser)
                              const SizedBox(width: 40),
                          ],
                        ),
    );
                    },
                  ),
          ),
          // Message Input
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          filled: true,
                          fillColor: AppTheme.backgroundColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    CircleAvatar(
                      backgroundColor: AppTheme.primaryColor,
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

