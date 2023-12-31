//   
//  KVAllKeysTester.swift
//  LarkStorageDevTests
//
//  Created by 李昊哲 on 2022/12/26.
//  

import Foundation
import XCTest
@testable import LarkStorageCore
@testable import LarkStorage

private let prefix = "KVAllKeysTester_"

class KVAllKeysTester: Tester {

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

        delegate = BaseDelegate(satisfy: { _ in false })
        do {
            base.delegate = delegate
            XCTAssert(store.allKeys().count == 0)
        }

        delegate = BaseDelegate(satisfy: { key in key.hasPrefix(prefix)})
        do {
            base.delegate = delegate
            let allKeys = store.allKeys()
            XCTAssert(allKeys.count == 6, "allKeys = \(allKeys), count = \(allKeys.count)")
        }

        checkItem(KVItems.bool)
        checkItem(KVItems.int)
        checkItem(KVItems.float)
        checkItem(KVItems.double)
        checkItem(KVItems.string)
        checkItem(KVItems.data)
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

    func checkItem<V: Equatable & Codable>(_ item: KVItem<V>) {
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
