import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import '../config/api_config.dart';

/// Service for uploading encrypted datasets to IPFS and Azure Storage
class StorageService {
  final ApiConfig _config = ApiConfig();

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
        final data = jsonDecode(response.body);
        final cid = data['Hash'] as String?;
        
        if (cid != null) {
          print('✅ Uploaded to IPFS: $cid');
          return cid;
        }
      }

      throw Exception('IPFS upload failed: ${response.statusCode} - ${response.body}');
    } catch (e) {
      print('❌ IPFS upload error: $e');
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

      final response = await http.put(
        url,
        headers: headers,
        body: encryptedData,
      );

      if (response.statusCode == 201) {
        final blobUrl = url.toString();
        print('✅ Uploaded to Azure: $blobUrl');
        return blobUrl;
      }

      throw Exception('Azure upload failed: ${response.statusCode} - ${response.body}');
    } catch (e) {
      print('❌ Azure upload error: $e');
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
      print('⚠️ IPFS upload failed, continuing with Azure: $e');
    }

    // Upload to Azure
    try {
      azureUrl = await uploadToAzure(
        encryptedData,
        blobName: filename,
        metadata: metadata?.map((k, v) => MapEntry(k, v.toString())),
      );
    } catch (e) {
      print('⚠️ Azure upload failed: $e');
    }

    if (ipfsCid == null && azureUrl == null) {
      throw Exception('Failed to upload to both IPFS and Azure');
    }

    return {
      'ipfs': ipfsCid,
      'azure': azureUrl,
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
      print('❌ IPFS retrieval error: $e');
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
      print('❌ Azure retrieval error: $e');
      rethrow;
    }
  }
}
