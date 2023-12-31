//
//  DIDManager.swift
//  LarkSensitivityControl
//
//  Created by huanzhengjie on 2023/11/25.
//

import Foundation
import UIKit
import LarkSnCService

struct DIDModel: Codable, Equatable {
    
    /// 设备型号，稳定特征
    let deviceModel: String
    /// 系统启动时间，每次系统启动重置，一般情况下都是递增
    let sysBootTime: TimeInterval
    /// app 版本
    let appVersion: String
    /// 系统启动uuid，每次系统启动重置
    let bootSessionuuid: String
    /// idfv，卸载重装重置
    var vendorID: String
    
    func isValid() -> Bool {
        return !deviceModel.isEmpty && sysBootTime > 0 && !appVersion.isEmpty && !bootSessionuuid.isEmpty && !vendorID.isEmpty
    }
    
    func toDict(withSuffix suffix: String) -> [String: Any] {
        return ["deviceModel_\(suffix)": deviceModel,
                "sysBootTime_\(suffix)": sysBootTime,
                "appVersion_\(suffix)": appVersion,
                "bootSessionuuid_\(suffix)": bootSessionuuid,
                "vendorID_\(suffix)": vendorID]
    }
    
    static func == (lhs: DIDModel, rhs: DIDModel) -> Bool {
        return lhs.deviceModel == rhs.deviceModel &&
        lhs.sysBootTime == rhs.sysBootTime &&
        lhs.appVersion == rhs.appVersion &&
        lhs.bootSessionuuid == rhs.bootSessionuuid &&
        lhs.vendorID == rhs.vendorID
    }
    
}

enum ActionType: Int {
    case commonUse = 0
    case newInstall = 1
    case migrationDiffDeviceModel = 2
    case updateInstallVendorID = 3
    case uninstallInstallVendorID = 4
    case updateInstallSysBootTime = 5
    case uninstallInstallSysBootTime = 6
    case updateInstallBootSessionuuid = 7
    case uninstallInstallBootSessionuuid = 8
    case migrationMaybeSysBootTime = 9
    case uninstallInstall = 10
    case migrationWithUd = 11
    case keychainSaveFailed = 12
    case udSaveFailed = 13
    case currentModelInavlid = 14
    case keychainReadFailed = 15
    case commonUseVendorID = 16
    case commonUseSysBootTime = 17
    case commonUseBootSessionuuid = 18
}

final public class DIDManager {
    private static let userdDefaultsPath = "did_model_from_userdefaults"
    private static let keychainPath = "did_model_from_keychain"
    private static let didModelUDCacheKey = "did_model_ud_cache_key"
    private static let kcSuccessSaveFlagKey = "keychain_success_save_flag_key"
    private static let simulatorModels: Set<String> = ["i386", "x86_64", "arm64"]
    
    /// keychain存储，卸载重装不会丢失
    private var kcDIDModel: DIDModel
    /// userDefaults存储，卸载重装丢失
    private var udDIDModel: DIDModel
    private var currentDIDModel: DIDModel
    private var kcSaveSuccess: Bool
    public static let shared = DIDManager()
    static var kcReacSuccess: Bool = false
    
    init() {
        kcDIDModel = Self.getDIDModelFromKeyChain()
        udDIDModel = Self.getDIDModelFromUserDefaults()
        currentDIDModel = Self.getDIDModelFromCurrentDevice()
        kcSaveSuccess = (Self.myUD.value(forKey: Self.kcSuccessSaveFlagKey) as? Bool) ?? false
    }
    
    public func updateCache() {
        guard currentDIDModel.isValid() else {
            LSC.logger?.info("currentDIDModel is invalid.")
            report(type: .currentModelInavlid)
            return
        }
        var udChanged = false
        if currentDIDModel != kcDIDModel {
            let success = Self.keyChainSaveData(data: currentDIDModel, withIdentifier: Self.keychainPath)
            if !success {
                report(type: .keychainSaveFailed)
                LSC.logger?.info("keychain save failed.")
            }
            Self.myUD.setValue(success, forKey: Self.kcSuccessSaveFlagKey)
            udChanged = true
        }
        if currentDIDModel != udDIDModel {
            do {
                let data = try JSONEncoder().encode(currentDIDModel)
                let jsonString = String(bytes: data, encoding: .utf8)
                Self.myUD.setValue(jsonString, forKey: Self.didModelUDCacheKey)
                udChanged = true
            } catch {
                LSC.logger?.info("Failed to encode model: \(error)")
            }
        }
        if udChanged {
            if !Self.myUD.synchronize() {
                report(type: .udSaveFailed)
            } else {
                if nil != UserDefaults(suiteName: Self.userdDefaultsPath) {
                    let filePath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0].appending("/Preferences/\(Self.userdDefaultsPath).plist")
                    addSkipBackupForFile(NSURL(fileURLWithPath: filePath))
                }
            }
        }
    }
    
    static var myUD: UserDefaults {
        if let ud = UserDefaults(suiteName: Self.userdDefaultsPath) {
            return ud
        } else {
            return UserDefaults.standard
        }
    }
    
    func addSkipBackupForFile(_ url: NSURL) {
        guard url.isFileURL else {
            return
        }
        do {
            guard url.checkResourceIsReachableAndReturnError(nil) else {
                return
            }
            var isExcludedFromBackup: AnyObject?
            try url.getResourceValue(&isExcludedFromBackup, forKey: URLResourceKey.isExcludedFromBackupKey)
            if let value = isExcludedFromBackup as? Bool, value == false {
                try url.setResourceValue(true, forKey: URLResourceKey.isExcludedFromBackupKey)
            }
        } catch {
            
        }
    }
    
    /// 内部子线程获取可能为nil，外部可以重置
    public func updateVendorID(_ vendorID: String) {
        guard !currentDIDModel.vendorID.isEmpty else {
            return
        }
        currentDIDModel.vendorID = vendorID
    }
    
    public func detectMigration() -> Bool {
        if Self.simulatorModels.contains(currentDIDModel.deviceModel) {
            // 过滤模拟器
            LSC.logger?.info("filter simulator.")
            return false
        }
        guard kcDIDModel.isValid() || udDIDModel.isValid() else {
            // 没有任何缓存信息，全新安装
            LSC.logger?.info("new install.")
            report(type: .newInstall)
            return false
        }
        guard cachedDeviceModel == currentDIDModel.deviceModel else {
            // 一键移机
            LSC.logger?.info("migration with diffrent device model.")
            report(type: .migrationDiffDeviceModel)
            return true
        }
        
        if cachedVendorID == currentDIDModel.vendorID && !cachedVendorID.isEmpty {
            if cachedAppVersion != currentDIDModel.appVersion {
                // 覆盖安装
                LSC.logger?.info("update install vendorID.")
                report(type: .updateInstallVendorID)
            } else if !udDIDModel.isValid() {
                // 卸载重装
                LSC.logger?.info("uninstall install vendorID.")
                report(type: .uninstallInstallVendorID)
            } else {
                LSC.logger?.info("common use vendorID.")
                report(type: .commonUseVendorID)
            }
            // 正常启动
            return false
        }
        
        if !udDIDModel.isValid() {
            // 卸载重装
            LSC.logger?.info("uninstall install.")
            report(type: .uninstallInstall)
            return false
        } else if !kcDIDModel.isValid() && kcSaveSuccess {
            if !Self.kcReacSuccess {
                report(type: .keychainReadFailed)
                LSC.logger?.info("keychain read failed.")
            } else {
                // 一键移机，ud迁移了，kc没有迁移
                LSC.logger?.info("migration with ud.")
                report(type: .migrationWithUd)
                return true
            }
        }
        
        if cachedSysBootTime == currentDIDModel.sysBootTime {
            if cachedAppVersion != currentDIDModel.appVersion {
                // 覆盖安装
                LSC.logger?.info("update install sysBootTime.")
                report(type: .updateInstallSysBootTime)
            } else if !udDIDModel.isValid() {
                // 卸载重装
                LSC.logger?.info("uninstall install sysBootTime.")
                report(type: .uninstallInstallSysBootTime)
            } else {
                LSC.logger?.info("common use sysBootTime.")
                report(type: .commonUseSysBootTime)
            }
            // 正常启动
            return false
        }
        
        if cachedBootSessionuuid == currentDIDModel.bootSessionuuid {
            if cachedAppVersion != currentDIDModel.appVersion {
                // 覆盖安装
                LSC.logger?.info("update install bootSessionuuid.")
                report(type: .updateInstallBootSessionuuid)
            } else if !udDIDModel.isValid() {
                // 卸载重装
                LSC.logger?.info("uninstall install bootSessionuuid.")
                report(type: .uninstallInstallBootSessionuuid)
            } else {
                LSC.logger?.info("common use bootSessionuuid.")
                report(type: .commonUseBootSessionuuid)
            }
            // 正常启动
            return false
        }
        
        if cachedSysBootTime > currentDIDModel.sysBootTime + 10.0 {
            // 疑似一键移机
            LSC.logger?.info("migration maybe sysBootTime")
            report(type: .migrationMaybeSysBootTime)
            return true
        }
        
        LSC.logger?.info("common use.")
        report(type: .commonUse)
        return false
    }
    
    public func showDataState(handler: ((String) -> Void)) {
        let dict = NSMutableDictionary()
        dict.addEntries(from: currentDIDModel.toDict(withSuffix: "now"))
        dict.addEntries(from: kcDIDModel.toDict(withSuffix: "kc"))
        dict.addEntries(from: udDIDModel.toDict(withSuffix: "ud"))
        let msg = (dict as Dictionary).toJsonString() ?? ""
        handler(msg)
    }
    
    public func updateCurrentModel() {
        kcDIDModel = Self.getDIDModelFromKeyChain()
        udDIDModel = Self.getDIDModelFromUserDefaults()
        currentDIDModel = Self.getDIDModelFromCurrentDevice()
        kcSaveSuccess = (Self.myUD.value(forKey: Self.kcSuccessSaveFlagKey) as? Bool) ?? false
    }
    
    private func report(type: ActionType) {
        let dict = NSMutableDictionary()
        dict.addEntries(from: currentDIDModel.toDict(withSuffix: "now"))
        dict.addEntries(from: kcDIDModel.toDict(withSuffix: "kc"))
        dict.addEntries(from: udDIDModel.toDict(withSuffix: "ud"))
        dict.setValue(type.rawValue, forKey: "type")
        LSC.monitor?.sendInfo(service: "did_params_report", category: dict as? [String: Any], metric: nil)
    }
    
    var cachedDeviceModel: String {
        kcDIDModel.deviceModel.isEmpty ? udDIDModel.deviceModel : kcDIDModel.deviceModel
    }
    
    var cachedVendorID: String {
        kcDIDModel.vendorID.isEmpty ? udDIDModel.vendorID : kcDIDModel.vendorID
    }
    
    var cachedBootSessionuuid: String {
        kcDIDModel.bootSessionuuid.isEmpty ? udDIDModel.bootSessionuuid : kcDIDModel.bootSessionuuid
    }
    
    var cachedSysBootTime: TimeInterval {
        kcDIDModel.sysBootTime <= 0 ? udDIDModel.sysBootTime : kcDIDModel.sysBootTime
    }
    
    var cachedAppVersion: String {
        kcDIDModel.appVersion.isEmpty ? udDIDModel.appVersion : kcDIDModel.appVersion
    }
    
    class func getDIDModelFromKeyChain() -> DIDModel {
        if let data = Self.keyChainReadData(identifier: Self.keychainPath) as? Data,
           let model = try? JSONDecoder().decode(DIDModel.self, from: data) {
            return model
        }
        return DIDModel(deviceModel: "", sysBootTime: 0, appVersion: "", bootSessionuuid: "", vendorID: "")
    }
    
    class func getDIDModelFromUserDefaults() -> DIDModel {
        if let jsonString = myUD.value(forKey: Self.didModelUDCacheKey) as? String,
           let data = jsonString.data(using: .utf8),
           let model = try? JSONDecoder().decode(DIDModel.self, from: data) {
            return model
        }
        return DIDModel(deviceModel: "", sysBootTime: 0, appVersion: "", bootSessionuuid: "", vendorID: "")
    }
    
    class func getDIDModelFromCurrentDevice() -> DIDModel {
        return DIDModel(deviceModel: getDeviceModel(),
                        sysBootTime: getBootTime(),
                        appVersion: getAppVersion(),
                        bootSessionuuid: getBootsessionuuid(), 
                        vendorID: getVendorID())
    }
    
    class func getDeviceModel() -> String {
        return getSysInfo(byname: "hw.machine")
    }
    
    class func getSysInfo(byname name: String) -> String {
        var size: size_t = 0
        sysctlbyname(name, nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: Int(size))
        sysctlbyname(name, &machine, &size, nil, 0)
        return String(cString: machine)
    }
    
    class func getBootTime() -> TimeInterval {
        var bootTime: timeval = timeval()
        // 获取系统的启动时间
        var size = MemoryLayout<timeval>.size
        let result = sysctlbyname("kern.boottime", &bootTime, &size, nil, 0)
        if result == 0 && size == MemoryLayout<timeval>.size {
            return TimeInterval(bootTime.tv_sec) + TimeInterval(bootTime.tv_usec) / 1_000_000.0
        } else {
            return 0
        }
    }
    
    class func getAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }
    
    class func getBootsessionuuid() -> String {
        return getSysInfo(byname: "kern.bootsessionuuid")
    }
    
    class func getVendorID() -> String {
        return UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
    }
    
}

extension DIDManager {
    /// 创建查询条件
    class func queryDict(identifier: String) -> NSMutableDictionary {
        // 创建一个条件字典
        let queryDict = NSMutableDictionary(capacity: 0)
        // 设置条件存储的类型
        queryDict.setValue(kSecClassGenericPassword, forKey: kSecClass as String)
        // 设置存储数据的标记
        queryDict.setValue(identifier, forKey: kSecAttrService as String)
        queryDict.setValue(identifier, forKey: kSecAttrAccount as String)
        queryDict.setValue("inhouse_did_keychain_service", forKey: kSecAttrService as String)
        // 设置数据访问属性，保证一键移机的场景不会同步
        queryDict.setValue(kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly, forKey: kSecAttrAccessible as String)
        queryDict.setValue(kCFBooleanFalse, forKey: kSecAttrSynchronizable as String)
        // 返回创建条件字典
        return queryDict
    }
    
    /// 存储数据
    class func keyChainSaveData(data: Any, withIdentifier identifier: String) -> Bool {
        // 获取存储数据的条件
        let queryDict = self.queryDict(identifier: identifier)
        // 删除旧的存储数据
        SecItemDelete(queryDict)
        // 设置数据
        do {
            let cacheData = try JSONEncoder().encode(data as? DIDModel)
            queryDict.setValue(cacheData, forKey: kSecValueData as String)
            // 进行存储数据
            let saveState = SecItemAdd(queryDict, nil)
            if saveState == noErr {
                return true
            }
        } catch {
            LSC.logger?.info("Failed to encode model: \(error)")
        }
        return false
    }
    
    /// 获取数据
    class func keyChainReadData(identifier: String) -> Any? {
        var ret: Any?
        // 获取查询条件
        let queryDict = self.queryDict(identifier: identifier)
        // 提供查询数据的两个必要参数
        queryDict.setValue(kCFBooleanTrue, forKey: kSecReturnData as String)
        queryDict.setValue(kSecMatchLimitOne, forKey: kSecMatchLimit as String)
        // 创建获取数据的引用
        var queryResult: AnyObject?
        // 通过查询是否存储在数据
        let readStatus = withUnsafeMutablePointer(to: &queryResult) { 
            SecItemCopyMatching(queryDict, UnsafeMutablePointer($0))
        }
        if readStatus == errSecSuccess {
            if let cacheData = queryResult as? Data {
                ret = cacheData
            }
            Self.kcReacSuccess = true
        } else {
            Self.kcReacSuccess = false
        }
        return ret
    }
    
    /// 删除数据
    class func keyChianDelete(identifier: String) {
        // 获取删除的条件
        let queryDict = self.queryDict(identifier: identifier)
        // 删除数据
        SecItemDelete(queryDict)
    }
}
