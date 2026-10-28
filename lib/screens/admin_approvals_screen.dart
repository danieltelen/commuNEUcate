import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/toast.dart';

class AdminApprovalsScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const AdminApprovalsScreen({super.key, this.onNavigate});

  @override
  State<AdminApprovalsScreen> createState() => _AdminApprovalsScreenState();
}

class _AdminApprovalsScreenState extends State<AdminApprovalsScreen> {
  List<dynamic> _pendingItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPendingItems();
  }

  Future<void> _fetchPendingItems() async {
    setState(() => _isLoading = true);
    try {
      final res = await Supabase.instance.client
          .from('reports')
          .select('*, claims(*)')
          .eq('status', 'pending_review')
          .order('created_at', ascending: false);

      final enriched = <Map<String, dynamic>>[];
      for (var report in res) {
        final reporterId = report['reporter_id']?.toString();
        String reporterEmail = 'Unknown';
        if (reporterId != null) {
          try {
            final profile = await Supabase.instance.client.from('profiles').select('email').eq('id', reporterId).maybeSingle();
            reporterEmail = profile?['email'] ?? 'Unknown';
          } catch (_) {}
        }

        final claims = report['claims'] as List<dynamic>? ?? [];
        Map<String, dynamic>? activeClaim;
        String claimerEmail = 'Unknown';

        final pendingClaims = claims.where((c) => c['status'] == 'pending').toList();
        if (pendingClaims.isNotEmpty) {
          activeClaim = pendingClaims.first;
          final claimerId = activeClaim!['claimer_id']?.toString();
          if (claimerId != null) {
            try {
              final profile = await Supabase.instance.client.from('profiles').select('email').eq('id', claimerId).maybeSingle();
              claimerEmail = profile?['email'] ?? 'Unknown';
            } catch (_) {}
          }
        }

        enriched.add({
          ...report,
          '_reporterEmail': reporterEmail,
          '_activeClaim': activeClaim,
          '_claimerEmail': claimerEmail,
        });
      }

      if (mounted) setState(() { _pendingItems = enriched; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('Fetch error: $e');
    }
  }

  Future<void> _approveItem(Map<String, dynamic> item) async {
    final reportId = item['id'];
    final activeClaim = item['_activeClaim'];
    final review = {
      'review_note': null,
      'reviewed_at': DateTime.now().toUtc().toIso8601String(),
      'reviewed_by': Supabase.instance.client.auth.currentUser?.id,
    };

    final index = _pendingItems.indexWhere((i) => i['id'] == reportId);
    if (index != -1) setState(() => _pendingItems.removeAt(index));

    try {
      if (activeClaim != null) {
        await Supabase.instance.client.from('reports').update({'status': 'claimed', ...review}).eq('id', reportId).select().single();
        await Supabase.instance.client.from('claims').update({'status': 'approved'}).eq('id', activeClaim['id']).select().single();
      } else {
        await Supabase.instance.client.from('reports').update({'status': 'unclaimed', ...review}).eq('id', reportId).select().single();
      }

      if (mounted) showTopToast(context, 'Approved successfully!');
    } catch (e) {
      if (mounted) showTopToast(context, 'Error approving: $e');
      _fetchPendingItems(); 
    }
  }

  Future<void> _rejectItem(Map<String, dynamic> item) async {
    final reportId = item['id'];
    final activeClaim = item['_activeClaim'];

    String? reviewNote;
    if (activeClaim == null) {
      final controller = TextEditingController();
      reviewNote = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: const Color(0xFF111120),
          title: const Text('Reject report'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Explain what the reporter should correct'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(dialogContext, controller.text.trim()), child: const Text('Reject', style: TextStyle(color: Colors.redAccent))),
          ],
        ),
      );
      controller.dispose();
      if (reviewNote == null) return;
      if (reviewNote.isEmpty) {
        showTopToast(context, 'Add a reason so the reporter can correct the item.');
        return;
      }
    }

    final index = _pendingItems.indexWhere((i) => i['id'] == reportId);
    if (index != -1) setState(() => _pendingItems.removeAt(index));

    try {
      if (activeClaim != null) {
        await Supabase.instance.client.from('reports').update({'status': 'unclaimed'}).eq('id', reportId).select().single();
        await Supabase.instance.client.from('claims').update({'status': 'rejected'}).eq('id', activeClaim['id']).select().single();
      } else {
        await Supabase.instance.client.from('reports').update({
          'status': 'rejected',
          'review_note': reviewNote,
          'reviewed_at': DateTime.now().toUtc().toIso8601String(),
          'reviewed_by': Supabase.instance.client.auth.currentUser?.id,
        }).eq('id', reportId).select().single();
      }

      if (mounted) showTopToast(context, 'Rejected.');
    } catch (e) {
      if (mounted) showTopToast(context, 'Error rejecting: $e');
      _fetchPendingItems(); 
    }
  }

  Future<void> _showProofDialog(String proofPath, String securityAnswer) async {
    var imageUrl = proofPath;
    if (!proofPath.startsWith('http://') && !proofPath.startsWith('https://')) {
      try {
        imageUrl = await Supabase.instance.client.storage
            .from('claim_proofs')
            .createSignedUrl(proofPath, 600);
      } catch (e) {
        if (mounted) showTopToast(context, 'Could not open claim proof: $e');
        return;
      }
    }
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF111120),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Claim Proof', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(imageUrl, height: 200, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_,_,_) => const Icon(Icons.broken_image, size: 50)),
              ),
              const SizedBox(height: 16),
              const Text('Security Answer:', style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text(securityAnswer, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C6AFF)),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
appBar: AppBar(
        title: const Text('Pending Approvals'),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF111120),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else if (widget.onNavigate != null) {
                  widget.onNavigate!(0); // Switch to Dashboard tab
                }
              },
            ),
          ),
        ),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchPendingItems)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0FE0B0)))
          : _pendingItems.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No pending approvals', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pendingItems.length,
                  itemBuilder: (context, index) {
                    final item = _pendingItems[index];
                    final reporterEmail = item['_reporterEmail'];
                    final activeClaim = item['_activeClaim'];
                    final isClaim = activeClaim != null;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isClaim ? const Color(0xFF7C6AFF).withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            ),
                            child: Row(
                              children: [
                                Icon(isClaim ? Icons.pan_tool_alt : Icons.fiber_new, color: isClaim ? const Color(0xFFA99BFF) : Colors.orange, size: 16),
                                const SizedBox(width: 8),
                                Text(isClaim ? 'CLAIM REQUEST' : 'NEW REPORT', style: TextStyle(color: isClaim ? const Color(0xFFA99BFF) : Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                                const Spacer(),
                                Text(_timeAgo(item['created_at']), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                          ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: Container(
                              width: 60, height: 60,
                              decoration: BoxDecoration(color: const Color(0xFF07070E), borderRadius: BorderRadius.circular(12)),
                              clipBehavior: Clip.hardEdge,
                              child: item['image_url'] != null
                                  ? Image.network(item['image_url'], fit: BoxFit.cover, errorBuilder: (_,_,_) => const Icon(Icons.image, color: Colors.grey))
                                  : const Icon(Icons.image, color: Colors.grey),
                            ),
                            title: Text(item['item_name'] ?? 'Unknown Item', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(isClaim ? 'Claimer: ${item['_claimerEmail']}' : 'Reporter: $reporterEmail', style: const TextStyle(fontSize: 12)),
                                Text('Category: ${item['category'] ?? '-'}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                            trailing: isClaim && activeClaim['proof_image_url'] != null
                                ? IconButton(
                                    icon: const Icon(Icons.remove_red_eye, color: Color(0xFF0FE0B0)),
                                    onPressed: () => _showProofDialog(activeClaim['proof_image_url'], activeClaim['security_answer'] ?? 'N/A'),
                                  )
                                : null,
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 18),
                                    label: const Text('Reject', style: TextStyle(color: Colors.redAccent)),
                                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)),
                                    onPressed: () => _rejectItem(item),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.check_circle_outline, size: 18),
                                    label: const Text('Approve'),
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0FE0B0), foregroundColor: Colors.black),
                                    onPressed: () => _approveItem(item),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
