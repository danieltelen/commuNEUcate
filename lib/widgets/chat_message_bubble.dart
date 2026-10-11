import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatMessageBubble extends StatefulWidget {
  final Map<String, dynamic> message;
  final bool isMe;
  final bool forceRight;
  final String? roleTag;

  const ChatMessageBubble({super.key, required this.message, required this.isMe, this.forceRight = false, this.roleTag});

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble> {
  static final Map<String, Map<String, dynamic>> _profileCache = {};

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void didUpdateWidget(covariant ChatMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message['sender_id'] != widget.message['sender_id']) {
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    final senderId = widget.message['sender_id'];
    if (senderId is! String || senderId.isEmpty) {
      return;
    }

    if (_profileCache.containsKey(senderId)) {
      return;
    }

    try {
      final res = await Supabase.instance.client
          .from('profiles')
          .select('full_name, email, avatar_url')
          .eq('id', senderId)
          .maybeSingle();
      _profileCache[senderId] = res ?? {};
    } catch (_) {
      // Keep rendering the message if the profile lookup fails.
      _profileCache[senderId] = {};
    }

    if (mounted && widget.message['sender_id'] == senderId) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final senderId = widget.message['sender_id'];
    final profile = senderId is String ? (_profileCache[senderId] ?? {}) : <String, dynamic>{};
    final String fullName = profile['full_name'] ?? profile['email']?.split('@').first ?? 'User';
    final avatarUrl = profile['avatar_url'] as String?;
    final hasAvatar = avatarUrl != null && avatarUrl.trim().isNotEmpty;
    
    final bool alignRight = widget.isMe || widget.forceRight;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!alignRight) ...[
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(color: Color(0xFF1A1A2E), shape: BoxShape.circle),
              clipBehavior: Clip.hardEdge,
              child: hasAvatar
                  ? Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Text(fullName.isNotEmpty ? fullName[0].toUpperCase() : '?', style: const TextStyle(color: Color(0xFF7C6AFF), fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    )
                  : Center(
                      child: Text(fullName.isNotEmpty ? fullName[0].toUpperCase() : '?', style: const TextStyle(color: Color(0xFF7C6AFF), fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!alignRight)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      widget.roleTag != null ? '$fullName ${widget.roleTag}' : fullName,
                      style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: widget.forceRight ? const Color(0xFFE04A5E) : (widget.isMe ? const Color(0xFF7C6AFF) : const Color(0xFF1A1A2E)),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: alignRight ? const Radius.circular(16) : Radius.zero,
                      bottomRight: alignRight ? Radius.zero : const Radius.circular(16),
                    ),
                  ),
                  child: Text(widget.message['content'] ?? '', style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
