import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/egt_colors.dart';
import '../../../core/theme/egt_dimens.dart';
import '../../../core/widgets/egt_button.dart';
import '../../../core/widgets/egt_text_field.dart';
import '../../providers/auth_providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _company = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _password.dispose();
    _company.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authStateProvider.notifier).register(
            fullName: _name.text.trim(),
            phone: _phone.text.trim(),
            password: _password.text,
            company: _company.text.trim().isEmpty ? null : _company.text.trim(),
          );
      if (!mounted) return;
      context.go('/home');
    } on AppException catch (_) {
      setState(() => _error = context.l10n.errorGeneric);
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
      appBar: AppBar(title: Text(l10n.authCreateAccount)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(EgtDimens.s24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                EgtTextField(
                  label: l10n.authFullName,
                  controller: _name,
                  prefixIcon: Icons.person_outline,
                  validator: (v) => requiredValidator(v, l10n.rfqValidationRequired),
                ),
                const SizedBox(height: EgtDimens.s16),
                EgtTextField(
                  label: l10n.authPhone,
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  validator: (v) => requiredValidator(v, l10n.rfqValidationRequired),
                ),
                const SizedBox(height: EgtDimens.s16),
                EgtTextField(
                  label: l10n.authCompany,
                  controller: _company,
                  prefixIcon: Icons.business_outlined,
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
                  validator: (v) {
                    if (v == null || v.isEmpty) return l10n.rfqValidationRequired;
                    if (v.length < 8) return l10n.errorValidation;
                    return null;
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: EgtDimens.s12),
                  Text(_error!,
                      style: const TextStyle(color: EgtColors.error, fontSize: 13)),
                ],
                const SizedBox(height: EgtDimens.s24),
                EgtButton(
                    label: l10n.actionCreateAccount,
                    onPressed: _submit,
                    isLoading: _busy),
                const SizedBox(height: EgtDimens.s16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(l10n.authHaveAccount),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: Text(l10n.actionSignIn),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
