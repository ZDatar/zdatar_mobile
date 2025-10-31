import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../models/deal.dart';
import '../config/api_config.dart';

class DealsService {
  static final DealsService _instance = DealsService._internal();
  factory DealsService() => _instance;
  DealsService._internal();

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

  final ApiConfig _apiConfig = ApiConfig();

  /// Fetch all deals from the API
  Future<DealsResponse?> fetchDeals() async {
    try {
      final baseUrl = await _apiConfig.getBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/deals'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        return DealsResponse.fromJson(jsonData);
      } else {
        _logger.w('Failed to fetch deals. Status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _logger.e('Error fetching deals: $e');
      return null;
    }
  }

  /// Fetch a specific deal by ID
  Future<Deal?> fetchDealById(String dealId) async {
    try {
      final baseUrl = await _apiConfig.getBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/deals/$dealId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        return Deal.fromJson(jsonData);
      } else {
        _logger.w('Failed to fetch deal $dealId. Status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _logger.e('Error fetching deal $dealId: $e');
      return null;
    }
  }

  /// Create a dataset record in the backend
  /// Returns dataset_id if successful
  Future<Map<String, dynamic>> createDataset({
    required String name,
    required String description,
    required double price,
    required String currency,
    required String ipfsCid,
    required String fileUrl,
    required String dataHash,
    required String encryptedAesKey,
    required String ownerWalletPubkey,
    required String dataStartTime,
    required String dataEndTime,
    required Map<String, dynamic> dataMeta,
    required int fileSize,
    required String icon,
    String? region,
    List<String>? tags,
  }) async {
    try {
      final baseUrl = await _apiConfig.getBaseUrl();
      _logger.d('📦 Creating dataset: $name');
      _logger.d('📡 API URL: $baseUrl/datasets');
      
      final requestBody = {
        'name': name,
        'description': description,
        'price': price,
        'currency': currency,
        'ipfs_cid': ipfsCid,
        'file_url': fileUrl,
        'data_hash': dataHash,
        'encrypted_aes_key': encryptedAesKey,
        'owner_wallet_pubkey': ownerWalletPubkey,
        'data_start_time': dataStartTime,
        'data_end_time': dataEndTime,
        'data_meta': dataMeta,
        'file_size': fileSize,
        'icon': icon,
        if (region != null) 'region': region,
        if (tags != null && tags.isNotEmpty) 'tags': tags,
      };
      
      _logger.d('📤 Request body: ${json.encode(requestBody)}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/datasets'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 15));
      
      _logger.d('📥 Response status: ${response.statusCode}');
      _logger.d('📥 Response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        _logger.i('✅ Dataset created successfully');
        return {'success': true, 'data': data};
      } else {
        _logger.w('❌ Failed to create dataset. Status: ${response.statusCode}');
        return {'success': false, 'error': 'Failed to create dataset: ${response.body}'};
      }
    } catch (e) {
      _logger.e('❌ Error creating dataset: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Accept a deal - seller confirms participation and provides dataset
  /// Returns a map with 'success' (bool) and optional 'error' (String) or 'data' (Map)
  Future<Map<String, dynamic>> acceptDeal(
    String dealId,
    String sellerWalletPubkey,
    String datasetId,
    String encryptedAesKey, {
    int retries = 2,
  }) async {
    final baseUrl = await _apiConfig.getBaseUrl();
    _logger.d('🔍 Accepting deal: $dealId with seller wallet: $sellerWalletPubkey');
    _logger.d('📡 API URL: $baseUrl/accept_deal');
    
    final requestBody = {
      'deal_id': dealId,
      'seller_wallet_pubkey': sellerWalletPubkey,
      'dataset_id': datasetId,
      'encrypted_aes_key': encryptedAesKey,
    };
    _logger.d('📤 Request body: ${json.encode(requestBody)}');

    for (int attempt = 0; attempt <= retries; attempt++) {
      if (attempt > 0) {
        _logger.d('🔄 Retry attempt $attempt/$retries');
        await Future.delayed(Duration(seconds: attempt * 2)); // Exponential backoff
      }

      try {
        final response = await http.post(
          Uri.parse('$baseUrl/accept_deal'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(requestBody),
        ).timeout(const Duration(seconds: 15));

        _logger.d('📥 Response status: ${response.statusCode}');
        _logger.d('📥 Response body: ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          _logger.i('✅ Deal $dealId accepted successfully');
          
          // Try to parse response data
          try {
            final data = json.decode(response.body) as Map<String, dynamic>;
            return {'success': true, 'data': data};
          } catch (e) {
            return {'success': true};
          }
        } else if (response.statusCode == 400) {
          // Bad request - parse error message
          try {
            final errorData = json.decode(response.body) as Map<String, dynamic>;
            final errorMsg = errorData['message'] ?? errorData['error'] ?? 'Bad request';
            _logger.w('❌ Deal acceptance failed: $errorMsg');
            return {'success': false, 'error': errorMsg};
          } catch (e) {
            return {'success': false, 'error': 'Bad request: ${response.body}'};
          }
        } else if (response.statusCode == 404) {
          _logger.w('❌ Deal $dealId not found');
          return {'success': false, 'error': 'Deal not found'};
        } else if (response.statusCode == 409) {
          _logger.w('❌ Deal $dealId already accepted or conflict');
          return {'success': false, 'error': 'Deal already accepted or unavailable'};
        } else {
          _logger.w('❌ Failed to accept deal $dealId. Status: ${response.statusCode}');
          // Don't retry on client errors (4xx except 409)
          if (response.statusCode >= 400 && response.statusCode < 500 && response.statusCode != 409) {
            return {
              'success': false,
              'error': 'Server error: ${response.statusCode}\n${response.body}'
            };
          }
          // Retry on 5xx errors
          if (attempt == retries) {
            return {
              'success': false,
              'error': 'Server error after $retries retries: ${response.statusCode}'
            };
          }
          continue; // Retry
        }
      } on TimeoutException catch (e) {
        _logger.e('❌ Request timeout (attempt ${attempt + 1}/${retries + 1}): $e');
        if (attempt == retries) {
          return {
            'success': false,
            'error': 'Request timed out after ${retries + 1} attempts.\n'
                'Backend may be slow or unreachable.'
          };
        }
        // Continue to retry
      } on http.ClientException catch (e) {
        _logger.e('❌ Network error (attempt ${attempt + 1}/${retries + 1}): $e');
        if (attempt == retries) {
          return {
            'success': false,
            'error': 'Connection failed. Please check:\n'
                '• Backend server is running\n'
                '• Network connection is stable\n'
                '• API_BASE_URL is correct ($baseUrl)'
          };
        }
        // Continue to retry
      } catch (e) {
        _logger.e('❌ Unexpected error: $e');
        if (attempt == retries) {
          return {'success': false, 'error': e.toString()};
        }
        // Continue to retry
      }
    }

    // Should never reach here, but just in case
    return {'success': false, 'error': 'Unknown error after $retries retries'};
  }
}
