import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../models/app_state.dart';
import '../services/real_data_collection_service.dart';

class CategoryDetailPage extends StatefulWidget {
  final String categoryName;
  final Map<String, dynamic> categoryData;

  const CategoryDetailPage({
    super.key,
    required this.categoryName,
    required this.categoryData,
  });

  @override
  State<CategoryDetailPage> createState() => _CategoryDetailPageState();
}

class _CategoryDetailPageState extends State<CategoryDetailPage> {
  final RealDataCollectionService _dataService = RealDataCollectionService();
  Map<String, Map<String, dynamic>> _realtimeData = {};
  Timer? _dataTimer;

  @override
  void initState() {
    super.initState();
    _startRealtimeData();
  }

  @override
  void dispose() {
    _dataTimer?.cancel();
    super.dispose();
  }

  void _startRealtimeData() {
    _updateData();
    _dataTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _updateData();
    });
  }

  Future<void> _updateData() async {
    final subcategories = widget.categoryData['subcategories'] as Map<String, bool>;
    final Map<String, Map<String, dynamic>> newData = {};
    
    // Collect data for all enabled subcategories
    for (var entry in subcategories.entries) {
      if (entry.value) {
        final data = await _dataService.collectRealData(
          widget.categoryName,
          entry.key,
        );
        newData[entry.key] = data;
      }
    }
    
    if (mounted) {
      setState(() {
        _realtimeData = newData;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = context.watch<MyAppState>();
    final isEnabled = widget.categoryData['enabled'] as bool;
    final subcategories = widget.categoryData['subcategories'] as Map<String, bool>;

    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text(
          widget.categoryName,
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Header
              Card(
                color: Colors.white.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.largeRadius,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            widget.categoryData['icon'] as IconData,
                            color: isEnabled ? Colors.green : Colors.grey,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.categoryName,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      isEnabled
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      size: 18,
                                      color: isEnabled
                                          ? Colors.green
                                          : Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isEnabled ? 'Active' : 'Paused',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
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
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.categoryData['description'] as String,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Data Collection Details
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Collection Details',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Use Case
                      _buildDetailCard(
                        'Use Case',
                        widget.categoryData['useCase'] as String,
                        Icons.lightbulb_outline,
                        theme,
                      ),

                      const SizedBox(height: 12),

                      // Data Retention
                      _buildDetailCard(
                        'Data Retention',
                        widget.categoryData['retention'] as String,
                        Icons.schedule,
                        theme,
                      ),

                      const SizedBox(height: 24),

                      // Subcategories
                      Text(
                        'Data Subcategories',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      ...subcategories.entries.map((entry) {
                        return _buildSubcategoryCard(
                          entry.key,
                          entry.value,
                          theme,
                          appState,
                        );
                      }),

                      const SizedBox(height: 24),

                      // Privacy Information
                      _buildPrivacyCard(theme),

                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: _buildToggleButton(subcategories, theme),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _deleteData(context),
                              icon: const Icon(Icons.delete, size: 16),
                              label: const Text('Delete Data'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
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
    );
  }

  Widget _buildDetailCard(
    String title,
    String content,
    IconData icon,
    ThemeData theme,
  ) {
    return Card(
      color: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mediumRadius),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
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

  Widget _buildSubcategoryCard(String name, bool isEnabled, ThemeData theme, MyAppState appState) {
    final hasRealtimeData = isEnabled && appState.developerMode && _realtimeData.containsKey(name);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.white.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.smallRadius),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Icon(
                    isEnabled ? Icons.check_circle : Icons.cancel,
                    color: isEnabled ? Colors.green : Colors.grey,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    isEnabled ? 'Active' : 'Paused',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isEnabled ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Real-time Data Card for this subcategory
          if (hasRealtimeData)
            Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 8.0),
              child: _buildRealtimeDataCardForSubcategory(name, theme),
            ),
        ],
      ),
    );
  }

  Widget _buildPrivacyCard(ThemeData theme) {
    return Card(
      color: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mediumRadius),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.security, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Privacy Protection',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '• Data processed locally on your device\n'
              '• Only aggregated insights shared\n'
              '• No personal identifiable information collected\n'
              '• You can pause or delete anytime',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealtimeDataCardForSubcategory(String subcategoryName, ThemeData theme) {
    final data = _realtimeData[subcategoryName];
    if (data == null) return const SizedBox.shrink();

    return Card(
      color: Colors.teal.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.mediumRadius,
        side: BorderSide(color: Colors.teal.withValues(alpha: 0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.developer_mode, color: Colors.teal, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Real-time Data',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.teal,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'LIVE',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SelectableText(
                  _formatRealtimeData(data),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Updates every 2s',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white54,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRealtimeData(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    data.forEach((key, value) {
      if (value is Map) {
        buffer.writeln('$key:');
        value.forEach((k, v) {
          buffer.writeln('  $k: $v');
        });
      } else {
        buffer.writeln('$key: $value');
      }
    });
    return buffer.toString().trim();
  }

  Widget _buildToggleButton(Map<String, bool> subcategories, ThemeData theme) {
    final allDisabled = subcategories.values.every((enabled) => !enabled);
    
    if (allDisabled) {
      return OutlinedButton.icon(
        onPressed: () => _toggleAllSubcategories(context, subcategories, true),
        icon: const Icon(Icons.play_arrow, size: 16),
        label: const Text('Enable All'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.green,
          side: const BorderSide(color: Colors.green),
          padding: const EdgeInsets.symmetric(
            vertical: 12,
          ),
        ),
      );
    } else {
      return OutlinedButton.icon(
        onPressed: () => _toggleAllSubcategories(context, subcategories, false),
        icon: const Icon(Icons.pause, size: 16),
        label: const Text('Pause All'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.orange,
          side: const BorderSide(color: Colors.orange),
          padding: const EdgeInsets.symmetric(
            vertical: 12,
          ),
        ),
      );
    }
  }

  void _toggleAllSubcategories(BuildContext context, Map<String, bool> subcategories, bool enable) {
    setState(() {
      subcategories.updateAll((key, value) => enable);
      widget.categoryData['enabled'] = enable;
    });
    
    // Start or stop data collection service
    if (enable) {
      _dataService.startCategoryCollection(widget.categoryName, subcategories);
    } else {
      _dataService.stopCategoryCollection(widget.categoryName);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enable 
            ? '${widget.categoryName} - All subcategories enabled'
            : '${widget.categoryName} - All subcategories paused'
        ),
        backgroundColor: enable ? Colors.green : Colors.orange,
      ),
    );
  }

  void _deleteData(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${widget.categoryName} Data'),
        content: Text(
          'This will permanently delete all ${widget.categoryName} data from your device. '
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
                  content: Text('${widget.categoryName} data deleted successfully'),
                  backgroundColor: Colors.red,
                ),
              );
              Navigator.of(context).pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
