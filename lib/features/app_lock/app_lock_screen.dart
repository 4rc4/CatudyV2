import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../app/demo/catudy_demo_store.dart';
import '../../app/lock/catudy_app_lock_models.dart';
import '../../app/lock/catudy_app_lock_service.dart';
import '../../app/theme/catudy_colors.dart';
import '../../shared/widgets/catudy_panel.dart';
import '../../shared/widgets/catudy_section_header.dart';
import '../../shared/widgets/screen_scaffold.dart';
import '../../shared/widgets/store_builder.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen>
    with WidgetsBindingObserver {
  final _service = CatudyAppLockService.instance;
  AppLockPermissionStatus _permissionStatus =
      AppLockPermissionStatus.unsupported;
  List<CatudyInstalledApp> _installedApps = const [];
  Future<List<CatudyInstalledApp>>? _installedAppsFuture;
  bool _loadingApps = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermissions();
    _syncNativeRules();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshPermissions());
    }
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, store) => ScreenScaffold(
        title: store.t('appLock.title'),
        showBack: true,
        fallbackBackPath: '/settings',
        children: [
          CatudyPanel(
            color: CatudyColors.lavenderSoft,
            accentColor: CatudyColors.violet,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CatudySectionHeader(
                  title: store.t('appLock.header'),
                  subtitle: store.t('appLock.headerBody'),
                  icon: Icons.lock_clock_rounded,
                  accentColor: CatudyColors.violet,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: store.lockSettings.enabled,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (value) {
                    store.updateLockSettings(enabled: value);
                    _syncNativeRules(startService: value);
                  },
                  title: Text(store.t('appLock.masterSwitch')),
                  subtitle: Text(store.t('appLock.masterSwitchBody')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _PermissionPanel(
            store: store,
            status: _permissionStatus,
            androidSupported: _service.isAndroid,
            onUsage: () =>
                _openPermissionSettings(_service.openUsageAccessSettings),
            onOverlay: () =>
                _openPermissionSettings(_service.openOverlaySettings),
            onLocation: () =>
                _openPermissionSettings(_service.openLocationSettings),
          ),
          const SizedBox(height: 14),
          _LockedAppsPanel(
            store: store,
            loadingApps: _loadingApps,
            onAdd: () => _pickInstalledApp(context, store),
            onSync: () => _syncNativeRules(startService: true),
          ),
          const SizedBox(height: 14),
          _LocationsPanel(
            store: store,
            onAdd: () => _pickLocation(context, store),
            onSync: () => _syncNativeRules(startService: true),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshPermissions() async {
    final status = await _service.getPermissionStatus();
    if (!mounted) {
      return;
    }
    setState(() => _permissionStatus = status);
  }

  Future<void> _openPermissionSettings(Future<void> Function() open) async {
    await open();
    unawaited(_refreshPermissionsAfterDelay());
  }

  Future<void> _refreshPermissionsAfterDelay() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) {
      return;
    }
    await _refreshPermissions();
  }

  Future<List<CatudyInstalledApp>> _loadInstalledApps() {
    if (_installedApps.isNotEmpty) {
      return Future.value(_installedApps);
    }
    final inFlight = _installedAppsFuture;
    if (inFlight != null) {
      return inFlight;
    }
    if (mounted) {
      setState(() => _loadingApps = true);
    }
    final future = _service
        .listInstalledApps()
        .then((apps) {
          if (mounted) {
            setState(() {
              _installedApps = apps;
              _loadingApps = false;
            });
          }
          return apps;
        })
        .whenComplete(() {
          _installedAppsFuture = null;
          if (mounted && _loadingApps) {
            setState(() => _loadingApps = false);
          }
        });
    _installedAppsFuture = future;
    return future;
  }

  Future<void> _pickInstalledApp(
    BuildContext context,
    CatudyDemoStore store,
  ) async {
    if (!_service.isAndroid) {
      _showSnack(context, store.t('appLock.androidOnly'));
      return;
    }
    final picked = await showModalBottomSheet<CatudyInstalledApp>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _InstalledAppPicker(
        initialApps: _installedApps,
        loadApps: _loadInstalledApps,
        lockedPackageNames: store.lockedApps
            .map((item) => item.packageName)
            .toSet(),
        store: store,
      ),
    );
    if (picked == null) {
      return;
    }
    final added = store.addLockedApp(picked);
    if (!context.mounted) {
      return;
    }
    if (!added) {
      _showSnack(context, store.t('appLock.limitReached'));
      return;
    }
    await _syncNativeRules(startService: true);
  }

  Future<void> _pickLocation(
    BuildContext context,
    CatudyDemoStore store,
  ) async {
    final picked = await showDialog<_PickedLockLocation>(
      context: context,
      builder: (context) => _LocationPickerDialog(store: store),
    );
    if (picked == null) {
      return;
    }
    final added = store.addLockLocation(
      name: picked.name,
      latitude: picked.point.latitude,
      longitude: picked.point.longitude,
      radiusMeters: picked.radiusMeters,
    );
    if (!context.mounted) {
      return;
    }
    if (!added) {
      _showSnack(context, store.t('appLock.locationLimitReached'));
      return;
    }
    await _syncNativeRules(startService: true);
  }

  Future<void> _syncNativeRules({bool startService = false}) async {
    final store = catudyDemoStore;
    await _service.syncLockRules(
      lockedApps: store.lockedApps,
      lockLocations: store.lockLocations,
      settings: store.lockSettings,
      activeSession: store.activeSession?.toJson(),
    );
    if (startService && store.lockSettings.enabled) {
      await _service.startLockService();
    }
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PermissionPanel extends StatelessWidget {
  const _PermissionPanel({
    required this.store,
    required this.status,
    required this.androidSupported,
    required this.onUsage,
    required this.onOverlay,
    required this.onLocation,
  });

  final CatudyDemoStore store;
  final AppLockPermissionStatus status;
  final bool androidSupported;
  final Future<void> Function() onUsage;
  final Future<void> Function() onOverlay;
  final Future<void> Function() onLocation;

  @override
  Widget build(BuildContext context) {
    return CatudyPanel(
      accentColor: CatudyColors.blueFor(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CatudySectionHeader(
            title: store.t('appLock.permissions'),
            subtitle: androidSupported
                ? store.t('appLock.permissionsBody')
                : store.t('appLock.androidOnly'),
            icon: Icons.admin_panel_settings_rounded,
            accentColor: CatudyColors.blueFor(context),
          ),
          const SizedBox(height: 12),
          _PermissionRow(
            label: store.t('appLock.usageAccess'),
            granted: status.usageAccess,
            onPressed: onUsage,
            store: store,
          ),
          _PermissionRow(
            label: store.t('appLock.overlayPermission'),
            granted: status.overlay,
            onPressed: onOverlay,
            store: store,
          ),
          _PermissionRow(
            label: store.t('appLock.locationPermission'),
            granted: status.location,
            onPressed: onLocation,
            store: store,
          ),
          _PermissionRow(
            label: store.t('appLock.backgroundLocationPermission'),
            granted: status.backgroundLocation,
            onPressed: onLocation,
            store: store,
          ),
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.label,
    required this.granted,
    required this.onPressed,
    required this.store,
  });

  final String label;
  final bool granted;
  final Future<void> Function() onPressed;
  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(
            granted ? Icons.check_circle_rounded : Icons.warning_rounded,
            color: granted ? CatudyColors.tealDark : CatudyColors.coral,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
          TextButton(
            onPressed: onPressed,
            child: Text(
              granted ? store.t('appLock.allowed') : store.t('appLock.open'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LockedAppsPanel extends StatelessWidget {
  const _LockedAppsPanel({
    required this.store,
    required this.loadingApps,
    required this.onAdd,
    required this.onSync,
  });

  final CatudyDemoStore store;
  final bool loadingApps;
  final VoidCallback onAdd;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final limitLabel = store.hasPremiumAccess
        ? store.t('appLock.plusUnlimited')
        : store.t('appLock.limit', {
            'used': store.lockedApps.length,
            'limit': CatudyDemoStore.freeLockedAppLimit,
          });
    return CatudyPanel(
      accentColor: CatudyColors.coral,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CatudySectionHeader(
                  title: store.t('appLock.lockedApps'),
                  subtitle: limitLabel,
                  icon: Icons.apps_rounded,
                  accentColor: CatudyColors.coral,
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: loadingApps || !store.canAddLockedApp ? null : onAdd,
                icon: loadingApps
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_rounded),
                label: Text(store.t('appLock.addApp')),
              ),
            ],
          ),
          if (!store.canAddLockedApp && !store.hasPremiumAccess) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => context.push('/plus'),
              icon: const Icon(Icons.workspace_premium_rounded),
              label: Text(store.t('appLock.plusLimit')),
            ),
          ],
          const SizedBox(height: 12),
          if (store.lockedApps.isEmpty)
            Text(
              store.t('appLock.noLockedApps'),
              style: TextStyle(color: CatudyColors.mutedFor(context)),
            )
          else
            for (final app in store.lockedApps) ...[
              _LockedAppTile(store: store, app: app, onChanged: onSync),
              const Divider(height: 18),
            ],
        ],
      ),
    );
  }
}

class _LockedAppTile extends StatelessWidget {
  const _LockedAppTile({
    required this.store,
    required this.app,
    required this.onChanged,
  });

  final CatudyDemoStore store;
  final LockedApp app;
  final VoidCallback onChanged;

  static const _minuteOptions = [5, 10, 15, 25, 40, 60, 90, 120];

  @override
  Widget build(BuildContext context) {
    final unlocked = store.isLockedAppUnlocked(app.packageName);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AppIconAvatar(
          name: app.appName,
          iconBase64: app.appIconBase64,
          size: 44,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      app.appName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Switch(
                    value: app.enabled,
                    onChanged: (value) {
                      store.setLockedAppEnabled(app.packageName, value);
                      onChanged();
                    },
                  ),
                ],
              ),
              Text(
                app.packageName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: CatudyColors.mutedFor(context)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  DropdownButton<int>(
                    value: _minuteOptions.contains(app.requiredFocusMinutes)
                        ? app.requiredFocusMinutes
                        : 25,
                    items: [
                      for (final minutes in _minuteOptions)
                        DropdownMenuItem(
                          value: minutes,
                          child: Text(
                            store.t('appLock.requiredMinutes', {
                              'minutes': minutes,
                            }),
                          ),
                        ),
                    ],
                    onChanged: (minutes) {
                      if (minutes == null) {
                        return;
                      }
                      store.updateLockedAppMinutes(app.packageName, minutes);
                      onChanged();
                    },
                  ),
                  if (unlocked)
                    Chip(
                      avatar: const Icon(Icons.lock_open_rounded, size: 18),
                      label: Text(store.t('appLock.unlockedToday')),
                    ),
                  TextButton.icon(
                    onPressed: () {
                      store.prepareAppUnlockFocus(app.packageName);
                      context.go(
                        '/focus/start?unlockApp=${Uri.encodeComponent(app.packageName)}',
                      );
                    },
                    icon: const Icon(Icons.timer_rounded),
                    label: Text(store.t('appLock.startFocus')),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            store.removeLockedApp(app.packageName);
            onChanged();
          },
          icon: const Icon(Icons.delete_outline_rounded),
          tooltip: store.t('common.delete'),
        ),
      ],
    );
  }
}

class _LocationsPanel extends StatelessWidget {
  const _LocationsPanel({
    required this.store,
    required this.onAdd,
    required this.onSync,
  });

  final CatudyDemoStore store;
  final VoidCallback onAdd;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final limitLabel = store.hasPremiumAccess
        ? store.t('appLock.plusUnlimited')
        : store.t('appLock.locationLimit', {
            'used': store.lockLocations.length,
            'limit': CatudyDemoStore.freeLockLocationLimit,
          });
    return CatudyPanel(
      accentColor: CatudyColors.tealDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CatudySectionHeader(
                  title: store.t('appLock.locations'),
                  subtitle: limitLabel,
                  icon: Icons.location_on_rounded,
                  accentColor: CatudyColors.tealDark,
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: store.canAddLockLocation ? onAdd : null,
                icon: const Icon(Icons.add_location_alt_rounded),
                label: Text(store.t('appLock.addLocation')),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: store.lockSettings.strictLocationLocksEnabled,
            onChanged: (value) {
              store.updateLockSettings(strictLocationLocksEnabled: value);
              onSync();
            },
            title: Text(store.t('appLock.strictLocation')),
          ),
          if (!store.canAddLockLocation && !store.hasPremiumAccess)
            TextButton.icon(
              onPressed: () => context.push('/plus'),
              icon: const Icon(Icons.workspace_premium_rounded),
              label: Text(store.t('appLock.plusLocationLimit')),
            ),
          const SizedBox(height: 10),
          if (store.lockLocations.isEmpty)
            Text(
              store.t('appLock.noLocations'),
              style: TextStyle(color: CatudyColors.mutedFor(context)),
            )
          else
            for (final location in store.lockLocations) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.my_location_rounded),
                title: Text(location.name),
                subtitle: Text(
                  store.t('appLock.locationDetails', {
                    'radius': location.radiusMeters.round(),
                  }),
                ),
                trailing: Wrap(
                  spacing: 2,
                  children: [
                    Switch(
                      value: location.active,
                      onChanged: (value) {
                        store.setLockLocationActive(location.id, value);
                        onSync();
                      },
                    ),
                    IconButton(
                      onPressed: () {
                        store.removeLockLocation(location.id);
                        onSync();
                      },
                      icon: const Icon(Icons.delete_outline_rounded),
                      tooltip: store.t('common.delete'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 16),
            ],
        ],
      ),
    );
  }
}

class _InstalledAppPicker extends StatefulWidget {
  const _InstalledAppPicker({
    required this.initialApps,
    required this.loadApps,
    required this.lockedPackageNames,
    required this.store,
  });

  final List<CatudyInstalledApp> initialApps;
  final Future<List<CatudyInstalledApp>> Function() loadApps;
  final Set<String> lockedPackageNames;
  final CatudyDemoStore store;

  @override
  State<_InstalledAppPicker> createState() => _InstalledAppPickerState();
}

class _InstalledAppPickerState extends State<_InstalledAppPicker> {
  final _controller = TextEditingController();
  late List<CatudyInstalledApp> _apps;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _apps = widget.initialApps;
    if (_apps.isEmpty) {
      _load();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_loading) {
      return;
    }
    setState(() => _loading = true);
    final apps = await widget.loadApps();
    if (!mounted) {
      return;
    }
    setState(() {
      _apps = apps;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text.trim().toLowerCase();
    final apps = [
      for (final app in _apps)
        if (query.isEmpty ||
            app.appName.toLowerCase().contains(query) ||
            app.packageName.toLowerCase().contains(query))
          app,
    ];
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.78,
          child: Column(
            children: [
              TextField(
                controller: _controller,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: widget.store.t('appLock.searchApps'),
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(child: _buildAppList(context, apps)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppList(BuildContext context, List<CatudyInstalledApp> apps) {
    if (_loading && apps.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(strokeWidth: 3),
            const SizedBox(height: 12),
            Text(
              widget.store.t('appLock.loadingApps'),
              style: TextStyle(color: CatudyColors.mutedFor(context)),
            ),
          ],
        ),
      );
    }
    if (apps.isEmpty) {
      return Center(
        child: Text(
          widget.store.t('appLock.noInstalledApps'),
          style: TextStyle(color: CatudyColors.mutedFor(context)),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        final apps = await widget.loadApps();
        if (mounted) {
          setState(() => _apps = apps);
        }
      },
      child: ListView.separated(
        itemCount: apps.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final app = apps[index];
          final locked = widget.lockedPackageNames.contains(app.packageName);
          return ListTile(
            enabled: !locked,
            leading: _AppIconAvatar(
              name: app.appName,
              iconBase64: app.appIconBase64,
              size: 42,
            ),
            title: Text(app.appName),
            subtitle: Text(app.packageName),
            trailing: locked
                ? const Icon(Icons.check_circle_rounded)
                : const Icon(Icons.add_rounded),
            onTap: locked ? null : () => Navigator.pop(context, app),
          );
        },
      ),
    );
  }
}

class _AppIconAvatar extends StatelessWidget {
  const _AppIconAvatar({
    required this.name,
    required this.iconBase64,
    required this.size,
  });

  final String name;
  final String? iconBase64;
  final double size;

  @override
  Widget build(BuildContext context) {
    final bytes = _decodeIcon(iconBase64);
    final radius = BorderRadius.circular(size * 0.24);
    final fallback = _FallbackAppIcon(name: name, size: size);
    if (bytes == null) {
      return fallback;
    }
    return ClipRRect(
      borderRadius: radius,
      child: Image.memory(
        bytes,
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}

class _FallbackAppIcon extends StatelessWidget {
  const _FallbackAppIcon({required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: CatudyColors.lavenderSoft,
        borderRadius: BorderRadius.circular(size * 0.24),
      ),
      alignment: Alignment.center,
      child: Text(
        _initialFor(name),
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

Uint8List? _decodeIcon(String? value) {
  final raw = value?.trim();
  if (raw == null || raw.isEmpty) {
    return null;
  }
  final clean = raw.contains(',') ? raw.split(',').last : raw;
  try {
    return base64Decode(clean);
  } on FormatException {
    return null;
  }
}

class _LocationPickerDialog extends StatefulWidget {
  const _LocationPickerDialog({required this.store});

  final CatudyDemoStore store;

  @override
  State<_LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<_LocationPickerDialog> {
  static const _initialPoint = LatLng(41.0082, 28.9784);
  late LatLng _point = _initialPoint;
  double _radiusMeters = 150;
  final _mapController = MapController();
  late final TextEditingController _nameController;
  late final TextEditingController _searchController;
  var _searchResults = <_LocationSearchResult>[];
  bool _searching = false;
  bool _loadingCurrentLocation = false;
  String? _searchMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.store.t('appLock.defaultLocationName'),
    );
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 430;
    final mapHeight = compact ? 250.0 : 310.0;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: size.height * 0.88,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        store.t('appLock.addLocation'),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: CatudyColors.blueFor(context),
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: store.t('appLock.locationName'),
                            prefixIcon: const Icon(Icons.label_rounded),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _searchController,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _searchLocation(),
                          decoration: InputDecoration(
                            labelText: store.t('appLock.searchLocation'),
                            hintText: store.t('appLock.searchLocationHint'),
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _searching
                                ? const Padding(
                                    padding: EdgeInsets.all(14),
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : IconButton(
                                    onPressed: _searchLocation,
                                    icon: const Icon(
                                      Icons.arrow_forward_rounded,
                                    ),
                                  ),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        if (_searchMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _searchMessage!,
                            style: TextStyle(
                              color: CatudyColors.coral,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        if (_searchResults.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _LocationSearchResults(
                            results: _searchResults,
                            onSelected: _selectSearchResult,
                          ),
                        ],
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: SizedBox(
                            height: mapHeight,
                            child: Stack(
                              children: [
                                FlutterMap(
                                  mapController: _mapController,
                                  options: MapOptions(
                                    initialCenter: _point,
                                    initialZoom: 14,
                                    onTap: (_, point) =>
                                        setState(() => _point = point),
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate:
                                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      userAgentPackageName:
                                          'com.catudy.catudy_app',
                                    ),
                                    CircleLayer(
                                      circles: [
                                        CircleMarker(
                                          point: _point,
                                          radius: _radiusMeters,
                                          useRadiusInMeter: true,
                                          color: CatudyColors.violet.withValues(
                                            alpha: 0.18,
                                          ),
                                          borderColor: CatudyColors.violet,
                                          borderStrokeWidth: 2,
                                        ),
                                      ],
                                    ),
                                    MarkerLayer(
                                      markers: [
                                        Marker(
                                          point: _point,
                                          width: 46,
                                          height: 46,
                                          child: const Icon(
                                            Icons.location_pin,
                                            color: CatudyColors.coral,
                                            size: 44,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Positioned(
                                  left: 10,
                                  right: 10,
                                  top: 10,
                                  child: _MapHint(
                                    text: store.t('appLock.tapMapHint'),
                                  ),
                                ),
                                Positioned(
                                  right: 10,
                                  bottom: 10,
                                  child: FilledButton.tonalIcon(
                                    onPressed: _loadingCurrentLocation
                                        ? null
                                        : _useCurrentLocation,
                                    icon: _loadingCurrentLocation
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.my_location_rounded,
                                            size: 18,
                                          ),
                                    label: Text(
                                      store.t('appLock.useCurrentLocation'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _RadiusControl(
                          radiusMeters: _radiusMeters,
                          onChanged: (value) =>
                              setState(() => _radiusMeters = value),
                          store: store,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          store.t('appLock.selectedCoordinates', {
                            'lat': _point.latitude.toStringAsFixed(5),
                            'lng': _point.longitude.toStringAsFixed(5),
                          }),
                          style: TextStyle(
                            color: CatudyColors.mutedFor(context),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(store.t('common.cancel')),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(
                          context,
                          _PickedLockLocation(
                            name: _nameController.text,
                            point: _point,
                            radiusMeters: _radiusMeters,
                          ),
                        ),
                        icon: const Icon(Icons.save_rounded),
                        label: Text(store.t('appLock.saveLocation')),
                      ),
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

  Future<void> _searchLocation() async {
    final query = _searchController.text.trim();
    if (query.isEmpty || _searching) {
      return;
    }
    setState(() {
      _searching = true;
      _searchMessage = null;
      _searchResults = [];
    });
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'format': 'jsonv2',
        'limit': '5',
        'q': query,
      });
      final response = await http.get(
        uri,
        headers: const {
          'Accept': 'application/json',
          'User-Agent': 'CatudyApp/1.0 app-lock-location-search',
        },
      );
      if (response.statusCode != 200) {
        throw StateError('Search failed: ${response.statusCode}');
      }
      final decoded = jsonDecode(response.body);
      final results = decoded is List
          ? [
              for (final item in decoded)
                if (item is Map)
                  _LocationSearchResult.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
            ].whereType<_LocationSearchResult>().toList()
          : <_LocationSearchResult>[];
      if (!mounted) {
        return;
      }
      setState(() {
        _searchResults = results;
        _searchMessage = results.isEmpty
            ? widget.store.t('appLock.locationSearchNoResults')
            : null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _searchMessage = widget.store.t('appLock.locationSearchFailed');
      });
    } finally {
      if (mounted) {
        setState(() => _searching = false);
      }
    }
  }

  Future<void> _useCurrentLocation() async {
    if (_loadingCurrentLocation) {
      return;
    }
    setState(() {
      _loadingCurrentLocation = true;
      _searchMessage = null;
    });
    final location = await CatudyAppLockService.instance.getLastKnownLocation();
    if (!mounted) {
      return;
    }
    setState(() => _loadingCurrentLocation = false);
    if (location == null) {
      setState(() {
        _searchMessage = widget.store.t('appLock.currentLocationUnavailable');
      });
      return;
    }
    _moveToPoint(LatLng(location.latitude, location.longitude), 16);
  }

  void _selectSearchResult(_LocationSearchResult result) {
    _searchController.text = result.shortLabel;
    if (_nameController.text.trim().isEmpty ||
        _nameController.text == widget.store.t('appLock.defaultLocationName')) {
      _nameController.text = result.shortLabel;
    }
    setState(() {
      _searchResults = [];
      _searchMessage = null;
    });
    _moveToPoint(result.point, 15.5);
  }

  void _moveToPoint(LatLng point, double zoom) {
    setState(() => _point = point);
    _mapController.move(point, zoom);
  }
}

class _LocationSearchResults extends StatelessWidget {
  const _LocationSearchResults({
    required this.results,
    required this.onSelected,
  });

  final List<_LocationSearchResult> results;
  final ValueChanged<_LocationSearchResult> onSelected;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 154),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: CatudyColors.surfaceFor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CatudyColors.lineFor(context)),
        ),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: results.length,
          separatorBuilder: (_, _) =>
              Divider(height: 1, color: CatudyColors.lineFor(context)),
          itemBuilder: (context, index) {
            final result = results[index];
            return ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              leading: const Icon(
                Icons.place_rounded,
                color: CatudyColors.teal,
              ),
              title: Text(
                result.shortLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                result.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => onSelected(result),
            );
          },
        ),
      ),
    );
  }
}

class _MapHint extends StatelessWidget {
  const _MapHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CatudyColors.surfaceFor(context).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: CatudyColors.teal.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.touch_app_rounded,
              color: CatudyColors.tealDark,
              size: 16,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: CatudyColors.mutedFor(context),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadiusControl extends StatelessWidget {
  const _RadiusControl({
    required this.radiusMeters,
    required this.onChanged,
    required this.store,
  });

  final double radiusMeters;
  final ValueChanged<double> onChanged;
  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CatudyColors.violet.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CatudyColors.violet.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.radar_rounded,
                  color: CatudyColors.violet,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    store.t('appLock.radiusMeters', {
                      'radius': radiusMeters.round(),
                    }),
                    style: TextStyle(
                      color: CatudyColors.blueFor(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            Slider(
              value: radiusMeters,
              min: 50,
              max: 500,
              divisions: 9,
              label: '${radiusMeters.round()} m',
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationSearchResult {
  const _LocationSearchResult({required this.displayName, required this.point});

  factory _LocationSearchResult.fromJson(Map<String, dynamic> json) {
    final lat = double.tryParse('${json['lat']}');
    final lon = double.tryParse('${json['lon']}');
    final displayName = '${json['display_name'] ?? ''}'.trim();
    if (lat == null || lon == null || displayName.isEmpty) {
      throw const FormatException('Invalid location search result');
    }
    return _LocationSearchResult(
      displayName: displayName,
      point: LatLng(lat, lon),
    );
  }

  final String displayName;
  final LatLng point;

  String get shortLabel {
    final first = displayName.split(',').first.trim();
    return first.isEmpty ? displayName : first;
  }
}

class _PickedLockLocation {
  const _PickedLockLocation({
    required this.name,
    required this.point,
    required this.radiusMeters,
  });

  final String name;
  final LatLng point;
  final double radiusMeters;
}

String _initialFor(String value) {
  final clean = value.trim();
  return clean.isEmpty ? '?' : clean.characters.first.toUpperCase();
}
