//
//  LarkSafeMode.swift
//  LarkSafeMode
//
//  Created by sniperj on 2020/9/1.
//

import UIKit
import Foundation
import BootManager
import Heimdallr
import LarkContainer
import LKCommonsLogging
import LKCommonsTracker
import LarkDebugExtensionPoint
import EENavigator
import LarkReleaseConfig
import LarkAccountInterface

var CRASHCOUNTKEY: String = "lk_safe_mode_crash_count"
var SAFEMODEFOREMOSTENABLE: String = "lk_safe_mode_foremost_enable"
var SAFEMODERUNTIMENABLE: String = "lk_safe_mode_runtime_enable"
var SAFEMODEPUREENABLE: String = "lk_safe_mode_pure_enable"
var LAUNCHCRASHTIMEINTERVAL: String = "lk_safe_mode_launch_crash_interval"
var LEVEL1ALARMCOUNT: String = "lk_safe_mode_level_1_alram_count"
var LEVEL2ALARMCOUNT: String = "lk_safe_mode_level_2_alram_count"
var LEVEL3ALARMCOUNT: String = "lk_safe_mode_level_3_alarm_count"

var SAFEMODECONFIG: String = "lark_custom_exception_config"
var LARKSAFEMODE: String = "lk_safe_mode"
var LARKLAUNCHGUIDE: String = "LarkLaunchGuide"
var LARKPRIVACYALERT: String = "LarkPrivacyAlert"
var USERQUITE: String = "user_quite"
var PASSPORT: String = "passport"

var POINTAUTOCLEARSUCCESS: String = "launch_safe_mode_auto_cleaning_success"
var POINTMANUALCLEARSUCCESS: String = "launch_safe_mode_manual_cleaning_success"
var POINTDEEPCLEARSUCCESS: String = "launch_safe_mode_deep_cleaning_success"
var ENTERFOREMOST: String = "launch_safe_mode_foremost"

var POINTAUTOCLEAR: String = "launch_safe_mode_auto_cleaning"
var POINTMANUALCLEAR: String = "launch_safe_mode_manual_cleaning"
var POINTDEEPCLEAR: String = "launch_safe_mode_deep_cleaning"
var EVENTNAME: String = "launch_safe_mode"
var RUSTDATACORRUPT: String = "rust_data_corrupt"
var ENTERRUSTDATACORRUPT: String = "enter_rust_data_corrupt"
var RUSTPOINTDEEPCLEARSUCCESS: String = "safe_mode_deep_rust_data_clean_success"
var SAFEMODEPURECLEARSUCCESS: String = "safe_mode_pure_clean_success"
var USERFREEDISK: String = "user_free_disk"
var PURESAFEMODE: String = "lk_safe_mode_pure"

struct SafeModeItem: DebugCellItem {
    var title: String { return "安全模式" }

    var type: DebugCellType { return .disclosureIndicator }

    func didSelect(_ item: DebugCellItem, debugVC: UIViewController) {
        Navigator.shared.push(SafeModeDebugViewController(), from: debugVC)
    }
}

/// Lark safe mode, in order to prevent continuous abnormalities
/// docs url:  https://bytedance.feishu.cn/docs/doccndW1m28PiZNiSnMtnTwoGOb
public final class LarkSafeMode {

    // `UserDefaults(suiteName: LARKSAFEMODE)` 是 SafeMode 相关状态数据，用户无关，不进行 lark_storage 检查
    // lint:disable lark_storage_check

    private static let logger = Logger.log(LarkSafeMode.self)

    static private let userDefault = UserDefaults(suiteName: LARKSAFEMODE)
    static private var crashCount = UserDefaults.standard.integer(forKey: CRASHCOUNTKEY)
    static private var isExitByUser = userDefault?.bool(forKey: USERQUITE)

    static var safeModeForemostEnable: Bool = {
        if let foremostEnable = safeModeConfig?[SAFEMODEFOREMOSTENABLE] as? Bool {
            return foremostEnable
        }
        return false
    }()
    
    static var safeModeRuntimeEnable: Bool = {
        if let runtimeEnable = safeModeConfig?[SAFEMODERUNTIMENABLE] as? Bool {
            return runtimeEnable
        }
        return false
    }()
    
    static var safeModePureEnable: Bool = {
        if let foremostEnable = safeModeConfig?[SAFEMODEPUREENABLE] as? Bool {
            return foremostEnable
        }
        return false
    }()

    /// Abnormal in "timeThreshold" time, it is launch abnormal
    static private var timeThreshold: Int = {
        if let interval = safeModeConfig?[LAUNCHCRASHTIMEINTERVAL] as? Int {
            return interval
        }
        return 5
    }()

    /// There are “level1AlarmCount” abnormalities, it is a level 1 alarm
    static private var level1AlarmCount: Int = {
        if let interval = safeModeConfig?[LEVEL1ALARMCOUNT] as? Int {
            return interval
        }
        return 2
    }()

    /// There are “level2AlarmCount” abnormalities, it is a level 2 alarm
    static private var level2AlarmCount: Int = {
        if let interval = safeModeConfig?[LEVEL2ALARMCOUNT] as? Int {
            return interval
        }
        return 3
    }()

    /// There are “level3AlarmCount” abnormalities, it is a level 3 alarm
    static private var level3AlarmCount: Int = {
        if let interval = safeModeConfig?[LEVEL3ALARMCOUNT] as? Int {
            return interval
        }
        return 4
    }()
    
    static private var safeModeConfig: [String: Any]? = {
        if let config = userDefault?.value(forKey: SAFEMODECONFIG) as? [String: Any],
            config["safe_mode"] != nil {
            return config["safe_mode"] as? [String: Any]
        }
        return nil
    }()

    public static func PureSafeModeEnable() -> Bool {
        let safeModeCount = UserDefaults.standard.integer(forKey: CRASHCOUNTKEY)
        let sefeModePureEnable = UserDefaults.standard.bool(forKey: SAFEMODEPUREENABLE)
        let sefeModeLevel3US = UserDefaults.standard.integer(forKey: LEVEL3ALARMCOUNT)
        let safeModeLevel3 = sefeModeLevel3US == 0 ? 4 : sefeModeLevel3US
        printNSLog("[safeMode-PureSafeModeEnable:\(safeModeCount),\(sefeModePureEnable)]")
        return safeModeCount < safeModeLevel3 || !sefeModePureEnable
    }
    
    public static func PureSafeModeSettingUpdate() {
        printNSLog("[safeMode-PureSafeModeSettingUpdate]")
        UserDefaults.standard.setValue(0, forKey: CRASHCOUNTKEY)
        userDefault?.set(true, forKey: PURESAFEMODE)
        userDefault?.set(false, forKey: POINTMANUALCLEAR)
        UserDefaults.standard.synchronize()
    }
    
    static internal func checkwhetherEnterSafeMode() -> Bool {

        if let exitByUser = isExitByUser,
            exitByUser {
            return false
        }
        if checkwhetherLaunchExit() {
            return true
        }
        return false
    }

    static internal func addApplicationTerminateObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didEnterBackgroundNotification),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(willResignActiveNotification),
                                               name: UIApplication.willResignActiveNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(willReciveTerminate),
                                               name: UIApplication.willTerminateNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                                selector: #selector(rustPushDataCorrupt),
                                               name: Notification.Name(RUSTDATACORRUPT),
                                               object: nil)
    }

    @objc
    static internal func didEnterBackgroundNotification() {
        clearUserDefault()
        printNSLog("[safeMode-didEnterBackgroundNotification]:\(String(describing: isExitByUser))")
    }

    @objc
    static internal func willResignActiveNotification() {
        clearUserDefault()
        printNSLog("[safeMode-willResignActiveNotification]:\(String(describing: isExitByUser))")
    }

    @objc
    static internal func willReciveTerminate() {
        clearUserDefault()
        printNSLog("[safeMode-willReciveTerminate]:\(String(describing: isExitByUser))")
    }
    
    @objc
    static internal func clearUserDefault() {
        userDefault?.set(true, forKey: USERQUITE)
        userDefault?.set(false, forKey: RUSTDATACORRUPT)
        userDefault?.set(false, forKey: ENTERRUSTDATACORRUPT)
    }
    
    
    @objc
    static internal func rustPushDataCorrupt() {
        userDefault?.set(false, forKey: RUSTDATACORRUPT)
        userDefault?.set(true, forKey: ENTERRUSTDATACORRUPT)

        printNSLog("[safeMode-rustPushDataCorrupt]:\(String(describing: rustPushDataCorrupt))")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
            guard let keyWindows = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else {
                return
            }
            HMDTTMonitor.defaultManager().hmdUploadImmediatelyTrackService(EVENTNAME,
                                                                           metric: [POINTDEEPCLEAR: NSNumber(value: 1)],
                                                                           category: [RUSTDATACORRUPT: NSNumber(value: 1)],
                                                                           extra: [USERFREEDISK:NSNumber(value: HMDDiskUsage.getFreeDiskSpace())])
            keyWindows.rootViewController = UINavigationController(rootViewController: SafeModeViewController(clear: LarkSafeModeUtil.deepClearAllUserCache))
        })
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    static internal func processException(_ callback: @escaping (Bool, @escaping () -> Void) -> Void) {
        // Use API provided by slardar to determine the reason for the last program exit
        HMDBootingProtection.appExitReason(withLaunchCrashTimeThreshold: TimeInterval(timeThreshold)) { (reson, _, _) in
            // if exit by crash,watchdog or oom.We need to judge whether to enter safe mode
            if reson == HMDApplicationRelaunchReasonCrash ||
                reson == HMDApplicationRelaunchReasonFOOM ||
                reson == HMDApplicationRelaunchReasonWatchDog {
                if crashCount == level1AlarmCount {
                    printNSLog("[safeMode-processException-POINTAUTOCLEAR]")
                    // auto clear data
                    if let ud = userDefault {
                        ud.set(true, forKey: POINTAUTOCLEAR)
                        ud.synchronize()
                    }
                    LarkSafeModeUtil.autoClearUserCache()
                    Tracker.post(SlardarEvent(name: EVENTNAME,
                                              metric: [POINTAUTOCLEAR: "1"],
                                              category: [ENTERFOREMOST: "0"],
                                              extra: [:],
                                              immediately: true))
                    callback(false, {})
                } else if crashCount == level2AlarmCount {
                    printNSLog("[safeMode-processException-POINTMANUALCLEAR]")
                    // need enter safe mode
                    if let ud = userDefault {
                        ud.set(true, forKey: POINTMANUALCLEAR)
                        ud.set(false, forKey: POINTAUTOCLEAR)
                        ud.synchronize()
                    }
                    Tracker.post(SlardarEvent(name: EVENTNAME,
                                              metric: [POINTMANUALCLEAR: "1"],
                                              category: [ENTERFOREMOST: "0"],
                                              extra: [:],
                                              immediately: true))
                    callback(true, LarkSafeModeUtil.clearAllUserCache)
                    return
                } else if crashCount >= level3AlarmCount {
                    printNSLog("[safeMode-processException-DEEPCLEAR]")
                    // need enter safe mode
                    if let ud = userDefault {
                        ud.set(true, forKey: POINTDEEPCLEAR)
                        ud.set(false, forKey: POINTMANUALCLEAR)
                        ud.synchronize()
                    }
                    Tracker.post(SlardarEvent(name: EVENTNAME,
                                              metric: [POINTDEEPCLEAR: "1"],
                                              category: [ENTERFOREMOST: "0"],
                                              extra: [:],
                                              immediately: true))
                    callback(true, LarkSafeModeUtil.deepClearAllUserCache)
                    return
                } else {
                    printNSLog("[safeMode-processException-1] = \(crashCount)")
                    if let ud = userDefault {
                        ud.set(false, forKey: POINTDEEPCLEAR)
                        ud.set(false, forKey: POINTMANUALCLEAR)
                        ud.set(false, forKey: POINTAUTOCLEAR)
                        ud.synchronize()
                    }
                    callback(false, {})
                }
            } else {
                printNSLog("[safeMode-processException-NO]")
                callback(false, {})
            }
            normalProcess()
//            callback(true, {})
        }
    }

    static internal func processExceptionForemost(_ callback: @escaping (Bool, @escaping () -> Void) -> Void) {
        if crashCount == level1AlarmCount {
            printNSLog("[safeMode-processException-POINTAUTOCLEAR]")
            // auto clear data
            if let ud = userDefault {
                ud.set(true, forKey: POINTAUTOCLEAR)
                ud.synchronize()
            }
            LarkSafeModeUtil.autoClearUserCache()
            HMDTTMonitor.defaultManager().hmdUploadImmediatelyTrackService(EVENTNAME,
                                                                           metric: [POINTAUTOCLEAR: NSNumber(value: 1)],
                                                                           category: [ENTERFOREMOST: NSNumber(value: 1)],
                                                                           extra: [:])
            callback(false, {})
        } else if crashCount == level2AlarmCount {
            printNSLog("[safeMode-processExceptionForemost-POINTMANUALCLEAR]")
            crashCount += 1
            UserDefaults.standard.set(crashCount, forKey: CRASHCOUNTKEY)
            // need enter safe mode
            if let ud = userDefault {
                ud.set(true, forKey: POINTMANUALCLEAR)
                ud.set(false, forKey: POINTAUTOCLEAR)
                ud.set(true, forKey: USERQUITE)
                ud.synchronize()
            }
            HMDTTMonitor.defaultManager().hmdUploadImmediatelyTrackService(EVENTNAME,
                                                                           metric: [POINTMANUALCLEAR: NSNumber(value: 1)],
                                                                           category: [ENTERFOREMOST: NSNumber(value: 1)],
                                                                           extra: [:])
            callback(true, LarkSafeModeUtil.clearAllUserCache)
            return
        }
        else if crashCount >= level3AlarmCount && !safeModePureEnable {
            printNSLog("[safeMode-processExceptionForemost-DEEPCLEAR]")
            crashCount = 0
            UserDefaults.standard.set(crashCount, forKey: CRASHCOUNTKEY)
            // need enter safe mode
            if let ud = userDefault {
                ud.set(true, forKey: POINTDEEPCLEAR)
                ud.set(false, forKey: POINTMANUALCLEAR)
                ud.synchronize()
            }
            HMDTTMonitor.defaultManager().hmdUploadImmediatelyTrackService(EVENTNAME,
                                                                           metric: [POINTDEEPCLEAR: NSNumber(value: 1)],
                                                                           category: [ENTERFOREMOST: NSNumber(value: 1)],
                                                                           extra: [:])
            callback(true, LarkSafeModeUtil.deepClearAllUserCache)
            return
        }
        else {
            printNSLog("[safeMode-processExceptionForemost-else] = \(crashCount)")
            if let ud = userDefault {
                ud.set(false, forKey: POINTDEEPCLEAR)
                ud.set(false, forKey: POINTMANUALCLEAR)
                ud.set(false, forKey: POINTAUTOCLEAR)
                ud.synchronize()
            }
            callback(false, {})
        }
        normalProcessForemost()
    }

    static internal func normalProcess() {
        if let exitByUser = isExitByUser, exitByUser {
            userDefault?.set(false, forKey: USERQUITE)
            printNSLog("[safeMode-normalProcess-exitByUser:\(exitByUser)]")
        } else {
            crashCount += 1
            UserDefaults.standard.set(crashCount, forKey: CRASHCOUNTKEY)
            printNSLog("[safeMode-normalProcess-crashCount:\(crashCount)]")
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + TimeInterval(timeThreshold)) {
            crashCount = 0
            UserDefaults.standard.set(crashCount, forKey: CRASHCOUNTKEY)
            if let ud = userDefault {
                if ud.bool(forKey: POINTMANUALCLEAR) {
                    printNSLog("[safeMode-normalProcess-POINTMANUALCLEAR]")
                    Tracker.post(SlardarEvent(name: EVENTNAME,
                                              metric: [POINTMANUALCLEARSUCCESS: "1"],
                                              category: [ENTERFOREMOST: "0"],
                                              extra: [:]))

                }
                if ud.bool(forKey: POINTAUTOCLEAR) {
                    printNSLog("[safeMode-normalProcess-POINTAUTOCLEAR]")
                    Tracker.post(SlardarEvent(name: EVENTNAME,
                                              metric: [POINTAUTOCLEARSUCCESS: "1"],
                                              category: [ENTERFOREMOST: "0"],
                                              extra: [:]))
                }
                if ud.bool(forKey: POINTDEEPCLEAR) {
                    printNSLog("[safeMode-normalProcess-POINTDEEPCLEAR]")
                    Tracker.post(SlardarEvent(name: EVENTNAME,
                                              metric: [POINTDEEPCLEARSUCCESS: "1"],
                                              category: [ENTERFOREMOST: "0"],
                                              extra: [:]))
                }
                if ud.bool(forKey: ENTERRUSTDATACORRUPT) {
                    printNSLog("[safeMode-normalProcess-ENTERRUSTDATACORRUPT]")
                    Tracker.post(SlardarEvent(name: EVENTNAME,
                                              metric: [RUSTPOINTDEEPCLEARSUCCESS: "1"],
                                              category: [RUSTDATACORRUPT: NSNumber(value: 1)],
                                              extra: [USERFREEDISK:NSNumber(value: HMDDiskUsage.getFreeDiskSpace())]))
                }
                if ud.bool(forKey: PURESAFEMODE) {
                    printNSLog("[safeMode-normalProcess-PURESAFEMODE]")
                    HMDTTMonitor.defaultManager().hmdUploadImmediatelyTrackService(EVENTNAME,
                                                                                   metric: [SAFEMODEPURECLEARSUCCESS: NSNumber(value: 1)],
                                                                                   category: [ENTERFOREMOST: NSNumber(value: 1)],
                                                                                   extra: [:])
                }
                ud.set(false, forKey: POINTMANUALCLEAR)
                ud.set(false, forKey: POINTAUTOCLEAR)
                ud.set(false, forKey: POINTDEEPCLEAR)
                ud.set(false, forKey: RUSTDATACORRUPT)
                ud.set(false, forKey: ENTERRUSTDATACORRUPT)
                ud.set(false, forKey: PURESAFEMODE)
            }
        }
    }

    static internal func normalProcessForemost() {
        if let exitByUser = isExitByUser, exitByUser {
            userDefault?.set(false, forKey: USERQUITE)
            printNSLog("[safeMode-normalProcessForemost-exitByUser:\(exitByUser)]")
        } else {
            crashCount += 1
            UserDefaults.standard.set(crashCount, forKey: CRASHCOUNTKEY)
            printNSLog("[safeMode-normalProcessForemost-crashCount:\(crashCount)]")
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + TimeInterval(timeThreshold)) {
            crashCount = 0
            UserDefaults.standard.set(crashCount, forKey: CRASHCOUNTKEY)
            UserDefaults.standard.set(self.safeModePureEnable, forKey: SAFEMODEPUREENABLE)
            UserDefaults.standard.set(self.level3AlarmCount, forKey: LEVEL3ALARMCOUNT)
            printNSLog("[safeMode-asyncAfter-crashCount\(crashCount)")
            if let ud = userDefault {
                if ud.bool(forKey: POINTMANUALCLEAR) {
                    printNSLog("[safeMode-normalProcessForemost-POINTMANUALCLEAR]")
                    HMDTTMonitor.defaultManager().hmdUploadImmediatelyTrackService(EVENTNAME,
                                                                                   metric: [POINTMANUALCLEARSUCCESS: NSNumber(value: 1)],
                                                                                   category: [ENTERFOREMOST: NSNumber(value: 1)],
                                                                                   extra: [:])
                }
                if ud.bool(forKey: POINTAUTOCLEAR) {
                    printNSLog("[safeMode-normalProcessForemost-POINTAUTOCLEAR]")
                    HMDTTMonitor.defaultManager().hmdUploadImmediatelyTrackService(EVENTNAME,
                                                                                   metric: [POINTAUTOCLEARSUCCESS: NSNumber(value: 1)],
                                                                                   category: [ENTERFOREMOST: NSNumber(value: 1)],
                                                                                   extra: [:])
                }
                if ud.bool(forKey: POINTDEEPCLEAR) {
                    printNSLog("[safeMode-normalProcessForemost-POINTDEEPCLEAR]")
                    HMDTTMonitor.defaultManager().hmdUploadImmediatelyTrackService(EVENTNAME,
                                                                                   metric: [POINTDEEPCLEARSUCCESS: NSNumber(value: 1)],
                                                                                   category: [ENTERFOREMOST: NSNumber(value: 1)],
                                                                                   extra: [:])
                }
                if ud.bool(forKey: ENTERRUSTDATACORRUPT) {
                    printNSLog("[safeMode-normalProcessForemost-ENTERRUSTDATACORRUPT]")
                    HMDTTMonitor.defaultManager().hmdUploadImmediatelyTrackService(EVENTNAME,
                                                                                   metric: [RUSTPOINTDEEPCLEARSUCCESS: NSNumber(value: 1)],
                                                                                   category: [RUSTDATACORRUPT: NSNumber(value: 1)],
                                                                                   extra: [USERFREEDISK:NSNumber(value: HMDDiskUsage.getFreeDiskSpace())])
                }
                if ud.bool(forKey: PURESAFEMODE) {
                    printNSLog("[safeMode-normalProcessForemost-PURESAFEMODE]")
                    HMDTTMonitor.defaultManager().hmdUploadImmediatelyTrackService(EVENTNAME,
                                                                                   metric: [SAFEMODEPURECLEARSUCCESS: NSNumber(value: 1)],
                                                                                   category: [ENTERFOREMOST: NSNumber(value: 1)],
                                                                                   extra: [:])
                }

                ud.set(false, forKey: POINTMANUALCLEAR)
                ud.set(false, forKey: POINTAUTOCLEAR)
                ud.set(false, forKey: POINTDEEPCLEAR)
                ud.set(false, forKey: RUSTDATACORRUPT)
                ud.set(false, forKey: ENTERRUSTDATACORRUPT)
                ud.set(false, forKey: PURESAFEMODE)
            }
            //NotificationCenter.default.removeObserver(self)
        }
    }

    /// check application exit state
    static private func checkwhetherLaunchExit() -> Bool {
        printNSLog("[safeMode-checkwhetherLaunchExit-crashCount:\(crashCount)]")
        return crashCount >= 2
    }

    /// debug log for console
    /// - Parameter log: info
    static func printNSLog(_ log: String) {
        #if DEBUG
        NSLog(log)
        #endif
        logger.info(log)
    }
}

final class SafeModeUDBundleConfig: NSObject {
    static let SelfBundle: Bundle = {
        if let url = Bundle.main.url(forResource: "Frameworks/UniverseDesignEmpty", withExtension: "framework") {
            return Bundle(url: url)!
        } else {
            return Bundle.main
        }
    }()
    static let UniverseDesignEmptyBundleURL = SelfBundle.url(forResource: "UniverseDesignEmpty", withExtension: "bundle")
    static let UniverseDesignEmptyBundle: Bundle? = {
        if let bundleURL = UniverseDesignEmptyBundleURL {
            return Bundle(url: bundleURL)
        }
        return nil
    }()
}
