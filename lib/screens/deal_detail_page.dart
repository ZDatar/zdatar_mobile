import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/deal.dart';
import '../services/deals_service.dart';
import '../services/solana_wallet_service.dart';
import '../services/storage_service.dart';
import '../services/encryption_service.dart';

class DealDetailPage extends StatefulWidget {
  final String dealId;
  final VoidCallback? onBack;

  const DealDetailPage({super.key, required this.dealId, this.onBack});

  @override
  State<DealDetailPage> createState() => _DealDetailPageState();
}

class _DealDetailPageState extends State<DealDetailPage> {
  final DealsService _dealsService = DealsService();
  final SolanaWalletService _walletService = SolanaWalletService();
  final StorageService _storageService = StorageService();
  final EncryptionService _encryptionService = EncryptionService();
  Deal? _deal;
  bool _isLoading = true;
  bool _isAccepting = false;

  @override
  void initState() {
    super.initState();
    _fetchDealDetails();
  }

  Future<void> _fetchDealDetails() async {
    final deal = await _dealsService.fetchDealById(widget.dealId);
    if (mounted) {
      setState(() {
        _deal = deal;
        _isLoading = false;
      });
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
  }

  Future<void> _handleAcceptDeal() async {
    setState(() {
      _isAccepting = true;
    });

    // Capture messenger before async operations
    final messenger = ScaffoldMessenger.of(context);

    try {
      // Step 1: Verify wallet exists (seller wallet)
      await _walletService.initialize();
      final hasWallet = await _walletService.hasWallet();

      if (!hasWallet) {
        if (mounted) {
          setState(() => _isAccepting = false);
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Please create a wallet first to accept deals'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      await _walletService.getEd25519PublicKey();
      final sellerWallet = _walletService.getPublicKeyBase58();

      debugPrint(
        '🔍 Accepting deal ${widget.dealId} as seller with wallet: $sellerWallet',
      );

      // Step 2: Show progress dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Preparing dataset...'),
              ],
            ),
          ),
        );
      }

      // Step 3: Collect and prepare dataset
      // PRODUCTION: Implement DataCollectionService to gather real user data
      // based on deal.dealMeta.category and deal.dealMeta.dataSubcategories
      // For now, we'll create a placeholder dataset for testing
      final datasetCsv = _createPlaceholderDatasetCsv(_deal!);
      final datasetBytes = Uint8List.fromList(utf8.encode(datasetCsv));

      debugPrint(
        '📦 Dataset collected: ${datasetBytes.length} bytes (CSV format)',
      );

      // Step 4: Encrypt dataset with AES-256-GCM for multiple recipients
      final encryptionEnvelope = await _encryptionService.encryptForRecipients(
        data: datasetBytes,
        recipientSolanaPublicKeys: [
          _deal!.buyerWallet, // Buyer can decrypt
          sellerWallet, // Seller can decrypt
        ],
      );

      // Extract encrypted data for upload
      final encryptedDataset = base64Decode(encryptionEnvelope.ciphertext);

      debugPrint(
        '🔐 Dataset encrypted with AES-256-GCM: ${encryptedDataset.length} bytes',
      );
      debugPrint(
        '🔑 Created ${encryptionEnvelope.wraps.length} key wraps for multi-recipient access',
      );

      // Step 5: Upload to IPFS and Azure
      if (mounted) {
        Navigator.of(context).pop(); // Close preparing dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Uploading to IPFS and Azure...'),
              ],
            ),
          ),
        );
      }

      final uploadResult = await _storageService.uploadToBoth(
        encryptedDataset,
        filename:
            'deal_${widget.dealId}_${DateTime.now().millisecondsSinceEpoch}.csv.enc',
        metadata: {
          'dealId': widget.dealId,
          'sellerWallet': sellerWallet,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
          'format': 'csv',
          'contentType': 'text/csv',
        },
      );

      final ipfsCid = uploadResult['ipfs'] ?? 'not_uploaded';
      final azureUrl = uploadResult['azure'] ?? 'not_uploaded';

      // At least one must have succeeded (checked in StorageService)
      debugPrint('☁️ IPFS: $ipfsCid');
      debugPrint('☁️ Azure: $azureUrl');

      // Step 6: Generate data hash
      final dataHash = _storageService.generateHash(encryptedDataset);
      debugPrint('🔑 Data hash: $dataHash');

      // Step 7: Serialize encryption envelope and base64-encode for backend
      final envelopeJson = encryptionEnvelope.toJsonString();
      final encryptedAesKey = base64Encode(utf8.encode(envelopeJson));

      debugPrint('📦 Encryption envelope JSON: ${envelopeJson.length} bytes');
      debugPrint(
        '📦 Encrypted AES key (base64): ${encryptedAesKey.length} bytes',
      );
      debugPrint('✅ Multi-recipient encryption complete (buyer + seller)');

      // Step 8: Create dataset in backend
      if (mounted) {
        Navigator.of(context).pop(); // Close upload dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Creating dataset record...'),
              ],
            ),
          ),
        );
      }

      final dealMeta = _deal!.dealMeta;
      final createDatasetResult = await _dealsService.createDataset(
        name: dealMeta?.category ?? 'Data',
        description:
            dealMeta?.requestDescription ?? 'Dataset for accepted deal',
        price: double.tryParse(dealMeta?.price ?? '0') ?? 0.0,
        currency: dealMeta?.currency ?? 'SOL',
        ipfsCid: ipfsCid,
        fileUrl: azureUrl,
        dataHash: dataHash,
        encryptedAesKey: encryptedAesKey,
        ownerWalletPubkey: sellerWallet,
        dataStartTime: DateTime.now()
            .toUtc()
            .subtract(const Duration(days: 7))
            .toIso8601String(),
        dataEndTime: DateTime.now().toUtc().toIso8601String(),
        dataMeta: {
          'dealId': widget.dealId,
          'fields': dealMeta?.dataFieldsRequired ?? [],
          'category': dealMeta?.category ?? 'General',
          'subcategories': dealMeta?.dataSubcategories ?? [],
        },
        fileSize: encryptedDataset.length,
        icon: _deal!.icon,
        tags: dealMeta?.dataSubcategories ?? [],
      );

      if (createDatasetResult['success'] != true) {
        throw Exception(
          createDatasetResult['error'] ?? 'Failed to create dataset',
        );
      }

      final datasetData = createDatasetResult['data'] as Map<String, dynamic>;
      final datasetId = datasetData['dataset_id'] as String;

      debugPrint('✅ Dataset created with ID: $datasetId');

      // Step 9: Accept the deal with dataset_id
      if (mounted) {
        Navigator.of(context).pop(); // Close dataset creation dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Accepting deal...'),
              ],
            ),
          ),
        );
      }

      final result = await _dealsService.acceptDeal(
        widget.dealId,
        sellerWallet,
        datasetId,
        encryptedAesKey,
      );

      // Close progress dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        setState(() {
          _isAccepting = false;
        });

        if (result['success'] == true) {
          debugPrint('✅ Deal accepted successfully!');
          messenger.showSnackBar(
            const SnackBar(
              content: Center(child: Text('✅ Deal accepted successfully!')),
              backgroundColor: Colors.green,
            ),
          );
          // Refresh deal details
          await _fetchDealDetails();
        } else {
          final errorMsg = result['error'] ?? 'Failed to accept deal';
          debugPrint('❌ Deal acceptance failed: $errorMsg');
          messenger.showSnackBar(
            SnackBar(
              content: Text('Failed: $errorMsg'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Exception accepting deal: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isAccepting = false);
        messenger.showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Create a placeholder dataset in CSV format based on deal requirements
  ///
  /// PRODUCTION IMPLEMENTATION REQUIRED:
  /// Replace with DataCollectionService that:
  /// 1. Reads deal.dealMeta.category (e.g., 'Health', 'Location')
  /// 2. Reads deal.dealMeta.dataSubcategories (e.g., ['steps', 'heart_rate'])
  /// 3. Reads deal.dealMeta.dataFieldsRequired
  /// 4. Collects actual sensor/HealthKit/location data from device
  /// 5. Formats as CSV with proper headers and data rows
  String _createPlaceholderDatasetCsv(Deal deal) {
    final dealMeta = deal.dealMeta;
    final now = DateTime.now();

    debugPrint(
      '⚠️ Using placeholder CSV dataset - implement actual data collection!',
    );

    // Generate CSV format with metadata header and data rows
    final csvBuffer = StringBuffer();

    // Metadata section (as comments)
    csvBuffer.writeln('# ZDatar Dataset Export');
    csvBuffer.writeln('# Deal ID: ${deal.dealId}');
    csvBuffer.writeln('# Category: ${dealMeta?.category ?? 'General'}');
    csvBuffer.writeln(
      '# Subcategories: ${(dealMeta?.dataSubcategories ?? []).join(', ')}',
    );
    csvBuffer.writeln(
      '# Required Fields: ${(dealMeta?.dataFieldsRequired ?? []).join(', ')}',
    );
    csvBuffer.writeln('# Collected At: ${now.toUtc().toIso8601String()}');
    csvBuffer.writeln('# Version: 1.0');
    csvBuffer.writeln('#');

    // CSV Header row - Always include timestamp as first column
    final fields = dealMeta?.dataFieldsRequired ?? ['value', 'unit'];
    csvBuffer.writeln('timestamp,${fields.join(',')}');

    // CSV Data rows (placeholder data)
    // In production, this would be real collected data
    for (int i = 0; i < 5; i++) {
      final row = <String>[];

      // Add Unix timestamp in milliseconds as first column
      final rowTimestamp = now.toUtc().subtract(Duration(hours: i));
      final unixTimestampMs = rowTimestamp.millisecondsSinceEpoch;
      row.add('$unixTimestampMs');

      for (final field in fields) {
        // Generate placeholder data based on field name patterns
        final fieldLower = field.toLowerCase();

        if (fieldLower.contains('_mbps') ||
            fieldLower.contains('download') ||
            fieldLower.contains('upload')) {
          row.add('${50 + i * 5}.$i'); // Network speed placeholder
        } else if (fieldLower.contains('latency') ||
            fieldLower.contains('_ms')) {
          row.add('${20 + i}'); // Latency placeholder
        } else if (fieldLower.contains('signal') ||
            fieldLower.contains('bars')) {
          row.add('${4 - (i % 4)}'); // Signal strength placeholder
        } else if (fieldLower.contains('battery') ||
            fieldLower.contains('level')) {
          row.add('${85 - i * 2}'); // Battery level placeholder
        } else if (fieldLower.contains('percent') ||
            fieldLower.contains('distribution')) {
          row.add('${20 + i * 3}.$i'); // Percentage placeholder
        } else if (fieldLower.contains('count') ||
            fieldLower.contains('number')) {
          row.add('${100 + i * 10}'); // Count placeholder
        } else if (fieldLower.contains('enabled') ||
            fieldLower.contains('charging') ||
            fieldLower.contains('saver')) {
          row.add(i % 2 == 0 ? 'true' : 'false'); // Boolean placeholder
        } else if (fieldLower.contains('status') ||
            fieldLower.contains('state') ||
            fieldLower.contains('type')) {
          row.add('active'); // Status placeholder
        } else if (fieldLower.contains('latitude') ||
            fieldLower.contains('longitude')) {
          row.add('${1.2649 + i * 0.001}'); // Coordinate placeholder
        } else if (fieldLower.contains('_x') ||
            fieldLower.contains('_y') ||
            fieldLower.contains('_z')) {
          row.add('${(i - 2) * 0.5}'); // Sensor axis placeholder
        } else {
          row.add('placeholder_$i'); // Generic placeholder
        }
      }

      csvBuffer.writeln(row.join(','));
    }

    return csvBuffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.colorScheme.primary,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_deal == null) {
      return Scaffold(
        backgroundColor: theme.colorScheme.primary,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: widget.onBack ?? () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.withValues(alpha: 0.7),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Deal not found',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final deal = _deal!;
    final price = deal.dealMeta?.price ?? '0';
    final currency = deal.dealMeta?.currency ?? 'SOL';
    final category = deal.dealMeta?.category ?? 'Data';
    final description = deal.dealMeta?.requestDescription ?? 'No description';
    final icon = deal.icon;

    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: widget.onBack ?? () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Data deal',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(icon, style: const TextStyle(fontSize: 80)),
                            const SizedBox(height: 16),
                            Text(
                              category,
                              style: theme.textTheme.headlineLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$price $currency',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: theme.colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: deal.status == 'created'
                                    ? Colors.green.withValues(alpha: 0.2)
                                    : Colors.blue.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                deal.status.toUpperCase(),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: deal.status == 'created'
                                      ? Colors.greenAccent
                                      : Colors.blueAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Description',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        description,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Deal Information',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: 'Deal ID',
                        value: '${deal.dealId.substring(0, 8)}...',
                        theme: theme,
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: 'Buyer Wallet',
                        value: '${deal.buyerWallet.substring(0, 8)}...',
                        theme: theme,
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: 'Created',
                        value: _formatDateTime(deal.createdAt),
                        theme: theme,
                      ),
                      if (deal.expiresAt != null) ...[
                        const SizedBox(height: 8),
                        _InfoRow(
                          label: 'Expires',
                          value: _formatDateTime(deal.expiresAt!),
                          theme: theme,
                        ),
                      ],
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: 'Transaction',
                        value: '${deal.solanaTxHash.substring(0, 8)}...',
                        theme: theme,
                      ),
                      if (deal.dealMeta?.category != null) ...[
                        const SizedBox(height: 8),
                        _InfoRow(
                          label: 'Data Category',
                          value: deal.dealMeta!.category,
                          theme: theme,
                        ),
                      ],
                      if (deal.dealMeta?.dataSubcategories.isNotEmpty ==
                          true) ...[
                        const SizedBox(height: 8),
                        _InfoRow(
                          label: 'Subcategories',
                          value: deal.dealMeta!.dataSubcategories.join(', '),
                          theme: theme,
                        ),
                      ],
                      if (deal.dealMeta?.dataFieldsRequired.isNotEmpty ==
                          true) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Required Data Fields (${deal.dealMeta!.dataFieldsRequired.length})',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: deal.dealMeta!.dataFieldsRequired.map((
                            field,
                          ) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: theme.colorScheme.secondary.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                field,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.secondary,
                                  fontSize: 11,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: theme.elevatedButtonTheme.style?.copyWith(
                            padding: WidgetStateProperty.all(
                              const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                          onPressed: _isAccepting || deal.status != 'created'
                              ? null
                              : _handleAcceptDeal,
                          child: _isAccepting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  deal.status == 'created'
                                      ? 'Accept Deal'
                                      : 'Deal ${deal.status}',
                                  style: theme.textTheme.titleLarge,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
