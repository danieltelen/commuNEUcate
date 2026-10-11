import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = false;
  Set<String> _readNotificationIds = {};
  RealtimeChannel? _reportsSubscription;
  RealtimeChannel? _claimsSubscription;
  RealtimeChannel? _messagesSubscription;

  List<Map<String, dynamic>> get notifications => _notifications;
  bool get isLoading => _isLoading;

  int get unreadCount {
    return _notifications
        .where((n) => !_readNotificationIds.contains(n['id']))
        .length;
  }

  Future<void> init() async {
    await loadReadStatus();
    await fetchNotifications();
    setupRealtime();
  }

  Future<void> loadReadStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('read_notification_ids') ?? [];
      _readNotificationIds = list.toSet();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading read status: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (var n in _notifications) {
        _readNotificationIds.add(n['id']);
      }
      await prefs.setStringList(
        'read_notification_ids',
        _readNotificationIds.toList(),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _readNotificationIds.add(id);
      await prefs.setStringList(
        'read_notification_ids',
        _readNotificationIds.toList(),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  Future<void> fetchNotifications() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Fetch claims on items the user reported (as finder)
      final claimsOnMyItems = await _supabase
          .from('claims')
          .select('*, reports!inner(*)')
          .eq('reports.reporter_id', user.id)
          .order('created_at', ascending: false);

      // 2. Fetch status updates on claims the user submitted (as claimer)
      final myClaimsUpdated = await _supabase
          .from('claims')
          .select('*, reports(*)')
          .eq('claimer_id', user.id)
          .order('created_at', ascending: false);

      // 3. Fetch status of items the user reported
      final myReports = await _supabase
          .from('reports')
          .select('*')
          .eq('reporter_id', user.id)
          .order('created_at', ascending: false);

      // 4. Fetch all public active alerts (unclaimed items)
      final publicAlerts = await _supabase
          .from('reports')
          .select('*')
          .eq('status', 'unclaimed')
          .order('created_at', ascending: false);

      // 5. Fetch manual admin alerts (system alerts)
      final manualAlerts = await _supabase
          .from('messages')
          .select('*')
          .eq('receiver_id', user.id)
          .ilike('content', '%SYSTEM_ALERT%')
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> combined = [];

      // A. Manual Alerts by Admin
      for (var msg in manualAlerts) {
        final contentStr = msg['content'].toString();

        if (contentStr.startsWith('[SYSTEM_ALERT_UNCLAIMED]')) {
          combined.add({
            'id': 'msg_${msg['id']}_unclaimed_broadcast',
            'type': 'unclaimed_broadcast',
            'title': 'Active Unclaimed Items Alert! 📢',
            'subtitle':
                'Admin has broadcasted an alert for active unclaimed items. Tap here to view the full list!',
            'icon': Icons.campaign,
            'color': Colors.amber,
            'created_at': msg['created_at'],
            'report': null,
          });
        } else {
          final content = contentStr.replaceAll('[SYSTEM_ALERT]', '').trim();

          // Find if we have item info
          Map<String, dynamic>? itemInfo;
          if (msg['item_id'] != null) {
            try {
              itemInfo = await _supabase
                  .from('reports')
                  .select('*')
                  .eq('id', msg['item_id'])
                  .maybeSingle();
            } catch (_) {}
          }

          combined.add({
            'id': 'msg_${msg['id']}_manual',
            'type': 'manual_alert',
            'title': 'Admin Broadcast Alert! 🚨',
            'subtitle': content,
            'icon': Icons.warning_amber_rounded,
            'color': Colors.redAccent,
            'created_at': msg['created_at'],
            'report': itemInfo,
          });
        }
      }

      // B. Public Alerts (approved items reported by others)
      for (var report in publicAlerts) {
        if (report['reporter_id'] == user.id) continue; // Skip my own reports

        combined.add({
          'id': 'rpt_${report['id']}_public',
          'type': 'public_alert',
          'title': 'New Item Alert! 📢',
          'subtitle':
              'A ${report['item_name']} was reported at ${report['location_found']}.',
          'icon': Icons.campaign,
          'color': const Color(0xFF7C6AFF),
          'created_at': report['created_at'],
          'report': report,
        });

        // C. Automatic Matches (Overlap detection!)
        for (var myReport in myReports) {
          final isSameCategory =
              myReport['category']?.toString().toLowerCase() ==
              report['category']?.toString().toLowerCase();

          if (isSameCategory) {
            combined.add({
              'id': 'match_${myReport['id']}_${report['id']}',
              'type': 'match_alert',
              'title': 'Potential Match Found! 🔍',
              'subtitle':
                  'A newly found "${report['item_name']}" matches your reported item "${myReport['item_name']}". Check it out!',
              'icon': Icons.compare_arrows_rounded,
              'color': const Color(0xFF0FE0B0),
              'created_at': report['created_at'],
              'report': report,
            });
            break;
          }
        }
      }

      // D. Report approved/submitted/rejected
      for (var report in myReports) {
        final status = report['status'] as String? ?? 'pending';

        if (status == 'unclaimed' || status == 'claimed') {
          combined.add({
            'id': 'rpt_${report['id']}_approved',
            'type': 'report_approved',
            'title': 'Report Approved! ✅',
            'subtitle':
                'Your report for "${report['item_name']}" was approved and is now public.',
            'icon': Icons.check_circle,
            'color': const Color(0xFF0FE0B0),
            'created_at': report['created_at'],
            'report': report,
          });
        } else if (status == 'rejected') {
          combined.add({
            'id': 'rpt_${report['id']}_rejected',
            'type': 'report_rejected',
            'title': 'Report Rejected ❌',
            'subtitle':
                'Your report for "${report['item_name']}" was rejected by the admin.',
            'icon': Icons.cancel,
            'color': Colors.redAccent,
            'created_at': report['created_at'],
            'report': report,
          });
        }

        combined.add({
          'id': 'rpt_${report['id']}_submitted',
          'type': 'report_submitted',
          'title': 'Report Submitted',
          'subtitle':
              'Your report for "${report['item_name']}" has been sent to the admin for review.',
          'icon': Icons.upload_file,
          'color': Colors.blueAccent,
          'created_at': report['created_at'],
          'report': report,
        });
      }

      // E. Claim requests received on my reports
      for (var claim in claimsOnMyItems) {
        final report = claim['reports'];
        combined.add({
          'id': 'claim_${claim['id']}_received',
          'type': 'claim_received',
          'title': 'Someone claimed your item!',
          'subtitle': '${report['item_name']} has a new claim request.',
          'icon': Icons.notification_important_outlined,
          'color': const Color(0xFFA99BFF),
          'created_at': claim['created_at'],
          'report': report,
          'claim_status': claim['status'],
        });
      }

      // F. Status updates on claims I made
      for (var claim in myClaimsUpdated) {
        final report = claim['reports'];
        if (report == null) continue;
        final status = claim['status'] as String? ?? 'pending';
        String title = 'Claim Update';
        String subtitle = '';
        Color color = Colors.grey;
        IconData icon = Icons.info_outline;

        if (status == 'approved') {
          title = 'Claim Approved! 🎉';
          subtitle =
              'Your claim for "${report['item_name']}" was approved. Visit the office to claim it.';
          color = const Color(0xFF0FE0B0);
          icon = Icons.check_circle_outline;
        } else if (status == 'rejected') {
          title = 'Claim Rejected';
          subtitle =
              'Your claim for "${report['item_name']}" was not approved.';
          color = Colors.redAccent;
          icon = Icons.cancel_outlined;
        } else {
          title = 'Claim Pending';
          subtitle =
              'Your claim for "${report['item_name']}" is pending admin review.';
          color = Colors.orange;
          icon = Icons.hourglass_empty_outlined;
        }

        combined.add({
          'id': 'claim_${claim['id']}_$status',
          'type': 'my_claim',
          'title': title,
          'subtitle': subtitle,
          'icon': icon,
          'color': color,
          'created_at': claim['created_at'],
          'report': report,
          'claim_status': status,
        });
      }

      // Sort by created_at descending
      combined.sort((a, b) {
        final aDate =
            DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(2000);
        final bDate =
            DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });

      _notifications = combined;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  void setupRealtime() {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    disposeRealtime();

    try {
      _reportsSubscription = _supabase
          .channel('public:reports_alerts')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'reports',
            callback: (payload) {
              debugPrint('Realtime reports change: ${payload.eventType}');
              fetchNotifications();
            },
          )
          .subscribe();

      _claimsSubscription = _supabase
          .channel('public:claims_alerts')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'claims',
            callback: (payload) {
              debugPrint('Realtime claims change: ${payload.eventType}');
              fetchNotifications();
            },
          )
          .subscribe();

      _messagesSubscription = _supabase
          .channel('public:messages_alerts')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'messages',
            callback: (payload) {
              final newRecord = payload.newRecord;
              if (newRecord['receiver_id'] == user.id &&
                  newRecord['content']?.toString().startsWith(
                        '[SYSTEM_ALERT]',
                      ) ==
                      true) {
                debugPrint('Realtime message alert received');
                fetchNotifications();
              }
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('Error setting up Realtime: $e');
    }
  }

  void disposeRealtime() {
    try {
      if (_reportsSubscription != null) {
        _supabase.removeChannel(_reportsSubscription!);
        _reportsSubscription = null;
      }
      if (_claimsSubscription != null) {
        _supabase.removeChannel(_claimsSubscription!);
        _claimsSubscription = null;
      }
      if (_messagesSubscription != null) {
        _supabase.removeChannel(_messagesSubscription!);
        _messagesSubscription = null;
      }
    } catch (_) {}
  }
}
