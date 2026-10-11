import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  final _supabase = Supabase.instance.client;

  // Realtime listener para sa messages
  Stream<List<Map<String, dynamic>>> getMessagesStream(String itemId) {
    final parsedId = int.tryParse(itemId) ?? itemId;
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('item_id', parsedId)
        .order('created_at', ascending: true);
  }

  // Function pang-send ng message
  Future<void> sendMessage(String itemId, String receiverId, String text) async {
    final senderId = _supabase.auth.currentUser!.id;
    final parsedId = int.tryParse(itemId) ?? itemId;
    await _supabase.from('messages').insert({
      'item_id': parsedId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': text.trim(),
    });
  }
}
