import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/chat_service.dart';
import '../widgets/chat_message_bubble.dart';

class AdminChatView extends StatefulWidget {
  final String itemId;
  final String reporterId;
  final String itemName;

  const AdminChatView({
    super.key,
    required this.itemId,
    required this.reporterId,
    required this.itemName,
  });

  @override
  State<AdminChatView> createState() => _AdminChatViewState();
}

class _AdminChatViewState extends State<AdminChatView> {
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchConversations();
  }

  Future<void> _fetchConversations() async {
    try {
      final parsedId = int.tryParse(widget.itemId) ?? widget.itemId;
      final currentUserId = Supabase.instance.client.auth.currentUser!.id;
      final res = await Supabase.instance.client
          .from('messages')
          .select('sender_id, receiver_id, created_at')
          .eq('item_id', parsedId)
          .order('created_at', ascending: false);

      final Map<String, DateTime> latestMessageMap = {};
      for (var msg in res) {
        final sender = msg['sender_id'] as String;
        final receiver = msg['receiver_id'] as String;
        
        // We want to group by "the user who is NOT the admin"
        final otherUser = (sender == currentUserId) ? receiver : sender;

        // Skip if the other user is also the admin (shouldn't happen)
        if (otherUser == currentUserId) continue;

        final date = DateTime.tryParse(msg['created_at'].toString()) ?? DateTime.now();
        if (!latestMessageMap.containsKey(otherUser) || date.isAfter(latestMessageMap[otherUser]!)) {
          latestMessageMap[otherUser] = date;
        }
      }

      final List<Map<String, dynamic>> convos = [];
      for (var otherUserId in latestMessageMap.keys) {
        final profileRes = await Supabase.instance.client
            .from('profiles')
            .select('full_name, email, avatar_url')
            .eq('id', otherUserId)
            .maybeSingle();
            
        convos.add({
          'other_user_id': otherUserId,
          'last_message_at': latestMessageMap[otherUserId],
          'profile': profileRes ?? {},
          'is_reporter': otherUserId == widget.reporterId,
        });
      }

      convos.sort((a, b) => (b['last_message_at'] as DateTime).compareTo(a['last_message_at'] as DateTime));

      if (mounted) {
        setState(() {
          _conversations = convos;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('AdminChatView error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _conversations = [{'error': e.toString()}]; // Hack to show error
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07070E),
      appBar: AppBar(
        title: Text('Chat Logs: ${widget.itemName}', style: const TextStyle(fontSize: 16)),
        backgroundColor: const Color(0xFF07070E),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C6AFF)))
            : _conversations.isEmpty
                ? const Center(child: Text('No chat logs found for this item.', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                  itemCount: _conversations.length,
                  itemBuilder: (context, index) {
                    final convo = _conversations[index];
                    if (convo.containsKey('error')) return Text(convo['error']);
                    
                    final profile = convo['profile'];
                    final name = profile['full_name'] ?? profile['email']?.split('@').first ?? 'User';
                    final avatarUrl = profile['avatar_url'] as String?;
                    final hasAvatar = avatarUrl != null && avatarUrl.trim().isNotEmpty;
                    
                    final isReporter = convo['is_reporter'] ?? false;
                    final subtitle = isReporter ? 'Item Reporter (Founder)' : 'Interested User (Looker)';

                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(color: Color(0xFF1A1A2E), shape: BoxShape.circle),
                        clipBehavior: Clip.hardEdge,
                        child: hasAvatar
                            ? Image.network(
                                avatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Center(
                                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: Color(0xFF7C6AFF), fontWeight: FontWeight.bold)),
                                ),
                              )
                            : Center(
                                child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: Color(0xFF7C6AFF), fontWeight: FontWeight.bold)),
                              ),
                      ),
                      title: Row(
                        children: [
                          Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          if (isReporter)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFF7C6AFF).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                              child: const Text('REPORTER', style: TextStyle(color: Color(0xFF7C6AFF), fontSize: 8, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminSingleChatLogScreen(
                              itemId: widget.itemId,
                              reporterId: widget.reporterId,
                              otherUserId: convo['other_user_id'],
                              chatTitle: 'Chat with $name',
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
      ),
    );
  }
}

class AdminSingleChatLogScreen extends StatefulWidget {
  final String itemId;
  final String reporterId;
  final String otherUserId;
  final String chatTitle;

  const AdminSingleChatLogScreen({
    super.key,
    required this.itemId,
    required this.reporterId,
    required this.otherUserId,
    required this.chatTitle,
  });

  @override
  State<AdminSingleChatLogScreen> createState() => _AdminSingleChatLogScreenState();
}

class _AdminSingleChatLogScreenState extends State<AdminSingleChatLogScreen> {
  final TextEditingController _textController = TextEditingController();

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final senderId = Supabase.instance.client.auth.currentUser!.id;
    final parsedId = int.tryParse(widget.itemId) ?? widget.itemId;
    
    // Only send the message to the specific user the admin is chatting with.
    await Supabase.instance.client.from('messages').insert([
      {
        'item_id': parsedId,
        'sender_id': senderId,
        'receiver_id': widget.otherUserId,
        'content': text,
      }
    ]);
    
    _textController.clear();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07070E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF07070E),
        title: Text(widget.chatTitle, style: const TextStyle(fontSize: 16)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: ChatService().getMessagesStream(widget.itemId),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                  }
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF0FE0B0)));
                  
                  final currentUserId = Supabase.instance.client.auth.currentUser?.id;
                  
                  final messages = snapshot.data!.where((msg) {
                    final sender = msg['sender_id'];
                    final receiver = msg['receiver_id'];
                    
                    // ONLY show messages where the specific other user is involved
                    // (either as a sender or receiver)
                    return sender == widget.otherUserId || receiver == widget.otherUserId;
                  }).toList();

                  if (messages.isEmpty) return const Center(child: Text('No messages found.', style: TextStyle(color: Colors.grey)));

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isAdmin = msg['sender_id'] == currentUserId;
                      
                      String? roleTag;
                      if (isAdmin) {
                        roleTag = '(Admin)';
                      } else if (msg['sender_id'] == widget.reporterId) {
                        roleTag = '(Founder)';
                      } else {
                        roleTag = '(Looker)';
                      }
                      
                      // Only Admin is "Me" (on the right) in the Admin View
                      return ChatMessageBubble(message: msg, isMe: isAdmin, forceRight: isAdmin, roleTag: roleTag);
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF111120),
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Type a message as Admin...',
                        hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.5)),
                        filled: true,
                        fillColor: const Color(0xFF1A1A2E),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(color: Color(0xFF7C6AFF), shape: BoxShape.circle),
                      child: const Icon(Icons.send, color: Colors.white, size: 20),
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
