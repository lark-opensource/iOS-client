//
//  PassportStorageMigration.swift
//  LarkAccount
//
//  Created by au on 2023/3/13.
//

import Foundation
import LarkStorage
import LKCommonsLogging

/// 将 Passport 存储的数据由 Isolator 迁移到 LarkStorage
public final class PassportStorageMigration {

    typealias Key = PassportStore.PassportStoreKey

    @_silgen_name("Lark.LarkStorage_KeyValueMigrationRegistry.Passport")
    public static func registerPassportMigration() {
        KVMigrationRegistry.registerMigration(forDomain: Domain.biz.passport, strategy: .sync) { space in
            switch space {
            case .global:
                return [
                    /// Passport previous universal storage which is using the `.passport` cipher suite.
                    .from(mmkv: .custom(mmapId: "lark_storage.Global.Domain_Passport.Cipher_passport", rootPath: "\(NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first ?? "")/MMKV"), to: .mmkv, cipherSuite: .passportRekey, items: [
                        .init(key: Key.eraseTaskIdentifier.cleanValue, type: String.self),
                        .init(key: Key.eraseUserScopeListKey.cleanValue, type: [EraseUserScope].self),
                    ]),
                    .from(userDefaults: .suiteName("com.bytedance.lark.passport.global_Global"),
                          to: .mmkv,
                          cipherSuite: .passport,
                          items: [
                            OfflineLogoutKey.logoutTokens.cleanValue ~> OfflineLogoutKey.logoutTokens.cleanValue
                          ]),
                    .from(userDefaults: .suiteName("com.bytedance.lark.passport.store_Global"),
                          to: .mmkv,
                          cipherSuite: .passport,
                          items: [
                            Key.migrationStatus.cleanValue ~> Key.migrationStatus.cleanValue,
                            Key.shouldUpgradeSession.cleanValue ~> Key.shouldUpgradeSession.cleanValue,
                            Key.dataIdentifier.cleanValue ~> Key.dataIdentifier.cleanValue,
                            Key.configEnv.cleanValue ~> Key.configEnv.cleanValue,
                            Key.configInfo.cleanValue ~> Key.configInfo.cleanValue,
                            Key.userLoginConfig.cleanValue ~> Key.userLoginConfig.cleanValue,
                            Key.regionCode.cleanValue ~> Key.regionCode.cleanValue,
                            Key.keepLogin.cleanValue ~> Key.keepLogin.cleanValue,
                            Key.loginMethod.cleanValue ~> Key.loginMethod.cleanValue,
                            Key.ssoPrefix.cleanValue ~> Key.ssoPrefix.cleanValue,
                            Key.ssoSuffix.cleanValue ~> Key.ssoSuffix.cleanValue,
                            Key.storedUUID.cleanValue ~> Key.storedUUID.cleanValue,
                            Key.logInstallID.cleanValue ~> Key.logInstallID.cleanValue,
                            Key.installIDMap.cleanValue ~> Key.installIDMap.cleanValue,
                            Key.deviceIDMap.cleanValue ~> Key.deviceIDMap.cleanValue,
                            Key.deviceID.cleanValue ~> Key.deviceID.cleanValue,
                            Key.installID.cleanValue ~> Key.installID.cleanValue,
                            Key.didChangedMap.cleanValue ~> Key.didChangedMap.cleanValue,
                            Key.indicatedIDP.cleanValue ~> Key.indicatedIDP.cleanValue,
                            Key.idpUserProfileMap.cleanValue ~> Key.idpUserProfileMap.cleanValue,
                            Key.idpAuthConfig.cleanValue ~> Key.idpAuthConfig.cleanValue,
                            Key.idpInternalConfig.cleanValue ~> Key.idpInternalConfig.cleanValue,
                            Key.idpExternalConfig.cleanValue ~> Key.idpExternalConfig.cleanValue,
                            Key.foregroundUserID.cleanValue ~> Key.foregroundUserID.cleanValue, // user:checked
                            Key.userIDList.cleanValue ~> Key.userIDList.cleanValue,
                            Key.hiddenUserIDList.cleanValue ~> Key.hiddenUserIDList.cleanValue,
                            Key.enableUserScope.cleanValue ~> Key.enableUserScope.cleanValue,
                            Key.enableInstallIDUpdatedSeparately.cleanValue ~> Key.enableInstallIDUpdatedSeparately.cleanValue,
                            Key.enableUUIDAndNewStoreReset.cleanValue ~> Key.enableUUIDAndNewStoreReset.cleanValue,
                            Key.recordLocalVerifyMethod.cleanValue ~> Key.recordLocalVerifyMethod.cleanValue,
                            Key.enableLazySetupEventRegister.cleanValue ~> Key.enableLazySetupEventRegister.cleanValue,
                            Key.tnsAuthURLRegex.cleanValue ~> Key.tnsAuthURLRegex.cleanValue,
                            Key.enableRegisterEntry.cleanValue ~> Key.enableRegisterEntry.cleanValue,
                            Key.universalDeviceServiceUpgraded.cleanValue ~> Key.universalDeviceServiceUpgraded.cleanValue,
                            Key.enableLeftNaviButtonsRootVCOpt.cleanValue ~> Key.enableLeftNaviButtonsRootVCOpt.cleanValue,
                            Key.enableNativeWebauthnRegister.cleanValue ~> Key.enableNativeWebauthnRegister.cleanValue,
                            Key.enableNativeWebauthnAuth.cleanValue ~> Key.enableNativeWebauthnAuth.cleanValue,
                            Key.passportGaryMap.cleanValue ~> Key.passportGaryMap.cleanValue
                          ])
                ]
            case .user(id: let userID):
                return [
                    .from(userDefaults: .suiteName("com.bytedance.lark.passport.store.user_\(userID)"),
                          to: .mmkv,
                          cipherSuite: .passport,
                          items: [
                            Key.user.cleanValue ~> Key.user.cleanValue
                          ])
                ]
            default:
                return []
            }
        }
    }

    @_silgen_name("Lark.LarkStorage_KeyValueCryptoRegistry.Passport")
    public static func registerPassportCipher() {
        KVCipherManager.shared.register(suite: .passport) { PassportCipher.shared }
        KVCipherManager.shared.register(suite: .passportRekey) {
            PassportRekeyCipher()
        }
    }
}

final class PassportCipher: KVCipher {
    static var shared = PassportCipher()

    func hashed(forKey key: String) -> String {
        return genKey(key)
    }

    func encrypt(_ data: Data) throws -> Data {
        // 此处调用原业务代码中的 aes 函数
        return try LarkAccount.aes(.encrypt, data)
    }

    func decrypt(_ data: Data) throws -> Data {
        // 此处调用原业务代码中的 aes 函数
        return try LarkAccount.aes(.decrypt, data)
    }
}

private final class PassportRekeyCipher: KVCipher {
    
    fileprivate init() {}

    fileprivate func hashed(forKey key: String) -> String {
        return genKey("lskv.space_Global.domain_Passport.\(key)")
    }

    fileprivate func encrypt(_ data: Data) throws -> Data {
        // 此处调用原业务代码中的 aes 函数
        return try LarkAccount.aes(.encrypt, data)
    }

    fileprivate func decrypt(_ data: Data) throws -> Data {
        // 此处调用原业务代码中的 aes 函数
        return try LarkAccount.aes(.decrypt, data)
    }
}
