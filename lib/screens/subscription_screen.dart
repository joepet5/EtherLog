import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/subscription_service.dart';
import '../widgets/animated_gradient_background.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  SubscriptionStatus? _status;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await SubscriptionService.getStatus();
    setState(() {
      _status = s;
      _loading = false;
    });
  }

  Future<void> _buy(SubscriptionPlan plan) async {
    setState(() => _busy = true);
    // TODO: Replace with Google Play Billing (in_app_purchase)
    await SubscriptionService.activatePlan(plan);
    await _load();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_status?.planLabel ?? 'Plan'} activated'),
        backgroundColor: AppTheme.success,
      ),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Subscription')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (_status?.canAddCases ?? false)
                    ? AppTheme.primary.withValues(alpha: 0.4)
                    : AppTheme.danger.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current status',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  _status?.planLabel ?? '—',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _status?.remainingLabel ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: (_status?.canAddCases ?? false)
                        ? AppTheme.primary
                        : AppTheme.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!(_status?.canAddCases ?? false)) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Your trial or subscription has ended. You can still view and export cases, but you cannot add new ones until you subscribe.',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'PLANS (INR)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          _planCard(
            title: '1 Month',
            price: '₹${SubscriptionService.priceMonth1}',
            subtitle: '30 days of full access',
            onTap: _busy ? null : () => _buy(SubscriptionPlan.month1),
          ),
          _planCard(
            title: '1 Year',
            price: '₹${SubscriptionService.priceYear1}',
            subtitle: 'Best for annual logbook cycle',
            highlight: true,
            onTap: _busy ? null : () => _buy(SubscriptionPlan.year1),
          ),
          _planCard(
            title: '3 Years',
            price: '₹${SubscriptionService.priceYear3}',
            subtitle: 'Long-term training access',
            onTap: _busy ? null : () => _buy(SubscriptionPlan.year3),
          ),
          _planCard(
            title: 'Lifetime',
            price: '₹${SubscriptionService.priceLifetime}',
            subtitle: 'One-time purchase, no expiry',
            onTap: _busy ? null : () => _buy(SubscriptionPlan.lifetime),
          ),
          const SizedBox(height: 12),
          Text(
            'Free trial: 1 month from first use.\n'
                'Payments will be processed via Google Play when billing is connected.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _planCard({
    required String title,
    required String price,
    required String subtitle,
    bool highlight = false,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight ? AppTheme.primary : AppTheme.surfaceLight,
          width: highlight ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Text(subtitle, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              price,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppTheme.primary,
              ),
            ),
            Text(
              'Subscribe',
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
