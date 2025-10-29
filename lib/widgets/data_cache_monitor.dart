import 'package:flutter/material.dart';
import 'dart:async';
import '../services/data_cache_service.dart';

/// Widget to monitor and display data cache statistics
class DataCacheMonitor extends StatefulWidget {
  const DataCacheMonitor({super.key});

  @override
  State<DataCacheMonitor> createState() => _DataCacheMonitorState();
}

class _DataCacheMonitorState extends State<DataCacheMonitor> {
  final DataCacheService _cacheService = DataCacheService();
  Map<String, dynamic> _stats = {};
  Timer? _refreshTimer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
    // Refresh stats every 5 seconds
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _loadStats(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final stats = await _cacheService.getCacheStats();
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  String _formatDuration(DateTime? timestamp) {
    if (timestamp == null) return 'N/A';
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${diff.inHours}h ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Card(
        color: Colors.white.withValues(alpha: 0.05),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final totalPoints = _stats['total_points'] ?? 0;
    final byCategory = _stats['by_category'] as Map<String, int>? ?? {};
    final oldestTime = _stats['oldest_timestamp'] as DateTime?;
    final newestTime = _stats['newest_timestamp'] as DateTime?;

    return Card(
      color: Colors.white.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage, color: theme.colorScheme.secondary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Data Cache Monitor',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'LIVE',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Total data points
            _buildStatRow(
              context,
              'Total Cached Points',
              totalPoints.toString(),
              Icons.data_usage,
            ),
            const SizedBox(height: 8),
            
            // Cache window
            _buildStatRow(
              context,
              'Cache Window',
              '5 minutes',
              Icons.schedule,
            ),
            const SizedBox(height: 8),
            
            // Oldest data
            if (oldestTime != null) ...[
              _buildStatRow(
                context,
                'Oldest Data',
                _formatDuration(oldestTime),
                Icons.access_time,
              ),
              const SizedBox(height: 8),
            ],
            
            // Newest data
            if (newestTime != null) ...[
              _buildStatRow(
                context,
                'Newest Data',
                _formatDuration(newestTime),
                Icons.update,
              ),
              const SizedBox(height: 16),
            ],
            
            // By category breakdown
            if (byCategory.isNotEmpty) ...[
              const Divider(color: Colors.white24),
              const SizedBox(height: 12),
              Text(
                'By Category',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              ...byCategory.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white60,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          entry.value.toString(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            
            // Clear cache button
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear Cache?'),
                      content: const Text(
                        'This will delete all cached data. This action cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirmed == true && mounted) {
                    await _cacheService.clearAllData();
                    await _loadStats();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cache cleared successfully'),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Clear Cache'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
