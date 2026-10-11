import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'find_item_screen.dart';
import 'item_details_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const HomeScreen({super.key, this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _firstName = 'User';
  int _itemsFoundCount = 0;
  int _claimedCount = 0;
  List<dynamic> _recentItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null && user.email != null) {
        // Parse firstname.lastname@neu.edu.ph -> firstname
        final email = user.email!;
        if (email.contains('.')) {
          final firstPart = email.split('.').first;
          // Capitalize first letter
          _firstName =
              firstPart[0].toUpperCase() + firstPart.substring(1).toLowerCase();
        } else {
          _firstName = email.split('@').first;
        }
      }

      // Fetch personal stats for the current user
      int found = 0;
      int claimed = 0;

      if (user != null) {
        // Automatically ensure the user has a profile in the profiles table
        // This fixes the foreign key constraint error for older accounts
        try {
          // Extract name from metadata if possible, else fallback to email prefix
          String fallbackName = user.email?.split('@')[0] ?? 'User';
          final metadataName = user.userMetadata?['full_name'];
          final nameToUse =
              (metadataName != null && metadataName.toString().isNotEmpty)
              ? metadataName
              : fallbackName;

          String? avatarUrl =
              user.userMetadata?['avatar_url'] ?? user.userMetadata?['picture'];
          if (avatarUrl != null &&
              avatarUrl.contains('googleusercontent.com') &&
              avatarUrl.contains('=')) {
            avatarUrl = '${avatarUrl.split('=').first}=s1024';
          }

          await Supabase.instance.client.from('profiles').upsert({
            'id': user.id,
            'email': user.email ?? 'unknown@email.com',
            'full_name': nameToUse,
            'role': 'user',
            'avatar_url': ?avatarUrl,
          });
        } catch (e) {
          // Ignore if it fails
        }

        // Count items reported (found) by this specific user
        final personalReports = await Supabase.instance.client
            .from('reports')
            .select('id')
            .eq('reporter_id', user.id);
        found = personalReports.length;

        // Count successful claims made by this specific user
        final personalClaims = await Supabase.instance.client
            .from('claims')
            .select('id')
            .eq('claimer_id', user.id)
            .eq('status', 'approved');
        claimed = personalClaims.length;
      }

      // Fetch global recent items to show in the feed (only approved/unclaimed or claimed)
      final recentReports = await Supabase.instance.client
          .from('reports')
          .select('*')
          .neq('status', 'pending_review')
          .neq('status', 'rejected')
          .order('created_at', ascending: false)
          .limit(3);

      if (mounted) {
        setState(() {
          _itemsFoundCount = found;
          _claimedCount = claimed;
          _recentItems = recentReports;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF7C6AFF)),
      );
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Good day',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _firstName,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Items Found',
                  '$_itemsFoundCount',
                  const Color(0xFFA99BFF),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Claimed',
                  '$_claimedCount',
                  const Color(0xFF0FE0B0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (context, constraints) {
              final reportAction = _buildActionCard(
                'Found Something?',
                'Report a found item',
                Icons.camera_alt_outlined,
                const Color(0xFF7C6AFF),
                () => widget.onNavigate?.call(2),
              );
              final searchAction = _buildActionCard(
                'Lost Something?',
                'Search & claim items',
                Icons.search,
                const Color(0xFF0FE0B0),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FindItemScreen()),
                ),
              );
              if (constraints.maxWidth < 520) {
                return Column(
                  children: [reportAction, const SizedBox(height: 12), searchAction],
                );
              }
              return Row(
                children: [
                  Expanded(child: reportAction),
                  const SizedBox(width: 16),
                  Expanded(child: searchAction),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Items',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'See all',
                  style: TextStyle(color: Color(0xFF7C6AFF)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._recentItems.map((item) {
            // Calculate relative time roughly
            final date =
                DateTime.tryParse(item['created_at'].toString()) ??
                DateTime.now();
            final diff = DateTime.now().difference(date);
            String timeAgo = diff.inHours > 0
                ? '${diff.inHours} hours ago'
                : '${diff.inMinutes} mins ago';
            if (diff.inDays > 0) timeAgo = '${diff.inDays} days ago';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildRecentItem(
                item['item_name'] ?? 'Unknown Item',
                'Found at ${item['location_found'] ?? 'Unknown'}',
                timeAgo,
                Icons.inventory_2_outlined,
                imageUrl: item['image_url'],
                onTap: () async {
                  final updated = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ItemDetailsScreen(item: item),
                    ),
                  );
                  if (updated == true) {
                    _fetchDashboardData();
                  }
                },
              ),
            );
          }),
          if (_recentItems.isEmpty)
            const Center(
              child: Text(
                'No recent items.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111120),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF111120),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentItem(
    String title,
    String location,
    String time,
    IconData icon, {
    String? imageUrl,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF07070E),
            borderRadius: BorderRadius.circular(12),
            image: imageUrl != null
                ? DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: imageUrl == null
              ? Icon(icon, color: const Color(0xFFA99BFF))
              : null,
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '$location • $time',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}
