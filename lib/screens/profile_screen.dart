import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'login_screen.dart';
import 'edit_report_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _firstName = 'User';
  String _email = 'user@example.com';
  String? _avatarUrl;
  int _itemsReported = 0;
  int _itemsClaimed = 0;
  List<dynamic> _myClaims = [];
  List<dynamic> _myReports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null && user.email != null) {
        final email = user.email!;
        _email = email;

        String? avatar =
            user.userMetadata?['avatar_url'] ?? user.userMetadata?['picture'];

        // Google avatar URLs usually look like: https://lh3.googleusercontent.com/a/SomeID=s96-c
        // We split at '=' and force it to be a high-resolution, uncropped image (=s1024)
        if (avatar != null &&
            avatar.contains('googleusercontent.com') &&
            avatar.contains('=')) {
          avatar = '${avatar.split('=').first}=s1024';
        }

        _avatarUrl = avatar;

        // Parse firstname.lastname@neu.edu.ph -> firstname
        if (email.contains('.')) {
          final firstPart = email.split('.').first;
          _firstName =
              firstPart[0].toUpperCase() + firstPart.substring(1).toLowerCase();
        } else {
          _firstName = email.split('@').first;
        }

        final reports = await Supabase.instance.client
            .from('reports')
            .select('*')
            .eq('reporter_id', user.id);

        final claims = await Supabase.instance.client
            .from('claims')
            .select('*, reports(item_name)')
            .eq('claimer_id', user.id);

        int reported = reports.length;
        int claimed = claims.where((c) => c['status'] == 'approved').length;

        if (mounted) {
          setState(() {
            _myClaims = claims;
            _myReports = reports;
            _itemsReported = reported;
            _itemsClaimed = claimed;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF7C6AFF)),
        ),
      );
    }

    return Scaffold(
appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: Colors
                    .white, // Matches the white background of the ID picture
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: _avatarUrl != null
                    ? Image.network(
                        _avatarUrl!,
                        fit: BoxFit
                            .contain, // Shows the whole image without zooming/cropping
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.grey,
                          );
                        },
                      )
                    : const Icon(Icons.person, size: 60, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _firstName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Center(
            child: Text(_email, style: const TextStyle(color: Colors.grey)),
          ),
          const SizedBox(height: 32),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.check_circle_outline,
                    color: Color(0xFF0FE0B0),
                  ),
                  title: const Text('Items Claimed'),
                  trailing: Text(
                    '$_itemsClaimed',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(height: 1, color: Colors.white10),
                ListTile(
                  leading: const Icon(
                    Icons.report_outlined,
                    color: Color(0xFF7C6AFF),
                  ),
                  title: const Text('Items Reported'),
                  trailing: Text(
                    '$_itemsReported',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_myReports.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text('My Reports', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._myReports.map((report) {
              final rejected = report['status'] == 'rejected';
              final status = (report['status'] ?? 'pending_review').toString().replaceAll('_', ' ');
              final note = (report['review_note'] ?? '').toString().trim();
              return Card(
                color: const Color(0xFF111120),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(rejected ? Icons.error_outline : Icons.inventory_2_outlined,
                    color: rejected ? Colors.orangeAccent : const Color(0xFF7C6AFF)),
                  title: Text(report['item_name'] ?? 'Found item', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(rejected && note.isNotEmpty ? 'Rejected: $note' : 'Status: $status'),
                  trailing: rejected
                      ? TextButton(
                          onPressed: () async {
                            final updated = await Navigator.push<bool>(context, MaterialPageRoute(
                              builder: (_) => EditReportScreen(item: Map<String, dynamic>.from(report)),
                            ));
                            if (updated == true) _fetchProfileData();
                          },
                          child: const Text('Update & Resubmit', style: TextStyle(color: Color(0xFF0FE0B0))),
                        )
                      : null,
                ),
              );
            }),
          ],
          if (_myClaims.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'My Claimed Items',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._myClaims.map((claim) {
              return Card(
                color: const Color(0xFF111120),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(
                    Icons.qr_code_2,
                    color: Color(0xFF0FE0B0),
                  ),
                  title: Text(
                    claim['reports'] != null
                        ? claim['reports']['item_name']
                        : 'Unknown Item',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Status: ${claim['status']}'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      _showQRDialog(
                        context,
                        claim['report_id'].toString(),
                        claim['reports']?['item_name'] ?? 'Item',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C6AFF),
                      minimumSize: const Size(80, 36),
                    ),
                    child: const Text(
                      'View QR',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              );
            }),
          ],
          const SizedBox(height: 24),
          const Text(
            'Settings',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Change Password'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap:
                      () {}, // Handled by Google OAuth usually, but left for layout
                ),
                const Divider(height: 1, color: Colors.white10),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy Settings'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1, color: Colors.white10),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onTap: _logout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showQRDialog(BuildContext context, String data, String itemName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111120),
          title: Text(
            itemName,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 220,
                height: 220,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: data.isEmpty ? 'EMPTY' : data,
                    version: QrVersions.auto,
                    size: 200.0,
                    gapless: false,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(color: Color(0xFF0FE0B0)),
              ),
            ),
          ],
        );
      },
    );
  }
}
