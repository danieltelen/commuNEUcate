import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/chat_service.dart';
import '../widgets/chat_message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String itemId;
  final String receiverId;
  final String chatTitle;

  const ChatScreen({super.key, required this.itemId, required this.receiverId, required this.chatTitle});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}
class _ChatScreenState extends State<ChatScreen> {
  final _chatService = ChatService();
  final _textController = TextEditingController();
  final _currentUser = Supabase.instance.client.auth.currentUser!.id;
  String? _reporterId;

  @override
  void initState() {
    super.initState();
    _fetchReporterId();
  }

  Future<void> _fetchReporterId() async {
    final parsedId = int.tryParse(widget.itemId) ?? widget.itemId;
    final res = await Supabase.instance.client.from('reports').select('reporter_id').eq('id', parsedId).maybeSingle();
    if (res != null && mounted) {
      setState(() {
        _reporterId = res['reporter_id'] as String?;
      });
    }
  }

  void _send() {
    if (_textController.text.trim().isNotEmpty) {
      _chatService.sendMessage(widget.itemId, widget.receiverId, _textController.text);
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07070E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF07070E),
        title: Text(widget.chatTitle),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chatService.getMessagesStream(widget.itemId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF7C6AFF)));
                  final messages = snapshot.data!.where((msg) {
                    final sender = msg['sender_id'];
                    final receiver = msg['receiver_id'];
                    
                    // Only show messages between the current user and the specific receiver
                    return (sender == widget.receiverId && receiver == _currentUser) ||
                           (sender == _currentUser && receiver == widget.receiverId);
                  }).toList();
                if (messages.isEmpty) {
                  return const Center(child: Text('No messages yet. Say hi!', style: TextStyle(color: Colors.grey)));
                }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg['sender_id'] == _currentUser;
                        
                        String? roleTag;
                        if (msg['sender_id'] == _reporterId) {
                          roleTag = '(Founder)';
                        } else {
                          roleTag = '(Looker)';
                        }

                        // We can check if the receiverId we are chatting with is an Admin, or if someone else intervened.
                        // For simplicity, if we know it's not us and not the reporter, and it's either an admin or an intervention:
                        // A more robust way is to just fetch profiles, but we'll use a heuristic for now: 
                        // If it's not the reporter and not the current user, it might be an Admin.
                        if (msg['sender_id'] != _currentUser && msg['sender_id'] != _reporterId) {
                          // We'll just label them as Admin since students can't talk to other students anymore.
                          roleTag = '(Admin)';
                        }
                        
                        return ChatMessageBubble(message: msg, isMe: isMe, roleTag: roleTag);
                      },
                    );
              },
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF111120),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFF07070E),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF7C6AFF),
                    radius: 24,
                    child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: _send),
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
