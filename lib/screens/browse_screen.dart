import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'item_details_screen.dart';

class BrowseScreen extends StatefulWidget {
  final String? initialSearchQuery;
  final bool isStandalone;

  const BrowseScreen({
    super.key,
    this.initialSearchQuery,
    this.isStandalone = false,
  });

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'All Items';

  @override
  void initState() {
    super.initState();
    if (widget.initialSearchQuery != null) {
      _searchController.text = widget.initialSearchQuery!;
    }
  }

  Future<List<dynamic>> _fetchItems() async {
    var query = Supabase.instance.client
        .from('reports')
        .select('*')
        .neq('status', 'pending_review')
        .neq('status', 'rejected');

    if (_selectedCategory != 'All Items') {
      query = query.eq('category', _selectedCategory);
    }

    final res = await query.order('created_at', ascending: false);
    if (_searchController.text.trim().isNotEmpty) {
      final searchTerms = _searchController.text
          .toLowerCase()
          .split(' ')
          .where((s) => s.isNotEmpty)
          .toList();
      return res.where((item) {
        final name = (item['item_name'] ?? '').toString().toLowerCase();
        final tags = (item['tags'] ?? '').toString().toLowerCase();
        final loc = (item['location_found'] ?? '').toString().toLowerCase();

        // Return true if ANY of the search terms are found in the name, tags, or loc
        return searchTerms.any(
          (term) =>
              name.contains(term) || tags.contains(term) || loc.contains(term),
        );
      }).toList();
    }
    return res;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Items'),
        automaticallyImplyLeading: widget.isStandalone,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search items, tags, locations...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFF111120),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('All Items'),
                _buildFilterChip('Electronics'),
                _buildFilterChip('Accessories'),
                _buildFilterChip('Documents'),
                _buildFilterChip('Clothing'),
                _buildFilterChip('Others'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _fetchItems(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF7C6AFF)),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return const Center(
                    child: Text(
                      'No items found.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        onTap: () async {
                          final updated = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ItemDetailsScreen(item: item),
                            ),
                          );
                          if (updated == true) {
                            _fetchItems();
                          }
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
                              ? Image.network(
                                  item['image_url'],
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.image, color: Colors.grey),
                        ),
                        title: Text(
                          item['item_name'] ?? 'Unknown Item',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Location: ${item['location_found'] ?? 'Unknown'}',
                            ),
                            Text('Found: ${item['date_found'] ?? 'Unknown'}'),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF7C6AFF).withValues(alpha: 0.2)
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? const Color(0xFF7C6AFF)
                : Colors.white.withValues(alpha: 0.1),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFFA99BFF) : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
