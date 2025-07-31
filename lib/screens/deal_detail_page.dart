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
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Marketplace',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Data Deals Details',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.tealAccent,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(icon, color: Colors.tealAccent, size: 36),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          dealTitle,
                                          style: theme.textTheme.titleLarge?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$reward Reward',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                              Text(
                                'Description',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.tealAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Data collect: GPS, Temperature, Humidity, Vibration',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Data will be collected during your travelling within the city',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Term and conditions',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.tealAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Only applicable within city limits and during active travel periods',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Outdoor environment required for accurate data collection',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 32),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Handle accept deal
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Deal accepted!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.tealAccent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Accept Deal',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
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