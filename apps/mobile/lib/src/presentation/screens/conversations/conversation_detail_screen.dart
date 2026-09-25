import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/egt_colors.dart';
import '../../../core/theme/egt_dimens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/egt_text_field.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../domain/entities/account.dart';
import '../../providers/account_providers.dart';
import '../../providers/core_providers.dart';

/// Scoped conversation thread. `scope` is 'rfq' or 'order' (from the route);
/// there is no global chat. Attachment upload is not yet in the backend
/// contract, so the thread is text-only for now (documented gap).
class ConversationDetailScreen extends ConsumerStatefulWidget {
  const ConversationDetailScreen({
    super.key,
    required this.scope,
    required this.scopeId,
  });

  final String scope; // 'rfq' | 'order'
  final String scopeId;

  @override
  ConsumerState<ConversationDetailScreen> createState() =>
      _ConversationDetailScreenState();
}

class _ConversationDetailScreenState
    extends ConsumerState<ConversationDetailScreen> {
  final _input = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(conversationRepositoryProvider).markRead(
          scope: widget.scope, scopeId: widget.scopeId);
      ref.invalidate(conversationsProvider);
    });
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ref.read(conversationRepositoryProvider).send(
            scope: widget.scope,
            scopeId: widget.scopeId,
            body: text,
          );
      ref.read(analyticsProvider).logEvent('conversation_message_sent',
          {'scope': widget.scope, 'scope_id': widget.scopeId});
      _input.clear();
      ref.invalidate(conversationMessagesProvider(
          (scope: widget.scope, scopeId: widget.scopeId)));
    } on AppException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.errorGeneric)));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final messages = ref.watch(conversationMessagesProvider(
        (scope: widget.scope, scopeId: widget.scopeId)));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.scope == 'order' ? l10n.convOrder : l10n.convRfq),
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: messages.when(
              data: (list) {
                if (list.isEmpty) {
                  return EgtEmptyState(
                      icon: Icons.chat_bubble_outline,
                      body: l10n.convEmpty);
                }
                return ListView.separated(
                  reverse: true,
                  padding: const EdgeInsets.all(EgtDimens.s16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: EgtDimens.s8),
                  itemBuilder: (_, i) => _MessageBubble(message: list[i]),
                );
              },
              loading: () => const EgtSkeletonList(),
              error: (e, _) => EgtErrorView(
                  error: e,
                  onRetry: () => ref.invalidate(
                      conversationMessagesProvider(
                          (scope: widget.scope, scopeId: widget.scopeId)))),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: EgtTextField(
                      hint: l10n.convHint,
                      controller: _input,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _sending
                      ? const SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(
                              color: EgtColors.red))
                      : IconButton.filled(
                          onPressed: _send,
                          icon: const Icon(Icons.send),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
          message.fromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.all(EgtDimens.s12),
        decoration: BoxDecoration(
          color: message.fromMe ? EgtColors.red : EgtColors.manifest,
          borderRadius: BorderRadius.circular(EgtDimens.radius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!message.fromMe && message.senderName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(message.senderName!,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ),
            Text(message.body,
                style: TextStyle(
                    color:
                        message.fromMe ? Colors.white : EgtColors.ink)),
            const SizedBox(height: 4),
            Text(formatDateTime(message.at),
                style: TextStyle(
                    fontSize: 10,
                    color: message.fromMe
                        ? Colors.white70
                        : EgtColors.steel)),
          ],
        ),
      ),
    );
  }
}
