import 'package:flutter/material.dart';
import 'package:flutter_laravel_testing/core/errors/api_error_handler.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/recurring_service_plan_model.dart';
import '../services/recurring_service_plan_api_service.dart';

class ServicePlansScreen extends StatefulWidget {
  final int? bookingId;
  final String? serviceName;
  const ServicePlansScreen({this.bookingId, this.serviceName, super.key});
  @override
  State<ServicePlansScreen> createState() => _ServicePlansScreenState();
}

class _ServicePlansScreenState extends State<ServicePlansScreen> {
  late final RecurringServicePlanApiService api;
  List<RecurringServicePlanModel> plans = [];
  bool loading = true;
  bool saving = false;
  int intervalDays = 90;

  @override
  void initState() {
    super.initState();
    api = RecurringServicePlanApiService(
      apiClient: ApiClient(tokenStorage: TokenStorage()),
    );
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await api.plans();
      if (mounted) setState(() => plans = items);
    } catch (error) {
      if (mounted) _message(ApiErrorHandler.message(error));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _create() async {
    if (widget.bookingId == null || saving) return;
    setState(() => saving = true);
    try {
      await api.create(widget.bookingId!, intervalDays);
      if (!mounted) return;
      _message('Maintenance plan saved.');
      await _load();
    } catch (error) {
      if (mounted) _message(ApiErrorHandler.message(error));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _toggle(RecurringServicePlanModel plan, bool active) async {
    try {
      await api.setActive(plan.id, active);
      await _load();
    } catch (error) {
      if (mounted) _message(ApiErrorHandler.message(error));
    }
  }

  void _message(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
  String _date(DateTime value) => '${value.day}/${value.month}/${value.year}';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Service plans')),
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.bookingId != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Maintain ${widget.serviceName}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'We will remind you before your next service is due. You will always choose whether to make a booking.',
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: intervalDays,
                      decoration: const InputDecoration(
                        labelText: 'Service interval',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 30, child: Text('Every month')),
                        DropdownMenuItem(
                          value: 60,
                          child: Text('Every 2 months'),
                        ),
                        DropdownMenuItem(
                          value: 90,
                          child: Text('Every 3 months'),
                        ),
                        DropdownMenuItem(
                          value: 180,
                          child: Text('Every 6 months'),
                        ),
                        DropdownMenuItem(value: 365, child: Text('Every year')),
                      ],
                      onChanged: saving
                          ? null
                          : (value) => setState(() => intervalDays = value!),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: saving ? null : _create,
                      child: Text(saving ? 'Saving...' : 'Start service plan'),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text('Your plans', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (plans.isEmpty)
            const Card(
              child: ListTile(title: Text('No active service plans yet.')),
            )
          else
            ...plans.map(
              (plan) => Card(
                child: SwitchListTile(
                  value: plan.isActive,
                  onChanged: (value) => _toggle(plan, value),
                  title: Text(plan.serviceName),
                  subtitle: Text(
                    'Every ${plan.intervalDays} days · Next reminder ${_date(plan.nextReminderAt)}',
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
