import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/egt_colors.dart';
import '../../../core/theme/egt_dimens.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../providers/core_providers.dart';

/// RFQ hub: new RFQ wizard, smart assistant, my RFQs.
class RfqLandingScreen extends ConsumerWidget {
  const RfqLandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.rfqTitle)),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(EgtDimens.s16),
              children: [
                Text(l10n.rfqLandingBody,
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: EgtDimens.s16),
                _Option(
                  icon: Icons.edit_note_outlined,
                  title: l10n.rfqNew,
                  subtitle: l10n.rfqLandingBody,
                  onTap: () {
                    ref.read(analyticsProvider).logEvent('rfq_started',
                        {'source': 'wizard'});
                    context.push('/rfq/new');
                  },
                ),
                const SizedBox(height: EgtDimens.s12),
                _Option(
                  icon: Icons.auto_awesome_outlined,
                  title: l10n.rfqSmart,
                  subtitle: l10n.smartExample,
                  onTap: () => context.push('/rfq/smart'),
                ),
                const SizedBox(height: EgtDimens.s12),
                _Option(
                  icon: Icons.history_outlined,
                  title: l10n.rfqMyRfqs,
                  subtitle: '',
                  onTap: () => context.push('/rfq/list'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
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
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(EgtDimens.radius),
        child: Padding(
          padding: const EdgeInsets.all(EgtDimens.s16),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                    color: EgtColors.red.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(EgtDimens.radius)),
                child: Icon(icon, color: EgtColors.red),
              ),
              const SizedBox(width: EgtDimens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context).textTheme.titleMedium),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(subtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: EgtColors.steel),
            ],
          ),
        ),
      ),
    );
  }
}
