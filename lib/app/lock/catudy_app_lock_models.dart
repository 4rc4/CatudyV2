import 'dart:math';

class CatudyInstalledApp {
  const CatudyInstalledApp({
    required this.packageName,
    required this.appName,
    this.appIconBase64,
  });

  factory CatudyInstalledApp.fromMap(Map<Object?, Object?> map) {
    return CatudyInstalledApp(
      packageName: _readString(map, 'packageName', ''),
      appName: _readString(map, 'appName', ''),
      appIconBase64:
          _readNullableString(map, 'appIconBase64') ??
          _readNullableString(map, 'appIcon'),
    );
  }

  final String packageName;
  final String appName;
  final String? appIconBase64;
}

class LockedApp {
  const LockedApp({
    required this.packageName,
    required this.appName,
    required this.requiredFocusMinutes,
    required this.enabled,
    this.appIconBase64,
    this.unlockedUntil,
  });

  factory LockedApp.fromJson(Map<String, dynamic> json) {
    return LockedApp(
      packageName: _readString(json, 'packageName', ''),
      appName: _readString(json, 'appName', ''),
      requiredFocusMinutes: _readInt(
        json,
        'requiredFocusMinutes',
        LockSettings.defaultFocusMinutes,
      ).clamp(1, 240).toInt(),
      enabled: _readBool(json, 'enabled', true),
      appIconBase64:
          _readNullableString(json, 'appIconBase64') ??
          _readNullableString(json, 'appIcon'),
      unlockedUntil: _readNullableDate(json, 'unlockedUntil'),
    );
  }

  final String packageName;
  final String appName;
  final int requiredFocusMinutes;
  final bool enabled;
  final String? appIconBase64;
  final DateTime? unlockedUntil;

  bool isUnlockedAt(DateTime at) {
    final until = unlockedUntil;
    return until != null && until.isAfter(at);
  }

  LockedApp copyWith({
    String? appName,
    int? requiredFocusMinutes,
    bool? enabled,
    String? appIconBase64,
    DateTime? unlockedUntil,
    bool clearUnlockedUntil = false,
  }) {
    return LockedApp(
      packageName: packageName,
      appName: appName ?? this.appName,
      requiredFocusMinutes:
          requiredFocusMinutes?.clamp(1, 240).toInt() ??
          this.requiredFocusMinutes,
      enabled: enabled ?? this.enabled,
      appIconBase64: appIconBase64 ?? this.appIconBase64,
      unlockedUntil: clearUnlockedUntil
          ? null
          : unlockedUntil ?? this.unlockedUntil,
    );
  }

  Map<String, dynamic> toJson() => {
    'packageName': packageName,
    'appName': appName,
    'requiredFocusMinutes': requiredFocusMinutes,
    'enabled': enabled,
    if (appIconBase64?.isNotEmpty == true) 'appIconBase64': appIconBase64,
    'unlockedUntil': unlockedUntil?.toIso8601String(),
  };
}

class LockLocation {
  const LockLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.active,
  });

  factory LockLocation.fromJson(Map<String, dynamic> json) {
    return LockLocation(
      id: _readString(json, 'id', ''),
      name: _readString(json, 'name', 'Focus area'),
      latitude: _readDouble(json, 'latitude', 0),
      longitude: _readDouble(json, 'longitude', 0),
      radiusMeters: _readDouble(
        json,
        'radiusMeters',
        150,
      ).clamp(25, 2000).toDouble(),
      active: _readBool(json, 'active', true),
    );
  }

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final bool active;

  LockLocation copyWith({
    String? name,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    bool? active,
  }) {
    return LockLocation(
      id: id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters:
          radiusMeters?.clamp(25, 2000).toDouble() ?? this.radiusMeters,
      active: active ?? this.active,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'radiusMeters': radiusMeters,
    'active': active,
  };
}

class UnlockSession {
  const UnlockSession({
    required this.id,
    required this.packageName,
    required this.focusRecordId,
    required this.focusMinutes,
    required this.unlockedUntil,
    required this.createdAt,
  });

  factory UnlockSession.fromJson(Map<String, dynamic> json) {
    return UnlockSession(
      id: _readString(json, 'id', ''),
      packageName: _readString(json, 'packageName', ''),
      focusRecordId: _readString(json, 'focusRecordId', ''),
      focusMinutes: _readInt(json, 'focusMinutes', 0),
      unlockedUntil: _readDate(json, 'unlockedUntil', DateTime.now()),
      createdAt: _readDate(json, 'createdAt', DateTime.now()),
    );
  }

  final String id;
  final String packageName;
  final String focusRecordId;
  final int focusMinutes;
  final DateTime unlockedUntil;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'packageName': packageName,
    'focusRecordId': focusRecordId,
    'focusMinutes': focusMinutes,
    'unlockedUntil': unlockedUntil.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };
}

class LockSettings {
  const LockSettings({
    this.enabled = false,
    this.defaultRequiredFocusMinutes = defaultFocusMinutes,
    this.strictLocationLocksEnabled = true,
  });

  factory LockSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const LockSettings();
    }
    return LockSettings(
      enabled: _readBool(json, 'enabled', false),
      defaultRequiredFocusMinutes: _readInt(
        json,
        'defaultRequiredFocusMinutes',
        defaultFocusMinutes,
      ).clamp(1, 240).toInt(),
      strictLocationLocksEnabled: _readBool(
        json,
        'strictLocationLocksEnabled',
        true,
      ),
    );
  }

  static const defaultFocusMinutes = 25;

  final bool enabled;
  final int defaultRequiredFocusMinutes;
  final bool strictLocationLocksEnabled;

  LockSettings copyWith({
    bool? enabled,
    int? defaultRequiredFocusMinutes,
    bool? strictLocationLocksEnabled,
  }) {
    return LockSettings(
      enabled: enabled ?? this.enabled,
      defaultRequiredFocusMinutes:
          defaultRequiredFocusMinutes?.clamp(1, 240).toInt() ??
          this.defaultRequiredFocusMinutes,
      strictLocationLocksEnabled:
          strictLocationLocksEnabled ?? this.strictLocationLocksEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'defaultRequiredFocusMinutes': defaultRequiredFocusMinutes,
    'strictLocationLocksEnabled': strictLocationLocksEnabled,
  };
}

double distanceMeters({
  required double startLatitude,
  required double startLongitude,
  required double endLatitude,
  required double endLongitude,
}) {
  const earthRadiusMeters = 6371000.0;
  final dLat = _radians(endLatitude - startLatitude);
  final dLon = _radians(endLongitude - startLongitude);
  final lat1 = _radians(startLatitude);
  final lat2 = _radians(endLatitude);
  final a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadiusMeters * c;
}

double _radians(double degrees) => degrees * pi / 180;

String _readString(Map<Object?, Object?> json, String key, String fallback) {
  final value = json[key];
  return value is String && value.isNotEmpty ? value : fallback;
}

String? _readNullableString(Map<Object?, Object?> json, String key) {
  final value = json[key];
  return value is String && value.isNotEmpty ? value : null;
}

int _readInt(Map<Object?, Object?> json, String key, int fallback) {
  final value = json[key];
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return fallback;
}

double _readDouble(Map<Object?, Object?> json, String key, double fallback) {
  final value = json[key];
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  return fallback;
}

bool _readBool(Map<Object?, Object?> json, String key, bool fallback) {
  final value = json[key];
  return value is bool ? value : fallback;
}

DateTime _readDate(Map<Object?, Object?> json, String key, DateTime fallback) {
  final value = json[key];
  return value is String ? DateTime.tryParse(value) ?? fallback : fallback;
}

DateTime? _readNullableDate(Map<Object?, Object?> json, String key) {
  final value = json[key];
  return value is String ? DateTime.tryParse(value) : null;
}
