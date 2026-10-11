import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_screen.dart';

class ReporterInboxScreen extends StatefulWidget {
  final String itemId;
  final String itemName;

  const ReporterInboxScreen({super.key, required this.itemId, required this.itemName});

  @override
  State<ReporterInboxScreen> createState() => _ReporterInboxScreenState();
}

class _ReporterInboxScreenState extends State<ReporterInboxScreen> {
  final _currentUser = Supabase.instance.client.auth.currentUser!.id;
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
      final res = await Supabase.instance.client
          .from('messages')
          .select('sender_id, receiver_id, created_at')
          .eq('item_id', parsedId)
          .order('created_at', ascending: false);

      // Get unique senders (Lookers)
      final Map<String, DateTime> latestMessageMap = {};
      for (var msg in res) {
        final sender = msg['sender_id'] as String;
        final receiver = msg['receiver_id'] as String;
        
        final date = DateTime.tryParse(msg['created_at'].toString()) ?? DateTime.now();
        
        // Only add them to the inbox if they are NOT the Admin, and NOT the Founder
        // The Admin "makikisawsaw" in the Looker's chat, so Admin doesn't get a separate inbox item.
        // We can just rely on the receiver_id or sender_id.
        // If Founder is receiver, sender is someone else.
        if (sender != _currentUser) {
          if (!latestMessageMap.containsKey(sender) || date.isAfter(latestMessageMap[sender]!)) {
            latestMessageMap[sender] = date;
          }
        }
        
        if (receiver != _currentUser) {
          if (!latestMessageMap.containsKey(receiver) || date.isAfter(latestMessageMap[receiver]!)) {
            latestMessageMap[receiver] = date;
          }
        }
      }

      final List<Map<String, dynamic>> convos = [];
      for (var otherId in latestMessageMap.keys) {
        final profileRes = await Supabase.instance.client.from('profiles').select('full_name, email, avatar_url, role').eq('id', otherId).maybeSingle();
        
        // Skip if this person is an Admin. Admin should not be a separate chat.
        if (profileRes != null && profileRes['role'] == 'admin') {
          continue;
        }

        convos.add({
          'sender_id': otherId,
          'last_message_at': latestMessageMap[otherId],
          'profile': profileRes ?? {},
          'is_admin': false,
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07070E),
      appBar: AppBar(
        title: Text('Messages for ${widget.itemName}', style: const TextStyle(fontSize: 16)),
        backgroundColor: const Color(0xFF07070E),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C6AFF)))
            : _conversations.isEmpty
                ? const Center(child: Text('No messages yet.', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                  itemCount: _conversations.length,
                  itemBuilder: (context, index) {
                    final convo = _conversations[index];
                    final profile = convo['profile'];
                    final name = profile['full_name'] ?? profile['email']?.split('@').first ?? 'User';
                    final avatarUrl = profile['avatar_url'] as String?;
                    final hasAvatar = avatarUrl != null && avatarUrl.trim().isNotEmpty;

                    final isAdmin = convo['is_admin'] ?? false;
                    final subtitle = isAdmin ? 'System Administrator' : 'Tap to view conversation';

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
                          if (isAdmin)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFFE04A5E).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                              child: const Text('ADMIN', style: TextStyle(color: Color(0xFFE04A5E), fontSize: 8, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              itemId: widget.itemId,
                              receiverId: convo['sender_id'],
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
