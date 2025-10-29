# Data Marketplace Architecture

## Overview

This document outlines the architecture for the ZDatar mobile data marketplace, including data collection, caching, encryption, and deal fulfillment.

## System Flow

```
Data Collection (Continuous)
    ↓
Local Cache (5-minute rolling window)
    ↓
Deal Acceptance Trigger
    ↓
Data Export (CSV by category/subcategory)
    ↓
AES Encryption + Hashing
    ↓
Multi-Recipient Key Encryption (Buyer + Seller)
    ↓
Upload to IPFS + Azure Blob Storage
    ↓
Complete Deal Transaction (Solana)
```

## Components

### 1. Data Cache Service (`data_cache_service.dart`)
**Purpose:** Continuously cache collected data with 5-minute rolling window

**Features:**
- Store timestamped data points for each category/subcategory
- Automatic cleanup of data older than 5 minutes
- Efficient retrieval by category/subcategory
- Thread-safe operations

**Data Structure:**
```dart
Map<String, Map<String, List<TimestampedDataPoint>>> {
  "category": {
    "subcategory": [
      { timestamp, data }
    ]
  }
}
```

### 2. Solana Wallet Service (`solana_wallet_service.dart`)
**Purpose:** Manage Solana keypair for encryption and transactions

**Features:**
- Generate/restore wallet from mnemonic
- Secure key storage using `flutter_secure_storage`
- Ed25519 to Curve25519 conversion for encryption
- Sign transactions
- Derive X25519 keys for ECDH

**Key Operations:**
- `generateWallet()` - Create new wallet
- `restoreWallet(mnemonic)` - Restore from seed phrase
- `getPublicKey()` - Get Solana public key
- `getX25519Keys()` - Get encryption keypair
- `signTransaction()` - Sign Solana transactions

### 3. Data Export Service (`data_export_service.dart`)
**Purpose:** Export cached data to CSV format

**Features:**
- Filter data by category/subcategory
- Generate CSV with headers
- Handle nested JSON data
- Timestamp formatting

**Output Format:**
```csv
timestamp,category,subcategory,field1,field2,...
2025-01-15T10:30:00Z,Mobility,GPS,37.7749,-122.4194,...
```

### 4. Encryption Service (`encryption_service.dart`)
**Purpose:** Handle AES encryption and multi-recipient key wrapping

**Features:**
- AES-256-GCM encryption
- X25519 ECDH key exchange
- HKDF-SHA256 key derivation
- Multi-recipient envelope encryption
- SHA-256 file hashing

**Multi-Recipient Encryption Algorithm:**
1. Generate random 256-bit AES data key
2. Encrypt payload with AES-GCM
3. For each recipient:
   - Generate ephemeral X25519 keypair
   - Perform ECDH with recipient's public key
   - Derive wrapping key using HKDF-SHA256
   - Encrypt data key with AES-GCM using wrapping key
4. Create envelope with all wrapped keys + ciphertext

**Envelope Structure:**
```json
{
  "ver": "1",
  "aead": "AESGCM-256",
  "nonce": "<base64>",
  "recipients": [
    {
      "kid": "seller",
      "kem": "X25519-HKDF-SHA256",
      "eph_pub": "<base64>",
      "nonce": "<base64>",
      "kw": "<base64 wrapped key>"
    },
    {
      "kid": "buyer",
      ...
    }
  ],
  "ciphertext": "<base64>"
}
```

### 5. Storage Upload Service (`storage_upload_service.dart`)
**Purpose:** Upload encrypted data to IPFS and Azure

**Features:**
- IPFS pinning via Pinata or Infura
- Azure Blob Storage upload
- Progress tracking
- Error handling and retries

**IPFS Upload:**
- Use Pinata API or IPFS HTTP client
- Returns IPFS CID (Content Identifier)

**Azure Upload:**
- Use Azure Storage SDK
- Returns blob URL

### 6. Deal Fulfillment Service (`deal_fulfillment_service.dart`)
**Purpose:** Orchestrate the entire deal acceptance flow

**Workflow:**
```dart
1. acceptDeal(dealId)
2. fetchDealDetails(dealId) // Get buyer pub key, categories
3. extractRelevantData(categories) // From cache
4. exportToCSV(data)
5. encryptData(csv, aesKey)
6. hashData(encryptedData)
7. multiRecipientEncrypt(aesKey, [buyerPk, sellerPk])
8. uploadToIPFS(encryptedData)
9. uploadToAzure(encryptedData)
10. createDealMetadata(ipfsCID, azureURL, hash, encryptedKeys)
11. submitToBlockchain(dealId, metadata)
12. updateDealStatus(dealId, 'completed')
```

## Deal Model Updates

Add fields to `Deal` model:

```dart
class Deal {
  // Existing fields...
  
  // New fields for data marketplace
  final List<String>? categories;
  final List<String>? subcategories;
  final String? buyerSolanaPublicKey;
  final DealRequirements? requirements;
}

class DealRequirements {
  final DateTime startTime;
  final DateTime endTime;
  final int minDataPoints;
  final Map<String, dynamic>? filters;
}
```

## Security Considerations

### 1. Key Management
- Store Solana private key in `flutter_secure_storage`
- Never log or expose private keys
- Use biometric authentication for sensitive operations

### 2. Data Privacy
- Only export data specified in deal requirements
- Clear sensitive data from memory after use
- Encrypt data before any network transmission

### 3. Encryption
- Use cryptographically secure random number generation
- Verify all public keys before encryption
- Include authentication tags in all encrypted data

## Required Flutter Packages

```yaml
dependencies:
  # Cryptography
  cryptography: ^2.5.0
  pointycastle: ^3.7.3
  
  # Solana
  solana: ^0.30.5
  bip39: ^1.0.6  # For mnemonic generation
  ed25519_hd_key: ^2.2.1
  
  # Storage
  flutter_secure_storage: ^9.0.0
  sqflite: ^2.3.0  # For data cache
  
  # Export/Import
  csv: ^5.1.0
  
  # Networking
  dio: ^5.4.0  # For IPFS and Azure uploads
  
  # Utilities
  convert: ^3.1.1
  crypto: ^3.0.3  # For hashing
```

## Database Schema (SQLite)

### data_cache table
```sql
CREATE TABLE data_cache (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  category TEXT NOT NULL,
  subcategory TEXT NOT NULL,
  timestamp INTEGER NOT NULL,
  data TEXT NOT NULL,  -- JSON
  created_at INTEGER NOT NULL
);

CREATE INDEX idx_category_subcategory ON data_cache(category, subcategory);
CREATE INDEX idx_timestamp ON data_cache(timestamp);
```

### Cleanup Query
```sql
DELETE FROM data_cache 
WHERE timestamp < (strftime('%s', 'now') - 300);  -- 5 minutes
```

## Implementation Priority

### Phase 1: Foundation (Current)
1. ✅ Local data cache service
2. ✅ Solana wallet service (basic)
3. ✅ Data export service

### Phase 2: Encryption
4. AES encryption implementation
5. X25519 ECDH implementation
6. Multi-recipient envelope encryption
7. Hash generation

### Phase 3: Storage
8. IPFS upload service
9. Azure Blob Storage service
10. Error handling and retries

### Phase 4: Integration
11. Deal fulfillment orchestration
12. UI updates for deal acceptance
13. Progress indicators
14. Error handling and user feedback

### Phase 5: Testing
15. Unit tests for encryption
16. Integration tests for full flow
17. End-to-end testing with backend
18. Security audit

## API Integration

### Backend Endpoints Needed

```
POST /deals/{deal_id}/accept
Body: {
  "seller_wallet": "...",
  "data_hash": "...",
  "ipfs_cid": "...",
  "azure_url": "...",
  "encrypted_keys": { ... }
}

POST /deals/{deal_id}/complete
Body: {
  "transaction_signature": "..."
}
```

## Configuration

Add to `.env`:

```env
# IPFS Configuration
IPFS_API_URL=https://api.pinata.cloud/pinning/pinFileToIPFS
IPFS_API_KEY=your_pinata_api_key
IPFS_API_SECRET=your_pinata_secret

# Azure Configuration
AZURE_STORAGE_CONNECTION_STRING=your_connection_string
AZURE_CONTAINER_NAME=zdatar-data

# Solana Configuration
SOLANA_RPC_URL=https://api.devnet.solana.com
SOLANA_NETWORK=devnet
```

## Testing Strategy

### Unit Tests
- Encryption/decryption with known vectors
- Key derivation functions
- CSV export formatting
- Data cache CRUD operations

### Integration Tests
- Full deal acceptance flow
- Multi-recipient encryption/decryption
- IPFS upload and retrieval
- Azure upload and download

### Security Tests
- Key material doesn't leak
- Encrypted data can't be decrypted without keys
- Multi-recipient encryption works correctly
- Hash verification

## Performance Considerations

### Data Cache
- Use indexed SQLite queries
- Batch inserts for better performance
- Background thread for cleanup

### Encryption
- Use isolates for heavy crypto operations
- Cache derived keys when possible
- Stream large files instead of loading into memory

### Upload
- Compress data before upload
- Use multipart upload for large files
- Implement retry logic with exponential backoff

## Error Handling

### Recoverable Errors
- Network failures → Retry with backoff
- Temporary storage issues → Wait and retry
- API rate limits → Exponential backoff

### Non-Recoverable Errors
- Invalid keys → Show error to user
- Corrupted data → Log and skip
- Insufficient data → Notify user

### User Feedback
- Progress indicators for long operations
- Clear error messages
- Ability to retry failed uploads
- Transaction status updates

## Future Enhancements

1. **Offline Support:** Queue deals for acceptance when online
2. **Partial Data:** Support deals with partial data fulfillment
3. **Data Streaming:** Stream large datasets instead of batch export
4. **Compression:** Add compression before encryption
5. **Metadata:** Include data quality metrics in deal metadata
6. **Escrow:** Integration with smart contract escrow
7. **Audit Trail:** Detailed logging of all operations
8. **Data Validation:** Verify data meets deal requirements before export
