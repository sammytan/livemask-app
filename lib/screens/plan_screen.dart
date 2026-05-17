import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/billing_models.dart';
import '../providers/billing_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_constants.dart';
import '../widgets/livemask_widgets.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_banner.dart';

/// Plan / Subscription screen with real billing data.
class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    await Future.wait([
      ref.read(billingPlansStateProvider.notifier).refresh(),
      ref.read(subscriptionStateProvider.notifier).refresh(),
      ref.read(billingHistoryStateProvider.notifier).refresh(),
    ]);
  }

  Future<void> _handleCheckout(String planId) async {
    final success = await ref.read(checkoutStateProvider.notifier).checkout(planId);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subscription updated successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checkout failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final plansState = ref.watch(billingPlansStateProvider);
    final subState = ref.watch(subscriptionStateProvider);
    final historyState = ref.watch(billingHistoryStateProvider);
    final checkoutState = ref.watch(checkoutStateProvider);
    final theme = Theme.of(context);

    final subscription = subState.effective;
    final isCheckoutLoading = checkoutState is AsyncLoading;

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, size: 20),
                      onPressed: () => Navigator.of(context).maybePop(),
                      visualDensity: VisualDensity.compact,
                    ),
                    const Expanded(
                      child: Text(
                        'Plan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (plansState.isLoading || subState.isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        onPressed: _refresh,
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Body
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Stale/subscription error banners
                  if (subState.isFromCache)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ErrorBanner.warning(
                        'Showing cached subscription data',
                      ),
                    ),
                  if (subState.hasError && subState.isFromCache)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ErrorBanner.danger(
                        'Failed to refresh subscription',
                        message: subState.errorMessage,
                      ),
                    ),
                  if (plansState.hasError && !plansState.isFromCache)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ErrorBanner.danger(
                        'Could not load plans',
                        message: plansState.errorMessage,
                        actions: [
                          TextButton(
                            onPressed: () =>
                                ref.read(billingPlansStateProvider.notifier).refresh(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),

                  // Current Subscription Card
                  _CurrentPlanCard(
                    subscription: subscription,
                    plans: plansState.plans,
                  ),

                  const SizedBox(height: 24),

                  // Available Plans
                  Text(
                    'AVAILABLE PLANS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (plansState.isLoading && !plansState.hasData)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (plansState.hasData)
                    ...plansState.plans.map((plan) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _PlanCard(
                            plan: plan,
                            isCurrentPlan: plan.planId == subscription.planId,
                            isLoading: isCheckoutLoading,
                            onSelect: () => _handleCheckout(plan.planId),
                          ),
                        ))
                  else if (plansState.hasError && !plansState.hasData)
                    EmptyState(
                      icon: Icons.credit_card_outlined,
                      title: 'Could not load plans',
                      message: plansState.errorMessage,
                      action: () =>
                          ref.read(billingPlansStateProvider.notifier).refresh(),
                      actionLabel: 'Retry',
                    ),

                  const SizedBox(height: 24),

                  // Billing History
                  _BillingHistorySection(historyState: historyState),

                  const SizedBox(height: 24),

                  // Rewards placeholder
                  LiveMaskCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome,
                            size: 20, color: AppColors.muted),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Rewards are coming soon',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Earn points and unlock exclusive benefits.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Current subscription status card.
class _CurrentPlanCard extends StatelessWidget {
  const _CurrentPlanCard({
    required this.subscription,
    required this.plans,
  });

  final SubscriptionInfo subscription;
  final List<BillingPlan> plans;

  Color _statusBg(String color) {
    switch (color) {
      case 'green':
        return AppColors.successBg;
      case 'amber':
        return AppColors.warningBg;
      case 'red':
        return AppColors.dangerBg;
      default:
        return AppColors.muted.withOpacity(0.1);
    }
  }

  Color _statusFg(String color) {
    switch (color) {
      case 'green':
        return const Color(0xFF166534);
      case 'amber':
        return const Color(0xFF92400E);
      case 'red':
        return const Color(0xFF991B1B);
      default:
        return AppColors.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = plans.where((p) => p.planId == subscription.planId).firstOrNull;
    final planName = plan?.name ?? (subscription.isFree ? 'Free' : subscription.planId);
    final colors = subscription.statusColor;

    return LiveMaskCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.card_giftcard, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Current Plan',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusBg(colors),
                  borderRadius: BorderRadius.circular(AppConstants.radiusXs),
                ),
                child: Text(
                  subscription.statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _statusFg(colors),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            planName,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.devices_outlined,
                  size: 16, color: AppColors.muted),
              const SizedBox(width: 6),
              Text(
                '${subscription.deviceUsed}/${subscription.deviceLimit} devices used',
                style: TextStyle(fontSize: 13, color: AppColors.muted),
              ),
            ],
          ),
          if (subscription.currentPeriodEnd != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 16, color: AppColors.muted),
                const SizedBox(width: 6),
                Text(
                  'Renews ${_formatDate(subscription.currentPeriodEnd!)}',
                  style: TextStyle(fontSize: 13, color: AppColors.muted),
                ),
              ],
            ),
          ],
          if (subscription.cancelAtPeriodEnd) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 16, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your plan will not renew. You can resubscribe at any time.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.warning.withOpacity(0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.month}/${dt.day}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

/// A single plan card with Select/Upgrade/Current actions.
class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.isCurrentPlan,
    required this.isLoading,
    required this.onSelect,
  });

  final BillingPlan plan;
  final bool isCurrentPlan;
  final bool isLoading;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final isPopular = plan.planId == 'premium_monthly';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(
          color: isCurrentPlan
              ? AppColors.primary
              : isPopular
                  ? AppColors.primary.withOpacity(0.4)
                  : Theme.of(context).colorScheme.outlineVariant,
          width: isCurrentPlan ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    plan.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isPopular && !isCurrentPlan)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'POPULAR',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                if (isCurrentPlan)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.successBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'CURRENT',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF166534),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  plan.priceDescription,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: plan.isFree ? AppColors.muted : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${plan.deviceLimit} device${plan.deviceLimit == 1 ? '' : 's'} · ${plan.nodeAccess} access',
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            ...plan.features.map((f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          f,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: isCurrentPlan
                  ? OutlinedButton(
                      onPressed: null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.muted,
                      ),
                      child: const Text('Current Plan'),
                    )
                  : FilledButton(
                      onPressed: isLoading ? null : onSelect,
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(plan.isFree ? 'Get Started' : 'Upgrade'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Billing history section.
class _BillingHistorySection extends StatelessWidget {
  const _BillingHistorySection({required this.historyState});

  final BillingHistoryState historyState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (historyState.isLoading && !historyState.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    if (historyState.hasError && !historyState.hasData) {
      return ErrorBanner.danger(
        'Could not load billing history',
        message: historyState.errorMessage,
      );
    }

    if (historyState.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (historyState.isFromCache)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ErrorBanner.warning('Showing cached billing history'),
          ),
        Text(
          'BILLING HISTORY',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 12),
        ...historyState.items.map((item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  bottom: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.planId,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '#${item.invoiceId.length > 12 ? '${item.invoiceId.substring(0, 12)}...' : item.invoiceId}',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        item.amountFormatted,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      _statusChip(item),
                    ],
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _statusChip(BillingHistoryItem item) {
    final (Color bg, Color fg, String label) = switch (item.status) {
      'paid' => (AppColors.successBg, const Color(0xFF166534), 'Paid'),
      'pending' => (AppColors.warningBg, const Color(0xFF92400E), 'Pending'),
      'failed' => (AppColors.dangerBg, const Color(0xFF991B1B), 'Failed'),
      _ => (AppColors.muted.withOpacity(0.1), AppColors.muted, item.status),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}
