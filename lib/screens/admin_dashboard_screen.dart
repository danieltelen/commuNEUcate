import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_approvals_screen.dart';
import 'admin_disputes_screen.dart';
import 'admin_items_screen.dart';
import 'admin_users_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _pendingCount = 0;
  int _revalidationCount = 0;
  int _disputesCount = 0;
  int _activeUsers = 0;
  int _itemsClaimed = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
  }

  Future<void> _fetchAdminData() async {
    try {
      // Fetch users count
      final profiles = await Supabase.instance.client.from('profiles').select('id,role,account_status');
      
      // Fetch reports
      final reports = await Supabase.instance.client.from('reports').select('id,status,revalidation_count');
      final pendingClaims = await Supabase.instance.client
          .from('claims')
          .select('report_id')
          .eq('status', 'pending');
      final claimReportIds = pendingClaims.map((claim) => claim['report_id'].toString()).toSet();
      
      int pending = 0;
      int revalidations = 0;
      int claimed = 0;
      for (var r in reports) {
        if (r['status'] == 'pending_review' && !claimReportIds.contains(r['id']?.toString())) {
          pending++;
          if ((r['revalidation_count'] as num? ?? 0) > 0) revalidations++;
        }
        if (r['status'] == 'claimed') claimed++;
      }

      if (mounted) {
        setState(() {
          _activeUsers = profiles.where((user) => user['account_status'] == 'approved' || user['role'] == 'admin').length;
          _pendingCount = pending;
          _revalidationCount = revalidations;
          _itemsClaimed = claimed;
          _disputesCount = 0; // Placeholder for now until disputes table exists
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF0FE0B0))));
    }

    return Scaffold(
appBar: AppBar(title: const Text('Admin Dashboard'), automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Welcome, Admin', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildAdminStatCard('Pending Approvals', '$_pendingCount', const Color(0xFF0FE0B0))),
              const SizedBox(width: 16),
              Expanded(child: _buildAdminStatCard('Flagged Disputes', '$_disputesCount', Colors.redAccent)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildAdminStatCard('Active Users', '$_activeUsers', const Color(0xFF7C6AFF))),
              const SizedBox(width: 16),
              Expanded(child: _buildAdminStatCard('Items Claimed', '$_itemsClaimed', Colors.white)),
            ],
          ),
          const SizedBox(height: 16),
          _buildAdminStatCard('Revalidations Awaiting Review', '$_revalidationCount', const Color(0xFFA99BFF)),
          const SizedBox(height: 32),
          const Text('Management Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildNavCard(context, 'Approve Reports', Icons.add_task, const Color(0xFF0FE0B0), const AdminApprovalsScreen()),
          _buildNavCard(context, 'Review Disputes', Icons.warning_amber_rounded, Colors.redAccent, const AdminDisputesScreen()),
          _buildNavCard(context, 'View All Items', Icons.inventory_2, Colors.white, const AdminItemsScreen()),
          _buildNavCard(context, 'Manage Users', Icons.people_alt, const Color(0xFF7C6AFF), const AdminUsersScreen()),
        ],
      ),
    );
  }

  Widget _buildNavCard(BuildContext context, String title, IconData icon, Color color, Widget destination) {
    return Card(
      color: const Color(0xFF111120),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination),
          ).then((_) => _fetchAdminData());
        },
      ),
    );
  }

  Widget _buildAdminStatCard(String label, String value, Color color) {
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
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}
