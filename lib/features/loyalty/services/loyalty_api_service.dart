import '../../../core/network/api_client.dart';
import '../models/loyalty_models.dart';

class LoyaltyApiService {
  final ApiClient apiClient;

  LoyaltyApiService({required this.apiClient});

  Future<LoyaltySummary> getSummary() async {
    final response = await apiClient.dio.get('/customer/loyalty');
    return LoyaltySummary.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<List<LoyaltyRewardModel>> getRewards() async {
    final response = await apiClient.dio.get('/customer/loyalty/rewards');
    final items = response.data['data']['rewards'] as List;
    return items
        .map(
          (item) => LoyaltyRewardModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<LoyaltyTransactionModel>> getTransactions() async {
    final response = await apiClient.dio.get('/customer/loyalty/transactions');
    final items = response.data['data']['data'] as List;
    return items
        .map(
          (item) =>
              LoyaltyTransactionModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<LoyaltyRedemptionModel>> getRedemptions() async {
    final response = await apiClient.dio.get('/customer/loyalty/redemptions');
    final items = response.data['data']['data'] as List;
    return items
        .map(
          (item) =>
              LoyaltyRedemptionModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> redeem(int rewardId) async {
    await apiClient.dio.post('/customer/loyalty/rewards/$rewardId/redeem');
  }
}
