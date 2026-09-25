import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/widgets/empty_state.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: EgtEmptyState(
        title: context.l10n.errorNotFound,
        actionLabel: context.l10n.navHome,
        onAction: () => context.go('/home'),
      ),
    );
  }
}
