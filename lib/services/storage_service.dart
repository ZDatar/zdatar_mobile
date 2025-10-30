import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:logger/logger.dart';
import '../config/api_config.dart';

/// Service for uploading encrypted datasets to IPFS and Azure Storage
class StorageService {
  final ApiConfig _config = ApiConfig();
  final Logger _logger = Logger();

  /// Upload encrypted dataset to IPFS
  /// Returns the IPFS CID (Content Identifier) on success
  Future<String?> uploadToIpfs(Uint8List encryptedData, {
    String? filename,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_config.isIpfsConfigured) {
      throw Exception('IPFS not configured. Please set IPFS_API_URL in .env');
    }

    try {
      final url = Uri.parse('${_config.ipfsApiUrl}/api/v0/add');
      
      var request = http.MultipartRequest('POST', url);
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          encryptedData,
          filename: filename ?? 'encrypted_dataset_${DateTime.now().millisecondsSinceEpoch}.enc',
        ),
      );

      // Add metadata as JSON if provided
      if (metadata != null) {
        request.fields['metadata'] = jsonEncode(metadata);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // IPFS returns NDJSON (newline-delimited JSON)
        // Each line is a separate JSON object
        final lines = response.body.trim().split('\n');
        
        // Parse the last line which contains the final result
        if (lines.isNotEmpty) {
          try {
            final data = jsonDecode(lines.last);
            final cid = data['Hash'] as String?;
            
            if (cid != null) {
              _logger.i('✅ Uploaded to IPFS: $cid');
              return cid;
            }
          } catch (e) {
            _logger.w('⚠️ Failed to parse IPFS response: $e');
            _logger.d('Response body: ${response.body}');
          }
        }
      }

      throw Exception('IPFS upload failed: ${response.statusCode} - ${response.body}');
    } catch (e) {
      _logger.e('❌ IPFS upload error: $e');
      rethrow;
    }
  }

  /// Upload encrypted dataset to Azure Blob Storage
  /// Returns the blob URL on success
  Future<String?> uploadToAzure(Uint8List encryptedData, {
    String? blobName,
    Map<String, String>? metadata,
  }) async {
    if (!_config.isAzureConfigured) {
      throw Exception('Azure Storage not configured. Please set AZURE_STORAGE_ACCOUNT and AZURE_STORAGE_ACCESS_KEY in .env');
    }

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final finalBlobName = blobName ?? 'dataset_$timestamp.enc';
      
      // Construct Azure Blob Storage URL
      final account = _config.azureStorageAccount;
      final container = _config.azureContainerName;
      final url = Uri.parse('https://$account.blob.core.windows.net/$container/$finalBlobName');

      // Generate SAS token or use access key for authentication
      final headers = <String, String>{
        'x-ms-blob-type': 'BlockBlob',
        'x-ms-version': '2021-08-06',
        'Content-Type': 'application/octet-stream',
        'Content-Length': encryptedData.length.toString(),
      };

      // Add custom metadata
      if (metadata != null) {
        metadata.forEach((key, value) {
          headers['x-ms-meta-$key'] = value;
        });
      }

      // Add authorization header
      headers['Authorization'] = _generateAzureAuthHeader(
        'PUT',
        account,
        container,
        finalBlobName,
        headers,
        encryptedData.length,
      );
      
      _logger.d('🔐 Azure headers: $headers');
      
      final response = await http.put(
        url,
        headers: headers,
        body: encryptedData,
      );

      if (response.statusCode == 201) {
        final url = response.headers['location'] ?? 
                    'https://$account.blob.core.windows.net/$container/$finalBlobName';
        _logger.i('✅ Uploaded to Azure: $url');
        return url;
      }

      throw Exception('Azure upload failed: ${response.statusCode} - ${response.body}');
    } catch (e) {
      _logger.e('❌ Azure upload error: $e');
      rethrow;
    }
  }

  /// Upload to both IPFS and Azure Storage (dual storage for redundancy)
  /// Returns a map with both storage locations
  Future<Map<String, String?>> uploadToBoth(Uint8List encryptedData, {
    String? filename,
    Map<String, dynamic>? metadata,
  }) async {
    String? ipfsCid;
    String? azureUrl;

    // Upload to IPFS
    try {
      ipfsCid = await uploadToIpfs(
        encryptedData,
        filename: filename,
        metadata: metadata,
      );
    } catch (e) {
      _logger.w('⚠️ IPFS upload failed, continuing with Azure: $e');
    }

    // Upload to Azure
    try {
      azureUrl = await uploadToAzure(
        encryptedData,
        blobName: filename,
        metadata: metadata?.map((k, v) => MapEntry(k, v.toString())),
      );
    } catch (e) {
      _logger.w('⚠️ Azure upload failed: $e');
    }

    // Require at least one successful upload
    if (ipfsCid == null && azureUrl == null) {
      throw Exception(
        'Failed to upload to storage.\n'
        'IPFS: Not configured or failed\n'
        'Azure: Not configured or failed\n'
        'Please configure at least one storage option in .env'
      );
    }

    if (ipfsCid != null) {
      _logger.i('✅ Using IPFS storage: $ipfsCid');
    }
    if (azureUrl != null) {
      _logger.i('✅ Using Azure storage: $azureUrl');
    }

    return {
      'ipfs': ipfsCid ?? 'not_uploaded',
      'azure': azureUrl ?? 'not_uploaded',
    };
  }

  /// Generate SHA-256 hash of the encrypted data for verification
  String generateHash(Uint8List data) {
    final digest = sha256.convert(data);
    return digest.toString();
  }

  /// Generate Azure Shared Key authentication header
  String _generateAzureAuthHeader(
    String method,
    String account,
    String container,
    String blobName,
    Map<String, String> headers,
    int contentLength,
  ) {
    // Azure Shared Key Lite signature
    // Format: SharedKey <account>:<signature>
    
    final accessKey = _config.azureStorageAccessKey;
    final canonicalizedHeaders = _buildCanonicalizedHeaders(headers);
    final canonicalizedResource = '/$account/$container/$blobName';
    
    _logger.d('🔑 Generating Azure auth signature...');
    
    final stringToSign = [
      method,
      '', // Content-Encoding
      '', // Content-Language
      contentLength.toString(), // Content-Length
      '', // Content-MD5
      headers['Content-Type'] ?? '',
      '', // Date
      '', // If-Modified-Since
      '', // If-Match
      '', // If-None-Match
      '', // If-Unmodified-Since
      '', // Range
      canonicalizedHeaders,
      canonicalizedResource,
    ].join('\n');

    // Sign with HMAC-SHA256
    final keyBytes = base64.decode(accessKey);
    final hmac = Hmac(sha256, keyBytes);
    final signature = base64.encode(hmac.convert(utf8.encode(stringToSign)).bytes);

    return 'SharedKey $account:$signature';
  }

  /// Build canonicalized headers for Azure authentication
  String _buildCanonicalizedHeaders(Map<String, String> headers) {
    final msHeaders = <String, String>{};
    
    headers.forEach((key, value) {
      final lowerKey = key.toLowerCase();
      if (lowerKey.startsWith('x-ms-')) {
        msHeaders[lowerKey] = value.trim();
      }
    });

    final sortedKeys = msHeaders.keys.toList()..sort();
    return sortedKeys.map((key) => '$key:${msHeaders[key]}').join('\n');
  }

  /// Retrieve file from IPFS
  Future<Uint8List?> retrieveFromIpfs(String cid) async {
    try {
      final url = Uri.parse('${_config.ipfsApiUrl}/api/v0/cat?arg=$cid');
      final response = await http.post(url);

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }

      throw Exception('IPFS retrieval failed: ${response.statusCode}');
    } catch (e) {
      _logger.e('❌ IPFS retrieval error: $e');
      rethrow;
    }
  }

  /// Retrieve file from Azure Blob Storage
  Future<Uint8List?> retrieveFromAzure(String blobUrl) async {
    try {
      final response = await http.get(Uri.parse(blobUrl));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }

      throw Exception('Azure retrieval failed: ${response.statusCode}');
    } catch (e) {
      _logger.e('❌ Azure retrieval error: $e');
      rethrow;
    }
  }
}
