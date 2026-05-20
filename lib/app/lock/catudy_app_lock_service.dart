import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'catudy_app_lock_models.dart';

class AppLockPermissionStatus {
  const AppLockPermissionStatus({
    required this.usageAccess,
    required this.overlay,
    required this.location,
    required this.backgroundLocation,
  });

  factory AppLockPermissionStatus.fromMap(Map<Object?, Object?> map) {
    return AppLockPermissionStatus(
      usageAccess: map['usageAccess'] == true,
      overlay: map['overlay'] == true,
      location: map['location'] == true,
      backgroundLocation: map['backgroundLocation'] == true,
    );
  }

  static const unsupported = AppLockPermissionStatus(
    usageAccess: false,
    overlay: false,
    location: false,
    backgroundLocation: false,
  );

  final bool usageAccess;
  final bool overlay;
  final bool location;
  final bool backgroundLocation;
}

class CatudyAppLockService {
  CatudyAppLockService._();

  static final instance = CatudyAppLockService._();
  static const _channel = MethodChannel('catudy/app_lock');

  bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<List<CatudyInstalledApp>> listInstalledApps() async {
    if (!isAndroid) {
      return const [];
    }
    try {
      final result = await _channel.invokeListMethod<Object?>(
        'listInstalledApps',
      );
      return [
        for (final item in result ?? const <Object?>[])
          if (item is Map)
            CatudyInstalledApp.fromMap(Map<Object?, Object?>.from(item)),
      ]..sort((a, b) => a.appName.compareTo(b.appName));
    } on PlatformException catch (_) {
      return const [];
    } on MissingPluginException catch (_) {
      return const [];
    }
  }

  Future<AppLockPermissionStatus> getPermissionStatus() async {
    if (!isAndroid) {
      return AppLockPermissionStatus.unsupported;
    }
    try {
      final result = await _channel.invokeMapMethod<Object?, Object?>(
        'getPermissionStatus',
      );
      return result == null
          ? AppLockPermissionStatus.unsupported
          : AppLockPermissionStatus.fromMap(result);
    } on PlatformException catch (_) {
      return AppLockPermissionStatus.unsupported;
    } on MissingPluginException catch (_) {
      return AppLockPermissionStatus.unsupported;
    }
  }

  Future<void> openUsageAccessSettings() async {
    await _invokeVoid('openUsageAccessSettings');
  }

  Future<void> openOverlaySettings() async {
    await _invokeVoid('openOverlaySettings');
  }

  Future<void> openLocationSettings() async {
    await _invokeVoid('openLocationSettings');
  }

  Future<void> startLockService() async {
    await _invokeVoid('startLockService');
  }

  Future<void> stopLockService() async {
    await _invokeVoid('stopLockService');
  }

  Future<void> syncLockRules({
    required List<LockedApp> lockedApps,
    required List<LockLocation> lockLocations,
    required LockSettings settings,
  }) async {
    if (!isAndroid) {
      return;
    }
    await _invokeVoid('syncLockRules', {
      'settings': settings.toJson(),
      'lockedApps': lockedApps.map((item) => item.toJson()).toList(),
      'lockLocations': lockLocations.map((item) => item.toJson()).toList(),
      'syncedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _invokeVoid(String method, [Object? arguments]) async {
    if (!isAndroid) {
      return;
    }
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on PlatformException catch (_) {
      return;
    } on MissingPluginException catch (_) {
      return;
    }
  }
}
