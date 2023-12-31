//
//  KVRekeyTests.swift
//  LarkStorageDevTests
//
//  Created by 7Up on 2022/5/20.
//

import Foundation
import XCTest
@testable import LarkStorageCore
@testable import LarkStorage

/// KVStoreRekeyProxy 测试
/// 测试点：
///   - set/get
///   - allValues()
///   - contains(key:)
///   - removeValue(forKey:)
///   - clearAll():（只会移除所属 space、domain 相关的 key-value）
class KVRekeyTests: KVTestCase {

    let domain = Domain("KVRekeyTests")

    func testUDKV() {
        runTesters {
            let space = Space.uuidUser(type: typeName)
            let suiteName = UD.suiteName(with: space)
            return KVStoreRekeyProxy(
                wrapped: UD.store(with: suiteName)!.disposed(self),
                config: .init(space: space, domain: domain)
            )
        }
    }

    func testMMKV() {
        runTesters {
            let space = Space.uuidUser(type: typeName)
            let config = MM.config(with: space)
            return KVStoreRekeyProxy(
                wrapped: MM.store(with: config)!.disposed(self),
                config: .init(space: space, domain: domain, type: .mmkv)
            )
        }
    }

    func runTesters(for store: () -> KVStoreRekeyProxy) {
        KVGetSetTester(store: store()).run()
        KVContainsTester(store: store()).run()
        KVRemoveTester(store: store()).run()
        RekeyClearTester(store: store()).run()
        RekeyAllValueTester(store: store()).run()
    }

}

fileprivate class RekeyClearTester: Tester {

    let base: KVStoreBase!
    let rekey: KVStoreRekeyProxy
    weak var originDelegate: KVStoreBaseDelegate?

    init(store: KVStoreRekeyProxy) {
        self.rekey = store
        self.base = store.findBase()!
        self.originDelegate = self.base.delegate
    }

    func run() {
        let oldCount = base.realAllValues().count
        KVItems.saveAllCases(in: base)
        KVItems.checkAllCases(in: base)
        XCTAssertEqual(oldCount + KVItems.allCasesCount, base.realAllKeys().count)
        XCTAssertEqual(oldCount + KVItems.allCasesCount, base.realAllValues().count)

        KVItems.saveAllCases(in: rekey)
        XCTAssertEqual(oldCount + KVItems.allCasesCount * 2, base.realAllKeys().count)
        XCTAssertEqual(oldCount + KVItems.allCasesCount * 2, base.realAllValues().count)

        XCTAssertEqual(KVItems.allCasesCount, rekey.allKeys().count)
        XCTAssertEqual(KVItems.allCasesCount, rekey.allValues().count)
        KVItems.checkAllCases(in: rekey)

        // 验证 rekey.clearAll 之后，base 的其他 key 不受影响
        rekey.clearAll()
        XCTAssertEqual(0, rekey.allKeys().count)
        XCTAssertEqual(0, rekey.allValues().count)
        KVItems.checkAllCases(in: base)
    }

}

fileprivate class RekeyAllValueTester: Tester {

    let base: KVStoreBase!
    let rekey: KVStoreRekeyProxy

    init(store: KVStoreRekeyProxy) {
        self.rekey = store
        self.base = store.findBase()!
    }

    func run() {
        KVItems.saveAllCases(in: base)
        KVItems.checkAllCases(in: base)
        XCTAssert(!base.realAllKeys().isEmpty)
        XCTAssert(!base.realAllValues().isEmpty)
        XCTAssert(rekey.allKeys().isEmpty)
        XCTAssert(rekey.allValues().isEmpty)

        KVItems.saveAllCases(in: rekey)
        XCTAssert(rekey.allKeys().count == KVItems.allCasesCount)
        XCTAssert(rekey.allValues().count == KVItems.allCasesCount)
    }

}
