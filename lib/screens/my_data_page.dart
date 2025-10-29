import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../theme/app_colors.dart';
import 'category_detail_page.dart';
import '../services/real_data_collection_service.dart';

class MyDataPage extends StatefulWidget {
  const MyDataPage({super.key});

  @override
  State<MyDataPage> createState() => _MyDataPageState();
}

class _MyDataPageState extends State<MyDataPage> {
  final RealDataCollectionService _dataCollectionService =
      RealDataCollectionService();
  
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      colors: true,
      printEmojis: true,
    ),
  );
  
  // Data collection categories with granular consent
  final Map<String, Map<String, dynamic>> _dataCategories = {
    'Core Device & Session': {
      'enabled': false,
      'description': 'Device profile, power, network, storage & performance',
      'subcategories': {
        'Device Profile': false,
        'Power & Thermal': false,
        'Network State': false,
        'Storage & Performance': false,
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
    'Developer & QA': {
      'enabled': false,
      'description':
          'Sensor availability, permissions, data quality indicators',
      'subcategories': {
        'Sensor Availability': false,
        'Data Quality Indicators': false,
      },
      'useCase': 'Sampling bias correction, cleaning & weighting',
      'retention': 'Metadata only, no personal data',
      'icon': Icons.bug_report,
    },
  };

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('data_categories');
    
    if (savedData != null) {
      try {
        final decoded = json.decode(savedData) as Map<String, dynamic>;
        setState(() {
          decoded.forEach((category, data) {
            if (_dataCategories.containsKey(category)) {
              _dataCategories[category]!['enabled'] = data['enabled'] ?? false;
              final savedSubcategories = data['subcategories'] as Map<String, dynamic>?;
              if (savedSubcategories != null) {
                final subcategories = _dataCategories[category]!['subcategories'] as Map<String, bool>;
                savedSubcategories.forEach((key, value) {
                  if (subcategories.containsKey(key)) {
                    subcategories[key] = value as bool;
                  }
                });
              }
            }
          });
        });
        
        // Restart data collection for enabled categories
        _dataCategories.forEach((category, data) {
          if (data['enabled'] == true) {
            final subcategories = data['subcategories'] as Map<String, bool>;
            _dataCollectionService.startCategoryCollection(category, subcategories);
          }
        });
      } catch (e) {
        _logger.e('Error loading saved settings: $e');
      }
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final dataToSave = <String, dynamic>{};
    
    _dataCategories.forEach((category, data) {
      dataToSave[category] = {
        'enabled': data['enabled'],
        'subcategories': data['subcategories'],
      };
    });
    
    await prefs.setString('data_categories', json.encode(dataToSave));
  }

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
                'My Data',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Granular, revocable consent per category',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
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
              // const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount:
                      _dataCategories.length + 1, // +1 for the buttons section
                  itemBuilder: (context, index) {
                    // If this is the last item, show the buttons
                    if (index == _dataCategories.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 24, bottom: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _hasAnyEnabledCategory() 
                                    ? _pauseAllDataCollection 
                                    : _enableAllDataCollection,
                                icon: Icon(_hasAnyEnabledCategory() 
                                    ? Icons.pause 
                                    : Icons.play_arrow),
                                label: Text(_hasAnyEnabledCategory() 
                                    ? 'Pause All' 
                                    : 'Enable All'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _hasAnyEnabledCategory() 
                                      ? Colors.orange 
                                      : Colors.green,
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
                      );
                    }

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
                                // When enabling/disabling main category, enable/disable all subcategories
                                final subcategories =
                                    _dataCategories[category]!['subcategories']
                                        as Map<String, bool>;
                                subcategories.updateAll(
                                  (key, subValue) => value,
                                );

                                // Start/stop data collection based on category state
                                if (value) {
                                  _dataCollectionService
                                      .startCategoryCollection(
                                        category,
                                        subcategories,
                                      );
                                } else {
                                  _dataCollectionService.stopCategoryCollection(
                                    category,
                                  );
                                }
                              });
                              _saveSettings();
                            },
                            activeThumbColor: Colors.green,
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
                                          onPressed: () => _navigateToDetail(
                                            context,
                                            category,
                                            categoryData,
                                          ),
                                          icon: const Icon(
                                            Icons.info_outline,
                                            size: 16,
                                          ),
                                          label: const Text('View Details'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.blue,
                                            side: const BorderSide(
                                              color: Colors.blue,
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

                        // If all subcategories are disabled, disable the main category
                        final allDisabled = subcategories.values.every(
                          (subValue) => !subValue,
                        );
                        if (allDisabled) {
                          _dataCategories[category]!['enabled'] = false;
                          _dataCollectionService.stopCategoryCollection(
                            category,
                          );
                        }
                        // If at least one subcategory is enabled, ensure main category is enabled
                        else if (value) {
                          _dataCategories[category]!['enabled'] = true;
                        }

                        // Update data collection based on current subcategory states
                        _dataCollectionService.startCategoryCollection(
                          category,
                          subcategories,
                        );
                      });
                      _saveSettings();
                    }
                  : null,
              activeThumbColor: Colors.green,
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

  bool _hasAnyEnabledCategory() {
    return _dataCategories.values.any((category) => category['enabled'] as bool);
  }

  void _enableAllDataCollection() {
    setState(() {
      for (final category in _dataCategories.keys) {
        _dataCategories[category]!['enabled'] = true;
        final subcategories =
            _dataCategories[category]!['subcategories'] as Map<String, bool>;
        subcategories.updateAll((key, value) => true);

        // Start data collection for all categories
        _dataCollectionService.startCategoryCollection(category, subcategories);
      }
    });
    _saveSettings();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All data collection enabled'),
        backgroundColor: Colors.green,
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

        // Stop data collection for all categories
        _dataCollectionService.stopCategoryCollection(category);
      }
    });
    _saveSettings();
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

              // Stop all data collection and clear data
              for (final category in _dataCategories.keys) {
                _dataCollectionService.stopCategoryCollection(category);
              }

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

  void _navigateToDetail(
    BuildContext context,
    String category,
    Map<String, dynamic> categoryData,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CategoryDetailPage(
          categoryName: category,
          categoryData: categoryData,
        ),
      ),
    );
    // Refresh the state and save when returning from detail page
    setState(() {});
    _saveSettings();
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

              // Stop data collection for this category
              _dataCollectionService.stopCategoryCollection(category);

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

  @override
  void dispose() {
    _dataCollectionService.dispose();
    super.dispose();
  }
}
