//
//  KVStoreBasicType.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation

protocol KVStoreBasicType {
    func save(in store: KVStoreBase, forKey key: String)
    static func load(from store: KVStoreBase, forKey key: String) -> Self?
}

// FIXME: 如下可模板生成

extension Int: KVStoreBasicType {
    func save(in store: KVStoreBase, forKey key: String) {
        store.saveValue(self, forKey: key)
    }

    static func load(from store: KVStoreBase, forKey key: String) -> Self? {
        return store.loadValue(forKey: key)
    }
}

extension Int64: KVStoreBasicType {
    func save(in store: KVStoreBase, forKey key: String) {
        store.saveValue(self, forKey: key)
    }

    static func load(from store: KVStoreBase, forKey key: String) -> Self? {
        return store.loadValue(forKey: key)
    }
}

extension Float: KVStoreBasicType {
    func save(in store: KVStoreBase, forKey key: String) {
        store.saveValue(self, forKey: key)
    }

    static func load(from store: KVStoreBase, forKey key: String) -> Self? {
        return store.loadValue(forKey: key)
    }
}

extension Double: KVStoreBasicType {
    func save(in store: KVStoreBase, forKey key: String) {
        store.saveValue(self, forKey: key)
    }

    static func load(from store: KVStoreBase, forKey key: String) -> Self? {
        return store.loadValue(forKey: key)
    }
}

extension String: KVStoreBasicType {
    func save(in store: KVStoreBase, forKey key: String) {
        store.saveValue(self, forKey: key)
    }

    static func load(from store: KVStoreBase, forKey key: String) -> Self? {
        return store.loadValue(forKey: key)
    }
}

extension Data: KVStoreBasicType {
    func save(in store: KVStoreBase, forKey key: String) {
        store.saveValue(self, forKey: key)
    }

    static func load(from store: KVStoreBase, forKey key: String) -> Self? {
        return store.loadValue(forKey: key)
    }
}

extension Date: KVStoreBasicType {
    func save(in store: KVStoreBase, forKey key: String) {
        store.saveValue(self, forKey: key)
    }

    static func load(from store: KVStoreBase, forKey key: String) -> Self? {
        return store.loadValue(forKey: key)
    }
}

extension Bool: KVStoreBasicType {
    func save(in store: KVStoreBase, forKey key: String) {
        store.saveValue(self, forKey: key)
    }

    static func load(from store: KVStoreBase, forKey key: String) -> Self? {
        return store.loadValue(forKey: key)
    }
}
