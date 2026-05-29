import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../app/demo/catudy_demo_store.dart';
import '../../app/device/catudy_device_controls.dart';
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

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  final _deviceControls = CatudyDeviceControls.instance;
  late final TextEditingController _nameController;
  late final TextEditingController _monthlyGoalController;
  bool _dnd = true;
  bool _focusDnd = true;
  bool _dndAccessGranted = false;
  bool _notifications = true;
  bool _dailyGoalReminderEnabled = true;
  bool _publicStatsVisible = true;
  String _language = 'tr';
  String _themeMode = 'system';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final store = catudyDemoStore;
    _nameController = TextEditingController(text: store.displayName);
    _monthlyGoalController = TextEditingController(
      text: store.monthlyGoalMinutes.toString(),
    );
    _dnd = store.dndReminder;
    _focusDnd = store.focusDndEnabled;
    _notifications = store.notifications;
    _dailyGoalReminderEnabled = store.dailyGoalReminderEnabled;
    _publicStatsVisible = store.publicStatsVisible;
    _language = store.languageCode;
    _themeMode = store.themeModeCode;
    _refreshDndAccess();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameController.dispose();
    _monthlyGoalController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshDndAccess();
    }
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
                  value: _focusDnd,
                  onChanged: (value) {
                    setState(() => _focusDnd = value);
                    _save(store);
                    if (value &&
                        _deviceControls.isAndroid &&
                        !_dndAccessGranted) {
                      _openDndAccessSettings();
                    }
                  },
                  title: Text(store.t('settings.focusDnd')),
                  subtitle: Text(
                    _focusDnd && _deviceControls.isAndroid && !_dndAccessGranted
                        ? store.t('settings.focusDndPermissionBody')
                        : store.t('settings.focusDndBody'),
                  ),
                ),
                if (_focusDnd &&
                    _deviceControls.isAndroid &&
                    !_dndAccessGranted)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: _openDndAccessSettings,
                      icon: const Icon(Icons.do_not_disturb_on_rounded),
                      label: Text(store.t('settings.openDndAccess')),
                    ),
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
                const SizedBox(height: 12),
                TextField(
                  controller: _monthlyGoalController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: store.t('settings.monthlyGoal'),
                    helperText: store.t('settings.monthlyGoalBody'),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.calendar_month_rounded),
                  ),
                  onChanged: (value) {
                    final minutes = int.tryParse(value);
                    if (minutes != null) {
                      store.updateMonthlyGoal(minutes);
                    }
                  },
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
            accentColor: CatudyColors.tealDark,
            child: Row(
              children: [
                const Icon(
                  Icons.lock_clock_rounded,
                  color: CatudyColors.tealDark,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.t('appLock.title'),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        store.t('appLock.headerBody'),
                        style: TextStyle(color: CatudyColors.mutedFor(context)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.tonalIcon(
                  onPressed: () => context.push('/app-lock'),
                  icon: const Icon(Icons.tune_rounded),
                  label: Text(store.t('appLock.open')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          CatudyPanel(
            accentColor: CatudyColors.teal,
            child: Row(
              children: [
                const Icon(Icons.widgets_rounded, color: CatudyColors.teal),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.t('settings.widgetSettingsTitle'),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        store.t('settings.widgetSettingsBody'),
                        style: TextStyle(color: CatudyColors.mutedFor(context)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.tonalIcon(
                  onPressed: () => context.push('/widget-settings'),
                  icon: const Icon(Icons.tune_rounded),
                  label: Text(store.t('appLock.open')),
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
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: store.isAuthenticated
                        ? CatudyColors.violet
                        : CatudyColors.tealDark,
                    foregroundColor: Colors.white,
                  ),
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
                const SizedBox(height: 10),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: CatudyColors.coral,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: store.authBusy
                      ? null
                      : () async {
                          final confirmed = await _confirmDeleteAccount(
                            context,
                            store,
                          );
                          if (!confirmed) {
                            return;
                          }
                          final deleted = await store.deleteAccount();
                          if (!deleted) {
                            if (context.mounted && store.authError != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(store.authError!)),
                              );
                            }
                            return;
                          }
                          if (context.mounted) {
                            context.go('/auth');
                          }
                        },
                  icon: const Icon(Icons.delete_forever_rounded),
                  label: Text(store.t('settings.deleteAccount')),
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
      focusDnd: _focusDnd,
      petNotifications: _notifications,
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

  Future<void> _refreshDndAccess() async {
    final granted = await _deviceControls.isDoNotDisturbAccessGranted();
    if (!mounted) {
      return;
    }
    setState(() => _dndAccessGranted = granted);
  }

  Future<void> _openDndAccessSettings() async {
    await _deviceControls.openDoNotDisturbAccessSettings();
    if (!mounted) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 900));
    await _refreshDndAccess();
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

  Future<bool> _confirmDeleteAccount(
    BuildContext context,
    CatudyDemoStore store,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(store.t('settings.deleteAccount')),
            content: Text(store.t('settings.deleteAccountBody')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(store.t('common.cancel')),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: CatudyColors.coral,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(store.t('settings.deleteAccountConfirm')),
              ),
            ],
          ),
        ) ??
        false;
  }
}
