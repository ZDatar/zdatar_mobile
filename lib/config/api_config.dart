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
}
