//
//  KVUtils+Lark.swift
//  LarkStorage
//
//  Created by 7Up on 2023/6/16.
//

import Foundation

extension KVUtils {

    /// 清除 UserDefaults.standard 的数据
    /// - Parameter excludeKeys: 需要保留的 key
    /// - Parameter sync: 标记是否立即同步
    public static func clearStandardUserDefaults(excludeKeys: [String] = [], sync: Bool = false) {
        let userDefaults = UserDefaults.standard
        let exclude = Set(excludeKeys)
        for key in userDefaults.dictionaryRepresentation().keys where !exclude.contains(key) {
            userDefaults.removeObject(forKey: key)
        }
        if sync {
            userDefaults.synchronize()
        }
    }

}

extension KVStores {
    /// 清除当前用户的 KV 数据
    /// - Parameter type: 如果为空，则清除所有 KV 数据，否则只清楚指定 type 的数据
    public static func clearAllForCurrentUser(type: KVStoreType? = nil) {
        guard let userId = KVStores.getCurrentUserId?(), !userId.isEmpty else {
            return
        }
        clearAll(forSpace: .user(id: userId), type: type)
    }

    /// 清除 UserDefaults.standard 的数据
    @available(*, deprecated, message: "Please use `KVUtils.clearStandardUserDefaults`")
    public static func clearAllForStandard() {
        KVUtils.clearStandardUserDefaults(excludeKeys: [], sync: false)
    }
}
