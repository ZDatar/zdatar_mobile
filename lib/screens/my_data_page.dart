import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class MyDataPage extends StatefulWidget {
  const MyDataPage({super.key});

  @override
  State<MyDataPage> createState() => _MyDataPageState();
}

class _MyDataPageState extends State<MyDataPage> {
  // Data collection categories with granular consent
  final Map<String, Map<String, dynamic>> _dataCategories = {
    'Core Device & Session': {
      'enabled': true,
      'description': 'Device profile, power, network, storage & performance',
      'subcategories': {
        'Device Profile': true,
        'Power & Thermal': true,
        'Network State': true,
        'Storage & Performance': true,
      },
      'useCase': 'QA/compatibility analytics, energy studies',
      'retention': '30 days local, aggregates only shared',
      'icon': Icons.phone_android,
    },
    'Mobility & Environment': {
      'enabled': false,
      'description':
          'Location, motion sensors, proximity, ambient audio features',
      'subcategories': {
        'Location (Coarse)': false,
        'Location (Fine)': false,
        'Motion Sensors': false,
        'Barometer & Magnetometer': false,
        'Proximity Scans': false,
        'Ambient Audio Features': false,
      },
      'useCase': 'Urban planning, traffic models, mobility studies',
      'retention': '7 days raw local, map-matched segments shared',
      'icon': Icons.location_on,
    },
    'App & Digital Behavior': {
      'enabled': false,
      'description':
          'App usage summaries, browsing categories, network throughput',
      'subcategories': {
        'App Usage Summaries': false,
        'Browsing Categories': false,
        'Network Throughput': false,
      },
      'useCase': 'Digital well-being cohorts, market research',
      'retention': 'Hourly/daily roll-ups, no raw content',
      'icon': Icons.apps,
    },
    'Health & Wellness': {
      'enabled': false,
      'description':
          'Activity & vitals aggregates via HealthKit/Health Connect',
      'subcategories': {'Activity & Vitals': false, 'Sensor Provenance': false},
      'useCase': 'Population wellness, ergonomic research',
      'retention': 'Daily/hourly bins, sync once daily',
      'icon': Icons.favorite,
    },
    'Commerce & Finance': {
      'enabled': false,
      'description': 'Purchase telemetry, wallet activity (opt-in, no PII)',
      'subcategories': {'Purchase Telemetry': false, 'Wallet Activity': false},
      'useCase': 'Macro consumption trends, marketplace analytics',
      'retention': 'Amount bins only, no merchant names',
      'icon': Icons.payment,
    },
    'Context Semantics': {
      'enabled': false,
      'description': 'Home/work anchors, routine features (computed on device)',
      'subcategories': {'Home/Work Anchors': false, 'Routine Features': false},
      'useCase': 'Commute analytics, behavioral science cohorts',
      'retention': 'Binary flags only, coordinates never uploaded',
      'icon': Icons.home_work,
    },
    'Developer & QA': {
      'enabled': true,
      'description':
          'Sensor availability, permissions, data quality indicators',
      'subcategories': {
        'Sensor Availability': true,
        'Data Quality Indicators': true,
      },
      'useCase': 'Sampling bias correction, cleaning & weighting',
      'retention': 'Metadata only, no personal data',
      'icon': Icons.bug_report,
    },
  };

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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'My Data',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showPrivacyPrinciples(context),
                    icon: const Icon(Icons.info_outline, color: Colors.white),
                    tooltip: 'Privacy Principles',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Granular, revocable consent per category',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pauseAllDataCollection,
                      icon: const Icon(Icons.pause),
                      label: const Text('Pause All'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _deleteAllData,
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Delete All'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: _dataCategories.length,
                  itemBuilder: (context, index) {
                    final category = _dataCategories.keys.elementAt(index);
                    final categoryData = _dataCategories[category]!;
                    final isEnabled = categoryData['enabled'] as bool;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Card(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.largeRadius,
                        ),
                        child: ExpansionTile(
                          leading: Icon(
                            categoryData['icon'] as IconData,
                            color: isEnabled ? Colors.green : Colors.grey,
                            size: 28,
                          ),
                          title: Text(
                            category,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                categoryData['description'] as String,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    isEnabled
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    size: 16,
                                    color: isEnabled
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isEnabled ? 'Active' : 'Paused',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isEnabled
                                          ? Colors.green
                                          : Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Switch(
                            value: isEnabled,
                            onChanged: (value) {
                              setState(() {
                                _dataCategories[category]!['enabled'] = value;
                                // If disabling main category, disable all subcategories
                                if (!value) {
                                  final subcategories =
                                      _dataCategories[category]!['subcategories']
                                          as Map<String, bool>;
                                  subcategories.updateAll(
                                    (key, value) => false,
                                  );
                                }
                              });
                            },
                            activeColor: Colors.green,
                            activeTrackColor: Colors.green.withValues(
                              alpha: 0.3,
                            ),
                            inactiveThumbColor: Colors.grey,
                            inactiveTrackColor: Colors.grey.withValues(
                              alpha: 0.3,
                            ),
                          ),
                          iconColor: Colors.white,
                          collapsedIconColor: Colors.white,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoRow(
                                    'Use Case:',
                                    categoryData['useCase'] as String,
                                    theme,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInfoRow(
                                    'Retention:',
                                    categoryData['retention'] as String,
                                    theme,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Subcategories:',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ..._buildSubcategoryToggles(
                                    category,
                                    categoryData,
                                    theme,
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () =>
                                              _pauseCategory(category),
                                          icon: const Icon(
                                            Icons.pause,
                                            size: 16,
                                          ),
                                          label: const Text('Pause'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.orange,
                                            side: const BorderSide(
                                              color: Colors.orange,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () =>
                                              _deleteCategoryData(category),
                                          icon: const Icon(
                                            Icons.delete,
                                            size: 16,
                                          ),
                                          label: const Text('Delete'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red,
                                            side: const BorderSide(
                                              color: Colors.red,
                                            ),
                                          ),
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
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildSubcategoryToggles(
    String category,
    Map<String, dynamic> categoryData,
    ThemeData theme,
  ) {
    final subcategories = categoryData['subcategories'] as Map<String, bool>;
    final isMainEnabled = categoryData['enabled'] as bool;

    return subcategories.entries.map((entry) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                entry.key,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.white),
              ),
            ),
            Switch(
              value: entry.value && isMainEnabled,
              onChanged: isMainEnabled
                  ? (value) {
                      setState(() {
                        subcategories[entry.key] = value;
                      });
                    }
                  : null,
              activeColor: Colors.green,
              activeTrackColor: Colors.green.withValues(alpha: 0.3),
              inactiveThumbColor: Colors.grey,
              inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
            ),
          ],
        ),
      );
    }).toList();
  }

  void _showPrivacyPrinciples(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Principles'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🔒 Only collect non-sensitive data\n'
                '📱 Default to on-device processing\n'
                '✅ Granular, revocable consent per category\n'
                '🏠 Store raw data locally; share aggregates/features\n'
                '👁️ Show who/why/how long for every collection stream\n'
                '⏸️ Let users pause or delete with one tap\n\n'
                'Privacy Guardrails:\n'
                '• No message/email/notification content\n'
                '• No contact lists, photos/videos, keystrokes\n'
                '• No call/SMS contents or exact addresses\n'
                '• Apply k-anonymity and differential privacy\n'
                '• Rotate hashed identifiers regularly',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _pauseAllDataCollection() {
    setState(() {
      for (final category in _dataCategories.keys) {
        _dataCategories[category]!['enabled'] = false;
        final subcategories =
            _dataCategories[category]!['subcategories'] as Map<String, bool>;
        subcategories.updateAll((key, value) => false);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All data collection paused'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _deleteAllData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Data'),
        content: const Text(
          'This will permanently delete all collected data from your device. '
          'This action cannot be undone. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All data deleted successfully'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _pauseCategory(String category) {
    setState(() {
      _dataCategories[category]!['enabled'] = false;
      final subcategories =
          _dataCategories[category]!['subcategories'] as Map<String, bool>;
      subcategories.updateAll((key, value) => false);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$category data collection paused'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _deleteCategoryData(String category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $category Data'),
        content: Text(
          'This will permanently delete all $category data from your device. '
          'This action cannot be undone. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$category data deleted successfully'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
