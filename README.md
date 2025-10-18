# ZDatar Mobile App

ZDatar is the official Flutter app for the ZDatar ecosystem, focused on privacy-preserving data collection, blockchain integration, and user monetization.

## Project Overview

ZDatar is a decentralized data platform that empowers users to collect, own, and monetize their personal data securely. The system leverages end-to-end encryption, decentralized storage, and blockchain smart contracts to ensure privacy, transparency, and fair compensation.

### System Architecture

- **Mobile App (ZDatar):**
  - Collects data (motion, location, environment, etc.)
  - Encrypts data client-side before upload
  - Connects with Web3 wallets (MetaMask, WalletConnect)
  - Uploads encrypted data to off-chain storage (IPFS/Arweave/Filecoin)
  - Interacts with smart contracts for data ownership and monetization

- **Off-Chain Data Storage:**
  - Stores encrypted data files
  - Returns content hash (CID) as a reference for on-chain storage
  - Ensures decentralized, tamper-proof storage

- **On-Chain Smart Contracts (Polygon/Layer 2 EVM):**
  - Metadata registry: maps CID to wallet address, timestamp, data type
  - Access control and marketplace logic for data sales and permissions

- **Web Dashboard:**
  - Manage uploaded data, permissions, and view stats
  - UI for interacting with smart contracts

- **Data Buyer API & Portal:**
  - Searchable data marketplace
  - Token-based authentication for buyers

- **Privacy Layer:**
  - End-to-end encryption (AES)
  - Optional Zero-Knowledge Proofs (ZKPs) for access validation
  - Token-gated access policies (ZDATA token)

### Security Considerations
- All data is encrypted on the client before upload
- Smart contracts are audited
- Role-based access for buyer portals
- Optional zk-SNARKs for privacy-preserving analytics

## Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- Dart
- Android Studio or Xcode (for iOS)

### Setup
1. Clone this repository or copy the `zdatar_mobile` folder.
2. Install dependencies:
   ```sh
   flutter pub get
   ```
3. Run the app:
   ```sh
   flutter run
   ```

### Folder Structure
- `lib/` — Main Flutter app code
- `android/`, `ios/` — Platform-specific code

## Contributing
Pull requests are welcome! For major changes, please open an issue first to discuss what you would like to change.

## License
This project is licensed under a proprietary End User License Agreement (EULA). See the [LICENSE](LICENSE) file for details.

**Important**: This is a closed-source application. Users are granted rights to use the app only. Redistribution, modification, and reverse engineering are strictly prohibited.
