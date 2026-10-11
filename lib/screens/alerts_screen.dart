import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import 'item_details_screen.dart';
import 'unclaimed_items_list_screen.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _notificationService.addListener(_onNotificationsChanged);
    _notificationService.fetchNotifications();
    
    // Mark all as read when entering the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationService.markAllAsRead();
    });
  }

  void _onNotificationsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _notificationService.removeListener(_onNotificationsChanged);
    super.dispose();
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    
    final formalDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    String elapsed;
    if (diff.inDays > 0) {
      elapsed = '${diff.inDays} days ago';
    } else if (diff.inHours > 0) {
      elapsed = '${diff.inHours} hrs ago';
    } else {
      elapsed = '${diff.inMinutes} mins ago';
    }
    
    return '$formalDate $elapsed';
  }

  @override
  Widget build(BuildContext context) {
    final notifications = _notificationService.notifications;
    final isLoading = _notificationService.isLoading;

    return Scaffold(
appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _notificationService.fetchNotifications();
            },
          ),
        ],
      ),
      body: isLoading && notifications.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C6AFF)))
          : notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No notifications yet', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    // Direct check against cached set to draw visual unread indicators
                    // Wait, we marked all as read in initState, but let's check dynamically
                    // before marking so they see what is new!
                    final isUnread = !_notificationService.unreadCount.toString().contains('0') && index < _notificationService.unreadCount; 

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isUnread ? const Color(0xFF7C6AFF).withValues(alpha: 0.5) : const Color(0x1AFFFFFF),
                          width: isUnread ? 2 : 1,
                        ),
                      ),
                      child: Stack(
                        children: [
                          ListTile(
                            onTap: () {
                              _notificationService.markAsRead(notif['id']);
                              if (notif['type'] == 'unclaimed_broadcast') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const UnclaimedItemsListScreen(),
                                  ),
                                );
                              } else if (notif['report'] != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ItemDetailsScreen(item: Map<String, dynamic>.from(notif['report'])),
                                  ),
                                );
                              }
                            },
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            leading: CircleAvatar(
                              backgroundColor: (notif['color'] as Color).withValues(alpha: 0.15),
                              child: Icon(notif['icon'] as IconData, color: notif['color'] as Color, size: 20),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    notif['title'], 
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ),
                                if (isUnread)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF7C6AFF),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(notif['subtitle'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  const SizedBox(height: 8),
                                  Text(_timeAgo(notif['created_at']), style: const TextStyle(color: Color(0xFFA99BFF), fontSize: 11, fontWeight: FontWeight.w600)),
                                ],
                              ),
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
