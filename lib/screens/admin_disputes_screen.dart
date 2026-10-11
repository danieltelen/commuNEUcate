import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_chat_view.dart';

class AdminDisputesScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const AdminDisputesScreen({super.key, this.onNavigate});

  @override
  State<AdminDisputesScreen> createState() => _AdminDisputesScreenState();
}

class _AdminDisputesScreenState extends State<AdminDisputesScreen> {
  List<dynamic> _disputes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDisputes();
  }

  Future<void> _fetchDisputes() async {
    setState(() => _isLoading = true);
    try {
      final claims = await Supabase.instance.client
          .from('claims')
          .select('*, reports(item_name, image_url, location_found, id, reporter_id)')
          .order('created_at', ascending: false);

      final Map<String, List<dynamic>> grouped = {};
      for (var claim in claims) {
        final reportId = claim['report_id']?.toString() ?? '';
        grouped.putIfAbsent(reportId, () => []).add(claim);
      }

      final disputes = grouped.entries
          .where((e) => e.value.length > 1)
          .map((e) => {'report_id': e.key, 'claims': e.value, 'report': e.value.first['reports']})
          .toList();

      if (mounted) setState(() { _disputes = disputes; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
appBar: AppBar(
        title: const Text('Disputes & AI Flags'),
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
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchDisputes)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0FE0B0)))
          : _disputes.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.gavel_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No disputes found', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _disputes.length,
                  itemBuilder: (context, index) {
                    final dispute = _disputes[index];
                    final report = dispute['report'];
                    final claimCount = (dispute['claims'] as List).length;
                    final itemName = report?['item_name'] ?? 'Unknown Item';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 36),
                        title: Text('$claimCount Claims on "$itemName"', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'Location: ${report?['location_found'] ?? '-'}\nAI flagged: Multiple competing claim requests.',
                          style: const TextStyle(fontSize: 12),
                        ),
                        isThreeLine: true,
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('$claimCount claims', style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdminChatView(
                                itemId: report?['id']?.toString() ?? '',
                                reporterId: report?['reporter_id']?.toString() ?? '',
                                itemName: report?['item_name'] ?? 'Item',
                              )
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
