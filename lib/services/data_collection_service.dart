import 'dart:async';
import 'dart:math';
import 'package:logger/logger.dart';

class DataCollectionService {
  static final DataCollectionService _instance =
      DataCollectionService._internal();
  factory DataCollectionService() => _instance;
  DataCollectionService._internal();

  final Map<String, Timer?> _activeCollectors = {};
  final Map<String, Map<String, dynamic>> _collectedData = {};

  // Logger instance with custom configuration
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0, // Don't show method stack
      errorMethodCount: 3, // Show more methods for errors
      lineLength: 80, // Shorter lines
      colors: true, // Colorful log messages
      printEmojis: true, // Print emojis for different log levels
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart, // Include timestamp
    ),
  );

  void startCategoryCollection(
    String category,
    Map<String, bool> subcategories,
  ) {
    _logger.i('🔄 Starting data collection for category: $category');

    // Stop existing collection for this category
    stopCategoryCollection(category);

    // Start collection for enabled subcategories
    subcategories.forEach((subcategory, isEnabled) {
      if (isEnabled) {
        _startSubcategoryCollection(category, subcategory);
      }
    });
  }

  void stopCategoryCollection(String category) {
    _logger.i('⏹️ Stopping data collection for category: $category');

    // Stop all timers for this category
    _activeCollectors.keys
        .where((key) => key.startsWith('$category:'))
        .toList()
        .forEach((key) {
          _activeCollectors[key]?.cancel();
          _activeCollectors.remove(key);
        });

    // Clear collected data for this category
    _collectedData.removeWhere((key, value) => key.startsWith('$category:'));
  }

  void _startSubcategoryCollection(String category, String subcategory) {
    final key = '$category:$subcategory';
    _logger.i('▶️ Starting collection for: $subcategory in $category');

    // Create a timer that collects data every 5 seconds
    _activeCollectors[key] = Timer.periodic(const Duration(seconds: 5), (
      timer,
    ) {
      final data = _generateMockData(category, subcategory);
      _collectedData[key] = data;

      _logger.d('📊 [$category] $subcategory: ${_formatDataForConsole(data)}');
    });

    // Collect initial data immediately
    final initialData = _generateMockData(category, subcategory);
    _collectedData[key] = initialData;
    _logger.d(
      '[$category] $subcategory: ${_formatDataForConsole(initialData)}',
    );
  }

  Map<String, dynamic> _generateMockData(String category, String subcategory) {
    final random = Random();
    final timestamp = DateTime.now();

    switch (category) {
      case 'Core Device & Session':
        return _generateCoreDeviceData(subcategory, random, timestamp);
      case 'Mobility & Environment':
        return _generateMobilityData(subcategory, random, timestamp);
      case 'App & Digital Behavior':
        return _generateAppBehaviorData(subcategory, random, timestamp);
      case 'Health & Wellness':
        return _generateHealthData(subcategory, random, timestamp);
      case 'Developer & QA':
        return _generateDeveloperData(subcategory, random, timestamp);
      default:
        return {
          'timestamp': timestamp.toIso8601String(),
          'value': random.nextDouble(),
        };
    }
  }

  Map<String, dynamic> _generateCoreDeviceData(
    String subcategory,
    Random random,
    DateTime timestamp,
  ) {
    switch (subcategory) {
      case 'Device Profile':
        return {
          'timestamp': timestamp.toIso8601String(),
          'device_model': 'iPhone_15_Pro',
          'os_version': '17.2.1',
          'app_version': '1.0.0',
          'screen_resolution': '1179x2556',
        };
      case 'Power & Thermal':
        return {
          'timestamp': timestamp.toIso8601String(),
          'battery_level': (random.nextDouble() * 100).round(),
          'is_charging': random.nextBool(),
          'thermal_state': ['normal', 'fair', 'serious'][random.nextInt(3)],
          'power_mode': random.nextBool() ? 'low_power' : 'normal',
        };
      case 'Network State':
        return {
          'timestamp': timestamp.toIso8601String(),
          'connection_type': ['wifi', 'cellular', 'none'][random.nextInt(3)],
          'signal_strength': random.nextInt(5),
          'data_usage_mb': (random.nextDouble() * 100).toStringAsFixed(2),
        };
      case 'Storage & Performance':
        return {
          'timestamp': timestamp.toIso8601String(),
          'available_storage_gb': (random.nextDouble() * 100).toStringAsFixed(
            1,
          ),
          'memory_usage_mb': (random.nextDouble() * 1000).round(),
          'cpu_usage_percent': (random.nextDouble() * 100).round(),
        };
      default:
        return {
          'timestamp': timestamp.toIso8601String(),
          'value': random.nextDouble(),
        };
    }
  }

  Map<String, dynamic> _generateMobilityData(
    String subcategory,
    Random random,
    DateTime timestamp,
  ) {
    switch (subcategory) {
      case 'Location (Coarse)':
        return {
          'timestamp': timestamp.toIso8601String(),
          'city': 'San Francisco',
          'region': 'California',
          'country': 'US',
        };
      case 'Location (Fine)':
        return {
          'timestamp': timestamp.toIso8601String(),
          'latitude': (37.7749 + (random.nextDouble() - 0.5) * 0.1)
              .toStringAsFixed(6),
          'longitude': (-122.4194 + (random.nextDouble() - 0.5) * 0.1)
              .toStringAsFixed(6),
          'accuracy_meters': random.nextInt(50) + 5,
        };
      case 'Motion Sensors':
        return {
          'timestamp': timestamp.toIso8601String(),
          'accelerometer_x': (random.nextDouble() - 0.5) * 2,
          'accelerometer_y': (random.nextDouble() - 0.5) * 2,
          'accelerometer_z': (random.nextDouble() - 0.5) * 2,
          'activity': [
            'stationary',
            'walking',
            'running',
            'driving',
          ][random.nextInt(4)],
        };
      case 'Proximity Scans':
        return {
          'timestamp': timestamp.toIso8601String(),
          'nearby_devices': random.nextInt(10),
          'bluetooth_beacons': random.nextInt(5),
        };
      default:
        return {
          'timestamp': timestamp.toIso8601String(),
          'value': random.nextDouble(),
        };
    }
  }

  Map<String, dynamic> _generateAppBehaviorData(
    String subcategory,
    Random random,
    DateTime timestamp,
  ) {
    switch (subcategory) {
      case 'App Usage Summaries':
        return {
          'timestamp': timestamp.toIso8601String(),
          'active_app_category': [
            'social',
            'productivity',
            'entertainment',
            'news',
          ][random.nextInt(4)],
          'session_duration_minutes': random.nextInt(60),
          'apps_opened_today': random.nextInt(20) + 5,
        };
      case 'Browsing Categories':
        return {
          'timestamp': timestamp.toIso8601String(),
          'category': [
            'technology',
            'news',
            'shopping',
            'social',
          ][random.nextInt(4)],
          'time_spent_minutes': random.nextInt(30),
        };
      case 'Network Throughput':
        return {
          'timestamp': timestamp.toIso8601String(),
          'download_speed_mbps': (random.nextDouble() * 100).toStringAsFixed(2),
          'upload_speed_mbps': (random.nextDouble() * 50).toStringAsFixed(2),
          'latency_ms': random.nextInt(100) + 10,
        };
      default:
        return {
          'timestamp': timestamp.toIso8601String(),
          'value': random.nextDouble(),
        };
    }
  }

  Map<String, dynamic> _generateHealthData(
    String subcategory,
    Random random,
    DateTime timestamp,
  ) {
    switch (subcategory) {
      case 'Activity & Vitals':
        return {
          'timestamp': timestamp.toIso8601String(),
          'steps_today': random.nextInt(15000) + 1000,
          'heart_rate_bpm': random.nextInt(40) + 60,
          'calories_burned': random.nextInt(500) + 200,
          'active_minutes': random.nextInt(120),
        };
      case 'Sensor Provenance':
        return {
          'timestamp': timestamp.toIso8601String(),
          'data_source': [
            'apple_watch',
            'iphone',
            'third_party',
          ][random.nextInt(3)],
          'accuracy_level': ['high', 'medium', 'low'][random.nextInt(3)],
        };
      default:
        return {
          'timestamp': timestamp.toIso8601String(),
          'value': random.nextDouble(),
        };
    }
  }

  Map<String, dynamic> _generateDeveloperData(
    String subcategory,
    Random random,
    DateTime timestamp,
  ) {
    switch (subcategory) {
      case 'Sensor Availability':
        return {
          'timestamp': timestamp.toIso8601String(),
          'gps_available': random.nextBool(),
          'accelerometer_available': random.nextBool(),
          'camera_available': random.nextBool(),
          'microphone_available': random.nextBool(),
        };
      case 'Data Quality Indicators':
        return {
          'timestamp': timestamp.toIso8601String(),
          'data_completeness': random.nextDouble(),
          'signal_quality': [
            'excellent',
            'good',
            'fair',
            'poor',
          ][random.nextInt(4)],
          'collection_errors': random.nextInt(5),
        };
      default:
        return {
          'timestamp': timestamp.toIso8601String(),
          'value': random.nextDouble(),
        };
    }
  }

  String _formatDataForConsole(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    data.forEach((key, value) {
      if (key != 'timestamp') {
        buffer.write('$key: $value, ');
      }
    });
    return buffer.toString().replaceAll(RegExp(r', $'), '');
  }

  Map<String, dynamic> getCollectedData(String category, String subcategory) {
    return _collectedData['$category:$subcategory'] ?? {};
  }

  Map<String, Map<String, dynamic>> getAllCollectedData() {
    return Map.from(_collectedData);
  }

  void dispose() {
    for (var timer in _activeCollectors.values) {
      timer?.cancel();
    }
    _activeCollectors.clear();
    _collectedData.clear();
  }
}
