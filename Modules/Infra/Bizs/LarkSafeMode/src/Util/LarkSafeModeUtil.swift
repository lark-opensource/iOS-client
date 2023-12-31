//
//  LarkSafeModeUtil.swift
//  AppContainer
//
//  Created by CL7R on 2020/9/9.
//

import Foundation
import RxSwift
import LarkContainer
import LarkSDKInterface
import LarkQuaterback
import LarkStorage

public final class LarkSafeModeUtil: NSObject {

    @Provider static private var cacheService: UserCacheService

    enum ItemPathType: UInt {
        case itemPathAll = 1
        case itemPathLarkUser = 2
        case itemPathDeep = 3
        case itemPathDeepPure = 4
    }

    public static func autoClearUserCache() {
        let semaphore = DispatchSemaphore(value: 0)
        LarkSafeMode.printNSLog("[safeMode-autoClearUserCache-0]")
        DispatchQueue.global().async {
            let path = NSHomeDirectory() + "/Documents"
            clearDirectory(path, .itemPathLarkUser)
            _ = cacheService.clearCache().subscribe(onCompleted: {
                LarkSafeMode.printNSLog("[safeMode-autoClearUserCache-1]")
                semaphore.signal()
            })
        }
        // block mainThread 3s
        _ = semaphore.wait(timeout: .now() + .seconds(3))
        LarkSafeMode.printNSLog("[safeMode-autoClearUserCache-2]")
    }

    public static func clearAllUserCache() {
        // clear 会清理did相关的缓存，先进行拉取操作
        Quaterback.shared.syncFetchBandages()

        var excludeKeys = [String]()
        // 保留语言环境
        excludeKeys.append(contentsOf: [
            KVPublic.Common.appleLanguages.key.raw,
            KVPublic.Common.appleLocale.key.raw,
            KVPublic.Common.systemLanguageIsSelected.key.raw,
        ])
        // 保留 crash 记录
        excludeKeys.append(CRASHCOUNTKEY)
        // 保留登录态
        excludeKeys.append("Passport.Store.LogoutTokenList")
        // 保留环境
        excludeKeys.append(contentsOf: [
            "isStdLarkKey",
            "debugEnvKey",
            "debugEnvKeyV2"
        ])
        // 保留热修复模块记录的App信息，如果不记录下次启动的时候会自动清理已经下载的热修包
        excludeKeys.append(contentsOf: [
            "kBDDQuaterbackAppInforKey",
            "safemode_hot_fix"
        ])
        KVUtils.clearStandardUserDefaults(excludeKeys: excludeKeys, sync: true)
        clearSandBox("Documents", .itemPathAll)
        clearSandBox("Library", .itemPathAll)
        clearSandBox("tmp", .itemPathAll)
    }

    public static func deepClearAllUserCache() {
        if let groupID = Bundle.main.infoDictionary!["EXTENSION_GROUP"] as? String,
           let groupPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID)?.path {
            clearDirectory(groupPath, .itemPathDeep)
        }
        // 保留热修复模块记录的App信息，如果不记录下次启动的时候会自动清理已经下载的热修包
        let excludeKeys = ["kBDDQuaterbackAppInforKey",
                           "lk_safe_mode_level_3_alarm_count",
                           "lk_safe_mode_pure_enable",
                           "safemode_hot_fix"]
        KVUtils.clearStandardUserDefaults(excludeKeys: excludeKeys, sync: true)
        clearSandBox("Documents", .itemPathDeep)
        clearSandBox("Library", .itemPathDeep)
        clearSandBox("tmp", .itemPathDeep)
    }
    
    public static func pureDeepClearAllUserCache() {
        KVUtils.clearStandardUserDefaults(excludeKeys: ["lk_safe_mode_pure"], sync: true)
        clearSandBox("Documents", .itemPathDeep)
        clearSandBox("Library", .itemPathDeep)
        clearSandBox("tmp", .itemPathDeep)
    }

    private static func clearSandBox(_ directory: String, _ type: ItemPathType) {
        let path = NSHomeDirectory() + "/\(directory)"
        clearDirectory(path, type)
    }

    private static func removeItemForAll(_ directoryPath: String) {
        // retain unzip_i18n folder
        if directoryPath.containsSubStr(find: "unzip_i18n") { return }
        // retain Library/Better folder
        if directoryPath.containsSubStr(find: "Library/Better") { return }
        guard directoryPath.containsSubStr(find: "Preferences")
                || directoryPath.containsSubStr(find: "sdk_storage") else {
            do {
                try FileManager.default.removeItem(atPath: directoryPath)
            } catch {
                NSLog("[safeMode-removeItemForAll-1]\(error)")
            }
            return
        }
        let bundleId = getBundleId()
        FileManager.default.enumerator(atPath: directoryPath)?.forEach({ (enumerator) in
            // retain safeMode plist
            if let str = enumerator as? String,
               !str.containsSubStr(find: LARKSAFEMODE),
               !str.containsSubStr(find: LARKLAUNCHGUIDE),
               !str.containsSubStr(find: LARKPRIVACYALERT),
               !str.containsSubStr(find: PASSPORT),
               !str.containsSubStr(find: "log"),
               !str.containsSubStr(find: bundleId) {
                do {
                    try FileManager.default.removeItem(atPath: directoryPath + "/\(str)")
                } catch {
                    NSLog("[safeMode-removeItemForAll-0]\(error)")
                }
            }
        })
    }

    private static func removeItemForDeep(_ directoryPath: String) {
        // retain unzip_i18n folder
        if directoryPath.containsSubStr(find: "unzip_i18n") { return }
        // retain Library/Better folder
        if directoryPath.containsSubStr(find: "Library/Better") { return }
        guard directoryPath.containsSubStr(find: "Preferences")
        || directoryPath.containsSubStr(find: "sdk_storage/log") else {
            do {
                try FileManager.default.removeItem(atPath: directoryPath)
            } catch {
                NSLog("[safeMode-removeItemForDeep-1]\(error)")
            }
            return
        }
        let bundleId = getBundleId()
        FileManager.default.enumerator(atPath: directoryPath)?.forEach({ (enumerator) in
            // retain safeMode and userdefault plist
            if let str = enumerator as? String,
               !str.containsSubStr(find: LARKSAFEMODE),
               !str.containsSubStr(find: bundleId),
               !str.containsSubStr(find: "sdk_storage/log") {
                do {
                    try FileManager.default.removeItem(atPath: directoryPath + "/\(str)")
                } catch {
                    NSLog("[safeMode-removeItemForDeep-0]\(error)")
                }
            }
        })
    }
    
    private static func pureRemoveItemForDeep(_ directoryPath: String) {
        FileManager.default.enumerator(atPath: directoryPath)?.forEach({ (enumerator) in
            // retain safeMode and userdefault plist
            if let str = enumerator as? String,
               !str.containsSubStr(find: "sdk_storage/log") {
                do {
                    try FileManager.default.removeItem(atPath: directoryPath + "/\(str)")
                } catch {
                    NSLog("[safeMode-removeItemForPure-0]\(error)")
                }
            }
        })
    }

    private static func removeItemLarkUser(_ directoryPath: String) {
        // clear user draf
        do {
            if directoryPath.containsSubStr(find: "LarkUser_") {
                try FileManager.default.removeItem(atPath: directoryPath)
            }
        } catch {
            NSLog("[safeMode-removeItemLarkUser-2]\(error)")
        }
    }

    private static func clearDirectory(_ path: String, _ type: ItemPathType) {
        var directoryPath = ""
        do {
            try FileManager.default.contentsOfDirectory(atPath: path).forEach { (itemPath) in
                directoryPath = path + "/\(itemPath)"
                if let fileType = try FileManager.default.attributesOfItem(atPath: directoryPath)[.type] as? FileAttributeType,
                    fileType == .typeDirectory {
                    switch type {
                    case .itemPathLarkUser:
                        removeItemLarkUser(directoryPath)
                        return
                    case .itemPathAll:
                        removeItemForAll(directoryPath)
                    case .itemPathDeep:
                        removeItemForDeep(directoryPath)
                    case .itemPathDeepPure:
                        pureRemoveItemForDeep(directoryPath)
                    }
                }
            }
        } catch {
            NSLog("[safeMode-clearDirectory-2]\(error)")
        }
    }

    private static func getBundleId() -> String {
        return Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String ?? ""
    }
}

extension String {
    func containsSubStr(find: String) -> Bool {
        return self.range(of: find) != nil
    }
}
