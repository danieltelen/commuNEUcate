import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'item_details_screen.dart';
import '../utils/toast.dart';

class AdminItemsScreen extends StatefulWidget {
  const AdminItemsScreen({super.key});

  @override
  State<AdminItemsScreen> createState() => _AdminItemsScreenState();
}

class _AdminItemsScreenState extends State<AdminItemsScreen> {
  List<dynamic> _items = [];
  bool _isLoading = true;
  bool _isAlerting = false;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    try {
      final response = await Supabase.instance.client.from('reports').select('*').order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _items = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _alertUnclaimedItems() async {
    setState(() => _isAlerting = true);
    try {
      final supabase = Supabase.instance.client;
      final adminId = supabase.auth.currentUser!.id;

      // 1. Fetch all unclaimed items
      final unclaimedRes = await supabase.from('reports').select('*').eq('status', 'unclaimed');
      if (unclaimedRes.isEmpty) {
        if (mounted) {
          showTopToast(context, 'No active unclaimed items to alert!');
          setState(() => _isAlerting = false);
        }
        return;
      }

      // 2. Fetch all profiles (students)
      final profiles = await supabase.from('profiles').select('id');

      // 3. Insert real-time broadcast system alerts
      final inserts = <Map<String, dynamic>>[];
      for (var profile in profiles) {
        final userId = profile['id']?.toString();
        if (userId == null || userId == adminId) continue;

        inserts.add({
          'item_id': unclaimedRes.first['id'], // Provide a valid item UUID to bypass foreign key constraint
          'sender_id': adminId,
          'receiver_id': userId,
          'content': '[SYSTEM_ALERT_UNCLAIMED] Active unclaimed items are waiting to be claimed! Tap here to view the full list.',
        });
      }

      if (inserts.isNotEmpty) {
        await supabase.from('messages').insert(inserts);
      }

      if (mounted) {
        showTopToast(context, 'Broadcast Alert sent to all students successfully!');
        setState(() => _isAlerting = false);
      }
    } catch (e) {
      if (mounted) {
        showTopToast(context, 'Error sending broadcast alert: $e');
        setState(() => _isAlerting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07070E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF07070E),
        elevation: 0,
        title: const Text('View All Items'),
        actions: [
          _isAlerting
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Color(0xFF0FE0B0), strokeWidth: 2),
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.campaign, color: Color(0xFF7C6AFF), size: 28),
                  tooltip: 'Alert Students of Unclaimed Items',
                  onPressed: _alertUnclaimedItems,
                ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0FE0B0)))
          : _items.isEmpty
              ? const Center(
                  child: Text('No items reported yet', style: TextStyle(color: Colors.grey)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Card(
                      color: const Color(0xFF111120),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ItemDetailsScreen(item: item, isAdmin: true)),
                          ).then((_) => _fetchItems());
                        },
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF07070E),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: item['image_url'] != null
                              ? Image.network(item['image_url'], fit: BoxFit.cover, errorBuilder: (_,_,_) => const Icon(Icons.broken_image, color: Colors.grey))
                              : const Icon(Icons.inventory_2, color: Colors.grey),
                        ),
                        title: Text(item['item_name'] ?? 'Unknown Item', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        subtitle: Text(item['location_found'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        trailing: Text(
                          (item['status'] ?? 'pending').toString().toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: item['status'] == 'claimed' ? Colors.grey : const Color(0xFF0FE0B0),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
