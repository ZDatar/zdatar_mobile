import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../app_icons.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

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
                'Wallet',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: Card(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.largeRadius,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Balance',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text('12.08 ZDT', style: theme.textTheme.headlineLarge),
                        Text(
                          '~\$45.00',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Card(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.largeRadius,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Transactions',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              InkWell(
                                borderRadius: AppRadius.largeRadius,
                                onTap: () {},
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Row(
                                    children: [
                                      AppIcons.rotatedArrowUp(),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Withdraw',
                                              style: theme.textTheme.titleLarge
                                                  ?.copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .onSurface,
                                                  ),
                                            ),
                                            Text(
                                              'Today',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .secondary,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '- 10.00 ZDT',
                                            style: theme.textTheme.titleLarge
                                                ?.copyWith(
                                                  color: Colors.redAccent,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '~\$22.00',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .secondary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 50.0,
                                ),
                                child: Container(
                                  height: 1,
                                  width: double.infinity,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.1,
                                  ),
                                ),
                              ),
                              InkWell(
                                borderRadius: AppRadius.largeRadius,
                                onTap: () {},
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Row(
                                    children: [
                                      AppIcons.rotatedArrowDown(),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Rewards',
                                              style: theme.textTheme.titleLarge
                                                  ?.copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .onSurface,
                                                  ),
                                            ),
                                            Text(
                                              'Yesterday',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .secondary,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '10.00 ZDT',
                                            style: theme.textTheme.titleLarge
                                                ?.copyWith(color: Colors.green),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '~\$22.00',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .secondary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 50.0,
                                ),
                                child: Container(
                                  height: 1,
                                  width: double.infinity,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.1,
                                  ),
                                ),
                              ),
                              InkWell(
                                borderRadius: AppRadius.largeRadius,
                                onTap: () {},
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Row(
                                    children: [
                                      AppIcons.rotatedArrowDown(),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Deposit',
                                              style: theme.textTheme.titleLarge
                                                  ?.copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .onSurface,
                                                  ),
                                            ),
                                            Text(
                                              'Yesterday',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .secondary,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '10.00 ZDT',
                                            style: theme.textTheme.titleLarge
                                                ?.copyWith(color: Colors.green),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '~\$22.00',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .secondary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 50.0,
                                ),
                                child: Container(
                                  height: 1,
                                  width: double.infinity,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.1,
                                  ),
                                ),
                              ),
                              InkWell(
                                borderRadius: AppRadius.largeRadius,
                                onTap: () {},
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Row(
                                    children: [
                                      AppIcons.rotatedArrowUp(),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Withdraw',
                                              style: theme.textTheme.titleLarge
                                                  ?.copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .onSurface,
                                                  ),
                                            ),
                                            Text(
                                              'Today',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .secondary,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '- 10.00 ZDT',
                                            style: theme.textTheme.titleLarge
                                                ?.copyWith(
                                                  color: Colors.redAccent,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '~\$22.00',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .secondary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 50.0,
                                ),
                                child: Container(
                                  height: 1,
                                  width: double.infinity,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.1,
                                  ),
                                ),
                              ),
                              InkWell(
                                borderRadius: AppRadius.largeRadius,
                                onTap: () {},
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Row(
                                    children: [
                                      AppIcons.rotatedArrowDown(),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Rewards',
                                              style: theme.textTheme.titleLarge
                                                  ?.copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .onSurface,
                                                  ),
                                            ),
                                            Text(
                                              'Yesterday',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .secondary,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '10.00 ZDT',
                                            style: theme.textTheme.titleLarge
                                                ?.copyWith(color: Colors.green),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '~\$22.00',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .secondary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 50.0,
                                ),
                                child: Container(
                                  height: 1,
                                  width: double.infinity,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.1,
                                  ),
                                ),
                              ),
                              InkWell(
                                borderRadius: AppRadius.largeRadius,
                                onTap: () {},
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Row(
                                    children: [
                                      AppIcons.rotatedArrowDown(),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Rewards',
                                              style: theme.textTheme.titleLarge
                                                  ?.copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .onSurface,
                                                  ),
                                            ),
                                            Text(
                                              'Yesterday',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .secondary,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '10.00 ZDT',
                                            style: theme.textTheme.titleLarge
                                                ?.copyWith(color: Colors.green),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '~\$22.00',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .secondary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 50.0,
                                ),
                                child: Container(
                                  height: 1,
                                  width: double.infinity,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.1,
                                  ),
                                ),
                              ),
                              InkWell(
                                borderRadius: AppRadius.largeRadius,
                                onTap: () {},
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Row(
                                    children: [
                                      AppIcons.rotatedArrowUp(),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Withdraw',
                                              style: theme.textTheme.titleLarge
                                                  ?.copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .onSurface,
                                                  ),
                                            ),
                                            Text(
                                              'Today',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .secondary,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '- 10.00 ZDT',
                                            style: theme.textTheme.titleLarge
                                                ?.copyWith(
                                                  color: Colors.redAccent,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '~\$22.00',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .secondary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 50.0,
                                ),
                                child: Container(
                                  height: 1,
                                  width: double.infinity,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.1,
                                  ),
                                ),
                              ),
                              InkWell(
                                borderRadius: AppRadius.largeRadius,
                                onTap: () {},
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Row(
                                    children: [
                                      AppIcons.rotatedArrowDown(),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Rewards',
                                              style: theme.textTheme.titleLarge
                                                  ?.copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .onSurface,
                                                  ),
                                            ),
                                            Text(
                                              'Yesterday',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .secondary,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '10.00 ZDT',
                                            style: theme.textTheme.titleLarge
                                                ?.copyWith(color: Colors.green),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '~\$22.00',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .secondary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 50.0,
                                ),
                                child: Container(
                                  height: 1,
                                  width: double.infinity,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.1,
                                  ),
                                ),
                              ),
                              InkWell(
                                borderRadius: AppRadius.largeRadius,
                                onTap: () {},
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Row(
                                    children: [
                                      AppIcons.rotatedArrowDown(),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Rewards',
                                              style: theme.textTheme.titleLarge
                                                  ?.copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .onSurface,
                                                  ),
                                            ),
                                            Text(
                                              'Yesterday',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .secondary,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '10.00 ZDT',
                                            style: theme.textTheme.titleLarge
                                                ?.copyWith(color: Colors.green),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '~\$22.00',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .secondary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
