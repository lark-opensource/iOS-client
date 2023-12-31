//
//  KVClearTester.swift
//  LarkStorageDevTests
//
//  Created by 7Up on 2022/5/20.
//

import Foundation
import XCTest
@testable import LarkStorageCore
@testable import LarkStorage

class KVClearTester: Tester, KVStoreBaseDelegate {
    
    let store: KVStore
    let prefix = "KVClearTester"
    
    init(store: KVStore) {
        self.store = store
    }
    
    func run() {
        let base = findBase()
        let oldDelegate = base?.delegate
        defer { base?.delegate = oldDelegate }
        base?.delegate = self
        
        setItem(KVItems.bool)
        setItem(KVItems.int)
        setItem(KVItems.float)
        setItem(KVItems.double)
        setItem(KVItems.string)
        setItem(KVItems.data)
        
        checkItem1(KVItems.bool)
        checkItem1(KVItems.int)
        checkItem1(KVItems.float)
        checkItem1(KVItems.double)
        checkItem1(KVItems.string)
        checkItem1(KVItems.data)

        store.clearAll()
        
        checkItem2(KVItems.bool)
        checkItem2(KVItems.int)
        checkItem2(KVItems.float)
        checkItem2(KVItems.double)
        checkItem2(KVItems.string)
        checkItem2(KVItems.data)
    }
    
    private func findBase() -> KVStoreBase? {
        if let base = store as? KVStoreBase {
            return base
        }
        if let proxy = store as? KVStoreProxy {
            return proxy.findBase()
        }
        return nil
    }
    
    func setItem<V: Codable>(_ item: KVItem<V>) {
        store.set(item.value, forKey: item.key)
        store.set(item.value, forKey: prefix + item.key)
    }
    
    func checkItem1<V: Equatable & Codable>(_ item: KVItem<V>) {
        item.check(in: store)
        item.mapKey({ prefix + $0 }).check(in: store)
    }
    
    func checkItem2<V: Equatable & Codable>(_ item: KVItem<V>) {
        item.check(in: store)
        item.mapKey({ prefix + $0 }).checkNil(in: store)
    }
    
    // MARK: KVStoreBaseDelegate
    
    func judgeSatisfy(forKey key: String) -> Bool {
        return key.hasPrefix(prefix)
    }

}
