import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/deal.dart';
import '../services/deals_service.dart';

class DealDetailPage extends StatefulWidget {
  final String dealId;
  final VoidCallback? onBack;

  const DealDetailPage({
    super.key,
    required this.dealId,
    this.onBack,
  });

  @override
  State<DealDetailPage> createState() => _DealDetailPageState();
}

class _DealDetailPageState extends State<DealDetailPage> {
  final DealsService _dealsService = DealsService();
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

    // TODO: Replace with actual seller wallet from user profile/authentication
    const sellerWallet = 'YOUR_WALLET_ADDRESS_HERE';
    
    final success = await _dealsService.acceptDeal(widget.dealId, sellerWallet);
    
    if (mounted) {
      setState(() {
        _isAccepting = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Center(child: Text('Deal accepted successfully!')),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh deal details
        _fetchDealDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Center(child: Text('Failed to accept deal')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.colorScheme.primary,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
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
    final dataType = deal.dealMeta?.dataType ?? 'Data';
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
                            Text(
                              icon,
                              style: const TextStyle(fontSize: 80),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              dataType,
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
                        value: deal.dealId.substring(0, 8) + '...',
                        theme: theme,
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: 'Buyer Wallet',
                        value: deal.buyerWallet.substring(0, 8) + '...',
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
                        value: deal.solanaTxHash.substring(0, 8) + '...',
                        theme: theme,
                      ),
                      if (deal.dealMeta?.dataCategory != null) ...[
                        const SizedBox(height: 8),
                        _InfoRow(
                          label: 'Data Category',
                          value: deal.dealMeta!.dataCategory,
                          theme: theme,
                        ),
                      ],
                      if (deal.dealMeta?.dataSubcategories.isNotEmpty == true) ...[
                        const SizedBox(height: 8),
                        _InfoRow(
                          label: 'Subcategories',
                          value: deal.dealMeta!.dataSubcategories.join(', '),
                          theme: theme,
                        ),
                      ],
                      if (deal.dealMeta?.dataFieldsRequired.isNotEmpty == true) ...[
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
                          children: deal.dealMeta!.dataFieldsRequired.map((field) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: theme.colorScheme.secondary.withValues(alpha: 0.3),
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
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
