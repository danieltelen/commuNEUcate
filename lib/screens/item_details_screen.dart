import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'claim_item_screen.dart';
import 'edit_report_screen.dart';
import 'chat_screen.dart';
import 'admin_chat_view.dart';

class ItemDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  final bool isAdmin;

  const ItemDetailsScreen({
    super.key,
    required this.item,
    this.isAdmin = false,
  });

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  bool _hasClaimed = false;
  bool _isLoadingClaimStatus = true;
  String? _adminId;
  String _expectedAnswer = 'N/A';

  @override
  void initState() {
    super.initState();
    _checkClaimStatus();
  }

  Future<void> _checkClaimStatus() async {
    try {
      if (widget.isAdmin) {
        final secret = await Supabase.instance.client
            .from('report_secrets')
            .select('expected_answer')
            .eq('report_id', widget.item['id'])
            .maybeSingle();
        if (mounted && secret != null) {
          setState(() => _expectedAnswer = secret['expected_answer']?.toString() ?? 'N/A');
        }
      }

      final adminRes = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('role', 'admin')
          .limit(1)
          .maybeSingle();
      if (adminRes != null && mounted) {
        setState(() => _adminId = adminRes['id']);
      }

      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final claims = await Supabase.instance.client
            .from('claims')
            .select('id')
            .eq('report_id', widget.item['id'])
            .eq('claimer_id', user.id);
        if (mounted) {
          setState(() {
            _hasClaimed = claims.isNotEmpty;
            _isLoadingClaimStatus = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingClaimStatus = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingClaimStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String status = widget.item['status'] ?? 'pending';
    final bool isUnclaimed = status != 'claimed';
    final currentUser = Supabase.instance.client.auth.currentUser;
    final bool isReporter =
        currentUser != null && widget.item['reporter_id'] == currentUser.id;
    final createdAt =
        DateTime.tryParse(widget.item['created_at']?.toString() ?? '') ??
        DateTime.now();
    final bool isWithin24Hours =
        DateTime.now().difference(createdAt).inHours < 24;
    final bool canEdit = isReporter && isWithin24Hours && isUnclaimed;

    return Scaffold(
      backgroundColor: const Color(0xFF07070E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF07070E),
        elevation: 0,
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
        title: const Text(
          'Item Details',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          if (!widget.isAdmin && _adminId != null)
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
              tooltip: 'Message Admin',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      itemId: widget.item['id'].toString(),
                      receiverId: _adminId!,
                      chatTitle: 'Chat with Admin',
                    ),
                  ),
                );
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                color: const Color(0xFF111120),
                borderRadius: BorderRadius.circular(16),
                image: widget.item['image_url'] != null
                    ? DecorationImage(
                        image: NetworkImage(widget.item['image_url']),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: widget.item['image_url'] == null
                  ? const Center(
                      child: Icon(
                        Icons.inventory_2_outlined,
                        size: 80,
                        color: Color(0xFF2A2A3A),
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 24),

            // Title and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.item['item_name'] ?? 'Unknown Item',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isUnclaimed
                        ? Colors.orange.withValues(alpha: 0.2)
                        : Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isUnclaimed ? 'Unclaimed' : 'Claimed',
                    style: TextStyle(
                      color: isUnclaimed ? Colors.orange : Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Basic Info Card
            _buildInfoCard([
              _buildInfoRow(
                Icons.location_on_outlined,
                'Location Found',
                widget.item['location_found'] ?? 'Unknown',
              ),
              const Divider(color: Colors.white10, height: 24),
              _buildInfoRow(
                Icons.calendar_today_outlined,
                'Date Found',
                widget.item['date_found'] ?? 'Unknown',
              ),
              const Divider(color: Colors.white10, height: 24),
              _buildInfoRow(
                Icons.category_outlined,
                'Category',
                widget.item['category'] ?? 'Others',
              ),
            ]),
            const SizedBox(height: 16),

            // Description Card
            _buildInfoCard([
              const Text(
                'DESCRIPTION',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.item['description'] ?? 'No description provided.',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ]),
            const SizedBox(height: 16),

            // Tags Card
            _buildInfoCard([
              const Text(
                'TAGS',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.item['tags'] ?? 'No tags.',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ]),
            const SizedBox(height: 16),

            // Security Card (ADMIN ONLY)
            if (widget.isAdmin &&
                widget.item['security_question'] != null &&
                widget.item['security_question'].toString().isNotEmpty) ...[
              _buildInfoCard([
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.security, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'SECURITY (ADMIN ONLY)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'SECURITY QUESTION',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.item['security_question'] ?? 'N/A',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const Divider(color: Colors.white10, height: 24),
                const Text(
                  'EXPECTED ANSWER',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _expectedAnswer,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ]),
              const SizedBox(height: 16),
            ],

            // AI Assist Card
            _buildInfoCard([
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFA99BFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 8, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'AI ASSIST',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildAIFeature(Icons.check, 'Item authenticity verified by AI'),
              const Divider(color: Colors.white10, height: 24),
              _buildAIFeature(
                Icons.person_outline,
                '3 potential owner matches found',
              ),
              const Divider(color: Colors.white10, height: 24),
              _buildAIFeature(Icons.bolt, 'Claim will be processed within 24h'),
            ]),

            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: widget.isAdmin
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminChatView(
                            itemId: widget.item['id']?.toString() ?? '',
                            reporterId:
                                widget.item['reporter_id']?.toString() ?? '',
                            itemName: widget.item['item_name'] ?? 'Item',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.forum_outlined, color: Colors.white),
                    label: const Text(
                      'View Chat Logs',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF7C6AFF)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : isReporter
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: canEdit
                            ? () async {
                                final updated = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        EditReportScreen(item: widget.item),
                                  ),
                                );
                                if (!context.mounted) return;
                                if (updated == true) {
                                  Navigator.pop(context, true);
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canEdit
                              ? const Color(0xFF0FE0B0)
                              : const Color(0xFF1A1A2E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              !isUnclaimed
                                  ? 'Item Claimed'
                                  : !isWithin24Hours
                                  ? 'Edit Expired (Past 24h)'
                                  : 'Edit Report',
                              style: TextStyle(
                                color: canEdit
                                    ? const Color(0xFF07070E)
                                    : Colors.grey,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              canEdit ? Icons.edit : Icons.lock,
                              color: canEdit
                                  ? const Color(0xFF07070E)
                                  : Colors.grey,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : isUnclaimed
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: (_isLoadingClaimStatus || _hasClaimed)
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ClaimItemScreen(item: widget.item),
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _hasClaimed
                              ? const Color(0xFF1A1A2E)
                              : const Color(0xFFA99BFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoadingClaimStatus
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _hasClaimed
                                        ? 'Claim Pending Approval'
                                        : 'Claim This Item',
                                    style: TextStyle(
                                      color: _hasClaimed
                                          ? Colors.grey
                                          : Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (!_hasClaimed) ...[
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.arrow_forward,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ],
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111120),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAIFeature(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF07070E),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFFA99BFF), size: 16),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
