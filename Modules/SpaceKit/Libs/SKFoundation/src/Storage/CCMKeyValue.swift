//
//  CCMKeyValue.swift
//  SKCommon
//
//  Created by ByteDance on 2022/10/17.
//

import Foundation
import LarkStorage

/// 键值对存储API
public protocol CCMKeyValueStorage {
    func set(_ value: Codable?, forKey defaultName: String)
    func value<T: Codable>(forKey defaultName: String) -> T?
    func removeObject(forKey defaultName: String)
    
    func string(forKey defaultName: String) -> String?
    func data(forKey defaultName: String) -> Data?
    
    func integer(forKey defaultName: String) -> Int
    func integer(forKey defaultName: String, defaultValue: Int) -> Int
    func float(forKey defaultName: String) -> Float
    func float(forKey defaultName: String, defaultValue: Float) -> Float
    func double(forKey defaultName: String) -> Double
    func double(forKey defaultName: String, defaultValue: Double) -> Double
    func bool(forKey defaultName: String) -> Bool
    func bool(forKey defaultName: String, defaultValue: Bool) -> Bool
    
    func register(defaults: [String: Any])
    func allKeys() -> [String]
    
    // 兼容旧的 NSUserDefaults 复合类型数据, 新代码不建议使用
    func stringArray(forKey defaultName: String) -> [String]?
    func setStringArray(_ array: [String], forKey defaultName: String)
    func dictionary(forKey defaultName: String) -> [String: Any]?
    func setDictionary(_ dict: [String: Any], forKey defaultName: String)
}

public extension CCMKeyValueStorage {
    func integer(forKey defaultName: String) -> Int {
        integer(forKey: defaultName, defaultValue: 0)
    }
    func float(forKey defaultName: String) -> Float {
        float(forKey: defaultName, defaultValue: 0.0)
    }
    func double(forKey defaultName: String) -> Double {
        double(forKey: defaultName, defaultValue: 0.0)
    }
    func bool(forKey defaultName: String) -> Bool {
        bool(forKey: defaultName, defaultValue: false)
    }
}

/// 对外暴露的键值对工具
public struct CCMKeyValue {
    
    /// 全局的UserDefault
    public static var globalUserDefault: CCMKeyValueStorage {
        CCMUserDefaultKeyValue(store: KVStores.udkv(space: .global, domain: Domains.Business.ccm))
    }
    
    /// 单个用户的UserDefault
    public static func userDefault(_ userId: String) -> CCMKeyValueStorage {
        CCMUserDefaultKeyValue(store: KVStores.udkv(space: .user(id: userId), domain: Domains.Business.ccm))
    }
    
    ///单个用户的Onboarding数据
    public static func onboardingUserDefault(_ userId: String) -> CCMKeyValueStorage {
        CCMUserDefaultKeyValue(store: KVStores.udkv(space: .user(id: userId), domain: Domains.Business.ccm.child("Onboarding")))
    }
    
    /// 单个用户的MMKV
    public static func MMKV(subDomain: String = "", userId: String) -> CCMKeyValueStorage {
        let domain: LarkStorage.DomainType
        domain = subDomain.isEmpty ? Domains.Business.ccm : Domains.Business.ccm.child(subDomain)
        let store = KVStores.mmkv(space: .user(id: userId), domain: domain)
        return CCMUserDefaultKeyValue(store: store)
    }
}

// MARK: NSUserDefault

private struct CCMUserDefaultKeyValue: CCMKeyValueStorage {
    
    let store: KVStore
    
    /// value 为nil表示移除
    func set(_ value: Codable?, forKey defaultName: String) {
        guard let value = value else {
            store.removeValue(forKey: defaultName)
            return
        }
        store.set(value, forKey: defaultName)
    }

    func value<T>(forKey defaultName: String) -> T? where T: Codable {
        let result: T? = store.value(forKey: defaultName)
        return result
    }

    func removeObject(forKey defaultName: String) {
        store.removeValue(forKey: defaultName)
    }

    func string(forKey defaultName: String) -> String? {
        return store.value(forKey: defaultName)
    }
    
    func stringArray(forKey defaultName: String) -> [String]? {
        return store.value(forKey: defaultName)
    }
    
    func setStringArray(_ array: [String], forKey defaultName: String) {
        store.set(array, forKey: defaultName)
    }
    
    func dictionary(forKey defaultName: String) -> [String: Any]? {
        return store.dictionary(forKey: defaultName)
    }

    func setDictionary(_ dict: [String: Any], forKey defaultName: String) {
        store.setDictionary(dict, forKey: defaultName)
    }
    
    func data(forKey defaultName: String) -> Data? {
        return store.value(forKey: defaultName)
    }

    func integer(forKey defaultName: String, defaultValue: Int) -> Int {
        let result: Int? = store.value(forKey: defaultName)
        return result ?? defaultValue
    }

    func float(forKey defaultName: String, defaultValue: Float) -> Float {
        let result: Float? = store.value(forKey: defaultName)
        return result ?? defaultValue
    }
    
    func double(forKey defaultName: String, defaultValue: Double) -> Double {
        let result: Double? = store.value(forKey: defaultName)
        return result ?? defaultValue
    }
    
    func bool(forKey defaultName: String, defaultValue: Bool) -> Bool {
        let result: Bool? = store.value(forKey: defaultName)
        return result ?? defaultValue
    }
    
    func register(defaults: [String: Any]) {
        store.register(defaults: defaults)
    }
    
    func allKeys() -> [String] {
        store.allKeys()
    }
}

public class CCMKeyValueMigration {
    // KV数据迁移
    @_silgen_name("Lark.LarkStorage_KeyValueMigrationRegistry.CCM")
    public static func registerCCMMigration() {
        CCMKeyValueMigration.registerCCMGlobalKV()
        CCMKeyValueMigration.registerOnboardingKV()
        CCMKeyValueMigration.registerMMKV()
    }
    
    private static func registerCCMGlobalKV() {
        KVMigrationRegistry.registerMigration(forDomain: Domain.biz.ccm, strategy: .sync) { space in
            switch space {
            case .global:
                return [
                    .from(userDefaults: .standard, prefixPattern: "DocsCoreDefaultPrefix"),
                    .from(userDefaults: .standard, prefixPattern: "com.bytedance.ee.docs"),
                    .from(userDefaults: .standard, prefixPattern: "com.bytedance.docs.template"),
                    .from(userDefaults: .standard, items: [
                        "enableStatisticsEncryption" ~> "enableStatisticsEncryption",
                        "enableRustHttpKeyForTest" ~> "enableRustHttpKeyForTest",
                        "com.bytedance.ee.docs.geckoPackageVersion" ~> "com.bytedance.ee.docs.geckoPackageVersion",
                        "is_grid_layout" ~> "com.bytedance.ee.docs.is_grid_layout",
                        "remoteConfigKeyForWifiNetworkTimeOut" ~> "remoteConfigKeyForWifiNetworkTimeOut",
                        "remoteConfigKeyForCarrierNetworkTimeOut" ~> "remoteConfigKeyForCarrierNetworkTimeOut",
                        "UseThirdPartyJavascript" ~> "UseThirdPartyJavascript",
                        "JavascriptPath" ~> "JavascriptPath",
                        "Debug-LynxPreloadServer" ~> "Debug-LynxPreloadServer",
                        "Debug-LynxSheetServer" ~> "Debug-LynxSheetServer",
                        "testServerVersion" ~> "testServerVersion",
                        "agentToFrontend" ~> "agentToFrontend",
                        "frontendHost" ~> "frontendHost",
                        "agentRepeatModule" ~> "agentRepeatModule",
                        "remoteRN" ~> "remoteRN",
                        "RCTDevMenu" ~> "RCTDevMenu",
                        "driveVideoLogEnable" ~> "driveVideoLogEnable",
                        "remoteRNAddress" ~> "remoteRNAddress",
                        "RNHost" ~> "RNHost",
                        "OpenAPI_OfflineConfig_protocolEnable" ~> "OpenAPI_OfflineConfig_protocolEnable",
                        "clipping.doc.js.locol.file" ~> "clipping.doc.js.locol.file",
                        
                    ]),
                    .from(userDefaults: .standard, suffixPattern: "FEATURE_BADGE_KEY"),
                    .from(userDefaults: .standard, suffixPattern: "USER_GUIDE"),
                    .from(userDefaults: .standard, suffixPattern: "__doc_catalog_auto_show__"),
                    .from(userDefaults: .standard, suffixPattern: "__callout_block_default_attrs__"),
                    .from(userDefaults: .standard, suffixPattern: "__CALLOUT_GUIDE_DONE_KEY__"),
                    .from(userDefaults: .standard, suffixPattern: "code_block_toast_key"),
                    .from(userDefaults: .standard, suffixPattern: "__code_block_lang__"),
                    .from(userDefaults: .standard, suffixPattern: "__code_word_wrap_lang__"),
                    .from(userDefaults: .standard, suffixPattern: "VC_RECENT_POSITION"),
                    .from(userDefaults: .standard, suffixPattern: "RECENT_POSITION"),
                    .from(userDefaults: .standard, suffixPattern: "NOTIFY_DOUBLE_CLICK"),
                    .from(userDefaults: .standard, suffixPattern: "mindnote_last_view"),
                    .from(userDefaults: .standard, suffixPattern: "__panel_status_cache_key__"),
                    .from(userDefaults: .standard, suffixPattern: "geckoFetchEnable")
                    
                    
                ]
            case .user(id: let userId):
                return [
                    .from(userDefaults: .standard, items: [
                        "DocUserId_\(userId)" ~> "DocsCoreDefaultPrefix_UserProperties",
                        "mindnote_enabled_\(userId)" ~> "DocsCoreDefaultPrefix_mindnote_enabled",
                        // UserDefaultKeys.newCurrentFileDBVersionKey
                        "DocsCoreDefaultPrefix3050001\(userId)" ~> "DocsCoreDefaultPrefix3050001"
                    ])
                ]
            default:
                return []
            }
        }
    }
    private static func registerOnboardingKV() {
        KVMigrationRegistry.registerMigration(forDomain: Domain.biz.ccm.child("Onboarding"), strategy: .sync) { space in
            guard case .user(let uid) = space, !uid.isEmpty else {
                return []
            }
            return [
                .from(userDefaults: .suiteName("SpaceKitOnboarding"), prefixPattern: "\(uid)-")
            ]
        }
    }
    
    private static func registerMMKV() {
        // --------以下定义要与业务代码中的值同步
        let subdomain = "draft_comment"
        let lagacyPath = "platform/mmkv"
        let lagacyBizName = "draft_comment"
        let lagacyBizMmapId = "mmkv_data"
        // --------以上定义要与业务代码中的值同步
        let domain = Domain.biz.ccm.child(subdomain)
        KVMigrationRegistry.registerMigration(forDomain: domain, strategy: .sync) { space in
            guard case .user(let userId) = space, !userId.isEmpty else {
                return []
            }
            let sdkDir = AbsPath.library.appendingRelativePath("DocsSDK").absoluteString
            let rootPath = sdkDir + "/" + lagacyPath + "/" + lagacyBizName + "/"
            return [
                .from(
                    mmkv: .custom(mmapId: lagacyBizMmapId, rootPath: rootPath),
                    dropPrefixPattern: "\(userId) | ", // 与 CCMMMKVStorage - makeKey() 一致
                    type: Data.self
                )
            ]
        }
    }
}
