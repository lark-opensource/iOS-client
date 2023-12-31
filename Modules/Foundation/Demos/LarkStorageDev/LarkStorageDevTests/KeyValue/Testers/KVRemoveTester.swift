//
//  KVRemoveTester.swift
//  LarkStorageDevTests
//
//  Created by 7Up on 2022/5/20.
//

import Foundation
import XCTest
@testable import LarkStorageCore
@testable import LarkStorage

class KVRemoveTester: Tester {
    
    let store: KVStore
    
    init(store: KVStore) {
        self.store = store
    }

    func run() {
        let key = UUID().uuidString
        store.set(key + "_value", forKey: key)
        XCTAssert(store.contains(key: key))
        
        store.removeValue(forKey: key)
        XCTAssert(!store.contains(key: key))
    }

}
