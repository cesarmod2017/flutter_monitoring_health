package com.flutter_monitoring_health;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import android.os.Build;
import android.app.ActivityManager;
import android.content.Context;
import android.os.StatFs;
import android.os.Environment;
import android.os.Handler;
import android.os.Looper;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.HashMap;
import java.util.Map;

public class FlutterMonitoringHealthPlugin implements FlutterPlugin, MethodCallHandler {
  private MethodChannel channel;
  private Context context;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "flutter_monitoring_health");
    channel.setMethodCallHandler(this);
    context = flutterPluginBinding.getApplicationContext();
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    switch (call.method) {
      case "getDeviceModel":
        result.success(Build.MODEL);
        break;
      case "getOSVersion":
        result.success(Build.VERSION.RELEASE);
        break;
      case "getTotalMemory":
        result.success(getTotalMemory());
        break;
      case "getUsedMemory":
        result.success(getUsedMemory());
        break;
      case "getAppMemoryUsage":
        result.success(getAppMemoryUsage());
        break;
      case "getTotalDiskSpace":
        result.success(getTotalDiskSpace());
        break;
      case "getUsedDiskSpace":
        result.success(getUsedDiskSpace());
        break;
      case "getAvailableDiskSpace":
        result.success(getAvailableDiskSpace());
        break;

      default:
        result.notImplemented();
        break;
    }
  }

  private long getTotalMemory() {
    ActivityManager.MemoryInfo memoryInfo = new ActivityManager.MemoryInfo();
    ActivityManager activityManager = (ActivityManager) context.getSystemService(Context.ACTIVITY_SERVICE);
    activityManager.getMemoryInfo(memoryInfo);
    return memoryInfo.totalMem;
  }

  private long getUsedMemory() {
    ActivityManager.MemoryInfo memoryInfo = new ActivityManager.MemoryInfo();
    ActivityManager activityManager = (ActivityManager) context.getSystemService(Context.ACTIVITY_SERVICE);
    activityManager.getMemoryInfo(memoryInfo);
    return memoryInfo.totalMem - memoryInfo.availMem;
  }

  private long getAppMemoryUsage() {
    Runtime runtime = Runtime.getRuntime();
    return runtime.totalMemory() - runtime.freeMemory();
  }

  private long getTotalDiskSpace() {
    StatFs statFs = new StatFs(Environment.getDataDirectory().getPath());
    return statFs.getTotalBytes();
  }

  private long getUsedDiskSpace() {
    StatFs statFs = new StatFs(Environment.getDataDirectory().getPath());
    return statFs.getTotalBytes() - statFs.getAvailableBytes();
  }

  private long getAvailableDiskSpace() {
    StatFs statFs = new StatFs(Environment.getDataDirectory().getPath());
    return statFs.getAvailableBytes();
  }



  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }
}
