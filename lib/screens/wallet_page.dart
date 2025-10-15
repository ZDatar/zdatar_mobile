import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../app_icons.dart';

// Data models
class WalletBalance {
  final String amount;
  final String currency;
  final String usdValue;

  const WalletBalance({
    required this.amount,
    required this.currency,
    required this.usdValue,
  });
}

class Transaction {
  final String title;
  final String date;
  final String amount;
  final String currency;
  final String usdValue;
  final Widget icon;
  final bool isPositive;

  const Transaction({
    required this.title,
    required this.date,
    required this.amount,
    required this.currency,
    required this.usdValue,
    required this.icon,
    required this.isPositive,
  });
}

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  // Mock data - in a real app, this would come from a state management solution
  static const _balance = WalletBalance(
    amount: '10.08',
    currency: 'SOL',
    usdValue: '\$1200.00',
  );

  static final _transactions = [
    Transaction(
      title: 'Sent',
      date: 'Today',
      amount: '1.00',
      currency: 'SOL',
      usdValue: '\$120.00',
      icon: AppIcons.sent(),
      isPositive: false,
    ),
    Transaction(
      title: 'Received',
      date: 'Today',
      amount: '0.50',
      currency: 'SOL',
      usdValue: '\$60.50',
      icon: AppIcons.received(),
      isPositive: true,
    ),
    Transaction(
      title: 'Sent',
      date: 'Yesterday',
      amount: '1.50',
      currency: 'SOL',
      usdValue: '\$180',
      icon: AppIcons.sent(),
      isPositive: false,
    ),
    Transaction(
      title: 'Rewards',
      date: 'Yesterday',
      amount: '1.00',
      currency: 'SOL',
      usdValue: '\$120.00',
      icon: AppIcons.received(),
      isPositive: true,
    ),
    Transaction(
      title: 'Received',
      date: 'Aug 12',
      amount: '2.00',
      currency: 'SOL',
      usdValue: '\$240.00',
      icon: AppIcons.received(),
      isPositive: true,
    ),
    Transaction(
      title: 'Sent',
      date: 'Aug 13',
      amount: '0.10',
      currency: 'SOL',
      usdValue: '\$12.00',
      icon: AppIcons.sent(),
      isPositive: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildHeader(context),
              const SizedBox(height: 16),
              _buildBalanceCard(context),
              const SizedBox(height: 16),
              Expanded(child: _buildTransactionsCard(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      'Wallet',
      style: theme.textTheme.headlineMedium?.copyWith(
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: Card(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.largeRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Balance',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '${_balance.amount} ${_balance.currency}',
                style: theme.textTheme.headlineLarge,
              ),
              Text(
                '~${_balance.usdValue}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.largeRadius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Transactions',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: _buildTransactionsList(context)),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: _transactions.asMap().entries.map((entry) {
          final index = entry.key;
          final transaction = entry.value;
          return Column(
            children: [
              _buildTransactionItem(context, transaction),
              if (index < _transactions.length - 1) _buildDivider(context),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, Transaction transaction) {
    final theme = Theme.of(context);
    final amountColor = transaction.isPositive
        ? Colors.green
        : theme.colorScheme.error;
    final amountPrefix = transaction.isPositive ? '+' : '-';

    return InkWell(
      borderRadius: AppRadius.largeRadius,
      onTap: () => _onTransactionTap(transaction),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            transaction.icon,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    transaction.date,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$amountPrefix${transaction.amount} ${transaction.currency}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: amountColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '~${transaction.usdValue}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 1,
        width: double.infinity,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
      ),
    );
  }

  void _onTransactionTap(Transaction transaction) {
    // Handle transaction tap - navigate to transaction details, etc.
    debugPrint('Tapped on transaction: ${transaction.title}');
  }
}
