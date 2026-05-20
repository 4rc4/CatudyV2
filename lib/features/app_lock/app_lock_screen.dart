import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
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

class _AppLockScreenState extends State<AppLockScreen> {
  final _service = CatudyAppLockService.instance;
  AppLockPermissionStatus _permissionStatus =
      AppLockPermissionStatus.unsupported;
  List<CatudyInstalledApp> _installedApps = const [];
  bool _loadingApps = false;

  @override
  void initState() {
    super.initState();
    _refreshPermissions();
    _syncNativeRules();
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
            onRefresh: _refreshPermissions,
            onUsage: _service.openUsageAccessSettings,
            onOverlay: _service.openOverlaySettings,
            onLocation: _service.openLocationSettings,
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
          const SizedBox(height: 14),
          CatudyPanel(
            accentColor: CatudyColors.teal,
            child: CatudySectionHeader(
              title: store.t('appLock.iosRoadmapTitle'),
              subtitle: store.t('appLock.iosRoadmapBody'),
              icon: Icons.phone_iphone_rounded,
              accentColor: CatudyColors.teal,
            ),
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

  Future<void> _loadInstalledApps() async {
    if (_loadingApps) {
      return;
    }
    setState(() => _loadingApps = true);
    final apps = await _service.listInstalledApps();
    if (!mounted) {
      return;
    }
    setState(() {
      _installedApps = apps;
      _loadingApps = false;
    });
  }

  Future<void> _pickInstalledApp(
    BuildContext context,
    CatudyDemoStore store,
  ) async {
    if (!_service.isAndroid) {
      _showSnack(context, store.t('appLock.androidOnly'));
      return;
    }
    await _loadInstalledApps();
    if (!context.mounted) {
      return;
    }
    if (_installedApps.isEmpty) {
      _showSnack(context, store.t('appLock.noInstalledApps'));
      return;
    }
    final picked = await showModalBottomSheet<CatudyInstalledApp>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _InstalledAppPicker(
        apps: _installedApps,
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
    required this.onRefresh,
    required this.onUsage,
    required this.onOverlay,
    required this.onLocation,
  });

  final CatudyDemoStore store;
  final AppLockPermissionStatus status;
  final bool androidSupported;
  final VoidCallback onRefresh;
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
          Row(
            children: [
              Expanded(
                child: CatudySectionHeader(
                  title: store.t('appLock.permissions'),
                  subtitle: androidSupported
                      ? store.t('appLock.permissionsBody')
                      : store.t('appLock.androidOnly'),
                  icon: Icons.admin_panel_settings_rounded,
                  accentColor: CatudyColors.blueFor(context),
                ),
              ),
              IconButton(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: store.t('common.refresh'),
              ),
            ],
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
        CircleAvatar(
          radius: 22,
          backgroundColor: CatudyColors.lavenderSoft,
          child: Text(
            _initialFor(app.appName),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
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
    required this.apps,
    required this.lockedPackageNames,
    required this.store,
  });

  final List<CatudyInstalledApp> apps;
  final Set<String> lockedPackageNames;
  final CatudyDemoStore store;

  @override
  State<_InstalledAppPicker> createState() => _InstalledAppPickerState();
}

class _InstalledAppPickerState extends State<_InstalledAppPicker> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text.trim().toLowerCase();
    final apps = [
      for (final app in widget.apps)
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
              Expanded(
                child: ListView.separated(
                  itemCount: apps.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final app = apps[index];
                    final locked = widget.lockedPackageNames.contains(
                      app.packageName,
                    );
                    return ListTile(
                      enabled: !locked,
                      leading: CircleAvatar(
                        child: Text(_initialFor(app.appName)),
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
              ),
            ],
          ),
        ),
      ),
    );
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
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.store.t('appLock.defaultLocationName'),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return AlertDialog(
      title: Text(store.t('appLock.addLocation')),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: store.t('appLock.locationName'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 300,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: _point,
                      initialZoom: 14,
                      onTap: (_, point) => setState(() => _point = point),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.catudy.catudy_app',
                      ),
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: _point,
                            radius: _radiusMeters,
                            useRadiusInMeter: true,
                            color: CatudyColors.violet.withValues(alpha: 0.18),
                            borderColor: CatudyColors.violet,
                            borderStrokeWidth: 2,
                          ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _point,
                            width: 44,
                            height: 44,
                            child: const Icon(
                              Icons.location_pin,
                              color: CatudyColors.coral,
                              size: 42,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      store.t('appLock.radiusMeters', {
                        'radius': _radiusMeters.round(),
                      }),
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: Slider(
                      value: _radiusMeters,
                      min: 50,
                      max: 500,
                      divisions: 9,
                      label: '${_radiusMeters.round()} m',
                      onChanged: (value) =>
                          setState(() => _radiusMeters = value),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(store.t('common.cancel')),
        ),
        FilledButton.icon(
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
      ],
    );
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
