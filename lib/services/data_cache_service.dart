import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:logger/logger.dart';
import '../models/cached_data_point.dart';

/// Service for caching collected data with a 5-minute rolling window
/// 
/// This service stores all data collection points in a local SQLite database
/// and automatically cleans up data older than 5 minutes.
class DataCacheService {
  static final DataCacheService _instance = DataCacheService._internal();
  factory DataCacheService() => _instance;
  DataCacheService._internal();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 3,
      lineLength: 120,
      colors: true,
      printEmojis: true,
    ),
  );

  Database? _database;
  Timer? _cleanupTimer;
  
  // Cache retention period (5 minutes)
  static const int cacheRetentionSeconds = 300;
  
  // Cleanup interval (run every 30 seconds)
  static const int cleanupIntervalSeconds = 30;

  /// Initialize the database
  Future<void> initialize() async {
    if (_database != null) {
      _logger.d('DataCacheService already initialized');
      return;
    }

    try {
      final databasePath = await getDatabasesPath();
      final path = join(databasePath, 'zdatar_data_cache.db');

      _database = await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );

      _logger.i('✅ DataCacheService initialized successfully');
      
      // Start automatic cleanup timer
      startCleanupTimer();
      
      // Run initial cleanup
      await cleanupOldData();
    } catch (e) {
      _logger.e('❌ Failed to initialize DataCacheService: $e');
      rethrow;
    }
  }

  /// Create database schema
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE data_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        subcategory TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        data TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // Create indexes for efficient queries
    await db.execute('''
      CREATE INDEX idx_category_subcategory 
      ON data_cache(category, subcategory)
    ''');

    await db.execute('''
      CREATE INDEX idx_timestamp 
      ON data_cache(timestamp)
    ''');

    await db.execute('''
      CREATE INDEX idx_created_at 
      ON data_cache(created_at)
    ''');

    _logger.i('✅ Database schema created');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    _logger.i('📦 Upgrading database from version $oldVersion to $newVersion');
    // Add migration logic here when schema changes
  }

  /// Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    await initialize();
    return _database!;
  }

  /// Cache a single data point
  Future<int> cacheDataPoint(CachedDataPoint dataPoint) async {
    try {
      final db = await database;
      final id = await db.insert(
        'data_cache',
        dataPoint.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      _logger.d('Cached data point: ${dataPoint.category}/${dataPoint.subcategory}');
      return id;
    } catch (e) {
      _logger.e('❌ Failed to cache data point: $e');
      rethrow;
    }
  }

  /// Cache multiple data points in a batch
  Future<void> cacheDataPoints(List<CachedDataPoint> dataPoints) async {
    if (dataPoints.isEmpty) return;

    try {
      final db = await database;
      final batch = db.batch();

      for (final dataPoint in dataPoints) {
        batch.insert(
          'data_cache',
          dataPoint.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
      _logger.d('✅ Cached ${dataPoints.length} data points');
    } catch (e) {
      _logger.e('❌ Failed to batch cache data points: $e');
      rethrow;
    }
  }

  /// Cache data from the real-time collection
  Future<void> cacheCollectedData(
    String category,
    String subcategory,
    Map<String, dynamic> data,
  ) async {
    final dataPoint = CachedDataPoint(
      category: category,
      subcategory: subcategory,
      timestamp: DateTime.now(),
      data: data,
    );

    await cacheDataPoint(dataPoint);
  }

  /// Get all cached data points (within 5-minute window)
  Future<List<CachedDataPoint>> getAllCachedData() async {
    try {
      final db = await database;
      final cutoffTime = DateTime.now()
          .subtract(const Duration(seconds: cacheRetentionSeconds))
          .millisecondsSinceEpoch;

      final List<Map<String, dynamic>> maps = await db.query(
        'data_cache',
        where: 'timestamp >= ?',
        whereArgs: [cutoffTime],
        orderBy: 'timestamp DESC',
      );

      return maps.map((map) => CachedDataPoint.fromMap(map)).toList();
    } catch (e) {
      _logger.e('❌ Failed to get all cached data: $e');
      return [];
    }
  }

  /// Get cached data by category
  Future<List<CachedDataPoint>> getDataByCategory(String category) async {
    try {
      final db = await database;
      final cutoffTime = DateTime.now()
          .subtract(const Duration(seconds: cacheRetentionSeconds))
          .millisecondsSinceEpoch;

      final List<Map<String, dynamic>> maps = await db.query(
        'data_cache',
        where: 'category = ? AND timestamp >= ?',
        whereArgs: [category, cutoffTime],
        orderBy: 'timestamp DESC',
      );

      return maps.map((map) => CachedDataPoint.fromMap(map)).toList();
    } catch (e) {
      _logger.e('❌ Failed to get data by category: $e');
      return [];
    }
  }

  /// Get cached data by category and subcategory
  Future<List<CachedDataPoint>> getDataByCategoryAndSubcategory(
    String category,
    String subcategory,
  ) async {
    try {
      final db = await database;
      final cutoffTime = DateTime.now()
          .subtract(const Duration(seconds: cacheRetentionSeconds))
          .millisecondsSinceEpoch;

      final List<Map<String, dynamic>> maps = await db.query(
        'data_cache',
        where: 'category = ? AND subcategory = ? AND timestamp >= ?',
        whereArgs: [category, subcategory, cutoffTime],
        orderBy: 'timestamp DESC',
      );

      return maps.map((map) => CachedDataPoint.fromMap(map)).toList();
    } catch (e) {
      _logger.e('❌ Failed to get data by category and subcategory: $e');
      return [];
    }
  }

  /// Get cached data by multiple categories and subcategories
  Future<List<CachedDataPoint>> getDataByFilters({
    List<String>? categories,
    List<String>? subcategories,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      final db = await database;
      final cutoffTime = DateTime.now()
          .subtract(const Duration(seconds: cacheRetentionSeconds))
          .millisecondsSinceEpoch;

      final whereConditions = <String>['timestamp >= ?'];
      final whereArgs = <dynamic>[cutoffTime];

      if (categories != null && categories.isNotEmpty) {
        final placeholders = List.filled(categories.length, '?').join(',');
        whereConditions.add('category IN ($placeholders)');
        whereArgs.addAll(categories);
      }

      if (subcategories != null && subcategories.isNotEmpty) {
        final placeholders = List.filled(subcategories.length, '?').join(',');
        whereConditions.add('subcategory IN ($placeholders)');
        whereArgs.addAll(subcategories);
      }

      if (startTime != null) {
        whereConditions.add('timestamp >= ?');
        whereArgs.add(startTime.millisecondsSinceEpoch);
      }

      if (endTime != null) {
        whereConditions.add('timestamp <= ?');
        whereArgs.add(endTime.millisecondsSinceEpoch);
      }

      final List<Map<String, dynamic>> maps = await db.query(
        'data_cache',
        where: whereConditions.join(' AND '),
        whereArgs: whereArgs,
        orderBy: 'timestamp DESC',
      );

      return maps.map((map) => CachedDataPoint.fromMap(map)).toList();
    } catch (e) {
      _logger.e('❌ Failed to get data by filters: $e');
      return [];
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final db = await database;
      final cutoffTime = DateTime.now()
          .subtract(const Duration(seconds: cacheRetentionSeconds))
          .millisecondsSinceEpoch;

      // Total data points
      final totalResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM data_cache WHERE timestamp >= ?',
        [cutoffTime],
      );
      final total = Sqflite.firstIntValue(totalResult) ?? 0;

      // Data points by category
      final categoryResult = await db.rawQuery('''
        SELECT category, COUNT(*) as count 
        FROM data_cache 
        WHERE timestamp >= ?
        GROUP BY category
      ''', [cutoffTime]);

      final Map<String, int> byCategory = {};
      for (final row in categoryResult) {
        byCategory[row['category'] as String] = row['count'] as int;
      }

      // Oldest and newest timestamps
      final timeResult = await db.rawQuery('''
        SELECT 
          MIN(timestamp) as oldest,
          MAX(timestamp) as newest
        FROM data_cache
        WHERE timestamp >= ?
      ''', [cutoffTime]);

      final stats = {
        'total_points': total,
        'by_category': byCategory,
        'oldest_timestamp': timeResult.first['oldest'] != null
            ? DateTime.fromMillisecondsSinceEpoch(timeResult.first['oldest'] as int)
            : null,
        'newest_timestamp': timeResult.first['newest'] != null
            ? DateTime.fromMillisecondsSinceEpoch(timeResult.first['newest'] as int)
            : null,
        'cache_window_seconds': cacheRetentionSeconds,
      };

      return stats;
    } catch (e) {
      _logger.e('❌ Failed to get cache stats: $e');
      return {};
    }
  }

  /// Clean up data older than 5 minutes
  Future<int> cleanupOldData() async {
    try {
      final db = await database;
      final cutoffTime = DateTime.now()
          .subtract(const Duration(seconds: cacheRetentionSeconds))
          .millisecondsSinceEpoch;

      final deletedCount = await db.delete(
        'data_cache',
        where: 'timestamp < ?',
        whereArgs: [cutoffTime],
      );

      if (deletedCount > 0) {
        _logger.d('🧹 Cleaned up $deletedCount old data points');
      }

      return deletedCount;
    } catch (e) {
      _logger.e('❌ Failed to cleanup old data: $e');
      return 0;
    }
  }

  /// Start automatic cleanup timer
  void startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(
      const Duration(seconds: cleanupIntervalSeconds),
      (_) => cleanupOldData(),
    );
    _logger.i('🔄 Started automatic cleanup timer (every ${cleanupIntervalSeconds}s)');
  }

  /// Stop automatic cleanup timer
  void stopCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _logger.i('⏸️  Stopped automatic cleanup timer');
  }

  /// Clear all cached data
  Future<void> clearAllData() async {
    try {
      final db = await database;
      await db.delete('data_cache');
      _logger.i('🗑️  Cleared all cached data');
    } catch (e) {
      _logger.e('❌ Failed to clear all data: $e');
      rethrow;
    }
  }

  /// Close the database and stop timers
  Future<void> close() async {
    stopCleanupTimer();
    await _database?.close();
    _database = null;
    _logger.i('👋 DataCacheService closed');
  }

  /// Dispose resources
  void dispose() {
    stopCleanupTimer();
  }
}
