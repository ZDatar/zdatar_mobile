import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Hi John! 👋',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Card(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.largeRadius,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        '\$12.08',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: MediaQuery.of(context).size.width * 0.08,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'earned month!',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontSize: MediaQuery.of(context).size.width * 0.06,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.largeRadius,
                      ),
                      child: InkWell(
                        borderRadius: AppRadius.largeRadius,
                        onTap: () {},
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bar_chart, color: Colors.tealAccent, size: 36),
                              const SizedBox(height: 8),
                              Text(
                                'View Data',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Card(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.largeRadius,
                      ),
                      child: InkWell(
                        borderRadius: AppRadius.largeRadius,
                        onTap: () {},
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.groups, color: Colors.tealAccent, size: 36),
                              const SizedBox(height: 8),
                              Text(
                                'Data Deals',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Card(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.largeRadius,
                ),
                child: InkWell(
                  borderRadius: AppRadius.largeRadius,
                  onTap: () {},
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wallet, color: Colors.tealAccent, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          'Withdraw Rewards',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 