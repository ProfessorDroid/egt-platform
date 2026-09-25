import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/assets/brand_assets.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/egt_colors.dart';
import '../../../core/theme/egt_dimens.dart';
import '../../../core/widgets/egt_button.dart';
import '../../../core/widgets/egt_text_field.dart';
import '../../providers/auth_providers.dart';
import '../../providers/core_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authStateProvider.notifier).login(
            phone: _phone.text.trim(),
            password: _password.text,
          );
      ref.read(analyticsProvider).logEvent('app_opened', {'method': 'login'});
      if (!mounted) return;
      final next = GoRouterState.of(context).uri.queryParameters['next'];
      context.go(next ?? '/home');
    } on AppException catch (e) {
      setState(() => _error = _friendly(e));
    } catch (_) {
      setState(() => _error = context.l10n.errorGeneric);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendly(AppException e) {
    final l10n = context.l10n;
    switch (e.kind) {
      case AppFailureKind.offline:
        return l10n.errorOffline;
      case AppFailureKind.unauthorized:
        return l10n.errorUnauthorized;
      default:
        return l10n.errorGeneric;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(EgtDimens.s24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(BrandAssets.logo, height: 52,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                const SizedBox(height: EgtDimens.s24),
                Text(l10n.authSignIn,
                    style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: EgtDimens.s24),
                EgtTextField(
                  label: l10n.authPhone,
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  validator: (v) => requiredValidator(v, l10n.rfqValidationRequired),
                ),
                const SizedBox(height: EgtDimens.s16),
                EgtTextField(
                  label: l10n.authPassword,
                  controller: _password,
                  obscureText: _obscure,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(_obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  validator: (v) => requiredValidator(v, l10n.rfqValidationRequired),
                  onSubmitted: (_) => _submit(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: EgtDimens.s12),
                  Text(_error!,
                      style: const TextStyle(color: EgtColors.error, fontSize: 13)),
                ],
                const SizedBox(height: EgtDimens.s24),
                EgtButton(
                    label: l10n.authSignInCta, onPressed: _submit, isLoading: _busy),
                const SizedBox(height: EgtDimens.s16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(l10n.authNoAccount),
                    TextButton(
                      onPressed: () => context.push('/register'),
                      child: Text(l10n.actionCreateAccount),
                    ),
                  ],
                ),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/home'),
                    child: Text(l10n.authGuestContinue),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
