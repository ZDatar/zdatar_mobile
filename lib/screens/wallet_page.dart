import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../services/solana_wallet_service.dart';
import '../services/deals_service.dart';
import '../models/deal.dart';
import 'wallet_detail_page.dart';

/// NEW COMPREHENSIVE WALLET PAGE
///
/// Features:
/// - Wallet creation with mnemonic backup
/// - Wallet import from recovery phrase
/// - Real Solana wallet integration
/// - Deal history and earnings tracking
/// - Security features (backup, export, delete)
///

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final SolanaWalletService _walletService = SolanaWalletService();
  final DealsService _dealsService = DealsService();

  bool _isLoading = true;
  bool _hasWallet = false;
  String? _walletAddress;
  String _balance = '0.00';
  List<Deal> _myDeals = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _initializeWallet();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_hasWallet) _refreshWalletData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeWallet() async {
    setState(() => _isLoading = true);
    try {
      await _walletService.initialize();
      final hasWallet = await _walletService.hasWallet();
      if (hasWallet) await _loadWalletData();
      setState(() {
        _hasWallet = hasWallet;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error initializing wallet: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadWalletData() async {
    try {
      await _walletService.getEd25519PublicKey();
      final address = _walletService.getPublicKeyBase58();

      // Fetch real SOL balance from Solana RPC
      double solBalance = 0.0;
      try {
        solBalance = await _walletService.getBalance();
        // debugPrint('💰 Fetched real balance: $solBalance SOL');
      } catch (e) {
        debugPrint('⚠️ Could not fetch on-chain balance: $e');
        // Fall back to deal-based calculation if RPC fails
      }

      final dealsResponse = await _dealsService.fetchDeals();
      final myDeals =
          dealsResponse?.deals
              .where(
                (deal) =>
                    deal.sellerWallet == address || deal.buyerWallet == address,
              )
              .toList() ??
          [];

      if (mounted) {
        setState(() {
          _walletAddress = address;
          _myDeals = myDeals;
          // Use real Solana balance instead of deal totals
          _balance = solBalance.toStringAsFixed(4);
        });
      }
    } catch (e) {
      debugPrint('Error loading wallet data: $e');
    }
  }

  Future<void> _refreshWalletData() async {
    if (!mounted) return;
    await _loadWalletData();
  }

  Future<void> _createNewWallet() async {
    try {
      setState(() => _isLoading = true);
      final result = await _walletService.generateWallet();
      if (mounted) {
        await _showMnemonicBackupDialog(result['mnemonic'] as String);
        await _loadWalletData();
        setState(() {
          _hasWallet = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to create wallet: $e')));
      }
    }
  }

  Future<void> _importWallet() async {
    final controller = TextEditingController();
    final mnemonic = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Wallet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter your 12 or 24-word recovery phrase:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'word1 word2 word3 ...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (mnemonic != null && mnemonic.isNotEmpty) {
      try {
        setState(() => _isLoading = true);
        await _walletService.restoreWallet(mnemonic);
        await _loadWalletData();
        if (mounted) {
          setState(() {
            _hasWallet = true;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Wallet imported successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to import wallet: $e')),
          );
        }
      }
    }
  }

  Future<void> _showMnemonicBackupDialog(String mnemonic) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 8),
            Text('Backup Your Wallet'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Write down these 12 words in order and keep them safe. This is the ONLY way to recover your wallet.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  mnemonic,
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: mnemonic));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard')),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                '⚠️ Never share these words with anyone!',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('I\'ve Saved It'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.primary,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_hasWallet) {
      return _buildWalletSetupScreen(context);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshWalletData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildHeader(context),
                  const SizedBox(height: 20),
                  _buildBalanceCard(context),
                  const SizedBox(height: 16),
                  _buildDealEarnings(context),
                  const SizedBox(height: 16),
                  _buildDealHistoryCard(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWalletSetupScreen(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.secondary,
                      theme.colorScheme.secondary.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: AppRadius.xlargeRadius,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          height: 44,
                          width: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.wallet_rounded,
                            color: Colors.green,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 18),
                        Text(
                          'Your wallet',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Generate a secure Solana wallet or import an existing recovery phrase to get started.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'What you get',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _FeatureTile(
                      icon: Icons.key_rounded,
                      title: 'Non-custodial & encrypted',
                      subtitle:
                          'Private keys are generated locally and stored securely on your device.',
                    ),
                    const SizedBox(height: 12),
                    _FeatureTile(
                      icon: Icons.trending_up_rounded,
                      title: 'Earn from your data',
                      subtitle:
                          'Track deal payouts and marketplace activity tied to your wallet.',
                    ),
                    const SizedBox(height: 12),
                    _FeatureTile(
                      icon: Icons.restore_rounded,
                      title: 'Easy recovery',
                      subtitle:
                          'Restore anytime using your recovery phrase. No accounts or emails required.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: _createNewWallet,
                    icon: const Icon(Icons.flash_on_rounded),
                    label: const Text('Create new wallet'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      foregroundColor: Colors.white,
                      textStyle: theme.textTheme.titleMedium,
                    ),
                    onPressed: _importWallet,
                    icon: const Icon(Icons.qr_code_2_rounded),
                    label: const Text('Import from recovery phrase'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Never share your recovery phrase. Anyone with it can access your funds.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final addressLabel = _walletAddress != null
        ? '${_walletAddress!.substring(0, 4)}...${_walletAddress!.substring(_walletAddress!.length - 4)}'
        : 'Unknown';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openWalletDetails,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Wallet',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Address • $addressLabel',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.secondary,
            theme.colorScheme.secondary.withValues(alpha: 0.65),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.xxlargeRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current balance',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _balance,
                style: theme.textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'SOL',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _BalanceTag(
                icon: Icons.lock_outline_rounded,
                label: 'Self-custodial',
              ),
              const SizedBox(width: 12),
              _BalanceTag(
                icon: Icons.shield_moon_outlined,
                label: 'Secure storage',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDealEarnings(BuildContext context) {
    final theme = Theme.of(context);

    final totals = _calculateDealTotals(_myDeals, _walletAddress);
    final earned = totals['earned']!;
    final spent = totals['spent']!;
    final net = totals['net']!;

    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white.withValues(alpha: 0.07),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.largeRadius),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Deal earnings',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _EarningRow(
              label: 'Earned from selling data',
              value: '+$earned SOL',
              icon: Icons.auto_graph_rounded,
              color: Colors.greenAccent,
            ),
            const Divider(height: 32, color: Colors.white24),
            _EarningRow(
              label: 'Spent on purchases',
              value: '-$spent SOL',
              icon: Icons.shopping_bag_outlined,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: AppRadius.mediumRadius,
                color: net.startsWith('-')
                    ? theme.colorScheme.error.withValues(alpha: 0.14)
                    : Colors.green.withValues(alpha: 0.18),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Net from deals',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  Text(
                    '$net SOL',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDealHistoryCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.largeRadius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent deal history',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_myDeals.length} deals',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          if (_myDeals.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 48,
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No deals yet',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._myDeals.take(5).map((deal) => _buildDealItem(context, deal)),
        ],
      ),
    );
  }

  Widget _buildDealItem(BuildContext context, Deal deal) {
    final theme = Theme.of(context);
    final isSeller = deal.sellerWallet == _walletAddress;
    final amount = deal.dealMeta?.price ?? '0';
    final date = DateFormat('MMM dd').format(deal.createdAt);

    final color = isSeller ? Colors.greenAccent : theme.colorScheme.error;
    final label = isSeller ? 'Data sold' : 'Data purchased';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(deal.icon, style: const TextStyle(fontSize: 26)),
      ),
      title: Text(
        '$label • ${deal.dealMeta?.dataCategory ?? 'Data deal'}',
        style: theme.textTheme.titleSmall?.copyWith(
          color: Colors.white.withValues(alpha: 0.9),
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        date,
        style: theme.textTheme.bodySmall?.copyWith(
          color: Colors.white.withValues(alpha: 0.6),
        ),
      ),
      trailing: Text(
        '${isSeller ? '+' : '-'}$amount SOL',
        style: theme.textTheme.titleSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: () {
        // Placeholder for navigation to deal detail.
      },
    );
  }

  void _openWalletDetails() {
    if (!_hasWallet || _walletAddress == null) {
      _showSnackbar('Create or import a wallet to view details.');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WalletDetailPage(
          walletAddress: _walletAddress!,
          onRefresh: _refreshWalletData,
          recentDeals: _myDeals,
        ),
      ),
    );
  }

  Map<String, String> _calculateDealTotals(List<Deal> deals, String? address) {
    double earned = 0;
    double spent = 0;

    if (address != null) {
      for (final deal in deals) {
        final amount = double.tryParse(deal.dealMeta?.price ?? '') ?? 0;
        if (deal.sellerWallet == address) {
          earned += amount;
        }
        if (deal.buyerWallet == address) {
          spent += amount;
        }
      }
    }

    String format(double value) => value.toStringAsFixed(2);
    final netValue = earned - spent;
    return {
      'earned': format(earned),
      'spent': format(spent),
      'net': format(netValue),
    };
  }

  void _showSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: AppRadius.largeRadius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BalanceTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: AppRadius.mediumRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _EarningRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
