import Flutter
import UIKit

public class FlutterMonitoringHealthPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_monitoring_health", binaryMessenger: registrar.messenger())
    let instance = FlutterMonitoringHealthPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getDeviceModel":
      result(UIDevice.current.model)
    case "getOSVersion":
      result(UIDevice.current.systemVersion)
    case "getTotalMemory":
      result(Int64(ProcessInfo.processInfo.physicalMemory))
    case "getUsedMemory":
      result(getUsedMemory())
    case "getAppMemoryUsage":
      result(getAppMemoryUsage())
    case "getTotalDiskSpace":
      result(getTotalDiskSpace())
    case "getUsedDiskSpace":
      result(getUsedDiskSpace())
    case "getAvailableDiskSpace":
      result(getAvailableDiskSpace())
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func getUsedMemory() -> Int64 {
    var taskInfo = task_vm_info_data_t()
    var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
    let kerr: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
      $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
        task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
      }
    }
    if kerr == KERN_SUCCESS {
      return Int64(taskInfo.phys_footprint)
    } else {
      return 0
    }
  }

  private func getAppMemoryUsage() -> Int64 {
    return Int64(mach_task_self_)
  }

  private func getTotalDiskSpace() -> Int64 {
    guard let space = try? URL(fileURLWithPath: NSHomeDirectory()).resourceValues(forKeys: [.volumeTotalCapacityKey]).volumeTotalCapacity else {
      return 0
    }
    return Int64(space)
  }

  private func getUsedDiskSpace() -> Int64 {
    guard let space = try? URL(fileURLWithPath: NSHomeDirectory()).resourceValues(forKeys: [.volumeAvailableCapacityKey]).volumeAvailableCapacity else {
      return 0
    }
    return getTotalDiskSpace() - Int64(space)
  }

  private func getAvailableDiskSpace() -> Int64 {
    guard let space = try? URL(fileURLWithPath: NSHomeDirectory()).resourceValues(forKeys: [.volumeAvailableCapacityKey]).volumeAvailableCapacity else {
      return 0
    }
    return Int64(space)
  }


}
