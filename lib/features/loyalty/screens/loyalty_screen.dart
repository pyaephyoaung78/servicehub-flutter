import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_laravel_testing/core/errors/api_error_handler.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/loyalty_models.dart';
import '../services/loyalty_api_service.dart';

class LoyaltyScreen extends StatefulWidget {
  const LoyaltyScreen({super.key});

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> {
  late final LoyaltyApiService loyaltyApiService;
  LoyaltySummary? summary;
  List<LoyaltyRewardModel> rewards = [];
  List<LoyaltyTransactionModel> transactions = [];
  List<LoyaltyRedemptionModel> redemptions = [];
  bool isLoading = true;
  int? redeemingRewardId;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loyaltyApiService = LoyaltyApiService(
      apiClient: ApiClient(tokenStorage: TokenStorage()),
    );
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final results = await Future.wait([
        loyaltyApiService.getSummary(),
        loyaltyApiService.getRewards(),
        loyaltyApiService.getTransactions(),
        loyaltyApiService.getRedemptions(),
      ]);
      if (!mounted) return;
      setState(() {
        summary = results[0] as LoyaltySummary;
        rewards = results[1] as List<LoyaltyRewardModel>;
        transactions = results[2] as List<LoyaltyTransactionModel>;
        redemptions = results[3] as List<LoyaltyRedemptionModel>;
      });
    } catch (error) {
      if (mounted) {
        setState(() => errorMessage = ApiErrorHandler.message(error));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _copyReferralCode() async {
    final code = summary?.referralCode;
    if (code == null || code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Referral code copied.')));
  }

  Future<void> _redeem(LoyaltyRewardModel reward) async {
    final available = summary?.pointsBalance ?? 0;
    if (available < reward.pointsCost) {
      _showMessage(
        'You need ${reward.pointsCost - available} more points for this reward.',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Redeem ${reward.name}?'),
        content: Text(
          '${reward.pointsCost} points will be reserved while the ServiceHub team reviews this reward.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Redeem'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => redeemingRewardId = reward.id);
    try {
      await loyaltyApiService.redeem(reward.id);
      if (!mounted) return;
      _showMessage('Reward submitted for review.');
      await _loadData();
    } catch (error) {
      if (mounted) _showMessage(ApiErrorHandler.message(error));
    } finally {
      if (mounted) setState(() => redeemingRewardId = null);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '';
    return '${value.day}/${value.month}/${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ServiceHub Rewards')),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Builder(
          builder: (context) {
            if (isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (errorMessage != null) {
              return ListView(
                children: [
                  const SizedBox(height: 180),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(errorMessage!, textAlign: TextAlign.center),
                    ),
                  ),
                ],
              );
            }

            final currentSummary = summary!;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Your available points'),
                        const SizedBox(height: 6),
                        Text(
                          '${currentSummary.pointsBalance}',
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        const SizedBox(height: 16),
                        const Text('Invite a friend'),
                        const SizedBox(height: 4),
                        Text(
                          'They receive ${currentSummary.referredCustomerPoints} points after their first completed service. You receive ${currentSummary.referrerPoints} points too.',
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _copyReferralCode,
                          icon: const Icon(Icons.content_copy_outlined),
                          label: Text(
                            'Copy code: ${currentSummary.referralCode}',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Rewards', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                if (rewards.isEmpty)
                  const Card(
                    child: ListTile(
                      title: Text('Rewards will be available soon.'),
                    ),
                  )
                else
                  ...rewards.map(
                    (reward) => Card(
                      child: ListTile(
                        title: Text(reward.name),
                        subtitle: Text(
                          '${reward.pointsCost} points${reward.description == null ? '' : '\n${reward.description}'}',
                        ),
                        isThreeLine: reward.description != null,
                        trailing: redeemingRewardId == reward.id
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : FilledButton(
                                onPressed: redeemingRewardId == null
                                    ? () => _redeem(reward)
                                    : null,
                                child: const Text('Redeem'),
                              ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  'Your reward requests',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (redemptions.isEmpty)
                  const Card(
                    child: ListTile(title: Text('No rewards redeemed yet.')),
                  )
                else
                  ...redemptions.map(
                    (redemption) => Card(
                      child: ListTile(
                        leading: Icon(
                          redemption.status == 'approved'
                              ? Icons.verified_outlined
                              : Icons.pending_outlined,
                        ),
                        title: Text(redemption.rewardName),
                        subtitle: Text(
                          '${redemption.pointsCost} points · ${redemption.status.toUpperCase()}${redemption.status == 'approved' ? '\nCode: ${redemption.redemptionCode}' : ''}${redemption.reviewNote == null ? '' : '\n${redemption.reviewNote}'}',
                        ),
                        isThreeLine:
                            redemption.status == 'approved' ||
                            redemption.reviewNote != null,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  'Points activity',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (transactions.isEmpty)
                  const Card(
                    child: ListTile(
                      title: Text(
                        'Complete a service to earn your first points.',
                      ),
                    ),
                  )
                else
                  ...transactions.map(
                    (transaction) => Card(
                      child: ListTile(
                        leading: Icon(
                          transaction.points >= 0
                              ? Icons.add_circle_outline
                              : Icons.remove_circle_outline,
                          color: transaction.points >= 0
                              ? Colors.green
                              : Colors.redAccent,
                        ),
                        title: Text(transaction.description),
                        subtitle: Text(_formatDate(transaction.createdAt)),
                        trailing: Text(
                          '${transaction.points > 0 ? '+' : ''}${transaction.points}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
