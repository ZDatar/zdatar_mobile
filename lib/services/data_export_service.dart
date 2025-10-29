import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:logger/logger.dart';
import '../models/cached_data_point.dart';
import 'data_cache_service.dart';

/// Service for exporting cached data to CSV format
class DataExportService {
  static final DataExportService _instance = DataExportService._internal();
  factory DataExportService() => _instance;
  DataExportService._internal();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 3,
      lineLength: 120,
      colors: true,
      printEmojis: true,
    ),
  );

  final DataCacheService _cacheService = DataCacheService();

  /// Export data to CSV for specific categories and subcategories
  Future<Uint8List> exportToCSV({
    required List<String> categories,
    List<String>? subcategories,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      _logger.i('📄 Exporting data to CSV...');
      _logger.d('Categories: $categories');
      _logger.d('Subcategories: $subcategories');
      
      // Get data from cache
      final dataPoints = await _cacheService.getDataByFilters(
        categories: categories,
        subcategories: subcategories,
        startTime: startTime,
        endTime: endTime,
      );

      if (dataPoints.isEmpty) {
        _logger.w('⚠️  No data points found for export');
        return Uint8List(0);
      }

      _logger.i('Found ${dataPoints.length} data points to export');

      // Convert to CSV
      final csvString = _convertToCSV(dataPoints);
      final csvBytes = Uint8List.fromList(utf8.encode(csvString));

      _logger.i('✅ Exported ${dataPoints.length} points to CSV (${csvBytes.length} bytes)');
      
      return csvBytes;
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to export CSV: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Export all cached data to CSV
  Future<Uint8List> exportAllToCSV() async {
    try {
      _logger.i('📄 Exporting all cached data to CSV...');
      
      final dataPoints = await _cacheService.getAllCachedData();
      
      if (dataPoints.isEmpty) {
        _logger.w('⚠️  No cached data to export');
        return Uint8List(0);
      }

      final csvString = _convertToCSV(dataPoints);
      final csvBytes = Uint8List.fromList(utf8.encode(csvString));

      _logger.i('✅ Exported ${dataPoints.length} points to CSV (${csvBytes.length} bytes)');
      
      return csvBytes;
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to export all data: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Convert list of data points to CSV string
  String _convertToCSV(List<CachedDataPoint> dataPoints) {
    if (dataPoints.isEmpty) {
      return '';
    }

    // Collect all unique field names across all data points
    final Set<String> allFields = {};
    for (final point in dataPoints) {
      allFields.addAll(_flattenMap(point.data).keys);
    }

    // Sort fields alphabetically for consistency
    final sortedFields = allFields.toList()..sort();

    // Create headers
    final headers = [
      'timestamp',
      'category',
      'subcategory',
      ...sortedFields,
    ];

    // Create rows
    final rows = <List<dynamic>>[headers];
    
    for (final point in dataPoints) {
      final flatData = _flattenMap(point.data);
      final row = <dynamic>[
        point.timestamp.toIso8601String(),
        point.category,
        point.subcategory,
        ...sortedFields.map((field) => flatData[field] ?? ''),
      ];
      rows.add(row);
    }

    // Convert to CSV
    return const ListToCsvConverter().convert(rows);
  }

  /// Flatten nested map to dot notation
  /// Example: {'device': {'model': 'iPhone'}} -> {'device.model': 'iPhone'}
  Map<String, dynamic> _flattenMap(
    Map<String, dynamic> map, [
    String prefix = '',
  ]) {
    final result = <String, dynamic>{};

    map.forEach((key, value) {
      final newKey = prefix.isEmpty ? key : '$prefix.$key';
      
      if (value is Map<String, dynamic>) {
        // Recursively flatten nested maps
        result.addAll(_flattenMap(value, newKey));
      } else if (value is List) {
        // Convert lists to JSON string
        result[newKey] = jsonEncode(value);
      } else if (value is DateTime) {
        // Format DateTime as ISO string
        result[newKey] = value.toIso8601String();
      } else {
        // Primitive values
        result[newKey] = value?.toString() ?? '';
      }
    });

    return result;
  }

  /// Export data and save to file (for testing/debugging)
  Future<String> exportToCSVString({
    required List<String> categories,
    List<String>? subcategories,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    final csvBytes = await exportToCSV(
      categories: categories,
      subcategories: subcategories,
      startTime: startTime,
      endTime: endTime,
    );
    
    return utf8.decode(csvBytes);
  }

  /// Get preview of CSV export (first N rows)
  Future<String> previewCSV({
    required List<String> categories,
    List<String>? subcategories,
    int maxRows = 10,
  }) async {
    try {
      final dataPoints = await _cacheService.getDataByFilters(
        categories: categories,
        subcategories: subcategories,
      );

      if (dataPoints.isEmpty) {
        return 'No data available';
      }

      // Take only first N data points for preview
      final previewPoints = dataPoints.take(maxRows).toList();
      final csvString = _convertToCSV(previewPoints);
      
      return csvString;
    } catch (e) {
      _logger.e('Failed to generate preview: $e');
      return 'Error generating preview: $e';
    }
  }

  /// Get CSV export statistics
  Future<Map<String, dynamic>> getExportStats({
    required List<String> categories,
    List<String>? subcategories,
  }) async {
    try {
      final dataPoints = await _cacheService.getDataByFilters(
        categories: categories,
        subcategories: subcategories,
      );

      if (dataPoints.isEmpty) {
        return {
          'total_points': 0,
          'categories': [],
          'subcategories': [],
          'estimated_size_bytes': 0,
        };
      }

      // Calculate statistics
      final categorySet = dataPoints.map((p) => p.category).toSet();
      final subcategorySet = dataPoints.map((p) => p.subcategory).toSet();
      
      // Estimate CSV size
      final csvString = _convertToCSV(dataPoints);
      final estimatedSize = utf8.encode(csvString).length;

      return {
        'total_points': dataPoints.length,
        'categories': categorySet.toList(),
        'subcategories': subcategorySet.toList(),
        'estimated_size_bytes': estimatedSize,
        'estimated_size_kb': (estimatedSize / 1024).toStringAsFixed(2),
        'oldest_timestamp': dataPoints.last.timestamp.toIso8601String(),
        'newest_timestamp': dataPoints.first.timestamp.toIso8601String(),
      };
    } catch (e) {
      _logger.e('Failed to get export stats: $e');
      return {};
    }
  }
}
