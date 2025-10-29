import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static final ApiConfig _instance = ApiConfig._internal();
  factory ApiConfig() => _instance;
  ApiConfig._internal();

  static const String _baseUrlKey = 'api_base_url';
  
  // Default URLs for different environments
  static const String defaultLocalUrl = 'http://localhost:3000';
  static const String defaultProductionUrl = 'https://api.zdatar.com';
  
  String? _cachedBaseUrl;

  /// Get default URL from .env file, fallback to defaultLocalUrl
  String get envDefaultUrl {
    return dotenv.env['API_BASE_URL'] ?? defaultLocalUrl;
  }

  /// Get the current base URL
  /// Priority: User saved preference > .env file > defaultLocalUrl
  Future<String> getBaseUrl() async {
    if (_cachedBaseUrl != null) {
      return _cachedBaseUrl!;
    }
    
    final prefs = await SharedPreferences.getInstance();
    _cachedBaseUrl = prefs.getString(_baseUrlKey) ?? envDefaultUrl;
    return _cachedBaseUrl!;
  }

  /// Set a new base URL
  Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, url);
    _cachedBaseUrl = url;
  }

  /// Reset to default local URL
  Future<void> resetToLocal() async {
    await setBaseUrl(defaultLocalUrl);
  }

  /// Set to production URL
  Future<void> setToProduction() async {
    await setBaseUrl(defaultProductionUrl);
  }

  /// Clear cache (useful for testing)
  void clearCache() {
    _cachedBaseUrl = null;
  }

  // ============================================================================
  // Solana Configuration
  // ============================================================================

  /// Get Solana RPC URL from environment
  String get solanaRpcUrl {
    return dotenv.env['SOLANA_RPC_URL'] ?? 'https://api.devnet.solana.com';
  }

  /// Get Solana Program ID from environment
  String get solanaProgramId {
    return dotenv.env['SOLANA_PROGRAM_ID'] ?? '';
  }

  // ============================================================================
  // IPFS Configuration
  // ============================================================================

  /// Get IPFS API URL from environment
  String get ipfsApiUrl {
    return dotenv.env['IPFS_API_URL'] ?? 'https://ipfs.infura.io:5001';
  }

  // ============================================================================
  // Azure Storage Configuration
  // ============================================================================

  /// Get Azure Storage Account name
  String get azureStorageAccount {
    return dotenv.env['AZURE_STORAGE_ACCOUNT'] ?? '';
  }

  /// Get Azure Storage Access Key
  String get azureStorageAccessKey {
    return dotenv.env['AZURE_STORAGE_ACCESS_KEY'] ?? '';
  }

  /// Get Azure Container Name
  String get azureContainerName {
    return dotenv.env['AZURE_CONTAINER_NAME'] ?? 'zdatar-datasets';
  }

  /// Check if Azure Storage is properly configured
  bool get isAzureConfigured {
    return azureStorageAccount.isNotEmpty && azureStorageAccessKey.isNotEmpty;
  }

  /// Check if IPFS is properly configured
  bool get isIpfsConfigured {
    return ipfsApiUrl.isNotEmpty;
  }

  /// Check if Solana is properly configured
  bool get isSolanaConfigured {
    return solanaRpcUrl.isNotEmpty && solanaProgramId.isNotEmpty;
  }
}
