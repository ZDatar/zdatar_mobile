import 'package:flutter/material.dart';

class DealDetailPage extends StatelessWidget {
  final String dealTitle;
  final String reward;
  final IconData icon;
  final VoidCallback? onBack;

  const DealDetailPage({
    super.key,
    required this.dealTitle,
    required this.reward,
    required this.icon,
    this.onBack,
  });

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
              Row(
                children: [
                  IconButton(
                    onPressed: onBack ?? () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Data deal',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              icon,
                              color: theme.colorScheme.secondary,
                              size: 80,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              dealTitle,
                              style: theme.textTheme.headlineLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(reward, style: theme.textTheme.headlineMedium),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Description',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Data collect: GPS, Temperature, Humidity, Vibration',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Data will be collected during your travelling within the city',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Terms',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Only applicable within city limits and during active travel periods',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Outdoor environment required for accurate data collection',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: theme.elevatedButtonTheme.style?.copyWith(
                            padding: WidgetStateProperty.all(
                              const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                          onPressed: () {
                            // Handle accept deal
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Center(child: Text('Deal accepted!')),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          child: Text(
                            'Accept Deal',
                            style: theme.textTheme.titleLarge,
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
