//
//  LarkStorageAdapter.swift
//  LarkAccount
//
//  Created by au on 2023/3/21.
//

import LarkStorage

extension PassportStorageSpace {
    var larkStorageSpace: LarkStorage.Space {
        switch self {
        case .global:
            return .global
        case .user(id: let userID):
            return .user(id: userID)
        }
    }
}

extension PassportStorageKey {
    var larkStorageKey: String {
        return self.cleanValue
    }
}

final class LarkStorageAdapter: PassportStorage {

    private let kvStore: KVStore

    init(space: PassportStorageSpace, simplified: Bool = false, cipherSuite: KVCipherSuite = .aes) {
        var store = KVStores.mmkv(space: space.larkStorageSpace, domain: Domain.biz.passport).usingCipher(suite: cipherSuite)
        if simplified {
            store = store.simplified()
        }
        do {
            try store.excludeFromBackup()
        } catch {
            assertionFailure("Store init with error \(error).")
        }
        self.kvStore = store
    }

    func value<T>(forKey key: PassportStorageKey<T>) -> T? {
        kvStore.value(forKey: key.larkStorageKey)
    }

    func set<T>(_ value: T, forKey key: PassportStorageKey<T>) {
        kvStore.set(value, forKey: key.larkStorageKey)
    }

    func removeValue<T: Codable>(forKey key: PassportStorageKey<T>) {
        kvStore.removeValue(forKey: key.larkStorageKey)
    }
}
