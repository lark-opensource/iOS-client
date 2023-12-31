//
//  PassportStore+Utility.swift
//  LarkAccount
//
//  Created by au on 2023/3/21.
//

import Foundation
import LarkStorage

// MARK: - Universal Storage

internal func migrateToUniversalStorage() {
    let kvStore = PassportStore.kvStore(space: .global, simplified: true)
    if !(kvStore.value(forKey: PassportStore.PassportStoreKey.universalStorageMigrationFlag) ?? false) {
        PassportStore.logger.info("n_action_passport_store: Migrate to universal storage.")
        kvStore.set(true, forKey: PassportStore.PassportStoreKey.universalStorageMigrationFlag)
    }
}

internal func rollbackToLegacyStorage() {
    let kvStore = PassportStore.kvStore(space: .global, simplified: true)
    if kvStore.value(forKey: PassportStore.PassportStoreKey.universalStorageMigrationFlag) ?? false {
        PassportStore.logger.info("n_action_passport_store: Rollback to legacy storage.")
        kvStore.removeValue(forKey: PassportStore.PassportStoreKey.universalStorageMigrationFlag)
        let executionBlock: () -> Void = {
            KVStores.clearMigrationMarks(forDomain: Domain.biz.passport)
            PassportStore.logger.info("n_action_passport_store: Rollback to legacy storage - done.")
        }
        if Thread.isMainThread {
            DispatchQueue.global().async(execute: executionBlock)
        } else {
            executionBlock()
        }
    }
}

extension PassportStore {

    // MARK: - MMKV Store

    /// 获取统一存储的 mmkv store
    /// simplified：功能简化，保留最基础功能，去除 log、track、migrate 等内容，目前只在 isLarkStorageEnabled 开关启用
    static func kvStore(space: PassportStorageSpace, simplified: Bool = false) -> PassportStorage {
        return LarkStorageAdapter(space: space, simplified: simplified)
    }
}
