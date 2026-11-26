import 'dart:io' show Platform;

import 'package:flutter/services.dart';

/// Launcher icons the user can pick in Settings > Appearance > App icon.
/// Each maps to an `<activity-alias>` in the Android manifest.
enum AppIconChoice { black, white, aurora }

class AppIconService {
  AppIconService._();

  static const _channel = MethodChannel('com.theluciferee.novaplayer/app_icon');

  static bool get isSupported => Platform.isAndroid;

  static Future<AppIconChoice> current() async {
    if (!isSupported) return AppIconChoice.black;
    try {
      final name = await _channel.invokeMethod<String>('getIcon');
      return AppIconChoice.values.firstWhere(
        (c) => c.name == name,
        orElse: () => AppIconChoice.black,
      );
    } on PlatformException {
      return AppIconChoice.black;
    } on MissingPluginException {
      return AppIconChoice.black;
    }
  }

  static Future<bool> set(AppIconChoice choice) async {
    if (!isSupported) return false;
    try {
      return await _channel.invokeMethod<bool>('setIcon', {
            'icon': choice.name,
          }) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
