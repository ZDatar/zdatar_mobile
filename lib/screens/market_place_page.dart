import 'package:flutter/material.dart';
import 'deal_detail_page.dart';

class MarketPlacePage extends StatelessWidget {
  final Function(String, String, IconData)? onDealTap;

  const MarketPlacePage({super.key, this.onDealTap});

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
                'Marketplace',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              _MarketCard(
                reward: '\$1.35',
                title: 'Urban Mobility Study',
                subtitle: 'Per 7 days GPS Data',
                icon: Icons.location_on,
                detail: 'Detail',
                onTap: () {
                  if (onDealTap != null) {
                    onDealTap!('Urban Mobility Study', '\$1.35', Icons.location_on);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DealDetailPage(
                          dealTitle: 'Urban Mobility Study',
                          reward: '\$1.35',
                          icon: Icons.location_on,
                        ),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 20),
              _MarketCard(
                reward: '\$0.80',
                title: 'App Usage Trend',
                subtitle: 'App open patterns',
                icon: Icons.apps,
                detail: 'Detail',
                onTap: () {
                  if (onDealTap != null) {
                    onDealTap!('App Usage Trend', '\$0.80', Icons.apps);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DealDetailPage(
                          dealTitle: 'App Usage Trend',
                          reward: '\$0.80',
                          icon: Icons.apps,
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarketCard extends StatelessWidget {
  final String reward;
  final String title;
  final String subtitle;
  final IconData icon;
  final String detail;
  final VoidCallback? onTap;

  const _MarketCard({
    required this.reward,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.detail,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: Colors.white.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.tealAccent, size: 36),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ' $reward Reward',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.tealAccent,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$detail ▼',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.tealAccent,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 