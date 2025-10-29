import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service for uploading files to IPFS via Pinata
class IPFSUploadService {
  static final IPFSUploadService _instance = IPFSUploadService._internal();
  factory IPFSUploadService() => _instance;
  IPFSUploadService._internal();

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
  late final String _pinataApiUrl;
  late final String _pinataApiKey;
  late final String _pinataSecretApiKey;

  /// Initialize IPFS upload service
  void initialize() {
    _pinataApiUrl = dotenv.env['IPFS_API_URL'] ?? 'https://api.pinata.cloud/pinning/pinFileToIPFS';
    _pinataApiKey = dotenv.env['IPFS_API_KEY'] ?? '';
    _pinataSecretApiKey = dotenv.env['IPFS_API_SECRET'] ?? '';

    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
    ));

    _logger.i('✅ IPFS Upload Service initialized');
  }

  /// Upload file to IPFS via Pinata
  Future<IPFSUploadResult> uploadFile({
    required Uint8List fileBytes,
    required String fileName,
    Map<String, dynamic>? metadata,
    void Function(int, int)? onProgress,
  }) async {
    try {
      if (_pinataApiKey.isEmpty || _pinataSecretApiKey.isEmpty) {
        throw Exception('IPFS API credentials not configured. Please set IPFS_API_KEY and IPFS_API_SECRET in .env file');
      }

      _logger.i('☁️  Uploading file to IPFS: $fileName (${fileBytes.length} bytes)');

      // Create form data
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          fileBytes,
          filename: fileName,
        ),
        if (metadata != null)
          'pinataMetadata': metadata,
        'pinataOptions': {
          'cidVersion': 1,
        },
      });

      // Upload to Pinata
      final response = await _dio.post(
        _pinataApiUrl,
        data: formData,
        options: Options(
          headers: {
            'pinata_api_key': _pinataApiKey,
            'pinata_secret_api_key': _pinataSecretApiKey,
          },
        ),
        onSendProgress: (sent, total) {
          if (onProgress != null) {
            onProgress(sent, total);
          }
          _logger.d('Upload progress: ${(sent / total * 100).toStringAsFixed(1)}%');
        },
      );

      if (response.statusCode == 200) {
        final ipfsHash = response.data['IpfsHash'] as String;
        final pinSize = response.data['PinSize'] as int;
        final timestamp = response.data['Timestamp'] as String;

        _logger.i('✅ File uploaded to IPFS: $ipfsHash');

        return IPFSUploadResult(
          success: true,
          ipfsHash: ipfsHash,
          ipfsCid: ipfsHash,
          ipfsUrl: 'ipfs://$ipfsHash',
          gatewayUrl: 'https://gateway.pinata.cloud/ipfs/$ipfsHash',
          pinSize: pinSize,
          timestamp: DateTime.parse(timestamp),
        );
      } else {
        throw Exception('Upload failed with status code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.e('❌ IPFS upload failed (Dio): ${e.message}');
      return IPFSUploadResult(
        success: false,
        error: e.message ?? 'Network error',
      );
    } catch (e, stackTrace) {
      _logger.e('❌ IPFS upload failed: $e', error: e, stackTrace: stackTrace);
      return IPFSUploadResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Upload JSON data to IPFS
  Future<IPFSUploadResult> uploadJson({
    required Map<String, dynamic> jsonData,
    required String fileName,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);
      final jsonBytes = Uint8List.fromList(utf8.encode(jsonString));

      return await uploadFile(
        fileBytes: jsonBytes,
        fileName: fileName,
        metadata: metadata,
      );
    } catch (e) {
      _logger.e('Failed to upload JSON: $e');
      return IPFSUploadResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Check if IPFS service is configured
  bool isConfigured() {
    return _pinataApiKey.isNotEmpty && _pinataSecretApiKey.isNotEmpty;
  }
}

/// Result of IPFS upload operation
class IPFSUploadResult {
  final bool success;
  final String? ipfsHash;
  final String? ipfsCid;
  final String? ipfsUrl;
  final String? gatewayUrl;
  final int? pinSize;
  final DateTime? timestamp;
  final String? error;

  IPFSUploadResult({
    required this.success,
    this.ipfsHash,
    this.ipfsCid,
    this.ipfsUrl,
    this.gatewayUrl,
    this.pinSize,
    this.timestamp,
    this.error,
  });

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      if (ipfsHash != null) 'ipfs_hash': ipfsHash,
      if (ipfsCid != null) 'ipfs_cid': ipfsCid,
      if (ipfsUrl != null) 'ipfs_url': ipfsUrl,
      if (gatewayUrl != null) 'gateway_url': gatewayUrl,
      if (pinSize != null) 'pin_size': pinSize,
      if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
      if (error != null) 'error': error,
    };
  }
}
