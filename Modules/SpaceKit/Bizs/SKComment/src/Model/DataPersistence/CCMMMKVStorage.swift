//
//  CCMMMKVStorage.swift
//  SKCommon
//
//  Created by zhouyanchen on 2022/8/9.
//

import MMKV
import Foundation
import SKFoundation
import SKCommon

// lint:disable lark_storage_migrate_check

/// MMKV 存储工具
public final class CCMMMKVStorage {
    
    // MARK: 新实现
    private let subDomain: String
    
    init(path: String) {
        self.subDomain = path
    }
    
    private func makeKey(userId: String, customKey: String) -> String {
        return "\(userId) | " + customKey
    }
    
    private func getMMKV(userId: String) -> CCMKeyValueStorage {
        let userId = currentUserId()
        return CCMKeyValue.MMKV(subDomain: subDomain, userId: userId)
    }
    
    private func currentUserId() -> String {
        guard let userId = User.current.basicInfo?.userID, !userId.isEmpty else {
            return "unknown"
        }
        return userId
    }
}

extension CCMMMKVStorage {
    
    public func getDataOfCurrentUser(forKey: String) -> Data? {
        let mmkv = getMMKV(userId: currentUserId())
        let data = mmkv.data(forKey: forKey)
        return data
    }
    
    public func setDataOfCurrentUser(_ data: Data, forKey: String) -> Bool {
        let mmkv = getMMKV(userId: currentUserId())
        mmkv.set(data, forKey: forKey)
        return true
    }
    
    public func removeDataOfCurrentUser(forKey: String) {
        let mmkv = getMMKV(userId: currentUserId())
        mmkv.removeObject(forKey: forKey)
    }
    
    public func removeAllKeysOfCurrentUserWith(prefix: String) {
        guard !prefix.isEmpty else { return }
        let mmkv = getMMKV(userId: currentUserId())
        var matchedKeys = [String]()
        let keys = mmkv.allKeys()
        for key in keys {
            if !key.isEmpty, key.hasPrefix(prefix) {
                matchedKeys.append(key)
            }
        }
        for key in matchedKeys {
            mmkv.removeObject(forKey: key)
        }
    }
}

extension CCMMMKVStorage {
    
    /// 移除所有符合过滤条件的数据
    public func removeAllData(filter: @escaping (Data) -> Bool) {
        var matchedKeys = [String]() // 符合过滤条件的所有key
        let mmkv = getMMKV(userId: currentUserId())
        let keys = mmkv.allKeys()
        for key in keys {
            if let data = mmkv.data(forKey: key), filter(data) {
                matchedKeys.append(key)
            }
        }
        for key in matchedKeys {
            mmkv.removeObject(forKey: key)
        }
    }
}

// lint:enable lark_storage_migrate_check
