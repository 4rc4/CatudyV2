import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../app/demo/catudy_demo_store.dart';
import '../../app/notifications/catudy_notification_service.dart';
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
  late final TextEditingController _profileShareUrlController;
  bool _dnd = true;
  bool _notifications = true;
  bool _dailyGoalReminderEnabled = true;
  bool _publicStatsVisible = true;
  String _language = 'tr';
  String _themeMode = 'system';

  @override
  void initState() {
    super.initState();
    final store = catudyDemoStore;
    _nameController = TextEditingController(text: store.displayName);
    _profileShareUrlController = TextEditingController(
      text: store.profileShareBaseUrl,
    );
    _dnd = store.dndReminder;
    _notifications = store.notifications;
    _dailyGoalReminderEnabled = store.dailyGoalReminderEnabled;
    _publicStatsVisible = store.publicStatsVisible;
    _language = store.languageCode;
    _themeMode = store.themeModeCode;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _profileShareUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, store) => ScreenScaffold(
        title: store.t('settings.title'),
        showBack: true,
        fallbackBackPath: '/profile',
        showSettingsAction: false,
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
                  onChanged: (_) => _save(store),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _profileShareUrlController,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: store.t('settings.profileShareBaseUrl'),
                    hintText: store.t('settings.profileShareBaseUrlHint'),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.link_rounded),
                  ),
                  onChanged: (_) => _save(store),
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
                  onChanged: (value) {
                    setState(() => _dnd = value);
                    _save(store);
                  },
                  title: Text(store.t('settings.dnd')),
                ),
                SwitchListTile(
                  value: _notifications,
                  onChanged: (value) {
                    setState(() => _notifications = value);
                    _save(store);
                  },
                  title: Text(store.t('settings.petNotifications')),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: _dailyGoalReminderEnabled,
                  onChanged: (value) {
                    setState(() => _dailyGoalReminderEnabled = value);
                    store.updateDailyGoalReminder(
                      enabled: value,
                      time: TimeOfDay(
                        hour: store.dailyGoalReminderHour,
                        minute: store.dailyGoalReminderMinute,
                      ),
                    );
                    _save(store);
                  },
                  title: Text(store.t('settings.dailyGoalReminder')),
                  subtitle: Text(
                    store.t('settings.dailyGoalReminderBody', {
                      'time':
                          '${store.dailyGoalReminderHour.toString().padLeft(2, '0')}:${store.dailyGoalReminderMinute.toString().padLeft(2, '0')}',
                    }),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () => _pickGoalReminderTime(context, store),
                    icon: const Icon(Icons.schedule_rounded),
                    label: Text(store.t('settings.changeReminderTime')),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          CatudyPanel(
            accentColor: CatudyColors.coral,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.t('settings.privacy'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: CatudyColors.mutedFor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: _publicStatsVisible,
                  onChanged: (value) {
                    setState(() => _publicStatsVisible = value);
                    _save(store);
                  },
                  title: Text(store.t('settings.profileStatsVisibility')),
                  subtitle: Text(
                    store.t('settings.profileStatsVisibilityBody'),
                  ),
                ),
                const Divider(height: 22),
                Text(
                  store.t('settings.blockedUsers'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: CatudyColors.mutedFor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                if (store.blockedUserIds.isEmpty)
                  Text(
                    store.t('settings.noBlockedUsers'),
                    style: TextStyle(color: CatudyColors.mutedFor(context)),
                  )
                else
                  for (final userId in store.blockedUserIds)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.block_rounded),
                      title: Text(store.blockedUserLabel(userId)),
                      subtitle: Text(store.displayUserId(userId)),
                      trailing: TextButton(
                        onPressed: () => store.unblockUser(userId),
                        child: Text(store.t('settings.unblock')),
                      ),
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
                      : () async {
                          if (store.isAuthenticated) {
                            await store.signOut();
                            if (context.mounted) {
                              context.go('/auth');
                            }
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
          if (kDebugMode) ...[
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
      profileShareUrl: _profileShareUrlController.text,
      profileStatsVisible: _publicStatsVisible,
      language: language ?? _language,
      themeMode: themeMode ?? _themeMode,
    );
    CatudyNotificationService.instance.scheduleDailyGoalReminder(
      hour: store.dailyGoalReminderHour,
      minute: store.dailyGoalReminderMinute,
      languageCode: store.languageCode,
      enabled: store.notifications && store.dailyGoalReminderEnabled,
    );
  }

  Future<void> _pickGoalReminderTime(
    BuildContext context,
    CatudyDemoStore store,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: store.dailyGoalReminderHour,
        minute: store.dailyGoalReminderMinute,
      ),
    );
    if (picked == null) {
      return;
    }
    store.updateDailyGoalReminder(
      enabled: _dailyGoalReminderEnabled,
      time: picked,
    );
    _save(store);
  }
}
