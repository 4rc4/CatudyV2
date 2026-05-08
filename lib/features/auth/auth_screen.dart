import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/demo/catudy_demo_store.dart';
import '../../app/theme/catudy_colors.dart';
import '../../shared/widgets/catudy_panel.dart';
import '../../shared/widgets/screen_scaffold.dart';
import '../../shared/widgets/store_builder.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _signUpMode = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, store) {
        if (store.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.go('/');
            }
          });
        }

        return ScreenScaffold(
          title: store.t('auth.title'),
          showBack: false,
          children: [
            CatudyPanel(
              accentColor: CatudyColors.teal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    store.t('auth.subtitle'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: CatudyColors.mutedFor(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_signUpMode) ...[
                    TextField(
                      controller: _displayNameController,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.name],
                      decoration: InputDecoration(
                        labelText: store.t('auth.displayName'),
                        prefixIcon: const Icon(Icons.person_rounded),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: InputDecoration(
                      labelText: store.t('auth.email'),
                      prefixIcon: const Icon(Icons.mail_rounded),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: store.t('auth.password'),
                      prefixIcon: const Icon(Icons.lock_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: store.authBusy
                        ? null
                        : () => unawaited(_submitEmail(store)),
                    icon: store.authBusy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _signUpMode
                                ? Icons.person_add_rounded
                                : Icons.login_rounded,
                          ),
                    label: Text(
                      _signUpMode
                          ? store.t('auth.signUp')
                          : store.t('auth.signIn'),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _signUpMode = !_signUpMode),
                    child: Text(
                      _signUpMode
                          ? store.t('auth.haveAccount')
                          : store.t('auth.needAccount'),
                    ),
                  ),
                  const Divider(height: 26),
                  OutlinedButton.icon(
                    onPressed: store.authBusy
                        ? null
                        : () => unawaited(store.signInWithGoogle()),
                    icon: const Icon(Icons.g_mobiledata_rounded),
                    label: Text(store.t('auth.google')),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: store.authBusy
                        ? null
                        : () => unawaited(store.signInWithApple()),
                    icon: const Icon(Icons.apple_rounded),
                    label: Text(store.t('auth.apple')),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: store.authBusy
                        ? null
                        : () => unawaited(store.signInAsGuest()),
                    icon: const Icon(Icons.person_outline_rounded),
                    label: Text(store.t('auth.guest')),
                  ),
                  if (store.authError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      store.authError!,
                      style: const TextStyle(
                        color: CatudyColors.coral,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitEmail(CatudyDemoStore store) {
    if (_signUpMode) {
      return store.signUpWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
        displayName: _displayNameController.text,
      );
    }
    return store.signInWithEmail(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }
}
