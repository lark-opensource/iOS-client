//
//  Utils+Device.swift
//  LarkFoundation
//
//  Created by K3 on 2018/6/12.
//  Copyright © 2018 com.bytedance.lark. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation
import LarkCompatible

public final class Utils {}

public extension Utils {
    //当前设备是否是模拟器
    static var isSimulator: Bool = TARGET_OS_SIMULATOR != 0

    static var appName = Bundle.main.infoDictionary?[kCFBundleIdentifierKey as String] as? String ?? ""
    static var appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    static var appBeta: String {
        let beta = appVersion.lf.matchingStrings(regex: "[a-zA-Z]+(\\d+)").first?[1] ?? "0"
        return beta
    }
    static var buildVersion = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String ?? ""
  
    static var omegaVersion = {
      let versionCode = Int(Bundle.main.infoDictionary?["LarkAlchemyVersionString"] as? String ?? "")
      guard let versionCode else {
        return ""
      }
      return "\(versionCode)"
    }()

    static var machineType: String {
        //获取模拟器对应的deviceModel
        if self.isSimulator, let simulatorDeviceModel = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return simulatorDeviceModel
        }
        //获取真机deviceModel,模拟器用下面方法获取的值是arm64。
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)
        let identifier = mirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }

    // 检查相机权限
    class func cameraPermissions() -> Bool {
        let authStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        if authStatus == .denied || authStatus == .restricted {
            return false
        }
        return true
    }

    static var isiOSAppOnMac: Bool {
        // iOS14.0 beta1 isiOSAppOnMac会导致方法找不到而crash
        if #available(iOS 14.0.1, *) {
            var result = false
            if let systemVersion = Float(UIDevice.current.systemVersion) {
               if systemVersion >= 14.0 {
                    result = ProcessInfo.processInfo.isiOSAppOnMac
               }
            } else {
                result = ProcessInfo.processInfo.isiOSAppOnMac
            }
            return result
        }
        return false
    }

    static var isMacCatalystApp: Bool {
        if #available(iOS 13.0, *) {
            return ProcessInfo.processInfo.isMacCatalystApp
        }
        return false
    }

    static var isiOSAppOnMacSystem: Bool {
        return isiOSAppOnMac || isMacCatalystApp
    }
}

// CPU & Memory

public extension Utils {

    /// 获取 CPU 平均使用率（已除以核心数）
    static var averageCPUUsage: Float {
        get throws {
            enum CPUMonitorError: Error {
                case oneThreadCPUMonitorFailed
                case cpuMonitorFailed
            }
            var totalCPUUsage: Float = 0
            var threadsList: thread_act_array_t?
            var threadsCount = mach_msg_type_number_t()
            let threadsResult = task_threads(mach_task_self_, &threadsList, &threadsCount)
            if threadsResult == KERN_SUCCESS, let threadsList {
                for index in 0..<threadsCount {
                    var threadInfo = thread_basic_info()
                    var threadInfoCount = mach_msg_type_number_t(THREAD_INFO_MAX)
                    let infoResult = withUnsafeMutablePointer(to: &threadInfo) {
                        $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                            thread_info(threadsList[Int(index)], thread_flavor_t(THREAD_BASIC_INFO), $0, &threadInfoCount)
                        }
                    }
                    if infoResult == KERN_SUCCESS {
                        let threadBasicInfo = threadInfo as thread_basic_info
                        if threadBasicInfo.flags & TH_FLAGS_IDLE == 0 {
                            totalCPUUsage = (totalCPUUsage + (Float(threadBasicInfo.cpu_usage) / Float(TH_USAGE_SCALE) * 100.0))
                        }
                    } else {
                        throw CPUMonitorError.oneThreadCPUMonitorFailed
                    }
                }
            } else {
                throw CPUMonitorError.cpuMonitorFailed
            }
            vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: threadsList)), vm_size_t(Int(threadsCount) * MemoryLayout<thread_t>.stride))
            let processCount = ProcessInfo.processInfo.activeProcessorCount
            let averageCPUUsage: Float = totalCPUUsage / Float(processCount)
            return averageCPUUsage
        }
    }

    /// 空闲内存，单位 Bytes，模拟器返回 Int64.max
    static var availableMemory: Int64 {
        get throws {
            // 模拟器不检测具体可用内存
#if targetEnvironment(simulator)
            return .max
#else
            enum MemoryFetchError: Error {
                case fetchVMStatisticsFailed
            }
            var page_size: vm_size_t = 0

            let host_port = mach_host_self()
            var host_size = mach_msg_type_number_t(MemoryLayout<vm_statistics_data_t>.stride / MemoryLayout<integer_t>.stride)
            host_page_size(host_port, &page_size)

            var vm_stat = vm_statistics_data_t()
            try withUnsafeMutablePointer(to: &vm_stat) { vm_stat_pointer in
                try vm_stat_pointer.withMemoryRebound(to: integer_t.self, capacity: Int(host_size)) {
                    if host_statistics(host_port, HOST_VM_INFO, $0, &host_size) != KERN_SUCCESS {
                        throw MemoryFetchError.fetchVMStatisticsFailed
                    }
                }
            }
            let mem_free = Int64(vm_stat.free_count) * Int64(page_size)
            return mem_free
#endif
        }
    }
}

extension String: LarkFoundationExtensionCompatible {}

extension LarkFoundationExtension where BaseType == String {
    public func matchingStrings(regex: String, options: NSRegularExpression.Options = []) -> [[String]] {
        guard let regex = try? NSRegularExpression(pattern: regex, options: options) else { return [] }
        let nsString = self.base as NSString
        let results = regex.matches(in: self.base, options: [], range: NSRange(location: 0, length: nsString.length))
        return results.map { result in
            (0..<result.numberOfRanges).map { result.range(at: $0).location != NSNotFound
                ? nsString.substring(with: result.range(at: $0))
                : ""
            }
        }
    }
}
