import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:logger/logger.dart';

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

  // Sensor streams
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;

  // Latest sensor data
  AccelerometerEvent? _latestAccelerometer;
  GyroscopeEvent? _latestGyroscope;
  MagnetometerEvent? _latestMagnetometer;

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
  }

  void _stopSensorStreams() {
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _magnetometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _gyroscopeSubscription = null;
    _magnetometerSubscription = null;
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
        case 'Commerce & Finance':
          return await _collectCommerceData(subcategory, timestamp);
        case 'Context Semantics':
          return await _collectContextData(subcategory, timestamp);
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
        final hasPermission = await _checkLocationPermission();
        if (!hasPermission) {
          return {
            'timestamp': timestamp.toIso8601String(),
            'error': 'Location permission not granted',
          };
        }

        try {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
            timeLimit: const Duration(seconds: 5),
          );
          return {
            'timestamp': timestamp.toIso8601String(),
            'latitude_coarse':
                (position.latitude * 100).round() / 100, // Reduced precision
            'longitude_coarse': (position.longitude * 100).round() / 100,
            'accuracy_meters': position.accuracy,
          };
        } catch (e) {
          return {
            'timestamp': timestamp.toIso8601String(),
            'error': 'Failed to get location: $e',
          };
        }

      case 'Location (Fine)':
        final hasPermission = await _checkLocationPermission();
        if (!hasPermission) {
          return {
            'timestamp': timestamp.toIso8601String(),
            'error': 'Location permission not granted',
          };
        }

        try {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 10),
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
          return {
            'timestamp': timestamp.toIso8601String(),
            'error': 'Failed to get precise location: $e',
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
        if (_latestMagnetometer == null && 
            _magnetometerSubscription != null) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
        
        return {
          'timestamp': timestamp.toIso8601String(),
          'magnetometer_x': _latestMagnetometer?.x ?? 0.0,
          'magnetometer_y': _latestMagnetometer?.y ?? 0.0,
          'magnetometer_z': _latestMagnetometer?.z ?? 0.0,
          'magnetometer_available': _latestMagnetometer != null,
          'streams_active': _magnetometerSubscription != null,
          'note': 'Barometer data requires additional platform-specific implementation',
        };

      case 'Proximity Scans':
        return {
          'timestamp': timestamp.toIso8601String(),
          'proximity_available': false,
          'bluetooth_scan_count': 0,
          'wifi_scan_count': 0,
          'note': 'Proximity scanning requires additional permissions and platform-specific implementation for Bluetooth/WiFi discovery',
          'status': 'not_implemented',
        };
    }

    // Handle potential character encoding issues or variations
    if (subcategory.contains('Barometer') && subcategory.contains('Magnetometer')) {
      _logger.d('Matched Barometer & Magnetometer via contains check');
      // Wait a short time for sensor data if streams are active but no data yet
      if (_latestMagnetometer == null && 
          _magnetometerSubscription != null) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      return {
        'timestamp': timestamp.toIso8601String(),
        'magnetometer_x': _latestMagnetometer?.x ?? 0.0,
        'magnetometer_y': _latestMagnetometer?.y ?? 0.0,
        'magnetometer_z': _latestMagnetometer?.z ?? 0.0,
        'magnetometer_available': _latestMagnetometer != null,
        'streams_active': _magnetometerSubscription != null,
        'note': 'Barometer data requires additional platform-specific implementation',
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
    // Note: App usage data requires special permissions and is limited on iOS
    return {
      'timestamp': timestamp.toIso8601String(),
      'note':
          'App behavior data collection requires additional permissions and platform-specific implementation',
      'subcategory': subcategory,
    };
  }

  Future<Map<String, dynamic>> _collectHealthData(
    String subcategory,
    DateTime timestamp,
  ) async {
    // Note: Health data requires HealthKit/Health Connect integration
    return {
      'timestamp': timestamp.toIso8601String(),
      'note':
          'Health data collection requires HealthKit/Health Connect integration',
      'subcategory': subcategory,
    };
  }

  Future<Map<String, dynamic>> _collectCommerceData(
    String subcategory,
    DateTime timestamp,
  ) async {
    // Note: Commerce data would require integration with payment systems
    return {
      'timestamp': timestamp.toIso8601String(),
      'note': 'Commerce data collection requires payment system integration',
      'subcategory': subcategory,
    };
  }

  Future<Map<String, dynamic>> _collectContextData(
    String subcategory,
    DateTime timestamp,
  ) async {
    // Context data can be derived from location and usage patterns
    return {
      'timestamp': timestamp.toIso8601String(),
      'note': 'Context data derived from location and usage patterns',
      'subcategory': subcategory,
    };
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

  Future<bool> _checkLocationPermission() async {
    final permission = await Permission.location.status;
    return permission == PermissionStatus.granted;
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
}
