//
//  UIDevice+IllegalDetection.swift
//  IsJailBroken
//
//  Created by Vineet Choudhary on 07/02/20.
//  Source: https://github.com/developerinsider/isJailBroken/blob/master/IsJailBroken/Extension/UIDevice%2BJailBroken.swift
//  Copyright © 2020 Developer Insider. All rights reserved.
//
import Foundation
import UIKit
import ECOProbe
import LKCommonsLogging

private let logger = Logger.oplog(UIDevice.self, category: "GetSecurityInfo")

/// UIDevice extension to detect if device is jailbroken
extension UIDevice {
    /// detect debugging environment
    /// Reference: https://wisonlin.github.io/2014/08/09/2014-08-09-pan-duan-zi-ji-de-ying-yong-shi-fou-bei-diao-shi-qi-dong/
    var isDebug: Bool {
        var info = kinfo_proc()
        var mib : [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.stride
        let junk = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
        let message = "sysctl failed"
        let condition = (junk == 0)
        if !condition {
            logger.warn(message)
        }
        assert(condition, message)
        return (info.kp_proc.p_flag & P_TRACED) != 0
    }

    /// detect when app is running on simulator
    /// Reference: https://stackoverflow.com/a/48871580
    var isSimulator: Bool {
        return (ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] != nil)
    }

    /// detect when app is jailbroken
    var isIllegal: Bool {
        get {
            if UIDevice.current.isSimulator { return false }
            if IllegalDetectionHelper.hasCydiaInstalled() { return true }
            if IllegalDetectionHelper.isContainsSuspiciousApps() { return true }
            if IllegalDetectionHelper.isSuspiciousSystemPathsExists() { return true }
            return IllegalDetectionHelper.canEditSystemFiles()
        }
    }
}

/// Helper to detect if device is jailbroken
private struct IllegalDetectionHelper {
    /// check if cydia is installed (using URI Scheme)
    static func hasCydiaInstalled() -> Bool {
        return UIApplication.shared.canOpenURL(URL(string: "cydia://")!)
    }

    /// Check if suspicious apps (Cydia, FakeCarrier, Icy etc.) is installed
    static func isContainsSuspiciousApps() -> Bool {
        for path in suspiciousAppsPathToCheck {
            if LSFileSystem.fileExists(filePath: path) {
                return true
            }
        }
        return false
    }

    /// Check if system contains suspicious files
    static func isSuspiciousSystemPathsExists() -> Bool {
        for path in suspiciousSystemPathsToCheck {
            if LSFileSystem.fileExists(filePath: path) {
                return true
            }
        }
        return false
    }

    /// Check if app can edit system files
    static func canEditSystemFiles() -> Bool {
        let jailBreakText = "Developer Insider"
        do {
            try jailBreakText.write(toFile: jailBreakText, atomically: true, encoding: .utf8)
            return true
        } catch {
            return false
        }
    }

    /// suspicious apps path to check
    static var suspiciousAppsPathToCheck: [String] {
        return ["/Applications/Cydia.app",
                "/Applications/blackra1n.app",
                "/Applications/FakeCarrier.app",
                "/Applications/Icy.app",
                "/Applications/IntelliScreen.app",
                "/Applications/MxTube.app",
                "/Applications/RockApp.app",
                "/Applications/SBSettings.app",
                "/Applications/WinterBoard.app"
        ]
    }

    /// suspicious system paths to check
    static var suspiciousSystemPathsToCheck: [String] {
        return ["/Library/MobileSubstrate/DynamicLibraries/LiveClock.plist",
                "/Library/MobileSubstrate/DynamicLibraries/Veency.plist",
                "/private/var/lib/apt",
                "/private/var/lib/apt/",
                "/private/var/lib/cydia",
                "/private/var/mobile/Library/SBSettings/Themes",
                "/private/var/stash",
                "/private/var/tmp/cydia.log",
                "/System/Library/LaunchDaemons/com.ikey.bbot.plist",
                "/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist",
                "/usr/bin/sshd",
                "/usr/libexec/sftp-server",
                "/usr/sbin/sshd",
                "/etc/apt",
                "/bin/bash",
                "/Library/MobileSubstrate/MobileSubstrate.dylib"
        ]
    }
}
