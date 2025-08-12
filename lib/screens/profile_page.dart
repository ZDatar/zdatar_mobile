import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Profile title
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Profile',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Profile Avatar and Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.secondary,
                      border: Border.all(
                        color: theme.colorScheme.secondary,
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Name
                  Text(
                    'John Doe',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Masked Email
                  Text(
                    'john***oe@gmail.com',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Account Number
                  Text(
                    'Account: 20346834',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Menu Items
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  borderRadius: AppRadius.largeRadius,
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      context,
                      'Personal Info',
                      Icons.chevron_right,
                      () {
                        // Navigate to personal info page
                      },
                    ),
                    _buildDivider(theme),
                    _buildMenuItem(
                      context,
                      'Security',
                      Icons.chevron_right,
                      () {
                        // Navigate to security page
                      },
                    ),
                    _buildDivider(theme),
                    _buildMenuItem(
                      context,
                      'Notifications',
                      Icons.chevron_right,
                      () {
                        // Navigate to notifications page
                      },
                    ),
                    _buildDivider(theme),
                    _buildMenuItem(context, 'Support', Icons.chevron_right, () {
                      // Navigate to support page
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Log Out Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.1),
                  borderRadius: AppRadius.largeRadius,
                ),
                child: TextButton(
                  onPressed: () {
                    // Handle log out
                    _showLogOutDialog(context);
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.largeRadius,
                    ),
                  ),
                  child: Text(
                    'Log Out',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Bottom Navigation Bar
            // _buildBottomNavigationBar(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.largeRadius,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            Icon(icon, color: theme.colorScheme.onSurface, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 50),
      height: 1,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
    );
  }

  void _showLogOutDialog(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text(
            'Log Out',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          content: Text(
            'Are you sure you want to log out?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: theme.colorScheme.secondary),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Handle actual log out logic here
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Logged out successfully',
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                    backgroundColor: theme.colorScheme.surface,
                  ),
                );
              },
              child: Text(
                'Log Out',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ],
        );
      },
    );
  }
}
