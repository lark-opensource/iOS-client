//
//  KVSubscriptTests.swift
//  LarkStorageDevTests
//
//  Created by 7Up on 2022/5/20.
//

import Foundation
import XCTest
@testable import LarkStorageCore
@testable import LarkStorage

class KVSubscriptTests: KVTestCase {
    
    func testUDKV() {
        let suiteName = UD.suiteName(with: .uuidUser(type: typeName))
        let store = UD.store(with: suiteName)!.disposed(self)
        checkStrKey(in: store)
        checkKVKey(in: store)
    }
    
    func testMMKV() {
        let config = MM.config(with: .uuidUser(type: typeName))
        let store = MM.store(with: config)!.disposed(self)
        checkStrKey(in: store)
        checkKVKey(in: store)
    }
    
    func checkStrKey(in store: KVStore) {
        checkSet(item: KVItems.bool, in: store)
        checkSet(item: KVItems.int, in: store)
        checkSet(item: KVItems.float, in: store)
        checkSet(item: KVItems.double, in: store)
        checkSet(item: KVItems.string, in: store)
    }
    
    func checkSet<V: KVValue & Equatable>(item: KVItem<V>, in store: KVStore) {
        item.checkNil(in: store)
        store[item.key] = item.value
        item.check(in: store)
        store[item.key] = V?.none
        item.checkNil(in: store)
    }
    
    func checkKVKey(in store: KVStore) {
        checkKVSet(item: KVItems.bool, in: store, newValue: !KVItems.bool.value)
        checkKVSet(item: KVItems.int, in: store, newValue: KVItems.int.value + 1)
        checkKVSet(item: KVItems.float, in: store, newValue: KVItems.float.value + 1.0)
        checkKVSet(item: KVItems.double, in: store, newValue: KVItems.double.value + 1.0)
        checkKVSet(item: KVItems.string, in: store, newValue: KVItems.string.value + "1.0")
    }
    
    func checkKVSet<V: KVValue & Equatable>(item: KVItem<V>, in store: KVStore, newValue: V) {
        let key = KVKey(item.key, default: item.value)
        
        XCTAssert(!store.contains(key: key))
        XCTAssert(!store.contains(key: item.key))
        XCTAssert(store[key] == item.value)
        
        store[key] = newValue
        XCTAssert(store.contains(key: key))
        XCTAssert(store.contains(key: item.key))
        XCTAssert(store[key] == newValue)
    }

}
