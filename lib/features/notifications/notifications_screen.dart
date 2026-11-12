import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/config/app_config.dart';
import '../../shared/models/app_notification.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/notifications_provider.dart';
import '../../shared/widgets/empty_state.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    if (user != null) {
      ref.read(notificationsProvider.notifier).fetchNotifications(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifState = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications & Alerts'),
      ),
      body: notifState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifState.notifications.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.notifications_none,
                  title: 'No Notifications Yet',
                  message: 'You are all caught up! Emergency alerts and contact notifications will appear here.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifState.notifications.length,
                  itemBuilder: (context, index) {
                    final item = notifState.notifications[index];
                    return _buildNotificationCard(item);
                  },
                ),
    );
  }

  Widget _buildNotificationCard(AppNotification item) {
    final isEmergency = item.isEmergency;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: item.isRead ? Colors.white : const Color(0xFFFEF2F2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isEmergency ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
          width: isEmergency ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isEmergency ? const Color(0xFFDC2626) : AppConfig.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isEmergency ? Icons.warning_amber_rounded : Icons.notifications_active,
            color: isEmergency ? Colors.white : AppConfig.primaryColor,
            size: 20,
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                  fontSize: 15,
                  color: isEmergency ? const Color(0xFF991B1B) : const Color(0xFF0D1B2A),
                ),
              ),
            ),
            Text(
              DateFormat('hh:mm a').format(item.createdAt),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            item.body,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.3,
            ),
          ),
        ),
        onTap: () {
          ref.read(notificationsProvider.notifier).markAsRead(item.id);
          final reqId = item.data['blood_request_id'];
          if (reqId != null) {
            context.push('/request-tracking/$reqId');
          }
        },
      ),
    );
  }
}
