//
//  KVAllValueTester.swift
//  LarkStorageDevTests
//
//  Created by 7Up on 2022/5/20.
//

import Foundation
import XCTest
@testable import LarkStorageCore
@testable import LarkStorage

private let prefix = "KVAllValueTester_"

class KVAllValueTester: Tester {
    
    let store: KVStore
    var delegate: BaseDelegate?
    
    init(store: KVStore) {
        self.store = store
    }

    func run() {
        guard let base = findBase() else {
            return
        }
        let oldDelegate = base.delegate
        defer { base.delegate = oldDelegate }
        
        setItem(KVItems.bool)
        setItem(KVItems.int)
        setItem(KVItems.float)
        setItem(KVItems.double)
        setItem(KVItems.string)
        setItem(KVItems.data)
        setItem(KVObjects.dict)
        setItem(KVObjects.array)
//        setItem(KVObjects.product)

        delegate = BaseDelegate(satisfy: { _ in false })
        do {
            base.delegate = delegate
            XCTAssert(store.allValues().count == 0)
        }
        
        delegate = BaseDelegate(satisfy: { key in key.hasPrefix(prefix) })
        do {
            base.delegate = delegate
            let allValues = store.allValues()
            XCTAssert(allValues.count == 8, "allValues = \(allValues), count = \(allValues.count)")
        }
        
        checkItem(KVItems.bool)
        checkItem(KVItems.int)
        checkItem(KVItems.float)
        checkItem(KVItems.double)
        checkItem(KVItems.string)
        checkItem(KVItems.data)
        checkItem(KVObjects.dict)
        checkItem(KVObjects.array)
//        checkItem(KVObjects.product)
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
        item.save(in: store)
        item.mapKey({ prefix + $0 }).save(in: store)
    }

    func setItem<O: NSCodingObject>(_ item: KVObject<O>) {
        item.save(in: store)
        item.mapKey({prefix + $0}).save(in: store)
    }
    
    func checkItem<V: Equatable & Codable>(_ item: KVItem<V>) {
        item.check(in: store)
        item.mapKey({ prefix + $0 }).check(in: store)
    }

    func checkItem<O: Equatable & NSCodingObject>(_ item: KVObject<O>) {
        item.check(in: store)
        item.mapKey({ prefix + $0 }).check(in: store)
    }
    
    class BaseDelegate: KVStoreBaseDelegate {
        let satisfy: (String) -> Bool
        init(satisfy: @escaping (String) -> Bool) {
            self.satisfy = satisfy
        }
        
        func judgeSatisfy(forKey key: String) -> Bool {
            return satisfy(key)
        }
    }

}
