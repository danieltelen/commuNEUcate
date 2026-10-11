import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'item_details_screen.dart';

class UnclaimedItemsListScreen extends StatefulWidget {
  const UnclaimedItemsListScreen({super.key});

  @override
  State<UnclaimedItemsListScreen> createState() => _UnclaimedItemsListScreenState();
}

class _UnclaimedItemsListScreenState extends State<UnclaimedItemsListScreen> {
  final _searchController = TextEditingController();
  List<dynamic> _allItems = [];
  List<dynamic> _filteredItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUnclaimedItems();
  }

  Future<void> _fetchUnclaimedItems() async {
    try {
      final response = await Supabase.instance.client
          .from('reports')
          .select('*')
          .eq('status', 'unclaimed')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _allItems = response;
          _filteredItems = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _filteredItems = _allItems;
      });
      return;
    }

    final terms = query.toLowerCase().split(' ').where((t) => t.isNotEmpty).toList();
    setState(() {
      _filteredItems = _allItems.where((item) {
        final name = (item['item_name'] ?? '').toString().toLowerCase();
        final tags = (item['tags'] ?? '').toString().toLowerCase();
        final loc = (item['location_found'] ?? '').toString().toLowerCase();

        return terms.any((term) =>
            name.contains(term) || tags.contains(term) || loc.contains(term));
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07070E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF07070E),
        elevation: 0,
        title: const Text('Unclaimed Items'),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF111120),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C6AFF)))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search unclaimed items...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF111120),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredItems.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('No unclaimed items found', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = _filteredItems[index];
                            return Card(
                              color: const Color(0xFF111120),
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  width: 1,
                                ),
                              ),
                              child: ListTile(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => ItemDetailsScreen(item: item)),
                                  );
                                  _fetchUnclaimedItems(); // Refresh on pop back
                                },
                                contentPadding: const EdgeInsets.all(12),
                                leading: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF07070E),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  clipBehavior: Clip.hardEdge,
                                  child: item['image_url'] != null
                                      ? Image.network(item['image_url'], fit: BoxFit.cover, errorBuilder: (_,_,_) => const Icon(Icons.broken_image, color: Colors.grey))
                                      : const Icon(Icons.image, color: Colors.grey),
                                ),
                                title: Text(item['item_name'] ?? 'Unknown Item', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('Location: ${item['location_found'] ?? 'Unknown'}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    Text('Found: ${item['date_found'] ?? 'Unknown'}', style: const TextStyle(color: Color(0xFFA99BFF), fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
