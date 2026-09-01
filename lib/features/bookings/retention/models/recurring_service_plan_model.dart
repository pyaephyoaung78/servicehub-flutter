class RecurringServicePlanModel {
  final int id;
  final String serviceName;
  final int intervalDays;
  final int reminderDaysBefore;
  final DateTime nextReminderAt;
  final bool isActive;

  const RecurringServicePlanModel({
    required this.id,
    required this.serviceName,
    required this.intervalDays,
    required this.reminderDaysBefore,
    required this.nextReminderAt,
    required this.isActive,
  });

  factory RecurringServicePlanModel.fromJson(Map<String, dynamic> json) =>
      RecurringServicePlanModel(
        id: json['id'] as int,
        serviceName: json['service_name'].toString(),
        intervalDays: (json['interval_days'] as num).toInt(),
        reminderDaysBefore: (json['reminder_days_before'] as num).toInt(),
        nextReminderAt: DateTime.parse(
          json['next_reminder_at'].toString(),
        ).toLocal(),
        isActive: json['is_active'] == true,
      );
}
