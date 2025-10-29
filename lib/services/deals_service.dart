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

  /// Accept a deal (placeholder - implement based on your backend API)
  Future<bool> acceptDeal(String dealId, String sellerWallet) async {
    try {
      final baseUrl = await _apiConfig.getBaseUrl();
      // This is a placeholder - update based on your actual accept deal API
      final response = await http.post(
        Uri.parse('$baseUrl/deals/$dealId/accept'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'seller_wallet': sellerWallet}),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 201) {
        _logger.i('Deal $dealId accepted successfully');
        return true;
      } else {
        _logger.w('Failed to accept deal $dealId. Status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _logger.e('Error accepting deal $dealId: $e');
      return false;
    }
  }
}
