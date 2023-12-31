//
//  KVContainsTester.swift
//  LarkStorageDevTests
//
//  Created by 7Up on 2022/5/20.
//

import Foundation
import XCTest
@testable import LarkStorageCore
@testable import LarkStorage

class KVContainsTester: Tester {
    
    let store: KVStore
    
    init(store: KVStore) {
        self.store = store
    }

    func run() {
        let key = UUID().uuidString
        XCTAssert(!store.contains(key: key))
        
        store.set("foo", forKey: key)
        XCTAssert(store.contains(key: key))
    }

}
