import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:crypto/crypto.dart' as crypto_hash;
import 'package:logger/logger.dart';
import 'solana_wallet_service.dart';

/// Encryption service implementing multi-recipient hybrid encryption
/// 
/// Uses AES-256-GCM for content encryption and X25519+HKDF for key wrapping
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 3,
      lineLength: 120,
      colors: true,
      printEmojis: true,
    ),
  );

  static const String _algorithm = 'AES-256-GCM';
  static const String _keyWrapMethod = 'X25519-HKDF-AEAD';
  static const String _kdfInfo = 'zdatar:ck-wrap';

  /// Encrypt data with AES-256-GCM and wrap key for multiple recipients
  Future<EncryptedDataEnvelope> encryptForRecipients({
    required Uint8List data,
    required List<String> recipientSolanaPublicKeys, // Base58 encoded
  }) async {
    try {
      _logger.i('🔐 Encrypting data for ${recipientSolanaPublicKeys.length} recipients');
      
      // 1. Generate content key (CK) and encrypt data
      final contentKey = await AesGcm.with256bits().newSecretKey();
      final nonce = AesGcm.with256bits().newNonce();
      
      final secretBox = await AesGcm.with256bits().encrypt(
        data,
        secretKey: contentKey,
        nonce: nonce,
      );

      _logger.d('Encrypted ${data.length} bytes of data');

      // 2. Extract content key bytes for wrapping
      final contentKeyBytes = await contentKey.extractBytes();

      // 3. Wrap content key for each recipient
      final wraps = <KeyWrap>[];
      for (final recipientPubKey in recipientSolanaPublicKeys) {
        final wrap = await _wrapKeyForRecipient(
          contentKeyBytes: Uint8List.fromList(contentKeyBytes),
          recipientSolanaPublicKey: recipientPubKey,
        );
        wraps.add(wrap);
      }

      _logger.i('✅ Created ${wraps.length} key wraps');

      // 4. Create envelope
      final envelope = EncryptedDataEnvelope(
        algorithm: _algorithm,
        cipherIv: base64Encode(nonce),
        cipherTag: base64Encode(secretBox.mac.bytes),
        ciphertext: base64Encode(secretBox.cipherText),
        createdAt: DateTime.now(),
        wraps: wraps,
      );

      return envelope;
    } catch (e, stackTrace) {
      _logger.e('❌ Encryption failed: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Wrap content key for a single recipient using X25519 ECDH
  Future<KeyWrap> _wrapKeyForRecipient({
    required Uint8List contentKeyBytes,
    required String recipientSolanaPublicKey,
  }) async {
    // 1. Convert recipient's Solana Ed25519 public key to X25519
    final recipientX25519Pub = await SolanaWalletService.solanaPublicKeyToX25519(
      recipientSolanaPublicKey,
    );

    // 2. Generate ephemeral X25519 keypair
    final x25519Algorithm = X25519();
    final ephemeralKeyPair = await x25519Algorithm.newKeyPair();
    final ephemeralPublicKey = await ephemeralKeyPair.extractPublicKey();

    // 3. Perform ECDH to get shared secret
    final sharedSecret = await x25519Algorithm.sharedSecretKey(
      keyPair: ephemeralKeyPair,
      remotePublicKey: SimplePublicKey(
        recipientX25519Pub,
        type: KeyPairType.x25519,
      ),
    );

    // 4. Derive wrapping key using HKDF-SHA256
    final sharedSecretBytes = await sharedSecret.extractBytes();
    final wrapKey = await Hkdf(
      hmac: Hmac.sha256(),
      outputLength: 32,
    ).deriveKey(
      secretKey: SecretKey(sharedSecretBytes),
      info: utf8.encode(_kdfInfo),
      nonce: [], // No salt for this use case
    );

    // 5. Encrypt content key with wrapping key
    final wrapNonce = AesGcm.with256bits().newNonce();
    final wrappedKey = await AesGcm.with256bits().encrypt(
      contentKeyBytes,
      secretKey: wrapKey,
      nonce: wrapNonce,
    );

    // 6. Create context hash for additional authentication
    final contextData = utf8.encode(
      '$recipientSolanaPublicKey|${base64Encode(ephemeralPublicKey.bytes)}|$_kdfInfo',
    );
    final contextHash = crypto_hash.sha256.convert(contextData);

    return KeyWrap(
      recipientSolanaPublicKey: recipientSolanaPublicKey,
      method: _keyWrapMethod,
      ephemeralPublicKey: base64Encode(ephemeralPublicKey.bytes),
      wrapNonce: base64Encode(wrapNonce),
      wrappedContentKey: base64Encode(wrappedKey.cipherText),
      contextHash: base64Encode(contextHash.bytes),
    );
  }

  /// Decrypt data using the seller's private key
  Future<Uint8List> decryptWithPrivateKey({
    required EncryptedDataEnvelope envelope,
    String? recipientSolanaPublicKey,
  }) async {
    try {
      final walletService = SolanaWalletService();
      
      // Get seller's public key if not provided
      final sellerPubKey = recipientSolanaPublicKey ??
          walletService.getPublicKeyBase58();
      
      _logger.i('🔓 Decrypting data for recipient: $sellerPubKey');

      // 1. Find matching key wrap
      final wrap = envelope.wraps.firstWhere(
        (w) => w.recipientSolanaPublicKey == sellerPubKey,
        orElse: () => throw Exception('No key wrap found for this recipient'),
      );

      // 2. Get recipient's X25519 private key
      final x25519PrivateKey = await walletService.getX25519KeyPair();
      final x25519Algorithm = X25519();
      final recipientKeyPair = await x25519Algorithm.newKeyPairFromSeed(
        Uint8List.fromList(x25519PrivateKey.bytes),
      );

      // 3. Reconstruct shared secret using ephemeral public key
      final ephemeralPubKey = base64Decode(wrap.ephemeralPublicKey);
      final sharedSecret = await x25519Algorithm.sharedSecretKey(
        keyPair: recipientKeyPair,
        remotePublicKey: SimplePublicKey(
          ephemeralPubKey,
          type: KeyPairType.x25519,
        ),
      );

      // 4. Derive wrapping key using same HKDF params
      final sharedSecretBytes = await sharedSecret.extractBytes();
      final wrapKey = await Hkdf(
        hmac: Hmac.sha256(),
        outputLength: 32,
      ).deriveKey(
        secretKey: SecretKey(sharedSecretBytes),
        info: utf8.encode(_kdfInfo),
        nonce: [],
      );

      // 5. Decrypt wrapped content key
      final wrapNonce = base64Decode(wrap.wrapNonce);
      final wrappedKeyBytes = base64Decode(wrap.wrappedContentKey);
      
      final contentKeyBytes = await AesGcm.with256bits().decrypt(
        SecretBox(
          wrappedKeyBytes,
          nonce: wrapNonce,
          mac: Mac.empty, // GCM tag is included in ciphertext
        ),
        secretKey: wrapKey,
      );

      _logger.d('Unwrapped content key');

      // 6. Decrypt data with content key
      final ciphertext = base64Decode(envelope.ciphertext);
      final nonce = base64Decode(envelope.cipherIv);
      final tag = base64Decode(envelope.cipherTag);

      final decryptedData = await AesGcm.with256bits().decrypt(
        SecretBox(
          ciphertext,
          nonce: nonce,
          mac: Mac(tag),
        ),
        secretKey: SecretKey(contentKeyBytes),
      );

      _logger.i('✅ Decrypted ${decryptedData.length} bytes of data');

      return Uint8List.fromList(decryptedData);
    } catch (e, stackTrace) {
      _logger.e('❌ Decryption failed: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Calculate SHA-256 hash of data
  static String hashData(Uint8List data) {
    final hash = crypto_hash.sha256.convert(data);
    return hash.toString();
  }

  /// Calculate SHA-256 hash and return as bytes
  static Uint8List hashDataBytes(Uint8List data) {
    final hash = crypto_hash.sha256.convert(data);
    return Uint8List.fromList(hash.bytes);
  }
}

/// Encrypted data envelope containing ciphertext and key wraps
class EncryptedDataEnvelope {
  final String algorithm;
  final String cipherIv;
  final String cipherTag;
  final String ciphertext;
  final String? ciphertextRef; // IPFS CID or Azure URL
  final DateTime createdAt;
  final List<KeyWrap> wraps;

  EncryptedDataEnvelope({
    required this.algorithm,
    required this.cipherIv,
    required this.cipherTag,
    required this.ciphertext,
    this.ciphertextRef,
    required this.createdAt,
    required this.wraps,
  });

  Map<String, dynamic> toJson() {
    return {
      'algo': algorithm,
      'cipher_iv': cipherIv,
      'cipher_tag': cipherTag,
      'ciphertext': ciphertext,
      if (ciphertextRef != null) 'ciphertext_ref': ciphertextRef,
      'created_at': createdAt.toIso8601String(),
      'wraps': wraps.map((w) => w.toJson()).toList(),
    };
  }

  factory EncryptedDataEnvelope.fromJson(Map<String, dynamic> json) {
    return EncryptedDataEnvelope(
      algorithm: json['algo'] as String,
      cipherIv: json['cipher_iv'] as String,
      cipherTag: json['cipher_tag'] as String,
      ciphertext: json['ciphertext'] as String,
      ciphertextRef: json['ciphertext_ref'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      wraps: (json['wraps'] as List)
          .map((w) => KeyWrap.fromJson(w as Map<String, dynamic>))
          .toList(),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  /// Create copy with ciphertext reference
  EncryptedDataEnvelope withCiphertextRef(String ref) {
    return EncryptedDataEnvelope(
      algorithm: algorithm,
      cipherIv: cipherIv,
      cipherTag: cipherTag,
      ciphertext: ciphertext,
      ciphertextRef: ref,
      createdAt: createdAt,
      wraps: wraps,
    );
  }
}

/// Key wrap information for a single recipient
class KeyWrap {
  final String recipientSolanaPublicKey;
  final String method;
  final String ephemeralPublicKey;
  final String wrapNonce;
  final String wrappedContentKey;
  final String contextHash;

  KeyWrap({
    required this.recipientSolanaPublicKey,
    required this.method,
    required this.ephemeralPublicKey,
    required this.wrapNonce,
    required this.wrappedContentKey,
    required this.contextHash,
  });

  Map<String, dynamic> toJson() {
    return {
      'recipient_solana_pub58': recipientSolanaPublicKey,
      'method': method,
      'eph_pub': ephemeralPublicKey,
      'wrap_nonce': wrapNonce,
      'wrapped_ck': wrappedContentKey,
      'context_hash': contextHash,
    };
  }

  factory KeyWrap.fromJson(Map<String, dynamic> json) {
    return KeyWrap(
      recipientSolanaPublicKey: json['recipient_solana_pub58'] as String,
      method: json['method'] as String,
      ephemeralPublicKey: json['eph_pub'] as String,
      wrapNonce: json['wrap_nonce'] as String,
      wrappedContentKey: json['wrapped_ck'] as String,
      contextHash: json['context_hash'] as String,
    );
  }
}
