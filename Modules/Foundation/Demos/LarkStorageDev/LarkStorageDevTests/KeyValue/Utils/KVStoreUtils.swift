//
//  KVStoreUtils.swift
//  LarkStorageDevTests
//
//  Created by 7Up on 2022/5/20.
//

import Foundation
import XCTest
@testable import LarkStorageCore
@testable import LarkStorage

func paths(forConfig config: KVStoreConfig, suite: KVCipherSuite?) -> [AbsPath] {
    switch config.type {
    case .udkv:
        let suiteName = KVStores.udSuiteName(forConfig: config, cipherSuite: suite)
        return [AbsPath.library + "Preferences" + "\(suiteName).plist"]
    case .mmkv:
        let mmapId = KVStores.mmkvId(forConfig: config, cipherSuite: suite)
        return [
            AbsPath(KVStores.mmkvRootPath(with: config.mode)!) + mmapId,
            AbsPath(KVStores.mmkvRootPath(with: config.mode)!) + "\(mmapId).crc"
        ]
    }
}

func makeStore(forConfig config: KVStoreConfig, suite: KVCipherSuite?) -> KVStore {
    var store: KVStore
    switch config.type {
    case .udkv:
        store = KVStores.udkv(space: config.space, domain: config.domain, mode: config.mode)
    case .mmkv:
        store = KVStores.mmkv(space: config.space, domain: config.domain, mode: config.mode)
    }
    if let suite = suite {
        store = store.usingCipher(suite: suite)
    }
    return store
}

// MARK: - UserDefaults Utils

/// Utils about UserDefaults
struct UD {
    static func rootPath() -> String {
        let libraryPath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0]
        return (libraryPath as NSString).appendingPathComponent("Preferences")
    }

    static func suiteName(with space: Space, mode: UDKVStoreMode = .normal) -> String {
        KVStores.udSuiteName(for: space, mode: mode)
    }

    static func store(with suiteName: String) -> UDKVStore? {
        return UDKVStore(suiteName: suiteName)
    }
}

// MARK: - MMKV Utils

/// Utils about MMKV
struct MM {
    typealias Config = (mmapId: String, rootPath: String)

    static func config(with space: Space, mode: MMKVStoreMode = .normal) -> Config {
        return (KVStores.mmkvId(with: space), KVStores.mmkvRootPath(with: .normal)!)
    }

    static func store(with config: Config) -> MMKVStore? {
        return .init(mmapId: config.mmapId, rootPath: config.rootPath)
    }

    static func filePath(with config: Config) -> String {
        return (config.rootPath as NSString).appendingPathComponent(config.mmapId)
    }
}

extension KVStoreBase {
    func realAllKeys() -> [String] {
        let originalDelegate = self.delegate
        defer { self.delegate = originalDelegate }
        self.delegate = nil
        return allKeys()
    }

    func realAllValues() -> [String : Any] {
        let originalDelegate = self.delegate
        defer { self.delegate = originalDelegate }
        self.delegate = nil
        return allValues()
    }

    func realClearAll() {
        let originalDelegate = self.delegate
        defer { self.delegate = originalDelegate }
        self.delegate = nil
        clearAll()
    }
}

extension KVStores {
    static func store(with config: KVStoreConfig) -> KVStore {
        switch config.type {
        case .udkv:
            return KVStores.udkv(space: config.space, domain: config.domain, mode: config.mode)
        case .mmkv:
            return KVStores.mmkv(space: config.space, domain: config.domain, mode: config.mode)
        }
    }

    static func clearStore(_ store: KVStore) {
        store.clearAll()
        guard let base = store.findBase() else { return }
        if let _ = base as? UDKVStore {
            // UserDefaults 不方便删除
        } else if let mmkv = base as? MMKVStore {
            if mmkv.allKeys().isEmpty {
                base.filePaths.forEach {
                    try? FileManager.default.removeItem(atPath: $0)
                }
                mmkv.removeFromCache()
            }
        }
    }

}

extension UserDefaults {
    static func removeFile(_ userDefaults: UserDefaults, suiteName: String) throws {
        let dictionary = userDefaults.dictionaryRepresentation()
        dictionary.keys.forEach(userDefaults.removeObject(forKey:))
        let path = (AbsPath.library + "Preferences" + "\(suiteName).plist")
        try path.notStrictly.removeItem()
    }
}

extension Space {
    static func uuidUser(prefix: Int = 5, type: String = "", function: String = #function) -> Self {
        .user(id: type + function + String(UUID().uuidString.prefix(prefix)))
    }
}

extension DomainConvertible {
    func funcChild(function: String = #function) -> Domain {
        child(function)
    }

    func uuidChild(prefix length: Int = 5) -> Domain {
        child(String(UUID().uuidString.prefix(length)))
    }
}
