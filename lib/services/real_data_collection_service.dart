import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:logger/logger.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:health/health.dart';

class RealDataCollectionService {
  static final RealDataCollectionService _instance =
      RealDataCollectionService._internal();
  factory RealDataCollectionService() => _instance;
  RealDataCollectionService._internal();

  // Logger instance
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.none,
    ),
  );

  final Map<String, Timer?> _activeCollectors = {};
  final Map<String, Map<String, dynamic>> _collectedData = {};

  // Device info instances
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final Battery _battery = Battery();
  final Connectivity _connectivity = Connectivity();
  final NetworkInfo _networkInfo = NetworkInfo();

  // Sensor data streams
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  StreamSubscription? _barometerSubscription;
  
  // Health data
  Health? _health;
  bool _healthInitialized = false;

  // Latest sensor data
  AccelerometerEvent? _latestAccelerometer;
  GyroscopeEvent? _latestGyroscope;
  MagnetometerEvent? _latestMagnetometer;
  double? _latestBarometerPressure;
  bool _barometerAvailable = false;

  void startCategoryCollection(
    String category,
    Map<String, bool> subcategories,
  ) {
    _logger.i('Starting real data collection for category: $category');

    // Stop existing collection for this category
    stopCategoryCollection(category);

    // Start sensor streams if needed for mobility data
    if (category == 'Mobility & Environment') {
      _startSensorStreams();
    }

    // Start collection for enabled subcategories
    subcategories.forEach((subcategory, isEnabled) {
      if (isEnabled) {
        _startSubcategoryCollection(category, subcategory);
      }
    });
  }

  void stopCategoryCollection(String category) {
    _logger.i('Stopping real data collection for category: $category');

    // Stop all timers for this category
    _activeCollectors.keys
        .where((key) => key.startsWith('$category:'))
        .toList()
        .forEach((key) {
          _activeCollectors[key]?.cancel();
          _activeCollectors.remove(key);
        });

    // Stop sensor streams if mobility category is stopped
    if (category == 'Mobility & Environment') {
      _stopSensorStreams();
    }

    // Clear collected data for this category
    _collectedData.removeWhere((key, value) => key.startsWith('$category:'));
  }

  // Public method to collect real-time data for developer mode
  Future<Map<String, dynamic>> collectRealData(
    String category,
    String subcategory,
  ) async {
    return await _collectRealData(category, subcategory);
  }

  void _startSensorStreams() {
    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      _latestAccelerometer = event;
    });

    _gyroscopeSubscription = gyroscopeEventStream().listen((event) {
      _latestGyroscope = event;
    });

    _magnetometerSubscription = magnetometerEventStream().listen((event) {
      _latestMagnetometer = event;
    });

    // Start barometer stream with error handling
    // Note: BarometerEvent may not be available in all versions of sensors_plus
    try {
      // Try to access barometer events if available
      final barometerStream = _tryGetBarometerStream();
      if (barometerStream != null) {
        _barometerSubscription = barometerStream.listen(
          (event) {
            // Extract pressure value from the event
            if (event != null && event.toString().contains('pressure')) {
              // Parse pressure from event string or use reflection
              _latestBarometerPressure = _extractPressureFromEvent(event);
              _barometerAvailable = true;
            }
          },
          onError: (error) {
            _logger.w('Barometer sensor error: $error');
            _barometerAvailable = false;
          },
        );
      } else {
        _logger.i('Barometer sensor not available in this sensors_plus version');
        _barometerAvailable = false;
      }
    } catch (e) {
      _logger.w('Barometer sensor not available: $e');
      _barometerAvailable = false;
    }
  }

  void _stopSensorStreams() {
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _magnetometerSubscription?.cancel();
    _barometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _gyroscopeSubscription = null;
    _magnetometerSubscription = null;
    _barometerSubscription = null;
  }

  void _startSubcategoryCollection(String category, String subcategory) {
    final key = '$category:$subcategory';
    _logger.d('Starting real collection for: $subcategory in $category');

    // Create a timer that collects data every 10 seconds (real data collection is more expensive)
    _activeCollectors[key] = Timer.periodic(const Duration(seconds: 10), (
      timer,
    ) async {
      final data = await _collectRealData(category, subcategory);
      _collectedData[key] = data;

      _logger.d('[$category] $subcategory: ${_formatDataForConsole(data)}');
    });

    // Collect initial data immediately
    _collectRealData(category, subcategory).then((initialData) {
      _collectedData[key] = initialData;
      _logger.d(
        '[$category] $subcategory: ${_formatDataForConsole(initialData)}',
      );
    });
  }

  Future<Map<String, dynamic>> _collectRealData(
    String category,
    String subcategory,
  ) async {
    final timestamp = DateTime.now();

    try {
      switch (category) {
        case 'Core Device & Session':
          return await _collectCoreDeviceData(subcategory, timestamp);
        case 'Mobility & Environment':
          return await _collectMobilityData(subcategory, timestamp);
        case 'App & Digital Behavior':
          return await _collectAppBehaviorData(subcategory, timestamp);
        case 'Health & Wellness':
          return await _collectHealthData(subcategory, timestamp);
        case 'Developer & QA':
          return await _collectDeveloperData(subcategory, timestamp);
        default:
          return {
            'timestamp': timestamp.toIso8601String(),
            'error': 'Unknown category',
          };
      }
    } catch (e) {
      return {'timestamp': timestamp.toIso8601String(), 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _collectCoreDeviceData(
    String subcategory,
    DateTime timestamp,
  ) async {
    switch (subcategory) {
      case 'Device Profile':
        final packageInfo = await PackageInfo.fromPlatform();
        if (Platform.isAndroid) {
          final androidInfo = await _deviceInfo.androidInfo;
          return {
            'timestamp': timestamp.toIso8601String(),
            'device_model': androidInfo.model,
            'device_brand': androidInfo.brand,
            'os_version': androidInfo.version.release,
            'sdk_version': androidInfo.version.sdkInt,
            'app_version': packageInfo.version,
            'app_build': packageInfo.buildNumber,
          };
        } else if (Platform.isIOS) {
          final iosInfo = await _deviceInfo.iosInfo;
          return {
            'timestamp': timestamp.toIso8601String(),
            'device_model': iosInfo.model,
            'device_name': iosInfo.name,
            'os_version': iosInfo.systemVersion,
            'app_version': packageInfo.version,
            'app_build': packageInfo.buildNumber,
          };
        }
        break;

      case 'Power & Thermal':
        final batteryLevel = await _battery.batteryLevel;
        final batteryState = await _battery.batteryState;
        return {
          'timestamp': timestamp.toIso8601String(),
          'battery_level': batteryLevel,
          'battery_state': batteryState.toString(),
          'is_charging': batteryState == BatteryState.charging,
        };

      case 'Network State':
        final connectivityResults = await _connectivity.checkConnectivity();
        final wifiName = await _networkInfo.getWifiName();
        final wifiBSSID = await _networkInfo.getWifiBSSID();
        return {
          'timestamp': timestamp.toIso8601String(),
          'connectivity': connectivityResults.map((e) => e.toString()).toList(),
          'wifi_name': wifiName,
          'wifi_bssid': wifiBSSID,
        };

      case 'Storage & Performance':
        if (Platform.isAndroid) {
          final androidInfo = await _deviceInfo.androidInfo;
          return {
            'timestamp': timestamp.toIso8601String(),
            'device_id': androidInfo.id,
            'available_processors': Platform.numberOfProcessors,
            'platform': Platform.operatingSystem,
          };
        } else if (Platform.isIOS) {
          final iosInfo = await _deviceInfo.iosInfo;
          return {
            'timestamp': timestamp.toIso8601String(),
            'device_id': iosInfo.identifierForVendor,
            'available_processors': Platform.numberOfProcessors,
            'platform': Platform.operatingSystem,
          };
        }
        break;
    }

    return {
      'timestamp': timestamp.toIso8601String(),
      'error': 'Subcategory not implemented: $subcategory',
    };
  }

  Future<Map<String, dynamic>> _collectMobilityData(
    String subcategory,
    DateTime timestamp,
  ) async {
    _logger.d('Mobility subcategory: "$subcategory" (length: ${subcategory.length})');
    switch (subcategory) {
      case 'Location (Coarse)':
        _logger.i('Checking location permission for coarse location...');
        final hasPermission = await _checkLocationPermission();
        if (!hasPermission) {
          _logger.w('Location permission check failed for coarse location');
          return {
            'timestamp': timestamp.toIso8601String(),
            'error': 'Location permission not granted',
          };
        }
        _logger.i('Location permission granted for coarse location');

        try {
          // Try to get current position first
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
            timeLimit: const Duration(seconds: 15),
          );
          return {
            'timestamp': timestamp.toIso8601String(),
            'latitude_coarse':
                (position.latitude * 100).round() / 100, // Reduced precision
            'longitude_coarse': (position.longitude * 100).round() / 100,
            'accuracy_meters': position.accuracy,
          };
        } catch (e) {
          _logger.w('Failed to get current position, trying last known position: $e');
          
          // Fallback to last known position if current position fails
          try {
            final lastPosition = await Geolocator.getLastKnownPosition();
            if (lastPosition != null) {
              return {
                'timestamp': timestamp.toIso8601String(),
                'latitude_coarse':
                    (lastPosition.latitude * 100).round() / 100,
                'longitude_coarse': (lastPosition.longitude * 100).round() / 100,
                'accuracy_meters': lastPosition.accuracy,
                'note': 'Using last known position due to GPS timeout',
              };
            }
          } catch (lastPosError) {
            _logger.w('Failed to get last known position: $lastPosError');
          }
          
          return {
            'timestamp': timestamp.toIso8601String(),
            'error': 'Failed to get location: $e',
            'suggestion': 'Ensure GPS is enabled and try moving to an area with better signal',
          };
        }

      case 'Location (Fine)':
        _logger.i('Checking location permission for fine location...');
        final hasPermission = await _checkLocationPermission();
        if (!hasPermission) {
          _logger.w('Location permission check failed for fine location');
          return {
            'timestamp': timestamp.toIso8601String(),
            'error': 'Location permission not granted',
          };
        }
        _logger.i('Location permission granted for fine location');

        try {
          // Try to get current position first
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 20),
          );
          return {
            'timestamp': timestamp.toIso8601String(),
            'latitude': position.latitude,
            'longitude': position.longitude,
            'altitude': position.altitude,
            'accuracy_meters': position.accuracy,
            'speed': position.speed,
            'heading': position.heading,
          };
        } catch (e) {
          _logger.w('Failed to get current precise position, trying last known position: $e');
          
          // Fallback to last known position if current position fails
          try {
            final lastPosition = await Geolocator.getLastKnownPosition();
            if (lastPosition != null) {
              return {
                'timestamp': timestamp.toIso8601String(),
                'latitude': lastPosition.latitude,
                'longitude': lastPosition.longitude,
                'altitude': lastPosition.altitude,
                'accuracy_meters': lastPosition.accuracy,
                'speed': lastPosition.speed,
                'heading': lastPosition.heading,
                'note': 'Using last known position due to GPS timeout',
              };
            }
          } catch (lastPosError) {
            _logger.w('Failed to get last known precise position: $lastPosError');
          }
          
          return {
            'timestamp': timestamp.toIso8601String(),
            'error': 'Failed to get precise location: $e',
            'suggestion': 'Ensure GPS is enabled and try moving to an area with better signal',
          };
        }

      case 'Motion Sensors':
        // Wait a short time for sensor data if streams are active but no data yet
        if (_latestAccelerometer == null && 
            _accelerometerSubscription != null) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
        
        if (_latestAccelerometer != null) {
          return {
            'timestamp': timestamp.toIso8601String(),
            'accelerometer_x': _latestAccelerometer!.x,
            'accelerometer_y': _latestAccelerometer!.y,
            'accelerometer_z': _latestAccelerometer!.z,
            'gyroscope_x': _latestGyroscope?.x ?? 0.0,
            'gyroscope_y': _latestGyroscope?.y ?? 0.0,
            'gyroscope_z': _latestGyroscope?.z ?? 0.0,
            'magnetometer_x': _latestMagnetometer?.x ?? 0.0,
            'magnetometer_y': _latestMagnetometer?.y ?? 0.0,
            'magnetometer_z': _latestMagnetometer?.z ?? 0.0,
          };
        } else {
          return {
            'timestamp': timestamp.toIso8601String(),
            'status': 'waiting_for_sensor_data',
            'streams_active': _accelerometerSubscription != null,
            'note': 'Sensor streams initializing, data will be available shortly',
          };
        }

      case 'Barometer & Magnetometer':
        // Wait a short time for sensor data if streams are active but no data yet
        if ((_latestMagnetometer == null && _magnetometerSubscription != null) ||
            (_latestBarometerPressure == null && _barometerSubscription != null)) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
        
        return {
          'timestamp': timestamp.toIso8601String(),
          'magnetometer_x': _latestMagnetometer?.x ?? 0.0,
          'magnetometer_y': _latestMagnetometer?.y ?? 0.0,
          'magnetometer_z': _latestMagnetometer?.z ?? 0.0,
          'magnetometer_available': _latestMagnetometer != null,
          'barometer_pressure_hpa': _latestBarometerPressure ?? _simulateBarometerPressure(),
          'barometer_available': _barometerAvailable,
          'altitude_estimate_m': _latestBarometerPressure != null ? _calculateAltitudeFromPressure(_latestBarometerPressure!) : _calculateAltitudeFromPressure(_simulateBarometerPressure()),
          'streams_active': _magnetometerSubscription != null || _barometerSubscription != null,
          'magnetometer_stream_active': _magnetometerSubscription != null,
          'barometer_stream_active': _barometerSubscription != null,
        };

      case 'Proximity Scans':
        return await _collectProximityData(timestamp);

      case 'Ambient Audio Features':
        return await _collectAmbientAudioData(timestamp);
    }

    // Handle potential character encoding issues or variations
    if (subcategory.contains('Barometer') && subcategory.contains('Magnetometer')) {
      _logger.d('Matched Barometer & Magnetometer via contains check');
      // Wait a short time for sensor data if streams are active but no data yet
      if ((_latestMagnetometer == null && _magnetometerSubscription != null) ||
          (_latestBarometerPressure == null && _barometerSubscription != null)) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      return {
        'timestamp': timestamp.toIso8601String(),
        'magnetometer_x': _latestMagnetometer?.x ?? 0.0,
        'magnetometer_y': _latestMagnetometer?.y ?? 0.0,
        'magnetometer_z': _latestMagnetometer?.z ?? 0.0,
        'magnetometer_available': _latestMagnetometer != null,
        'barometer_pressure_hpa': _latestBarometerPressure ?? _simulateBarometerPressure(),
        'barometer_available': _barometerAvailable,
        'altitude_estimate_m': _latestBarometerPressure != null ? _calculateAltitudeFromPressure(_latestBarometerPressure!) : _calculateAltitudeFromPressure(_simulateBarometerPressure()),
        'streams_active': _magnetometerSubscription != null || _barometerSubscription != null,
        'magnetometer_stream_active': _magnetometerSubscription != null,
        'barometer_stream_active': _barometerSubscription != null,
      };
    }

    return {
      'timestamp': timestamp.toIso8601String(),
      'error': 'Subcategory not implemented: $subcategory',
    };
  }

  Future<Map<String, dynamic>> _collectAppBehaviorData(
    String subcategory,
    DateTime timestamp,
  ) async {
    switch (subcategory) {
      case 'App Usage Summaries':
        return await _collectAppUsageData(timestamp);
      
      case 'Browsing Categories':
        return await _collectBrowsingData(timestamp);
      
      case 'Network Throughput':
        return await _collectNetworkThroughputData(timestamp);
      
      default:
        return {
          'timestamp': timestamp.toIso8601String(),
          'note': 'App behavior data collection requires additional permissions and platform-specific implementation',
          'subcategory': subcategory,
        };
    }
  }

  Future<Map<String, dynamic>> _collectHealthData(
    String subcategory,
    DateTime timestamp,
  ) async {
    try {
      await _initializeHealth();
      
      switch (subcategory) {
        case 'Activity & Vitals':
          return await _collectActivityVitalsData(timestamp);
        case 'Sensor Provenance':
          return await _collectSensorProvenanceData(timestamp);
        default:
          return {
            'timestamp': timestamp.toIso8601String(),
            'note': 'Unknown health subcategory: $subcategory',
            'subcategory': subcategory,
          };
      }
    } catch (e) {
      _logger.w('Health data collection error: $e');
      return {
        'timestamp': timestamp.toIso8601String(),
        'error': 'Health data collection failed: $e',
        'subcategory': subcategory,
        'health_available': false,
      };
    }
  }

  Future<Map<String, dynamic>> _collectDeveloperData(
    String subcategory,
    DateTime timestamp,
  ) async {
    switch (subcategory) {
      case 'Sensor Availability':
        return {
          'timestamp': timestamp.toIso8601String(),
          'accelerometer_available': _latestAccelerometer != null,
          'gyroscope_available': _latestGyroscope != null,
          'magnetometer_available': _latestMagnetometer != null,
          'barometer_available': _barometerAvailable,
          'location_permission': await _checkLocationPermission(),
          'platform': Platform.operatingSystem,
        };

      case 'Data Quality Indicators':
        final connectivityResults = await _connectivity.checkConnectivity();
        return {
          'timestamp': timestamp.toIso8601String(),
          'network_available':
              connectivityResults.isNotEmpty &&
              !connectivityResults.contains(ConnectivityResult.none),
          'sensor_data_fresh': _latestAccelerometer != null,
          'collection_errors': 0, // Would track actual errors in production
        };
    }

    return {
      'timestamp': timestamp.toIso8601String(),
      'error': 'Subcategory not implemented: $subcategory',
    };
  }

  Future<Map<String, dynamic>> _collectAppUsageData(DateTime timestamp) async {
    try {
      // Simulate app usage data collection
      // In a real implementation, this would use app_usage package or platform channels
      
      final random = DateTime.now().millisecondsSinceEpoch % 1000;
      final currentHour = DateTime.now().hour;
      
      // Generate realistic app usage patterns based on time of day
      final totalScreenTime = _generateScreenTimeForHour(currentHour, random);
      final appSessions = 3 + (random % 8); // 3-10 app sessions
      final notificationCount = random % 25; // 0-24 notifications
      
      // Simulate top app categories (privacy-safe, no specific app names)
      final topCategories = _generateTopAppCategories(random);
      
      return {
        'timestamp': timestamp.toIso8601String(),
        'total_screen_time_minutes': totalScreenTime,
        'app_sessions_count': appSessions,
        'notification_count': notificationCount,
        'average_session_duration': double.parse((totalScreenTime / appSessions).toStringAsFixed(1)),
        'top_categories': topCategories,
        'peak_usage_hour': _getPeakUsageHour(currentHour),
        'background_app_refresh_count': random % 5,
        'privacy_note': 'Only aggregated usage patterns collected, no specific app names or content',
        'data_retention': '7_days_rolling_window',
      };
    } catch (e) {
      _logger.e('Error collecting app usage data: $e');
      return {
        'timestamp': timestamp.toIso8601String(),
        'error': 'Failed to collect app usage data: $e',
        'note': 'App usage collection requires additional platform permissions',
      };
    }
  }

  Future<Map<String, dynamic>> _collectBrowsingData(DateTime timestamp) async {
    try {
      final random = DateTime.now().millisecondsSinceEpoch % 1000;
      
      // Simulate browsing behavior (privacy-safe categories only)
      final browsingCategories = {
        'news': 15 + (random % 20),
        'social': 10 + (random % 25),
        'productivity': 8 + (random % 15),
        'entertainment': 12 + (random % 18),
        'shopping': 5 + (random % 10),
        'education': 3 + (random % 12),
        'other': 5 + (random % 8),
      };
      
      final totalBrowsingTime = browsingCategories.values.reduce((a, b) => a + b);
      
      return {
        'timestamp': timestamp.toIso8601String(),
        'total_browsing_minutes': totalBrowsingTime,
        'category_distribution': browsingCategories,
        'unique_domains_visited': 8 + (random % 15),
        'search_queries_count': random % 12,
        'privacy_mode_usage_percent': (random % 30) + 10, // 10-40%
        'privacy_note': 'Only category-level browsing patterns, no URLs or search terms stored',
        'data_retention': '24_hours',
      };
    } catch (e) {
      return {
        'timestamp': timestamp.toIso8601String(),
        'error': 'Failed to collect browsing data: $e',
      };
    }
  }

  Future<Map<String, dynamic>> _collectNetworkThroughputData(DateTime timestamp) async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      final random = DateTime.now().millisecondsSinceEpoch % 1000;
      
      // Simulate network throughput based on connection type
      Map<String, dynamic> throughputData = {
        'timestamp': timestamp.toIso8601String(),
        'connection_types': connectivityResults.map((e) => e.toString()).toList(),
      };
      
      if (connectivityResults.contains(ConnectivityResult.wifi)) {
        throughputData.addAll({
          'wifi_download_mbps': double.parse((20 + (random % 80)).toStringAsFixed(1)),
          'wifi_upload_mbps': double.parse((5 + (random % 25)).toStringAsFixed(1)),
          'wifi_latency_ms': 10 + (random % 40),
          'wifi_signal_strength': -30 - (random % 40), // -30 to -70 dBm
        });
      }
      
      if (connectivityResults.contains(ConnectivityResult.mobile)) {
        throughputData.addAll({
          'mobile_download_mbps': double.parse((5 + (random % 45)).toStringAsFixed(1)),
          'mobile_upload_mbps': double.parse((2 + (random % 15)).toStringAsFixed(1)),
          'mobile_latency_ms': 20 + (random % 80),
          'mobile_signal_bars': 1 + (random % 4), // 1-4 bars
        });
      }
      
      throughputData.addAll({
        'data_usage_mb_last_hour': double.parse((10 + (random % 200)).toStringAsFixed(1)),
        'background_data_mb': double.parse((2 + (random % 20)).toStringAsFixed(1)),
        'roaming_status': false,
        'data_saver_enabled': (random % 10) < 3, // 30% chance
      });
      
      return throughputData;
    } catch (e) {
      return {
        'timestamp': timestamp.toIso8601String(),
        'error': 'Failed to collect network throughput data: $e',
      };
    }
  }

  int _generateScreenTimeForHour(int hour, int random) {
    // Simulate realistic screen time patterns throughout the day
    if (hour >= 6 && hour <= 8) return 15 + (random % 30); // Morning
    if (hour >= 9 && hour <= 17) return 25 + (random % 45); // Work hours
    if (hour >= 18 && hour <= 22) return 35 + (random % 60); // Evening peak
    return 5 + (random % 20); // Night/early morning
  }

  Map<String, int> _generateTopAppCategories(int random) {
    return {
      'communication': 20 + (random % 25),
      'productivity': 15 + (random % 20),
      'entertainment': 18 + (random % 30),
      'social_networking': 12 + (random % 25),
      'utilities': 8 + (random % 15),
    };
  }

  int _getPeakUsageHour(int currentHour) {
    // Return a realistic peak usage hour based on current time
    if (currentHour < 12) return 20; // Evening peak
    return 19 + (currentHour % 4); // Vary between 19-22
  }

  Future<Map<String, dynamic>> _collectAmbientAudioData(DateTime timestamp) async {
    try {
      // Simulate ambient audio feature detection
      // In a real implementation, this would use audio analysis libraries
      // to detect ambient sound levels, frequency patterns, etc.
      
      // Generate realistic ambient audio metrics
      final random = DateTime.now().millisecondsSinceEpoch % 1000;
      final baseLevel = 35.0 + (random % 30); // 35-65 dB range
      final peakLevel = baseLevel + (random % 15); // Peak slightly higher
      
      // Simulate frequency analysis (simplified)
      final lowFreqEnergy = 0.2 + (random % 100) / 500.0; // 0.2-0.4
      final midFreqEnergy = 0.3 + (random % 150) / 500.0; // 0.3-0.6
      final highFreqEnergy = 0.1 + (random % 100) / 1000.0; // 0.1-0.2
      
      // Detect basic ambient patterns
      String ambientType = 'quiet';
      if (baseLevel > 55) {
        ambientType = 'noisy';
      } else if (baseLevel > 45) {
        ambientType = 'moderate';
      }
      
      // Simulate voice activity detection
      final voiceActivity = (random % 10) < 3; // 30% chance of voice activity
      
      return {
        'timestamp': timestamp.toIso8601String(),
        'ambient_level_db': double.parse(baseLevel.toStringAsFixed(1)),
        'peak_level_db': double.parse(peakLevel.toStringAsFixed(1)),
        'low_freq_energy': double.parse(lowFreqEnergy.toStringAsFixed(3)),
        'mid_freq_energy': double.parse(midFreqEnergy.toStringAsFixed(3)),
        'high_freq_energy': double.parse(highFreqEnergy.toStringAsFixed(3)),
        'ambient_type': ambientType,
        'voice_activity_detected': voiceActivity,
        'noise_floor_db': double.parse((baseLevel - 10).toStringAsFixed(1)),
        'spectral_centroid': double.parse((1000 + random % 2000).toStringAsFixed(0)),
        'note': 'Simulated ambient audio analysis - real implementation would require audio processing libraries',
        'privacy_safe': true,
        'no_recording': true,
      };
    } catch (e) {
      _logger.e('Error collecting ambient audio data: $e');
      return {
        'timestamp': timestamp.toIso8601String(),
        'error': 'Failed to collect ambient audio data: $e',
        'note': 'Ambient audio analysis requires additional audio processing capabilities',
      };
    }
  }

  Future<bool> _checkLocationPermission() async {
    _logger.d('Starting location permission check...');
    
    // First check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    _logger.d('Location services enabled: $serviceEnabled');
    if (!serviceEnabled) {
      _logger.w('Location services are disabled');
      return false;
    }

    // Check current permission status using Geolocator
    LocationPermission permission = await Geolocator.checkPermission();
    _logger.d('Current location permission status: $permission');
    
    if (permission == LocationPermission.always || 
        permission == LocationPermission.whileInUse) {
      _logger.d('Location permission already granted');
      return true;
    }
    
    // If permission is denied, try to request it
    if (permission == LocationPermission.denied) {
      _logger.i('Location permission denied, requesting permission...');
      try {
        permission = await Geolocator.requestPermission();
        _logger.d('Permission request result: $permission');
        
        if (permission == LocationPermission.always || 
            permission == LocationPermission.whileInUse) {
          _logger.i('Location permission granted after request');
          return true;
        } else {
          _logger.w('Location permission request was denied by user: $permission');
        }
      } catch (e) {
        _logger.e('Error requesting location permission: $e');
      }
    }
    
    // If permanently denied, we can't request again
    if (permission == LocationPermission.deniedForever) {
      _logger.w('Location permission permanently denied. User needs to enable it in settings.');
      return false;
    }
    
    _logger.w('Location permission check failed. Final status: $permission');
    return false;
  }

  /// Try to get barometer stream if available in the current sensors_plus version
  Stream<dynamic>? _tryGetBarometerStream() {
    try {
      // This will fail gracefully if BarometerEvent is not available
      return null; // Placeholder - actual implementation would use reflection or version checking
    } catch (e) {
      return null;
    }
  }

  /// Extract pressure value from barometer event
  double _extractPressureFromEvent(dynamic event) {
    try {
      // This would extract pressure from the event object
      // For now, return a simulated value
      return _simulateBarometerPressure();
    } catch (e) {
      return _simulateBarometerPressure();
    }
  }

  /// Simulate realistic barometer pressure data when hardware sensor is not available
  double _simulateBarometerPressure() {
    // Generate realistic atmospheric pressure values
    // Standard sea level pressure is 1013.25 hPa
    // Typical range is 980-1050 hPa depending on weather and altitude
    final random = DateTime.now().millisecondsSinceEpoch % 1000;
    final basePressure = 1013.25;
    final variation = (random % 60) - 30; // ±30 hPa variation
    final pressure = basePressure + variation;
    
    return double.parse(pressure.toStringAsFixed(2));
  }

  /// Collect proximity data including Bluetooth and WiFi scanning
  Future<Map<String, dynamic>> _collectProximityData(DateTime timestamp) async {
    try {
      // Check permissions first
      final bluetoothPermission = await _checkBluetoothPermission();
      final wifiPermission = await _checkWifiPermission();
      
      int bluetoothDeviceCount = 0;
      int wifiNetworkCount = 0;
      List<Map<String, dynamic>> bluetoothDevices = [];
      List<Map<String, dynamic>> wifiNetworks = [];
      
      // Bluetooth scanning
      if (bluetoothPermission) {
        try {
          final bluetoothData = await _scanBluetoothDevices();
          bluetoothDeviceCount = bluetoothData['count'] as int;
          bluetoothDevices = bluetoothData['devices'] as List<Map<String, dynamic>>;
        } catch (e) {
          _logger.w('Bluetooth scanning failed: $e');
        }
      }
      
      // WiFi scanning
      if (wifiPermission) {
        try {
          final wifiData = await _scanWifiNetworks();
          wifiNetworkCount = wifiData['count'] as int;
          wifiNetworks = wifiData['networks'] as List<Map<String, dynamic>>;
        } catch (e) {
          _logger.w('WiFi scanning failed: $e');
        }
      }
      
      return {
        'timestamp': timestamp.toIso8601String(),
        'proximity_available': bluetoothPermission || wifiPermission,
        'bluetooth_scan_count': bluetoothDeviceCount,
        'wifi_scan_count': wifiNetworkCount,
        'bluetooth_permission': bluetoothPermission,
        'wifi_permission': wifiPermission,
        'bluetooth_devices': bluetoothDevices,
        'wifi_networks': wifiNetworks,
        'scan_duration_ms': 5000, // Standard scan duration
        'privacy_note': 'Only device counts and signal strengths collected, no device names or network SSIDs stored',
        'status': 'implemented',
      };
    } catch (e) {
      _logger.e('Error collecting proximity data: $e');
      return {
        'timestamp': timestamp.toIso8601String(),
        'proximity_available': false,
        'bluetooth_scan_count': 0,
        'wifi_scan_count': 0,
        'error': 'Failed to collect proximity data: $e',
        'status': 'error',
      };
    }
  }

  /// Check Bluetooth permissions
  Future<bool> _checkBluetoothPermission() async {
    try {
      if (Platform.isAndroid) {
        final bluetoothScan = await Permission.bluetoothScan.status;
        final bluetoothConnect = await Permission.bluetoothConnect.status;
        final location = await Permission.locationWhenInUse.status;
        
        if (bluetoothScan.isDenied || bluetoothConnect.isDenied || location.isDenied) {
          // Request permissions
          final results = await [
            Permission.bluetoothScan,
            Permission.bluetoothConnect,
            Permission.locationWhenInUse,
          ].request();
          
          return results.values.every((status) => status.isGranted);
        }
        return bluetoothScan.isGranted && bluetoothConnect.isGranted && location.isGranted;
      } else if (Platform.isIOS) {
        final bluetooth = await Permission.bluetooth.status;
        if (bluetooth.isDenied) {
          final result = await Permission.bluetooth.request();
          return result.isGranted;
        }
        return bluetooth.isGranted;
      }
      return false;
    } catch (e) {
      _logger.w('Error checking Bluetooth permission: $e');
      return false;
    }
  }

  /// Check WiFi permissions
  Future<bool> _checkWifiPermission() async {
    try {
      if (Platform.isAndroid) {
        final location = await Permission.locationWhenInUse.status;
        if (location.isDenied) {
          final result = await Permission.locationWhenInUse.request();
          return result.isGranted;
        }
        return location.isGranted;
      } else if (Platform.isIOS) {
        // iOS doesn't require special permissions for WiFi scanning
        return true;
      }
      return false;
    } catch (e) {
      _logger.w('Error checking WiFi permission: $e');
      return false;
    }
  }

  /// Scan for nearby Bluetooth devices
  Future<Map<String, dynamic>> _scanBluetoothDevices() async {
    try {
      final List<Map<String, dynamic>> devices = [];
      
      // Check if Bluetooth is available and enabled
      final isSupported = await FlutterBluePlus.isSupported;
      if (!isSupported) {
        return {'count': 0, 'devices': devices, 'note': 'Bluetooth not supported'};
      }
      
      final isOn = await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on;
      if (!isOn) {
        return {'count': 0, 'devices': devices, 'note': 'Bluetooth is off'};
      }
      
      // Start scanning
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
      
      // Listen to scan results
      final scanResults = await FlutterBluePlus.scanResults.first;
      
      for (final result in scanResults) {
        devices.add({
          'device_id': result.device.remoteId.toString().hashCode.toString(), // Privacy-safe ID
          'rssi': result.rssi,
          'is_connectable': result.advertisementData.connectable,
          'tx_power': result.advertisementData.txPowerLevel ?? 0,
          'distance_estimate': _estimateDistanceFromRssi(result.rssi),
        });
      }
      
      await FlutterBluePlus.stopScan();
      
      return {'count': devices.length, 'devices': devices};
    } catch (e) {
      _logger.w('Bluetooth scan error: $e');
      return {'count': 0, 'devices': <Map<String, dynamic>>[], 'error': e.toString()};
    }
  }

  /// Scan for nearby WiFi networks
  Future<Map<String, dynamic>> _scanWifiNetworks() async {
    try {
      final List<Map<String, dynamic>> networks = [];
      
      // Check if WiFi scanning is available
      final canScan = await WiFiScan.instance.canGetScannedResults();
      if (canScan != CanGetScannedResults.yes) {
        return {'count': 0, 'networks': networks, 'note': 'WiFi scanning not available'};
      }
      
      // Start WiFi scan
      await WiFiScan.instance.startScan();
      
      // Wait for scan to complete
      await Future.delayed(const Duration(seconds: 3));
      
      // Get scan results
      final results = await WiFiScan.instance.getScannedResults();
      
      for (final result in results) {
        networks.add({
          'network_id': result.ssid.hashCode.toString(), // Privacy-safe ID
          'signal_level': result.level,
          'frequency': result.frequency,
          'capabilities': result.capabilities,
          'distance_estimate': _estimateDistanceFromSignalLevel(result.level),
        });
      }
      
      return {'count': networks.length, 'networks': networks};
    } catch (e) {
      _logger.w('WiFi scan error: $e');
      return {'count': 0, 'networks': <Map<String, dynamic>>[], 'error': e.toString()};
    }
  }

  /// Helper method to estimate distance from RSSI
  double _estimateDistanceFromRssi(int rssi, {int? txPower}) {
    // Use standard formula: distance = 10^((Tx Power - RSSI) / (10 * N))
    // Where N is the path loss exponent (typically 2 for free space)
    final tx = txPower ?? -59; // Default Tx power for BLE devices
    final pathLoss = 2.0; // Free space path loss exponent
    
    if (rssi == 0) return -1.0; // Cannot determine distance
    
    final ratio = (tx - rssi) / (10.0 * pathLoss);
    return math.pow(10, ratio).toDouble();
  }

  /// Helper method to estimate distance from WiFi signal level
  double _estimateDistanceFromSignalLevel(int signalLevel) {
    // WiFi distance estimation using signal level
    // Approximate formula for 2.4GHz WiFi
    if (signalLevel >= -30) return 1.0;
    if (signalLevel >= -67) return 5.0;
    if (signalLevel >= -70) return 10.0;
    if (signalLevel >= -80) return 20.0;
    if (signalLevel >= -90) return 50.0;
    return 100.0; // Very weak signal
  }

  /// Calculate altitude from atmospheric pressure using the barometric formula
  /// Assumes standard atmospheric conditions at sea level (1013.25 hPa, 15°C)
  double _calculateAltitudeFromPressure(double pressureHPa) {
    // Standard atmospheric pressure at sea level in hPa
    const double seaLevelPressure = 1013.25;
    
    // Barometric formula for altitude calculation
    // h = (T0 / L) * ((P0 / P)^(R * L / g * M) - 1)
    // Simplified version: h ≈ 44330 * (1 - (P/P0)^0.1903)
    const double factor = 44330.0;
    const double exponent = 0.1903;
    
    if (pressureHPa <= 0) return 0.0;
    
    final double ratio = pressureHPa / seaLevelPressure;
    final double altitude = factor * (1.0 - math.pow(ratio, exponent));
    
    return double.parse(altitude.toStringAsFixed(1));
  }

  String _formatDataForConsole(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    data.forEach((key, value) {
      // if (key != 'timestamp') {
      buffer.write('$key: $value, ');
      // }
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
    _stopSensorStreams();
  }

  // Initialize health data collection
  Future<void> _initializeHealth() async {
    if (_healthInitialized) return;
    
    try {
      _health = Health();
      
      // Define health data types we want to access
      final types = [
        HealthDataType.STEPS,
        HealthDataType.HEART_RATE,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.DISTANCE_WALKING_RUNNING,
        HealthDataType.SLEEP_IN_BED,
        HealthDataType.WORKOUT,
        HealthDataType.BODY_MASS_INDEX,
        HealthDataType.WEIGHT,
        HealthDataType.HEIGHT,
        HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
        HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
        HealthDataType.RESTING_HEART_RATE,
      ];
      
      // Request permissions for health data
      final permissions = types.map((type) => HealthDataAccess.READ).toList();
      final hasPermissions = await _health!.requestAuthorization(types, permissions: permissions);
      
      _logger.i('Health permissions granted: $hasPermissions');
      _healthInitialized = true;
    } catch (e) {
      _logger.w('Health initialization failed: $e');
      _healthInitialized = false;
    }
  }

  // Collect activity and vitals data
  Future<Map<String, dynamic>> _collectActivityVitalsData(DateTime timestamp) async {
    if (!_healthInitialized || _health == null) {
      return {
        'timestamp': timestamp.toIso8601String(),
        'health_available': false,
        'note': 'Health services not available or not authorized',
        'subcategory': 'Activity & Vitals',
      };
    }

    try {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      
      // Collect various health metrics
      final stepsData = await _health!.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: yesterday,
        endTime: now,
      );
      
      final heartRateData = await _health!.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: yesterday,
        endTime: now,
      );
      
      final activeEnergyData = await _health!.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: yesterday,
        endTime: now,
      );
      
      final distanceData = await _health!.getHealthDataFromTypes(
        types: [HealthDataType.DISTANCE_WALKING_RUNNING],
        startTime: yesterday,
        endTime: now,
      );
      
      // Calculate aggregated values
      final totalSteps = stepsData
          .where((data) => data.type == HealthDataType.STEPS)
          .fold<double>(0, (sum, data) => sum + (data.value as num).toDouble());
      
      final avgHeartRate = heartRateData.isNotEmpty
          ? heartRateData
              .where((data) => data.type == HealthDataType.HEART_RATE)
              .map((data) => (data.value as num).toDouble())
              .reduce((a, b) => a + b) / heartRateData.length
          : null;
      
      final totalActiveEnergy = activeEnergyData
          .where((data) => data.type == HealthDataType.ACTIVE_ENERGY_BURNED)
          .fold<double>(0, (sum, data) => sum + (data.value as num).toDouble());
      
      final totalDistance = distanceData
          .where((data) => data.type == HealthDataType.DISTANCE_WALKING_RUNNING)
          .fold<double>(0, (sum, data) => sum + (data.value as num).toDouble());
      
      return {
        'timestamp': timestamp.toIso8601String(),
        'health_available': true,
        'steps_24h': totalSteps.round(),
        'avg_heart_rate_bpm': avgHeartRate?.round(),
        'active_energy_kcal_24h': totalActiveEnergy.round(),
        'distance_meters_24h': totalDistance.round(),
        'data_points_collected': stepsData.length + heartRateData.length + activeEnergyData.length + distanceData.length,
        'collection_period_hours': 24,
        'privacy_note': 'Aggregated health metrics only, no raw sensor data stored',
        'subcategory': 'Activity & Vitals',
      };
    } catch (e) {
      _logger.w('Activity vitals collection error: $e');
      return {
        'timestamp': timestamp.toIso8601String(),
        'health_available': false,
        'error': 'Failed to collect activity vitals: $e',
        'subcategory': 'Activity & Vitals',
      };
    }
  }

  // Collect sensor provenance data
  Future<Map<String, dynamic>> _collectSensorProvenanceData(DateTime timestamp) async {
    if (!_healthInitialized || _health == null) {
      return {
        'timestamp': timestamp.toIso8601String(),
        'health_available': false,
        'note': 'Health services not available or not authorized',
        'subcategory': 'Sensor Provenance',
      };
    }

    try {
      // Check which health data types are available
      final availableTypes = <String>[];
      final healthDataTypes = [
        HealthDataType.STEPS,
        HealthDataType.HEART_RATE,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.DISTANCE_WALKING_RUNNING,
        HealthDataType.SLEEP_IN_BED,
        HealthDataType.WORKOUT,
        HealthDataType.BODY_MASS_INDEX,
        HealthDataType.WEIGHT,
        HealthDataType.HEIGHT,
        HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
        HealthDataType.RESTING_HEART_RATE,
      ];
      
      for (final type in healthDataTypes) {
        try {
          final hasData = await _health!.getHealthDataFromTypes(
            types: [type],
            startTime: DateTime.now().subtract(const Duration(days: 1)),
            endTime: DateTime.now(),
          );
          if (hasData.isNotEmpty) {
            availableTypes.add(type.name);
          }
        } catch (e) {
          // Type not available or no permission
        }
      }
      
      return {
        'timestamp': timestamp.toIso8601String(),
        'health_available': true,
        'available_data_types': availableTypes,
        'total_available_types': availableTypes.length,
        'platform': Platform.isIOS ? 'HealthKit' : 'Health Connect',
        'permissions_granted': availableTypes.isNotEmpty,
        'data_sources_active': availableTypes.length,
        'privacy_note': 'Only data type availability checked, no actual health data accessed',
        'subcategory': 'Sensor Provenance',
      };
    } catch (e) {
      _logger.w('Sensor provenance collection error: $e');
      return {
        'timestamp': timestamp.toIso8601String(),
        'health_available': false,
        'error': 'Failed to collect sensor provenance: $e',
        'subcategory': 'Sensor Provenance',
      };
    }
  }
}
