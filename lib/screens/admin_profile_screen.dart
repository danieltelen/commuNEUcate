import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  String _adminEmail = 'Loading...';

  @override
  void initState() {
    super.initState();
    _fetchAdminDetails();
  }

  void _fetchAdminDetails() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && user.email != null) {
      setState(() {
        _adminEmail = user.email!;
      });
    } else {
      setState(() {
        _adminEmail = 'admin@admin.com';
      });
    }
  }

  Future<void> _handleLogout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error logging out: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
appBar: AppBar(title: const Text('Admin Settings'), automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const CircleAvatar(radius: 50, backgroundColor: Color(0xFF0FE0B0), child: Icon(Icons.admin_panel_settings, size: 50, color: Colors.black)),
          const SizedBox(height: 16),
          const Center(child: Text('System Administrator', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
          Center(child: Text(_adminEmail, style: const TextStyle(color: Colors.grey))),
          const SizedBox(height: 32),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
              onTap: _handleLogout,
            ),
          ),
        ],
      ),
    );
  }
}
