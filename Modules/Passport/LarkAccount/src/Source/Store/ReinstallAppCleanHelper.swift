//
//  ReinstallAppCleanHelper.swift
//  LarkAccount
//
//  Created by au on 2021/12/2.
//

import Foundation
import KeychainAccess
import LKCommonsLogging

/// https://bytedance.feishu.cn/wiki/wikcnJEkuSwdFsmZLe1dbXQ5A7d
/// https://bytedance.feishu.cn/docx/doxcnyKC8t8efohbx8iBei28Mhg
/// 当用户带着登录态卸载 app 时，服务端无法感知卸载事件，此时用户相当于已登出
/// 这个卸载后的登录态可能会造成一些影响，例如不正确的 VoIP Push，在线设备依然存在等
/// 在用户重新安装 app 时，将 keychain 中保存的上一次带有效 session 的用户离线登出
final class ReinstallAppCleanHelper {

    private static let logger = Logger.plog(ReinstallAppCleanHelper.self, category: "Store.ReinstallAppCleanHelper")

    private static let executeQueue = DispatchQueue(label: "Passport.Store.Keychain.reinstallAppCleanHelper.queue")
    private static let userDefaults = UserDefaults.standard
    private static let sharedKeychain = Keychain(service: "Passport.Store.Keychain.reinstallAppCleanHelperKey").synchronizable(false).accessibility(.alwaysThisDeviceOnly)

    private static let privateKeychainService = "Passport.Store.Keychain.private.reinstallAppCleanHelperKey"
    private static let logoutTokenListKey = "Passport.Store.LogoutTokenList"
    /// true：已经从共享 keychain 迁移到私有
    private static let alreadyMigratedKey = "Passport.Store.alreadyMigrated"
    private static let separator = ","

    static func updateLogoutTokenList(_ tokens: [String]) {
        executeQueue.async {
            let value = tokens.joined(separator: Self.separator)
            Self.logger.info("n_action_reinstall_clean_helper_updateLogoutTokenList", additionalData: ["list": "\(tokens.map { $0.desensitized() })"])

            userDefaults.set(value, forKey: Self.logoutTokenListKey)
            if !PackageInfo.isChannelHZOversea() {
                sharedKeychain.commonSet(value, Self.logoutTokenListKey, logDesensitized: true)
            }
            guard let privateKeychain = Self.getPrivateKeychain() else {
                return
            }
            privateKeychain.commonSet(value, Self.logoutTokenListKey, logDesensitized: true)
        }
    }

    static func migrateFromSharedGroupToPrivateIfNeeded() {
        executeQueue.async {
            defer { userDefaults.set(true, forKey: Self.alreadyMigratedKey) }

            Self.logger.info("n_action_reinstall_clean_helper_migrate_start")

            userDefaults.register(defaults: [Self.alreadyMigratedKey: false])
            if userDefaults.bool(forKey: Self.alreadyMigratedKey) { return }

            let kContent = ReinstallAppCleanHelper.getLogoutTokenListStringFromPrivateKeychain()
            if !kContent.isEmpty { return }

            let uContent = ReinstallAppCleanHelper.getLogoutTokenListStringFromUserDefaults()
            if uContent.isEmpty { return }

            let sharedContent = sharedKeychain.commonGet(Self.logoutTokenListKey, logDesensitized: true) ?? ""
            // 只有 ud 和旧 keychain 都有值、新 keychain 没有值的时候做迁移
            guard ReinstallAppCleanHelper.inspectLogoutTokenFit(kContent: sharedContent, uContent: uContent) else { return }

            guard let keychain = Self.getPrivateKeychain() else { return }
            Self.logger.info("n_action_reinstall_clean_helper_migrate_succ")
            keychain.commonSet(sharedContent, Self.logoutTokenListKey, logDesensitized: true)
        }
    }

    static func logoutPreviousInstallUserIfNeeded() {
        executeQueue.async {
            let uContent = ReinstallAppCleanHelper.getLogoutTokenListStringFromUserDefaults()
            if !uContent.isEmpty { return }

            let kContent: String

            if PackageInfo.isChannelHZOversea() {
                // hz 同开发者帐号下会发两个包，华住海外从私有 Keychain 里获取，后续所有包保持一致
                Self.logger.info("n_action_reinstall_clean_helper_HZ_logoutPreviousInstallUserIfNeeded")
                kContent = ReinstallAppCleanHelper.getLogoutTokenListStringFromPrivateKeychain()
            } else {
                Self.logger.info("n_action_reinstall_clean_helper_logoutPreviousInstallUserIfNeeded")
                kContent = ReinstallAppCleanHelper.getLogoutTokenListStringFromSharedKeychain()
            }

            if kContent.isEmpty { return }
            if ReinstallAppCleanHelper.inspectLogoutTokenFit(kContent: kContent, uContent: uContent) { return }

            let tokens = ReinstallAppCleanHelper.fetchLogoutTokenListFromText(kContent)
            OfflineLogoutHelper.shared.append(logoutTokens: tokens)
            ReinstallAppCleanHelper.clearKeychainAndUserDefaultsData()
        }
    }

    /// true: Keychain 和 UserDefaults 里的数据一致，无需处理
    /// false: Keychain 和 UserDefaults 里的数据不一致，需要外部登出所有 Keychain 里的用户，并清空数据
    private static func inspectLogoutTokenFit(kContent: String, uContent: String) -> Bool {

        let kLog = kContent.components(separatedBy: Self.separator).map { $0.desensitized() }
        let uLog = uContent.components(separatedBy: Self.separator).map { $0.desensitized() }

        Self.logger.info("n_action_reinstall_clean_helper_inspectLogoutTokenStatus",
                         additionalData: ["k": "\(kLog)", "u": "\(uLog)"])

        return kContent == uContent
    }

    private static func fetchLogoutTokenListFromText(_ text: String) -> [String] {
        let log = text.components(separatedBy: Self.separator).map { $0.desensitized() }
        Self.logger.info("n_action_reinstall_clean_helper_fetchLogoutTokenListFromText",
                         additionalData: ["text": "\(log)"])
        if text.isEmpty {
            return []
        }
        return text.components(separatedBy: Self.separator)
    }

    private static func clearKeychainAndUserDefaultsData() {
        Self.logger.info("n_action_reinstall_clean_helper_clearKeychainAndUserDefaultsData")
        userDefaults.removeObject(forKey: Self.logoutTokenListKey)
        if !PackageInfo.isChannelHZOversea() {
            sharedKeychain.commonSet("", Self.logoutTokenListKey)
        }
        guard let privateKeychain = Self.getPrivateKeychain() else {
            return
        }
        privateKeychain.commonSet("", Self.logoutTokenListKey)
    }

    private static func getLogoutTokenListStringFromPrivateKeychain() -> String {
        Self.logger.info("n_action_reinstall_clean_helper_private_getLogoutTokenListStringFromKeychain")
        guard let keychain = Self.getPrivateKeychain() else {
            return ""
        }
        return keychain.commonGet(Self.logoutTokenListKey, logDesensitized: true) ?? ""
    }

    private static func getLogoutTokenListStringFromSharedKeychain() -> String {
        Self.logger.info("n_action_reinstall_clean_helper_shared_getLogoutTokenListStringFromKeychain")
        return sharedKeychain.commonGet(Self.logoutTokenListKey, logDesensitized: true) ?? ""
    }

    private static func getLogoutTokenListStringFromUserDefaults() -> String {
        Self.logger.info("n_action_reinstall_clean_helper_getLogoutTokenListStringFromUserDefaults")
        return userDefaults.string(forKey: Self.logoutTokenListKey) ?? ""
    }

    // 获取当前 app 私有的 Keychain
    private static func getPrivateKeychain() -> Keychain? {
        guard let teamID = Bundle.main.object(forInfoDictionaryKey: "AppIdentifierPrefix") as? String,
              let bundleID = Bundle.main.bundleIdentifier else {
            Self.logger.error("n_action_reinstall_clean_helper_team_or_bundle_nil")
            return nil
        }
        let group = teamID + bundleID
        return Keychain(service: Self.privateKeychainService, accessGroup: group).synchronizable(false).accessibility(.alwaysThisDeviceOnly)
    }
}
