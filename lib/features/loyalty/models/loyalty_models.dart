class LoyaltySummary {
  final int pointsBalance;
  final String referralCode;
  final int completedBookingPoints;
  final int referrerPoints;
  final int referredCustomerPoints;

  const LoyaltySummary({
    required this.pointsBalance,
    required this.referralCode,
    required this.completedBookingPoints,
    required this.referrerPoints,
    required this.referredCustomerPoints,
  });

  factory LoyaltySummary.fromJson(Map<String, dynamic> json) {
    return LoyaltySummary(
      pointsBalance: (json['points_balance'] as num).toInt(),
      referralCode: json['referral_code']?.toString() ?? '',
      completedBookingPoints: (json['completed_booking_points'] as num).toInt(),
      referrerPoints: (json['referrer_points'] as num).toInt(),
      referredCustomerPoints: (json['referred_customer_points'] as num).toInt(),
    );
  }
}

class LoyaltyRewardModel {
  final int id;
  final String name;
  final String? description;
  final int pointsCost;

  const LoyaltyRewardModel({
    required this.id,
    required this.name,
    required this.description,
    required this.pointsCost,
  });

  factory LoyaltyRewardModel.fromJson(Map<String, dynamic> json) {
    return LoyaltyRewardModel(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      pointsCost: (json['points_cost'] as num).toInt(),
    );
  }
}

class LoyaltyTransactionModel {
  final int id;
  final int points;
  final String type;
  final String description;
  final DateTime? createdAt;

  const LoyaltyTransactionModel({
    required this.id,
    required this.points,
    required this.type,
    required this.description,
    required this.createdAt,
  });

  factory LoyaltyTransactionModel.fromJson(Map<String, dynamic> json) {
    return LoyaltyTransactionModel(
      id: json['id'] as int,
      points: (json['points'] as num).toInt(),
      type: json['type']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'].toString()).toLocal(),
    );
  }
}

class LoyaltyRedemptionModel {
  final int id;
  final int pointsCost;
  final String redemptionCode;
  final String status;
  final String? reviewNote;
  final String rewardName;

  const LoyaltyRedemptionModel({
    required this.id,
    required this.pointsCost,
    required this.redemptionCode,
    required this.status,
    required this.reviewNote,
    required this.rewardName,
  });

  factory LoyaltyRedemptionModel.fromJson(Map<String, dynamic> json) {
    final reward = json['reward'] as Map<String, dynamic>? ?? {};
    return LoyaltyRedemptionModel(
      id: json['id'] as int,
      pointsCost: (json['points_cost'] as num).toInt(),
      redemptionCode: json['redemption_code']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      reviewNote: json['review_note']?.toString(),
      rewardName: reward['name']?.toString() ?? 'Reward',
    );
  }
}
