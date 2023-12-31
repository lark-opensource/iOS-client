//
//  PassportStore+User.swift
//  LarkAccount
//
//  Created by au on 2023/3/14.
//

import Foundation
import LarkAccountInterface

/// Normally, userId need to be encrypted. The encryption logic is `(prefixToken() + (userId + suffixToken()).md5()).sha1()`.
/// The prefixToken function is make `"ee".md5()` logic and the length up to 6 byte (from start to end).
/// The suffixToken funciton is also the same as the prefixToken function, however, return value from end to start.
private let prefix = "08a441"

/// @see prefix
private let suffix = "42b91e"

extension PassportStore {

    // 用户维度目前场景只有 user info，这里抽出操作用户的便捷 getter setter

    static func userInfoFromUserSpace(_ userID: String) -> V4UserInfo? {
        return valueFromUserSpace(forKey: PassportStoreKey.user, with: userID)
    }
    
    internal static func storeUserInfoToShared(userInfo: V4UserInfo?, userId: String) {
        if MultiUserActivitySwitch.enableMultipleUser {
            if let session = userInfo?.suiteSessionKey, let tenantId = userInfo?.user.tenant.id, let unit = userInfo?.user.unit {
                GlobalUserServiceImpl.shared.updateUser(userId: userId, userDao: UserDao(session: session, tenantId: tenantId, unit: unit, encryptedUserId: (prefix + (userId + suffix).md5()).sha1()))
            } else {
                GlobalUserServiceImpl.shared.updateUser(userId: userId, userDao: nil)
            }
        }
    }

    static func setUserInfoToUserSpace(_ userInfo: V4UserInfo?, with userID: String) {
        storeUserInfoToShared(userInfo: userInfo, userId: userID)
        setToUserSpace(userInfo, forKey: PassportStoreKey.user, with: userID)
    }

    // 原实现下，移除用户数据时会将对应的 isolator 删除
    static func removeUserInfo(_ userID: String) {
        if passportStorageCipherMigration {
            Self.setUserInfoToUserSpace(nil, with: userID)
        } else {
            Isolator.deleteIsolateData(namespace: .passportStoreUserInfoIsolator, isolatorLayersIds: [userID])
            storeUserInfoToShared(userInfo: nil, userId: userID)
        }
    }

    // MARK: -

    static func valueFromUserSpace<T>(forKey key: PassportStorageKey<T>, with userID: String) -> T? where T: Codable {
        if passportStorageCipherMigration {
            return Self.kvStore(space: .user(id: userID)).value(forKey: key)
        } else {
            let isolator = Isolator.createIsolateKVData(namespace: .passportStoreUserInfoIsolator, isolatorLayersIds: [userID], isolatorConfig: IsolatorConfig(loggerClass: PassportStore.self, shouldEncrypted: true))

            return isolator.get(key: key)
        }
    }

    static func setToUserSpace<T>(_ value: T?, forKey key: PassportStorageKey<T>, with userID: String) where T: Codable {
        if passportStorageCipherMigration {
            if let value = value {
                Self.kvStore(space: .user(id: userID)).set(value, forKey: key)
            } else {
                Self.kvStore(space: .user(id: userID)).removeValue(forKey: key)
            }
        } else {
            let isolator = Isolator.createIsolateKVData(namespace: .passportStoreUserInfoIsolator, isolatorLayersIds: [userID], isolatorConfig: IsolatorConfig(loggerClass: PassportStore.self, shouldEncrypted: true))
            _ = isolator.update(key: key, value: value)
        }
    }
}
