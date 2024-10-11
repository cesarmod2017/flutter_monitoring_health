import 'dart:async';

import 'package:flutter/services.dart';

class FlutterMonitoringHealth {
  static const MethodChannel _channel =
      MethodChannel('flutter_monitoring_health');

  static Future<String?> getDeviceModel() async {
    final String? model = await _channel.invokeMethod('getDeviceModel');
    return model ?? 'Não suportado';
  }

  static Future<String?> getOSVersion() async {
    final String? version = await _channel.invokeMethod('getOSVersion');
    return version ?? 'Não suportado';
  }

  static Future<String> getTotalMemory() async {
    final int? totalMemory = await _channel.invokeMethod('getTotalMemory');
    return totalMemory != null
        ? '${(totalMemory / (1024 * 1024)).toStringAsFixed(2)} MB'
        : 'Não suportado';
  }

  static Future<String> getUsedMemory() async {
    final int? usedMemory = await _channel.invokeMethod('getUsedMemory');
    return usedMemory != null
        ? '${(usedMemory / (1024 * 1024)).toStringAsFixed(2)} MB'
        : 'Não suportado';
  }

  static Future<String> getAppMemoryUsage() async {
    final int? appMemoryUsage =
        await _channel.invokeMethod('getAppMemoryUsage');
    return appMemoryUsage != null
        ? '${(appMemoryUsage / (1024 * 1024)).toStringAsFixed(2)} MB'
        : 'Não suportado';
  }

  static Future<String> getTotalDiskSpace() async {
    final int? totalDiskSpace =
        await _channel.invokeMethod('getTotalDiskSpace');
    return totalDiskSpace != null
        ? '${(totalDiskSpace / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB'
        : 'Não suportado';
  }

  static Future<String> getUsedDiskSpace() async {
    final int? usedDiskSpace = await _channel.invokeMethod('getUsedDiskSpace');
    return usedDiskSpace != null
        ? '${(usedDiskSpace / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB'
        : 'Não suportado';
  }

  static Future<String> getAvailableDiskSpace() async {
    final int? availableDiskSpace =
        await _channel.invokeMethod('getAvailableDiskSpace');
    return availableDiskSpace != null
        ? '${(availableDiskSpace / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB'
        : 'Não suportado';
  }
}
