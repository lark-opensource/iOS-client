//
//  KVStore+Config.swift
//  LarkStorage
//
//  Created by 7Up on 2023/4/1.
//

import Foundation

extension KVStore {
    /// 进行功能简化，只保留最基础功能，刨掉 log、track、migrate 等
    public func simplified() -> KVStore {
        if let logProxy: KVStoreLogProxy = findProxy() {
            logProxy.strategy = .disabled
        }
        if let trackProxy: KVStoreTrackProxy = findProxy() {
            trackProxy.strategy = .disabled
        }
        if let migrateProxy: KVStoreMigrateProxy = findProxy() {
            migrateProxy.disabled = true
        }
        return self
    }
}
