import 'dart:convert';

/// Represents a single data point cached locally
class CachedDataPoint {
  final int? id;
  final String category;
  final String subcategory;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  CachedDataPoint({
    this.id,
    required this.category,
    required this.subcategory,
    required this.timestamp,
    required this.data,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'subcategory': subcategory,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'data': jsonEncode(data),
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  /// Create from database Map
  factory CachedDataPoint.fromMap(Map<String, dynamic> map) {
    return CachedDataPoint(
      id: map['id'] as int?,
      category: map['category'] as String,
      subcategory: map['subcategory'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      data: jsonDecode(map['data'] as String) as Map<String, dynamic>,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  /// Copy with modifications
  CachedDataPoint copyWith({
    int? id,
    String? category,
    String? subcategory,
    DateTime? timestamp,
    Map<String, dynamic>? data,
    DateTime? createdAt,
  }) {
    return CachedDataPoint(
      id: id ?? this.id,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      timestamp: timestamp ?? this.timestamp,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'CachedDataPoint{id: $id, category: $category, subcategory: $subcategory, '
        'timestamp: $timestamp, dataKeys: ${data.keys.toList()}}';
  }
}
