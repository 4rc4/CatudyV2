import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/demo/catudy_demo_store.dart';
import '../../app/theme/catudy_colors.dart';
import '../../shared/widgets/catudy_panel.dart';
import '../../shared/widgets/screen_scaffold.dart';
import '../../shared/widgets/store_builder.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _nameController;
  bool _dnd = true;
  bool _notifications = true;
  String _language = 'tr';
  String _themeMode = 'system';

  @override
  void initState() {
    super.initState();
    final store = catudyDemoStore;
    _nameController = TextEditingController(text: store.displayName);
    _dnd = store.dndReminder;
    _notifications = store.notifications;
    _language = store.languageCode;
    _themeMode = store.themeModeCode;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, store) => ScreenScaffold(
        title: store.t('settings.title'),
        showBack: true,
        fallbackBackPath: '/profile',
        children: [
          CatudyPanel(
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: store.t('settings.displayName'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _language,
                  decoration: InputDecoration(
                    labelText: store.t('settings.language'),
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'tr',
                      child: Text(store.t('settings.turkish')),
                    ),
                    DropdownMenuItem(
                      value: 'en',
                      child: Text(store.t('settings.english')),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() => _language = value);
                    _save(store, language: value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _themeMode,
                  decoration: InputDecoration(
                    labelText: store.t('settings.theme'),
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'system',
                      child: Text(store.t('settings.system')),
                    ),
                    DropdownMenuItem(
                      value: 'light',
                      child: Text(store.t('settings.light')),
                    ),
                    DropdownMenuItem(
                      value: 'dark',
                      child: Text(store.t('settings.dark')),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() => _themeMode = value);
                    _save(store, themeMode: value);
                  },
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: _dnd,
                  onChanged: (value) => setState(() => _dnd = value),
                  title: Text(store.t('settings.dnd')),
                ),
                SwitchListTile(
                  value: _notifications,
                  onChanged: (value) => setState(() => _notifications = value),
                  title: Text(store.t('settings.petNotifications')),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {
                    _save(store);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(store.t('settings.saved'))),
                    );
                  },
                  icon: const Icon(Icons.save_rounded),
                  label: Text(store.t('settings.save')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          CatudyPanel(
            color: store.offlineMode
                ? CatudyColors.lavenderSoft
                : CatudyColors.surface,
            child: Row(
              children: [
                Icon(
                  store.offlineMode
                      ? Icons.cloud_off_rounded
                      : Icons.cloud_done_rounded,
                  color: CatudyColors.violet,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    store.offlineMode
                        ? store.t('settings.offline')
                        : store.t('settings.server'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          CatudyPanel(
            accentColor: CatudyColors.violet,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.t('settings.authTitle'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: CatudyColors.muted,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  store.isAuthenticated
                      ? store.t('settings.authSignedIn', {
                          'provider': store.authProvider ?? 'guest',
                          'email': store.authEmail ?? store.displayName,
                        })
                      : store.t('settings.authSignedOut'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: store.authBusy
                      ? null
                      : () {
                          if (store.isAuthenticated) {
                            unawaited(store.signOut());
                          } else {
                            context.go('/auth');
                          }
                        },
                  icon: Icon(
                    store.isAuthenticated
                        ? Icons.logout_rounded
                        : Icons.login_rounded,
                  ),
                  label: Text(
                    store.isAuthenticated
                        ? store.t('settings.signOut')
                        : store.t('settings.openLogin'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          CatudyPanel(
            accentColor: CatudyColors.teal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.t('settings.demoWallet'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: CatudyColors.muted,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(store.t('settings.demoWalletBody')),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: () {
                    store.loadDemoWallet();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(store.t('settings.demoWalletLoaded')),
                      ),
                    );
                  },
                  icon: const Icon(Icons.account_balance_wallet_rounded),
                  label: Text(store.t('settings.demoWalletButton')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _save(CatudyDemoStore store, {String? language, String? themeMode}) {
    store.updateSettings(
      name: _nameController.text,
      apiUrl: store.apiBaseUrl,
      dnd: _dnd,
      petNotifications: _notifications,
      language: language ?? _language,
      themeMode: themeMode ?? _themeMode,
    );
  }
}
