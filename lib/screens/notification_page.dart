import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and title
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: Icon(
                      Icons.arrow_back,
                      color: theme.colorScheme.onPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.notifications,
                    color: theme.colorScheme.secondary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Notifications',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      _markAllAsRead(context);
                    },
                    child: Text(
                      'Mark all read',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Notifications list
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                  borderRadius: AppRadius.largeRadius,
                ),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildNotificationItem(
                      context,
                      'New reward earned!',
                      'You earned 5.00 ZDT from data sharing. Keep up the great work!',
                      '2 min ago',
                      Icons.monetization_on,
                      Colors.green,
                      isUnread: true,
                    ),
                    const SizedBox(height: 16),
                    _buildNotificationItem(
                      context,
                      'Market update',
                      'ZDT price increased by 12% in the last 24 hours. Current price: \$2.24',
                      '1 hour ago',
                      Icons.trending_up,
                      Colors.blue,
                      isUnread: true,
                    ),
                    const SizedBox(height: 16),
                    _buildNotificationItem(
                      context,
                      'Security alert',
                      'New login detected from iPhone 15 Pro. If this wasn\'t you, please secure your account.',
                      '3 hours ago',
                      Icons.security,
                      Colors.orange,
                      isUnread: true,
                    ),
                    const SizedBox(height: 16),
                    _buildNotificationItem(
                      context,
                      'Data sharing completed',
                      'Your health data has been successfully shared with approved partners.',
                      '1 day ago',
                      Icons.check_circle,
                      Colors.green,
                      isUnread: false,
                    ),
                    const SizedBox(height: 16),
                    _buildNotificationItem(
                      context,
                      'Weekly summary',
                      'You earned 45.50 ZDT this week from various data sharing activities.',
                      '2 days ago',
                      Icons.analytics,
                      Colors.purple,
                      isUnread: false,
                    ),
                    const SizedBox(height: 16),
                    _buildNotificationItem(
                      context,
                      'Profile updated',
                      'Your profile information has been successfully updated.',
                      '3 days ago',
                      Icons.person,
                      Colors.blue,
                      isUnread: false,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    String title,
    String message,
    String time,
    IconData icon,
    Color iconColor, {
    bool isUnread = false,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnread
            ? theme.colorScheme.secondary.withValues(alpha: 0.05)
            : theme.colorScheme.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnread
              ? theme.colorScheme.secondary.withValues(alpha: 0.2)
              : theme.colorScheme.onSurface.withValues(alpha: 0.1),
          width: isUnread ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          _handleNotificationTap(context, title);
        },
        borderRadius: BorderRadius.circular(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    time,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _markAllAsRead(BuildContext context) {
    final theme = Theme.of(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'All notifications marked as read',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        backgroundColor: theme.colorScheme.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _handleNotificationTap(BuildContext context, String title) {
    final theme = Theme.of(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Opened: $title',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        backgroundColor: theme.colorScheme.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
