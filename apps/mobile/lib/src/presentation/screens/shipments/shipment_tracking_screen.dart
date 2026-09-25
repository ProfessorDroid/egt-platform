import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/egt_colors.dart';
import '../../../core/theme/egt_dimens.dart';
import '../../../core/widgets/egt_button.dart';
import '../../../core/widgets/egt_text_field.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../domain/entities/trade.dart';
import '../../providers/core_providers.dart';
import '../../providers/trade_providers.dart';
import 'shipment_detail_screen.dart';

/// Public shipment tracking: enter tracking / order / shipment ID.
/// Results ALWAYS label data "Last verified update" — never fabricated realtime.
class ShipmentTrackingScreen extends ConsumerStatefulWidget {
  const ShipmentTrackingScreen({super.key});

  @override
  ConsumerState<ShipmentTrackingScreen> createState() =>
      _ShipmentTrackingScreenState();
}

class _ShipmentTrackingScreenState
    extends ConsumerState<ShipmentTrackingScreen> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _error;
  Shipment? _result;

  @override
  void initState() {
    super.initState();
    final q = GoRouterState.of(context).uri.queryParameters['q'];
    if (q != null && q.isNotEmpty) {
      _controller.text = q;
      WidgetsBinding.instance.addPostFrameCallback((_) => _track());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _track() async {
    final id = _controller.text.trim();
    if (id.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
      _result = null;
    });
    try {
      final shipment = await ref.read(shipmentRepositoryProvider).track(id);
      ref.read(analyticsProvider).logEvent('shipment_tracked', {'found': true});
      setState(() => _result = shipment);
    } on AppException catch (e) {
      final l10n = context.l10n;
      setState(() => _error = e.kind == AppFailureKind.notFound
          ? l10n.shipmentNotFound
          : l10n.errorGeneric);
    } catch (_) {
      setState(() => _error = context.l10n.errorGeneric);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.shipmentTrackTitle)),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(EgtDimens.s16),
              child: Column(
                children: [
                  EgtTextField(
                    hint: l10n.shipmentTrackHint,
                    controller: _controller,
                    prefixIcon: Icons.local_shipping_outlined,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _track(),
                  ),
                  const SizedBox(height: EgtDimens.s12),
                  EgtButton(
                      label: l10n.shipmentTrackCta,
                      icon: Icons.search,
                      onPressed: _track,
                      isLoading: _busy),
                  if (_error != null) ...[
                    const SizedBox(height: EgtDimens.s16),
                    Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: EgtColors.error),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!)),
                      ],
                    ),
                  ],
                  if (_result != null) ...[
                    const SizedBox(height: EgtDimens.s16),
                    ShipmentCard(shipment: _result!),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
