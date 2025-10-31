import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/deal.dart';
import '../theme/app_colors.dart';

class WalletDetailPage extends StatefulWidget {
  const WalletDetailPage({
    super.key,
    required this.walletAddress,
    this.onRefresh,
    this.recentDeals = const [],
  });

  final String walletAddress;
  final Future<void> Function()? onRefresh;
  final List<Deal> recentDeals;

  @override
  State<WalletDetailPage> createState() => _WalletDetailPageState();
}

class _WalletDetailPageState extends State<WalletDetailPage> {
  bool _isRefreshing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Wallet details',
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWalletAddressCard(context),
              const SizedBox(height: 20),
              _buildQuickActions(context),
              if (widget.recentDeals.isNotEmpty) ...[
                const SizedBox(height: 20),
                _buildRecentActivity(context),
              ],
              const SizedBox(height: 20),
              _buildSecurityTips(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletAddressCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.largeRadius),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wallet address',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SelectableText(
              widget.walletAddress,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                _AddressButton(
                  icon: Icons.copy_rounded,
                  label: 'Copy address',
                  onTap: () {
                    Clipboard.setData(
                      ClipboardData(text: widget.walletAddress),
                    );
                    _showSnackbar('Wallet address copied');
                  },
                ),
                _AddressButton(
                  icon: Icons.refresh_rounded,
                  label: _isRefreshing ? 'Refreshing...' : 'Refresh wallet',
                  isDisabled: _isRefreshing,
                  onTap: _handleRefresh,
                ),
                _AddressButton(
                  icon: Icons.qr_code_rounded,
                  label: 'Show QR',
                  onTap: () => _showSnackbar('QR code support coming soon.'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final theme = Theme.of(context);
    final actions = [
      _DetailActionData(
        icon: Icons.backup_outlined,
        label: 'Backup wallet',
        description: 'View your recovery phrase and safety tips.',
        onTap: () => _promptBackupInstructions(context),
      ),
      _DetailActionData(
        icon: Icons.qr_code_2_rounded,
        label: 'Receive SOL',
        description: 'Share your wallet address to receive payments.',
        onTap: () => _showSnackbar('Share your address to receive funds.'),
      ),
      _DetailActionData(
        icon: Icons.send_rounded,
        label: 'Send SOL',
        description: 'Initiate outgoing transfers (coming soon).',
        onTap: () => _showSnackbar('Send functionality coming soon.'),
      ),
    ];

    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.largeRadius),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick actions',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...actions.map(
              (action) => _DetailActionTile(
                icon: action.icon,
                title: action.label,
                subtitle: action.description,
                onTap: action.onTap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.largeRadius),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent activity',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...widget.recentDeals
                .take(4)
                .map(
                  (deal) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                      child: Text(deal.icon),
                    ),
                    title: Text(
                      deal.dealMeta?.category ?? 'Data deal',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      deal.status,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityTips(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.largeRadius),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Security reminders',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...const [
              'Never screenshot or share your recovery phrase.',
              'Store backups offline in multiple secure locations.',
              'Enable device-level security (Face ID, biometrics, passcode).',
            ].map(
              (tip) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: Colors.white)),
                    Expanded(
                      child: Text(
                        tip,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.72),
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
    );
  }

  Future<void> _handleRefresh() async {
    if (widget.onRefresh == null) {
      _showSnackbar('Refresh unavailable on this screen.');
      return;
    }
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);
    try {
      await widget.onRefresh!();
      _showSnackbar('Wallet refreshed');
    } catch (e) {
      _showSnackbar('Failed to refresh wallet');
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _promptBackupInstructions(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Backup wallet'),
        content: const Text(
          'Write down your recovery phrase and store it securely. '
          'Anyone with access to the phrase can control your wallet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Okay, got it'),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _AddressButton extends StatelessWidget {
  const _AddressButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDisabled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: isDisabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: isDisabled ? 0.05 : 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white.withValues(alpha: isDisabled ? 0.5 : 1),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: isDisabled ? 0.6 : 0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailActionTile extends StatelessWidget {
  const _DetailActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: AppRadius.largeRadius,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: AppRadius.largeRadius,
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: const BoxDecoration(
                color: Colors.white12,
                shape: BoxShape.circle,
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
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}

class _DetailActionData {
  const _DetailActionData({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;
}
