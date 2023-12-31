//
// Created by maozhixiang.lip on 2023/3/8.
//

import Foundation
import LarkLocalizations

public struct Util {
    @inline(__always)
    public static func runInMainThread(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async(execute: block)
        }
    }

    public static func formatTime(_ time: CFTimeInterval) -> String {
        if time > 1 {
            return String(format: "%.3fs", time)
        } else {
            return String(format: "%.1fms", time * 1_000)
        }
    }

    public static var appName: String {
        LanguageManager.bundleDisplayName
    }

    public static var isiOSAppOnMacSystem: Bool {
        return isiOSAppOnMac || isMacCatalystApp
    }

    private static var isiOSAppOnMac: Bool {
        // iOS14.0 beta1 isiOSAppOnMac会导致方法找不到而crash
        if #available(iOS 14.0.1, *) {
            var result = false
            if let systemVersion = Float(UIDevice.current.systemVersion) {
                let compareVersion: Float = 14.0
                if systemVersion >= compareVersion {
                    result = ProcessInfo.processInfo.isiOSAppOnMac
                }
            } else {
                result = ProcessInfo.processInfo.isiOSAppOnMac
            }
            return result
        }
        return false
    }

    private static var isMacCatalystApp: Bool {
        if #available(iOS 13.0, *) {
            return ProcessInfo.processInfo.isMacCatalystApp
        }
        return false
    }

    public static func isOsVersionBetween(min: OperatingSystemVersion, max: OperatingSystemVersion) -> Bool {
        if ProcessInfo.processInfo.isOperatingSystemAtLeast(max) {
            return false
        } else if ProcessInfo.processInfo.isOperatingSystemAtLeast(min) {
            return true
        } else {
            return false
        }
    }
}

@inline(__always)
@usableFromInline
func assertMain(function: StaticString = #function) {
    assert(Thread.isMainThread, "Method must called in main thread: \(function)")
}
