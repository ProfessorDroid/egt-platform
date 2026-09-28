import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/egt_dimens.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/egt_button.dart';
import '../../../core/widgets/egt_text_field.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../providers/account_providers.dart';
import '../../providers/auth_providers.dart';
import '../../providers/core_providers.dart';

/// Security: change password, biometric unlock toggle, log out everywhere.
class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadBiometrics();
  }

  Future<void> _loadBiometrics() async {
    try {
      final auth = LocalAuthentication();
      final canCheck = await auth.canCheckBiometrics;
      final enabled =
          await ref.read(appPreferencesProvider).isBiometricEnabled();
      if (mounted) {
        setState(() {
          _biometricAvailable = canCheck;
          _biometricEnabled = enabled && canCheck;
        });
      }
    } catch (_) {
      // Biometrics unsupported — toggle stays hidden.
    }
  }

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final l10n = context.l10n;
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).changePassword(
            currentPassword: _current.text,
            newPassword: _next.text,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.accountPasswordChanged)));
      }
      _current.clear();
      _next.clear();
      _confirm.clear();
    } on AppException {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    final l10n = context.l10n;
    if (value) {
      try {
        final ok = await LocalAuthentication().authenticate(
          localizedReason: l10n.authBiometricUnlock,
        );
        if (!ok) return;
      } catch (_) {
        return;
      }
    }
    await ref.read(appPreferencesProvider).setBiometricEnabled(value);
    setState(() => _biometricEnabled = value);
  }

  Future<void> _logoutAll() async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.securityLogoutAllTitle,
      body: l10n.securityLogoutAllBody,
      confirmLabel: l10n.securityLogoutAll,
      destructive: true,
    );
    if (!confirmed) return;
    await ref.read(authStateProvider.notifier).logoutAllDevices();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.securityTitle)),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(EgtDimens.s16),
              children: [
                Text(l10n.securityChangePassword,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                Form(
                  key: _form,
                  child: Column(
                    children: [
                      EgtTextField(
                        label: l10n.authPassword,
                        controller: _current,
                        obscureText: true,
                        validator: (v) => requiredValidator(
                            v, l10n.rfqValidationRequired),
                      ),
                      EgtTextField(
                        label: l10n.accountNewPassword,
                        controller: _next,
                        obscureText: true,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return l10n.rfqValidationRequired;
                          }
                          if (v.length < 8) return l10n.errorValidation;
                          return null;
                        },
                      ),
                      EgtTextField(
                        label: l10n.accountConfirmPassword,
                        controller: _confirm,
                        obscureText: true,
                        validator: (v) =>
                            v != _next.text ? l10n.errorValidation : null,
                      ),
                      const SizedBox(height: 12),
                      EgtButton(
                          label: l10n.securityChangePassword,
                          onPressed: _changePassword,
                          isLoading: _busy),
                    ],
                  ),
                ),
                const SizedBox(height: EgtDimens.s24),
                Text(l10n.securityBiometric,
                    style: Theme.of(context).textTheme.headlineSmall),
                if (_biometricAvailable)
                  SwitchListTile(
                    title: Text(l10n.securityBiometric),
                    subtitle: Text(l10n.securityBiometricBody),
                    value: _biometricEnabled,
                    onChanged: _toggleBiometric,
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(l10n.securityBiometricUnavailable),
                  ),
                const SizedBox(height: EgtDimens.s24),
                OutlinedButton.icon(
                  onPressed: _logoutAll,
                  icon: const Icon(Icons.logout),
                  label: Text(l10n.securityLogoutAll),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
