import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/assets/brand_assets.dart';
import '../../../core/company/company_info.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/egt_colors.dart';
import '../../../core/theme/egt_dimens.dart';
import '../../../core/utils/launch_helper.dart';
import '../../../core/widgets/egt_app_bar.dart';
import '../../../core/widgets/egt_button.dart';
import '../../../core/widgets/egt_text_field.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/product_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../domain/entities/catalog.dart';
import '../../providers/catalog_providers.dart';
import '../../providers/core_providers.dart';

/// Home: hero + backend-driven sections with graceful empty states.
/// Verified facts (hero copy, stats, sectors) come from [CompanyInfo];
/// products come ONLY from the backend — never invented.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(homeContentProvider);
    ref.read(analyticsProvider).logEvent('app_opened', {'screen': 'home'});

    return Scaffold(
      appBar: const EgtHomeAppBar(),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(homeContentProvider),
              child: home.when(
                data: (content) => _HomeBody(content: content),
                loading: () => const EgtSkeletonList(itemCount: 5),
                error: (e, _) => EgtErrorView(
                    error: e,
                    onRetry: () => ref.invalidate(homeContentProvider)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.content});
  final HomeContent content;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stats = content.stats.isNotEmpty
        ? content.stats
        : CompanyInfo.stats
            .map((s) => StatTile(value: s.$1, label: s.$2))
            .toList();
    final sectors = content.sectors.isNotEmpty
        ? content.sectors.map((s) => s.name).toList()
        : CompanyInfo.featuredSectors;

    return ListView(
      children: [
        _Hero(
          title: content.heroTitle ?? l10n.homeHeroTitle,
          subtitle: content.heroSubtitle ?? l10n.homeHeroSubtitle,
        ),
        // Quick RFQ
        SectionHeader(title: l10n.homeSectionQuickRfq),
        _QuickRfqRow(categories: content.quickRfqCategories),
        // Popular products (backend only)
        if (content.popularProducts.isNotEmpty) ...[
          SectionHeader(
              title: l10n.homeSectionPopular,
              onViewAll: () => context.push('/products')),
          _ProductCarousel(products: content.popularProducts),
        ],
        // Categories / sectors (verified site data)
        SectionHeader(title: l10n.homeSectionCategories),
        _SectorGrid(sectors: sectors),
        // Private label teaser
        _TeaserCard(
          title: l10n.homePrivateLabelTitle,
          body: l10n.homePrivateLabelBody,
          cta: l10n.homePrivateLabelCta,
          icon: Icons.branding_watermark_outlined,
          onTap: () => context.push('/private-label/new'),
        ),
        // Global sourcing teaser
        _TeaserCard(
          title: l10n.homeSourcingTitle,
          body: l10n.homeSourcingBody,
          cta: l10n.homeSourcingCta,
          icon: Icons.public_outlined,
          onTap: () => context.push('/rfq/smart'),
        ),
        // Why EGT (verified stats)
        SectionHeader(title: l10n.homeWhyTitle),
        _StatsGrid(stats: stats),
        _RegisteredPills(),
        // Supplier opportunity
        _TeaserCard(
          title: l10n.homeSupplierTitle,
          body: l10n.homeSupplierBody,
          cta: l10n.homeSupplierCta,
          icon: Icons.factory_outlined,
          onTap: () => context.push('/supplier'),
        ),
        // Shipment tracking
        SectionHeader(title: l10n.homeSectionTracking),
        const _TrackingCard(),
        // Featured products (backend only)
        if (content.featuredProducts.isNotEmpty) ...[
          SectionHeader(
              title: l10n.homeSectionFeatured,
              onViewAll: () => context.push('/products')),
          _ProductCarousel(products: content.featuredProducts),
        ],
        // Contact EGT (verified contact facts only — no email)
        SectionHeader(title: l10n.homeSectionContact),
        _ContactCard(),
        const SizedBox(height: EgtDimens.s32),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Stack(
      children: [
        SizedBox(
          height: 300,
          width: double.infinity,
          child: Image.asset(BrandAssets.heroShipping,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: EgtColors.harbor)),
        ),
        Container(
          height: 300,
          decoration: BoxDecoration(
            color: EgtColors.harbor.withOpacity(0.55),
          ),
        ),
        SizedBox(
          height: 300,
          child: Padding(
            padding: const EdgeInsets.all(EgtDimens.s24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .displayMedium
                        ?.copyWith(color: Colors.white)),
                const SizedBox(height: EgtDimens.s8),
                Text(subtitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white.withOpacity(0.92)),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: EgtDimens.s16),
                Row(
                  children: [
                    Expanded(
                      child: EgtButton(
                          label: l10n.homeStartRfq,
                          onPressed: () => context.push('/rfq/new')),
                    ),
                    const SizedBox(width: EgtDimens.s12),
                    Expanded(
                      child: EgtOutlineButton(
                        label: l10n.homeExploreProducts,
                        onPressed: () => context.push('/products'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickRfqRow extends StatelessWidget {
  const _QuickRfqRow({required this.categories});
  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: EgtOutlineButton(
          label: context.l10n.homeStartRfq,
          icon: Icons.request_quote_outlined,
          onPressed: () => context.push('/rfq/new'),
        ),
      );
    }
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => ActionChip(
          label: Text(categories[i].name),
          onPressed: () => context.push(
              '/rfq/new?categoryId=${categories[i].id}&categoryName=${Uri.encodeComponent(categories[i].name)}'),
        ),
      ),
    );
  }
}

class _ProductCarousel extends StatelessWidget {
  const _ProductCarousel({required this.products});
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) =>
            SizedBox(width: 190, child: ProductCard(product: products[i])),
      ),
    );
  }
}

class _SectorGrid extends StatelessWidget {
  const _SectorGrid({required this.sectors});
  final List<String> sectors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: sectors
            .map((s) => ActionChip(
                  label: Text(s, style: const TextStyle(fontSize: 12)),
                  onPressed: () => context.push('/rfq/new'),
                ))
            .toList(),
      ),
    );
  }
}

class _TeaserCard extends StatelessWidget {
  const _TeaserCard({
    required this.title,
    required this.body,
    required this.cta,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String body;
  final String cta;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card(
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
                      borderRadius: BorderRadius.circular(EgtDimens.radius)),
                  child: Icon(icon, color: EgtColors.red),
                ),
                const SizedBox(width: EgtDimens.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(body,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Text(cta,
                          style: const TextStyle(
                              color: EgtColors.red,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: EgtColors.steel),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});
  final List<StatTile> stats;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
        ),
        itemCount: stats.length,
        itemBuilder: (_, i) => Container(
          decoration: BoxDecoration(
            color: EgtColors.harbor,
            borderRadius: BorderRadius.circular(EgtDimens.radius),
          ),
          padding: const EdgeInsets.all(EgtDimens.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(stats[i].value,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: EgtColors.gold)),
              const SizedBox(height: 4),
              Text(stats[i].label,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegisteredPills extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.homeRegisteredBusiness,
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CompanyInfo.registrationPills
                .map((p) => Chip(
                      avatar: const Icon(Icons.verified_outlined,
                          size: 16, color: EgtColors.success),
                      label: Text(p, style: const TextStyle(fontSize: 12)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _TrackingCard extends StatefulWidget {
  const _TrackingCard();

  @override
  State<_TrackingCard> createState() => _TrackingCardState();
}

class _TrackingCardState extends State<_TrackingCard> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(EgtDimens.s16),
          child: Column(
            children: [
              EgtTextField(
                hint: l10n.homeTrackingHint,
                controller: _controller,
                prefixIcon: Icons.local_shipping_outlined,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _track(),
              ),
              const SizedBox(height: EgtDimens.s12),
              EgtButton(
                  label: l10n.actionTrack,
                  icon: Icons.search,
                  onPressed: _track),
            ],
          ),
        ),
      ),
    );
  }

  void _track() {
    final id = _controller.text.trim();
    if (id.isEmpty) return;
    context.push('/shipments/track?q=${Uri.encodeComponent(id)}');
  }
}

class _ContactCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: EgtColors.harbor,
        child: Padding(
          padding: const EdgeInsets.all(EgtDimens.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(CompanyInfo.phoneDisplay,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: Colors.white)),
              const SizedBox(height: 4),
              Text(CompanyInfo.address,
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: EgtDimens.s16),
              Row(
                children: [
                  Expanded(
                    child: EgtButton(
                        label: l10n.homeContactCall,
                        icon: Icons.phone,
                        onPressed: LaunchHelper.callPhone),
                  ),
                  const SizedBox(width: EgtDimens.s12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: LaunchHelper.openWhatsApp,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                        minimumSize:
                            const Size(64, EgtDimens.minTouchTarget),
                      ),
                      child: Text(l10n.homeContactWhatsapp),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: EgtDimens.s8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => context.push('/contact'),
                  child: Text(l10n.homeContactEnquiry,
                      style: const TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
