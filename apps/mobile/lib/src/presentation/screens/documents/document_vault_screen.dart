import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/egt_colors.dart';
import '../../../core/theme/egt_dimens.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../domain/entities/account.dart';
import '../../providers/account_providers.dart';
import '../../providers/core_providers.dart';

/// Document vault: categories, preview where possible, downloads via
/// backend-issued signed URLs only.
class DocumentVaultScreen extends ConsumerWidget {
  const DocumentVaultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final categories = ref.watch(documentCategoriesProvider);
    final selected = ref.watch(_docCategoryProvider);
    final docs = ref.watch(documentsProvider(selected));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.docsTitle)),
      body: Column(
        children: [
          const OfflineBanner(),
          categories.maybeWhen(
            data: (cats) => cats.isEmpty
                ? const SizedBox.shrink()
                : SizedBox(
                    height: 48,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: cats.length + 1,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final cat = i == 0 ? null : cats[i - 1];
                        final label = cat ?? l10n.actionViewAll;
                        return ChoiceChip(
                          label: Text(label,
                              style: const TextStyle(fontSize: 12)),
                          selected: selected == cat,
                          onSelected: (_) => ref
                              .read(_docCategoryProvider.notifier)
                              .state = cat,
                        );
                      },
                    ),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(documentsProvider(selected));
              },
              child: docs.when(
                data: (list) {
                  if (list.isEmpty) {
                    return EgtEmptyState(
                        icon: Icons.folder_outlined,
                        body: l10n.docsEmpty);
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(EgtDimens.s16),
                    itemCount: list.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: EgtDimens.s8),
                    itemBuilder: (_, i) =>
                        _DocumentRow(document: list[i]),
                  );
                },
                loading: () => const EgtSkeletonList(),
                error: (e, _) => EgtErrorView(
                    error: e,
                    onRetry: () =>
                        ref.invalidate(documentsProvider(selected))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final _docCategoryProvider = StateProvider<String?>((ref) => null);

class _DocumentRow extends ConsumerWidget {
  const _DocumentRow({required this.document});
  final DocumentItem document;

  Future<void> _preview(BuildContext context, WidgetRef ref) async {
    try {
      final url =
          await ref.read(documentRepositoryProvider).signedDownloadUrl(document.id);
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } on AppException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.errorGeneric)));
      }
    }
  }

  Future<void> _share(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    try {
      final url =
          await ref.read(documentRepositoryProvider).signedDownloadUrl(document.id);
      ref.read(analyticsProvider).logEvent('document_downloaded',
          {'document_id': document.id, 'category': document.category});
      await Share.shareUri(url);
    } on AppException {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.insert_drive_file_outlined,
            color: EgtColors.red),
        title: Text(document.name,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle:
            Text(document.category, style: Theme.of(context).textTheme.bodySmall),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (document.isPreviewable)
              IconButton(
                icon: const Icon(Icons.visibility_outlined),
                tooltip: l10n.docsPreview,
                onPressed: () => _preview(context, ref),
              ),
            IconButton(
              icon: const Icon(Icons.download_outlined),
              tooltip: l10n.docsDownload,
              onPressed: () => _share(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}
