import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class CatudyDeviceControls {
  CatudyDeviceControls._();

  static final instance = CatudyDeviceControls._();
  static const _channel = MethodChannel('catudy/device_controls');

  bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<bool> isDoNotDisturbAccessGranted() async {
    if (!isAndroid) {
      return false;
    }
    try {
      final granted = await _channel.invokeMethod<bool>(
        'isDoNotDisturbAccessGranted',
      );
      return granted ?? false;
    } on PlatformException catch (_) {
      return false;
    } on MissingPluginException catch (_) {
      return false;
    }
  }

  Future<void> openDoNotDisturbAccessSettings() async {
    await _invokeVoid('openDoNotDisturbAccessSettings');
  }

  Future<bool> setDoNotDisturb(bool enabled) async {
    if (!isAndroid) {
      return false;
    }
    try {
      final applied = await _channel.invokeMethod<bool>('setDoNotDisturb', {
        'enabled': enabled,
      });
      return applied ?? false;
    } on PlatformException catch (_) {
      return false;
    } on MissingPluginException catch (_) {
      return false;
    }
  }

  Future<void> _invokeVoid(String method) async {
    if (!isAndroid) {
      return;
    }
    try {
      await _channel.invokeMethod<void>(method);
    } on PlatformException catch (_) {
      return;
    } on MissingPluginException catch (_) {
      return;
    }
  }
}
