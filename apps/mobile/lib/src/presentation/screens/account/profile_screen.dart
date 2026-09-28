import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/egt_dimens.dart';
import '../../../core/widgets/egt_button.dart';
import '../../../core/widgets/egt_text_field.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/skeleton.dart';
import '../../providers/account_providers.dart';

/// Profile: full name + email (phone is the account identifier and is
/// managed through support).
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  bool _busy = false;
  bool _seeded = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  void _seed() {
    if (_seeded) return;
    final user = ref.read(profileProvider).maybeWhen(
          data: (u) => u,
          orElse: () => null,
        );
    if (user == null) return;
    _name.text = user.fullName;
    _email.text = user.email ?? '';
    _seeded = true;
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(userRepositoryProvider).updateProfile(
            fullName: _name.text.trim(),
            email: _email.text.trim().isEmpty ? null : _email.text.trim(),
          );
      ref.invalidate(profileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.accountProfileSaved)));
      }
    } on AppException {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = ref.watch(profileProvider);
    _seed();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountProfile)),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: user.when(
              data: (_) => Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.all(EgtDimens.s16),
                  children: [
                    EgtTextField(
                      label: l10n.contactName,
                      controller: _name,
                      validator: (v) => requiredValidator(
                          v, l10n.rfqValidationRequired),
                    ),
                    EgtTextField(
                      label: l10n.accountEmail,
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 24),
                    EgtButton(
                        label: l10n.actionSave,
                        onPressed: _save,
                        isLoading: _busy),
                  ],
                ),
              ),
              loading: () => const EgtSkeletonList(itemCount: 2),
              error: (e, _) => Center(child: Text(l10n.errorGeneric)),
            ),
          ),
        ],
      ),
    );
  }
}
