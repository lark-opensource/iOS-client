//
//  KVSharedTests.swift
//  LarkStorageDevTests
//
//  Created by 7Up on 2022/5/20.
//

import XCTest
@testable import LarkStorage
@testable import LarkStorageCore

/// 多进程共享场景
class KVSharedTests: KVTestCase {

    let domain = Domain("KVSharedTests")

    func testUDKV() {
        runTesters {
            let space = Space.uuidUser(type: typeName)
            return KVStores.udkv(space: space, domain: domain, mode: .shared).disposed(self)
        }
    }

    func runTesters(for store: () -> KVStore) {
        KVGetSetTester(store: store()).run()
        KVContainsTester(store: store()).run()
        KVRemoveTester(store: store()).run()
        KVInt64Tester(store: store()).run()
    }

}
