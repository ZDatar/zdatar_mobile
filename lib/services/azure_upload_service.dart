import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:crypto/crypto.dart' as crypto_hash;

/// Service for uploading files to Azure Blob Storage
class AzureUploadService {
  static final AzureUploadService _instance = AzureUploadService._internal();
  factory AzureUploadService() => _instance;
  AzureUploadService._internal();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 3,
      lineLength: 120,
      colors: true,
      printEmojis: true,
    ),
  );

  late final Dio _dio;
  late final String _storageAccountName;
  late final String _containerName;
  late final String _sasToken; // Shared Access Signature
  late final String _storageAccountUrl;

  /// Initialize Azure upload service
  void initialize() {
    // Parse connection string or use SAS token
    final connectionString = dotenv.env['AZURE_STORAGE_CONNECTION_STRING'] ?? '';
    _containerName = dotenv.env['AZURE_CONTAINER_NAME'] ?? 'zdatar-data';
    _sasToken = dotenv.env['AZURE_SAS_TOKEN'] ?? '';

    if (connectionString.isNotEmpty) {
      // Parse connection string
      final parts = connectionString.split(';');
      for (final part in parts) {
        if (part.startsWith('AccountName=')) {
          _storageAccountName = part.substring('AccountName='.length);
        }
      }
    } else {
      _storageAccountName = dotenv.env['AZURE_STORAGE_ACCOUNT_NAME'] ?? '';
    }

    _storageAccountUrl = 'https://$_storageAccountName.blob.core.windows.net';

    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 90),
      sendTimeout: const Duration(seconds: 90),
    ));

    _logger.i('✅ Azure Upload Service initialized');
  }

  /// Upload file to Azure Blob Storage
  Future<AzureUploadResult> uploadFile({
    required Uint8List fileBytes,
    required String blobName,
    String? contentType,
    Map<String, String>? metadata,
    void Function(int, int)? onProgress,
  }) async {
    try {
      if (_storageAccountName.isEmpty) {
        throw Exception('Azure Storage not configured. Please set AZURE_STORAGE_CONNECTION_STRING or AZURE_STORAGE_ACCOUNT_NAME in .env file');
      }

      _logger.i('☁️  Uploading file to Azure: $blobName (${fileBytes.length} bytes)');

      // Construct blob URL
      final blobUrl = '$_storageAccountUrl/$_containerName/$blobName${_sasToken.isNotEmpty ? '?$_sasToken' : ''}';

      // Calculate MD5 hash for integrity
      final md5Hash = crypto_hash.md5.convert(fileBytes);
      final md5Base64 = base64Encode(md5Hash.bytes);

      // Prepare headers
      final headers = <String, String>{
        'x-ms-blob-type': 'BlockBlob',
        'Content-Type': contentType ?? 'application/octet-stream',
        'Content-MD5': md5Base64,
        'x-ms-version': '2021-08-06',
      };

      // Add metadata headers
      if (metadata != null) {
        metadata.forEach((key, value) {
          headers['x-ms-meta-$key'] = value;
        });
      }

      // Upload to Azure
      final response = await _dio.put(
        blobUrl,
        data: fileBytes,
        options: Options(
          headers: headers,
          contentType: contentType ?? 'application/octet-stream',
        ),
        onSendProgress: (sent, total) {
          if (onProgress != null) {
            onProgress(sent, total);
          }
          _logger.d('Upload progress: ${(sent / total * 100).toStringAsFixed(1)}%');
        },
      );

      if (response.statusCode == 201) {
        final etag = response.headers.value('etag');
        final lastModified = response.headers.value('last-modified');

        _logger.i('✅ File uploaded to Azure: $blobName');

        return AzureUploadResult(
          success: true,
          blobUrl: '$_storageAccountUrl/$_containerName/$blobName',
          blobName: blobName,
          containerName: _containerName,
          etag: etag,
          lastModified: lastModified != null ? DateTime.tryParse(lastModified) : null,
          contentMd5: md5Base64,
          size: fileBytes.length,
        );
      } else {
        throw Exception('Upload failed with status code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.e('❌ Azure upload failed (Dio): ${e.message}');
      return AzureUploadResult(
        success: false,
        error: e.message ?? 'Network error',
      );
    } catch (e, stackTrace) {
      _logger.e('❌ Azure upload failed: $e', error: e, stackTrace: stackTrace);
      return AzureUploadResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Upload JSON data to Azure
  Future<AzureUploadResult> uploadJson({
    required Map<String, dynamic> jsonData,
    required String blobName,
    Map<String, String>? metadata,
  }) async {
    try {
      final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);
      final jsonBytes = Uint8List.fromList(utf8.encode(jsonString));

      return await uploadFile(
        fileBytes: jsonBytes,
        blobName: blobName,
        contentType: 'application/json',
        metadata: metadata,
      );
    } catch (e) {
      _logger.e('Failed to upload JSON: $e');
      return AzureUploadResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Upload text data to Azure
  Future<AzureUploadResult> uploadText({
    required String text,
    required String blobName,
    Map<String, String>? metadata,
  }) async {
    final textBytes = Uint8List.fromList(utf8.encode(text));

    return await uploadFile(
      fileBytes: textBytes,
      blobName: blobName,
      contentType: 'text/plain',
      metadata: metadata,
    );
  }

  /// Check if Azure service is configured
  bool isConfigured() {
    return _storageAccountName.isNotEmpty;
  }

  /// Get blob URL
  String getBlobUrl(String blobName) {
    return '$_storageAccountUrl/$_containerName/$blobName';
  }
}

/// Result of Azure upload operation
class AzureUploadResult {
  final bool success;
  final String? blobUrl;
  final String? blobName;
  final String? containerName;
  final String? etag;
  final DateTime? lastModified;
  final String? contentMd5;
  final int? size;
  final String? error;

  AzureUploadResult({
    required this.success,
    this.blobUrl,
    this.blobName,
    this.containerName,
    this.etag,
    this.lastModified,
    this.contentMd5,
    this.size,
    this.error,
  });

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      if (blobUrl != null) 'blob_url': blobUrl,
      if (blobName != null) 'blob_name': blobName,
      if (containerName != null) 'container_name': containerName,
      if (etag != null) 'etag': etag,
      if (lastModified != null) 'last_modified': lastModified!.toIso8601String(),
      if (contentMd5 != null) 'content_md5': contentMd5,
      if (size != null) 'size': size,
      if (error != null) 'error': error,
    };
  }
}
