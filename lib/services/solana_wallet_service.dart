import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'package:bs58check/bs58check.dart' as bs58;
import 'package:logger/logger.dart';
import 'package:cryptography/cryptography.dart' as crypto;
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Solana wallet service for managing Ed25519 keypairs
/// and converting to X25519 for encryption
class SolanaWalletService {
  static final SolanaWalletService _instance = SolanaWalletService._internal();
  factory SolanaWalletService() => _instance;
  SolanaWalletService._internal();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 3,
      lineLength: 120,
      colors: true,
      printEmojis: true,
    ),
  );

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final ApiConfig _config = ApiConfig();
  
  // Storage keys
  static const String _mnemonicKey = 'solana_mnemonic';
  static const String _seedKey = 'solana_seed';
  static const String _privateKeyKey = 'solana_private_key';
  static const String _publicKeyKey = 'solana_public_key';

  // Cached keypair
  Uint8List? _cachedPrivateKey;
  Uint8List? _cachedPublicKey;
  String? _cachedMnemonic;

  /// Initialize sodium library
  Future<void> initialize() async {
    // sodium_libs initializes automatically, no need for explicit init
    _logger.i('✅ Sodium library ready');
  }

  /// Generate a new Solana wallet with BIP39 mnemonic
  Future<Map<String, dynamic>> generateWallet({int strength = 128}) async {
    try {
      // Generate mnemonic (12 words for 128 bits, 24 words for 256 bits)
      final mnemonic = bip39.generateMnemonic(strength: strength);
      
      // Derive seed from mnemonic
      final seed = bip39.mnemonicToSeed(mnemonic);
      
      // Derive Ed25519 keypair using BIP44 path for Solana: m/44'/501'/0'/0'
      final derivedKey =
          await ED25519_HD_KEY.derivePath("m/44'/501'/0'/0'", seed);
      
      // Extract private and public keys (Ed25519)
      final privateKey = Uint8List.fromList(derivedKey.key);
      
      // For Ed25519, public key is derived from private key using cryptography package
      final keyPair = await crypto.Ed25519().newKeyPairFromSeed(privateKey.sublist(0, 32));
      final publicKeyObj = await keyPair.extractPublicKey();
      final publicKey = Uint8List.fromList(publicKeyObj.bytes);
      
      // Store securely
      await _secureStorage.write(key: _mnemonicKey, value: mnemonic);
      await _secureStorage.write(key: _seedKey, value: base64Encode(seed));
      await _secureStorage.write(key: _privateKeyKey, value: base64Encode(privateKey));
      await _secureStorage.write(key: _publicKeyKey, value: base64Encode(publicKey));
      
      // Cache
      _cachedMnemonic = mnemonic;
      _cachedPrivateKey = privateKey;
      _cachedPublicKey = publicKey;
      
      _logger.i('✅ Generated new Solana wallet');
      
      return {
        'mnemonic': mnemonic,
        'publicKey': getPublicKeyBase58(),
        'address': getPublicKeyBase58(),
      };
    } catch (e) {
      _logger.e('❌ Failed to generate wallet: $e');
      rethrow;
    }
  }

  /// Restore wallet from mnemonic
  Future<Map<String, dynamic>> restoreWallet(String mnemonic) async {
    try {
      if (!bip39.validateMnemonic(mnemonic)) {
        throw Exception('Invalid mnemonic phrase');
      }
      
      // Derive seed from mnemonic
      final seed = bip39.mnemonicToSeed(mnemonic);
      
      // Derive Ed25519 keypair
      final derivedKey =
          await ED25519_HD_KEY.derivePath("m/44'/501'/0'/0'", seed);
      final privateKey = Uint8List.fromList(derivedKey.key);
      
      // Derive public key
      final keyPair = await crypto.Ed25519().newKeyPairFromSeed(privateKey.sublist(0, 32));
      final publicKeyObj = await keyPair.extractPublicKey();
      final publicKey = Uint8List.fromList(publicKeyObj.bytes);
      
      // Store securely
      await _secureStorage.write(key: _mnemonicKey, value: mnemonic);
      await _secureStorage.write(key: _seedKey, value: base64Encode(seed));
      await _secureStorage.write(key: _privateKeyKey, value: base64Encode(privateKey));
      await _secureStorage.write(key: _publicKeyKey, value: base64Encode(publicKey));
      
      // Cache
      _cachedMnemonic = mnemonic;
      _cachedPrivateKey = privateKey;
      _cachedPublicKey = publicKey;
      
      _logger.i('✅ Restored Solana wallet from mnemonic');
      
      return {
        'mnemonic': mnemonic,
        'publicKey': getPublicKeyBase58(),
        'address': getPublicKeyBase58(),
      };
    } catch (e) {
      _logger.e('❌ Failed to restore wallet: $e');
      rethrow;
    }
  }

  /// Check if wallet exists
  Future<bool> hasWallet() async {
    final privateKey = await _secureStorage.read(key: _privateKeyKey);
    return privateKey != null;
  }

  /// Get Ed25519 private key (32 bytes)
  Future<Uint8List> getEd25519PrivateKey() async {
    if (_cachedPrivateKey != null) {
      return _cachedPrivateKey!;
    }
    
    final privateKeyB64 = await _secureStorage.read(key: _privateKeyKey);
    if (privateKeyB64 == null) {
      throw Exception('No wallet found. Please generate or restore a wallet first.');
    }
    
    _cachedPrivateKey = base64Decode(privateKeyB64);
    return _cachedPrivateKey!;
  }

  /// Get Ed25519 public key (32 bytes)
  Future<Uint8List> getEd25519PublicKey() async {
    if (_cachedPublicKey != null) {
      return _cachedPublicKey!;
    }
    
    final publicKeyB64 = await _secureStorage.read(key: _publicKeyKey);
    if (publicKeyB64 == null) {
      throw Exception('No wallet found. Please generate or restore a wallet first.');
    }
    
    _cachedPublicKey = base64Decode(publicKeyB64);
    return _cachedPublicKey!;
  }

  /// Get public key in Base58 format (Solana address)
  String getPublicKeyBase58() {
    if (_cachedPublicKey == null) {
      throw Exception('Wallet not loaded. Call getEd25519PublicKey() first.');
    }
    return bs58.base58.encode(_cachedPublicKey!);
  }

  /// Get X25519 keypair for encryption (separate from Ed25519)
  /// Note: For now, we generate a separate X25519 keypair from the Ed25519 seed
  /// In production, you may want to use deterministic derivation
  Future<crypto.SimpleKeyPairData> getX25519KeyPair() async {
    final ed25519PrivateKey = await getEd25519PrivateKey();
    
    // Use the Ed25519 private key as seed for X25519 keypair
    // This is a simplified approach - in production consider deterministic derivation
    final x25519Algorithm = crypto.X25519();
    final x25519KeyPair = await x25519Algorithm.newKeyPairFromSeed(
      ed25519PrivateKey.sublist(0, 32),
    );
    
    _logger.d('Generated X25519 keypair from Ed25519 seed');
    return await x25519KeyPair.extract();
  }

  /// Convert Ed25519 private key to X25519 private key for encryption
  Future<Uint8List> getX25519PrivateKey() async {
    final keyPairData = await getX25519KeyPair();
    return Uint8List.fromList(keyPairData.bytes);
  }

  /// Convert Ed25519 public key to X25519 public key for encryption
  Future<Uint8List> getX25519PublicKey() async {
    final keyPairData = await getX25519KeyPair();
    return Uint8List.fromList(keyPairData.publicKey.bytes);
  }

  /// Convert any Solana public key (Base58) to X25519 public key
  /// Note: This is a simplified conversion using the public key as seed
  static Future<Uint8List> solanaPublicKeyToX25519(String solanaPublicKeyBase58) async {
    final ed25519PublicKey = bs58.base58.decode(solanaPublicKeyBase58);
    
    // For recipient public keys, we need to generate X25519 public key
    // Using a deterministic approach based on the Ed25519 public key
    final x25519Algorithm = crypto.X25519();
    final x25519KeyPair = await x25519Algorithm.newKeyPairFromSeed(
      Uint8List.fromList(ed25519PublicKey),
    );
    final publicKey = await x25519KeyPair.extractPublicKey();
    return Uint8List.fromList(publicKey.bytes);
  }

  /// Get mnemonic phrase (for backup)
  Future<String?> getMnemonic() async {
    if (_cachedMnemonic != null) {
      return _cachedMnemonic;
    }
    
    _cachedMnemonic = await _secureStorage.read(key: _mnemonicKey);
    return _cachedMnemonic;
  }

  /// Get wallet info
  Future<Map<String, dynamic>> getWalletInfo() async {
    final hasWallet = await this.hasWallet();
    if (!hasWallet) {
      return {
        'exists': false,
        'publicKey': null,
        'address': null,
      };
    }
    
    final publicKey = await getEd25519PublicKey();
    final publicKeyBase58 = bs58.base58.encode(publicKey);
    
    return {
      'exists': true,
      'publicKey': publicKeyBase58,
      'address': publicKeyBase58,
      'publicKeyBytes': publicKey.length,
    };
  }

  /// Delete wallet (use with caution!)
  Future<void> deleteWallet() async {
    await _secureStorage.delete(key: _mnemonicKey);
    await _secureStorage.delete(key: _seedKey);
    await _secureStorage.delete(key: _privateKeyKey);
    await _secureStorage.delete(key: _publicKeyKey);
    
    _cachedMnemonic = null;
    _cachedPrivateKey = null;
    _cachedPublicKey = null;
    
    _logger.w('⚠️  Wallet deleted');
  }

  /// Sign data with Ed25519 (for transactions)
  Future<Uint8List> signData(Uint8List data) async {
    final privateKeyBytes = await getEd25519PrivateKey();
    
    // Create Ed25519 keypair from the private key
    final algorithm = crypto.Ed25519();
    final keyPair = await algorithm.newKeyPairFromSeed(privateKeyBytes.sublist(0, 32));
    
    // Sign the data
    final signature = await algorithm.sign(data, keyPair: keyPair);
    return Uint8List.fromList(signature.bytes);
  }

  /// Verify signature
  static Future<bool> verifySignature(
    Uint8List data,
    Uint8List signature,
    Uint8List publicKey,
  ) async {
    final algorithm = crypto.Ed25519();
    final publicKeyObj = crypto.SimplePublicKey(
      publicKey,
      type: crypto.KeyPairType.ed25519,
    );
    final signatureObj = crypto.Signature(signature, publicKey: publicKeyObj);
    
    return await algorithm.verify(data, signature: signatureObj);
  }

  /// Clear cached keys from memory
  void clearCache() {
    _cachedMnemonic = null;
    _cachedPrivateKey = null;
    _cachedPublicKey = null;
    _logger.d('Cleared wallet cache');
  }

  // ============================================================================
  // Solana RPC Methods
  // ============================================================================

  /// Get SOL balance for the current wallet
  Future<double> getBalance() async {
    try {
      await getEd25519PublicKey(); // Ensure wallet is loaded
      final publicKeyBase58 = getPublicKeyBase58();
      
      final response = await http.post(
        Uri.parse(_config.solanaRpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'id': 1,
          'method': 'getBalance',
          'params': [publicKeyBase58],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final lamports = data['result']['value'] as int;
        // Convert lamports to SOL (1 SOL = 1,000,000,000 lamports)
        return lamports / 1000000000.0;
      }

      throw Exception('Failed to get balance: ${response.statusCode}');
    } catch (e) {
      _logger.e('Error getting balance: $e');
      rethrow;
    }
  }

  /// Get recent blockhash for transaction
  Future<String> getRecentBlockhash() async {
    try {
      final response = await http.post(
        Uri.parse(_config.solanaRpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'id': 1,
          'method': 'getLatestBlockhash',
          'params': [
            {'commitment': 'finalized'}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['result']['value']['blockhash'] as String;
      }

      throw Exception('Failed to get blockhash: ${response.statusCode}');
    } catch (e) {
      _logger.e('Error getting blockhash: $e');
      rethrow;
    }
  }

  /// Send raw transaction to Solana network
  Future<String?> sendTransaction(Uint8List signedTransaction) async {
    try {
      final encodedTx = base64.encode(signedTransaction);
      
      final response = await http.post(
        Uri.parse(_config.solanaRpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'id': 1,
          'method': 'sendTransaction',
          'params': [
            encodedTx,
            {'encoding': 'base64', 'preflightCommitment': 'confirmed'}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['error'] != null) {
          throw Exception('Transaction error: ${data['error']}');
        }
        return data['result'] as String?;
      }

      throw Exception('Failed to send transaction: ${response.statusCode}');
    } catch (e) {
      _logger.e('Error sending transaction: $e');
      rethrow;
    }
  }

  /// Confirm transaction
  Future<bool> confirmTransaction(String signature, {int maxRetries = 30}) async {
    try {
      for (int i = 0; i < maxRetries; i++) {
        final response = await http.post(
          Uri.parse(_config.solanaRpcUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'jsonrpc': '2.0',
            'id': 1,
            'method': 'getSignatureStatuses',
            'params': [
              [signature],
              {'searchTransactionHistory': true}
            ],
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final statuses = data['result']['value'] as List?;
          
          if (statuses != null && statuses.isNotEmpty && statuses[0] != null) {
            final status = statuses[0] as Map<String, dynamic>;
            if (status['confirmationStatus'] == 'finalized' || 
                status['confirmationStatus'] == 'confirmed') {
              return status['err'] == null;
            }
          }
        }

        // Wait 1 second before retry
        await Future.delayed(const Duration(seconds: 1));
      }

      return false;
    } catch (e) {
      _logger.e('Error confirming transaction: $e');
      return false;
    }
  }

  /// Get transaction history for the wallet
  Future<List<Map<String, dynamic>>> getTransactionHistory({int limit = 10}) async {
    try {
      final publicKeyBase58 = getPublicKeyBase58();
      
      final response = await http.post(
        Uri.parse(_config.solanaRpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'id': 1,
          'method': 'getSignaturesForAddress',
          'params': [
            publicKeyBase58,
            {'limit': limit}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['result'] ?? []);
      }

      throw Exception('Failed to get transaction history: ${response.statusCode}');
    } catch (e) {
      _logger.e('Error getting transaction history: $e');
      return [];
    }
  }

  /// Get Solana program ID from config
  String getProgramId() {
    return _config.solanaProgramId;
  }

  /// Check if Solana configuration is valid
  bool isSolanaConfigured() {
    return _config.isSolanaConfigured;
  }
}
