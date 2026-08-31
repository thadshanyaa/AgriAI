import 'package:flutter/material.dart';
import '../app_routes.dart';
import '../localization/app_language.dart';
import '../services/firebase_backend.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/agri_ui.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  Future<void> _markAllRead() async {
    try {
      await FirebaseBackend.markAllNotificationsRead();
      if (mounted) showDemoMessage(context, 'All notifications marked as read');
    } catch (error) {
      if (mounted) {
        showDemoMessage(context, FirebaseBackend.friendlyMessage(error));
      }
    }
  }

  IconData _iconFor(String type) {
    return switch (type) {
      'weather' => Icons.cloud_rounded,
      'disease' => Icons.bug_report_rounded,
      'market' => Icons.trending_up_rounded,
      'harvest' => Icons.event_available_rounded,
      _ => Icons.notifications_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirebaseBackend.notificationsStream(),
      builder: (context, snapshot) {
        final alerts = snapshot.data ?? const <Map<String, dynamic>>[];
        final unread = alerts.where((alert) => alert['isRead'] != true).length;
        return AgriPage(
          title: 'Notifications',
          subtitle: 'Stay updated with your farm alerts',
          actions: [
            IconButton(
              tooltip: tr('Agriculture News'),
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.governmentNews),
              icon: const Icon(Icons.newspaper_rounded),
            ),
          ],
          child: Column(
            children: [
              AgriHeroCard(
                eyebrow: "Today's Alerts",
                title: unread == 0
                    ? 'All Caught Up'
                    : '$unread New Notifications',
                subtitle: 'Weather • Disease • Harvest • Market',
                trailing: Icon(
                  unread == 0
                      ? Icons.done_all_rounded
                      : Icons.notifications_active_rounded,
                  color: Colors.white,
                  size: 42,
                ),
              ),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                )
              else if (snapshot.hasError)
                AgriSection(
                  child: Text(
                    FirebaseBackend.friendlyMessage(snapshot.error!),
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              else if (alerts.isEmpty)
                const AgriSection(child: Text('No notifications yet.'))
              else
                ...alerts.map(
                  (alert) => Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: AgriActionTile(
                      title: alert['title'] as String? ?? 'Notification',
                      subtitle: alert['message'] as String? ?? '',
                      icon: _iconFor(alert['type'] as String? ?? ''),
                      trailing: alert['isRead'] == true
                          ? const Icon(
                              Icons.done_all_rounded,
                              color: AppColors.primary,
                            )
                          : const CircleAvatar(
                              radius: 5,
                              backgroundColor: AppColors.primary,
                            ),
                      onTap: () => showDemoMessage(
                        context,
                        alert['message'] as String? ?? '',
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              AgriPrimaryButton(
                label: unread == 0 ? 'All Alerts Read' : 'Mark All as Read',
                icon: Icons.done_all_rounded,
                onPressed: unread == 0 ? null : _markAllRead,
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.governmentNews),
                icon: const Icon(Icons.campaign_rounded),
                label: Text(tr('View Agriculture News')),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () async {
                  try {
                    final enabled = await NotificationService.setEnabled(true);
                    if (!enabled) {
                      if (context.mounted) {
                        showDemoMessage(
                          context,
                          'Allow notifications in phone settings',
                        );
                      }
                      return;
                    }
                    await NotificationService.showTestNotification();
                    if (context.mounted) {
                      showDemoMessage(context, 'Test notification sent');
                    }
                  } catch (_) {
                    if (context.mounted) {
                      showDemoMessage(
                        context,
                        'Unable to send test notification',
                      );
                    }
                  }
                },
                icon: const Icon(Icons.notification_add_rounded),
                label: Text(tr('Test Phone Notification')),
              ),
            ],
          ),
        );
      },
    );
  }
}
