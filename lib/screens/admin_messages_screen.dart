import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminMessagesScreen extends StatefulWidget {
  const AdminMessagesScreen({super.key});

  @override
  State<AdminMessagesScreen> createState() => _AdminMessagesScreenState();
}

class _AdminMessagesScreenState extends State<AdminMessagesScreen> {
  final _currentUser = Supabase.instance.client.auth.currentUser!.id;
  bool _isLoading = true;
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _fetchAdminMessages();
  }

  Future<void> _fetchAdminMessages() async {
    try {
      // Get all messages where receiver is current user
      final res = await Supabase.instance.client
          .from('messages')
          .select('*, profiles!sender_id(role, full_name, avatar_url)')
          .eq('receiver_id', _currentUser)
          .order('created_at', ascending: false);

      // Filter to only messages from admin
      final adminMessages = res.where((msg) {
        final profile = msg['profiles'];
        return profile != null && profile['role'] == 'admin';
      }).toList();

      if (mounted) {
        setState(() {
          _messages = List<Map<String, dynamic>>.from(adminMessages);
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
        title: const Text('Admin Messages & Announcements', style: TextStyle(fontSize: 16)),
        backgroundColor: const Color(0xFF07070E),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C6AFF)))
            : _messages.isEmpty
                ? const Center(child: Text('No messages from Admin yet.', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final profile = msg['profiles'];
                      final name = profile['full_name'] ?? 'Admin';
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111120),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF7C6AFF).withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.campaign, color: Color(0xFF7C6AFF), size: 20),
                                  const SizedBox(width: 8),
                                  Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  const Spacer(),
                                  Text(
                                    _formatDate(msg['created_at']),
                                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(msg['content'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14)),
                              if (msg['item_id'] != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7C6AFF).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('Related to Item #${msg['item_id']}', style: const TextStyle(color: Color(0xFF7C6AFF), fontSize: 10)),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    return '${date.month}/${date.day}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
