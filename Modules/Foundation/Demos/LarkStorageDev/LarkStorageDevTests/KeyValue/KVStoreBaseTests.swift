//
//  KVStoreBaseTests.swift
//  LarkStorageDevTests
//
//  Created by 7Up on 2022/5/20.
//

import Foundation
import XCTest
@testable import LarkStorageCore
@testable import LarkStorage

func runTesters(with storeMaker: () -> KVStoreBase) {
    KVSaveLoadTester(store: storeMaker()).run()
    KVGetSetTester(store: storeMaker()).run()
    KVContainsTester(store: storeMaker()).run()
    KVRemoveTester(store: storeMaker()).run()
    KVClearTester(store: storeMaker()).run()
    KVAllKeysTester(store: storeMaker()).run()
    KVAllValueTester(store: storeMaker()).run()
    KVInt64Tester(store: storeMaker()).run()
}

class UDKVTests: KVTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testSuiteName() {
        var space: Space
        var suiteName: String
        do {
            space = .global
            suiteName = UD.suiteName(with: space, mode: .normal)
            XCTAssert("lark_storage." + space.isolationId == suiteName)
        }
        do {
            space = Space.user(id: typeName)
            suiteName = KVStores.udSuiteName(for: space, mode: .normal)
            XCTAssert("lark_storage." + space.isolationId == suiteName)
        }
    }

    func testCommon() {
        runTesters {
            let space = Space.uuidUser(type: typeName)
            let suiteName = UD.suiteName(with: space)
            return UD.store(with: suiteName)!.disposed(self)
        }
    }

}

class MMKVTests: KVTestCase {

    // test mmkv correct
    func testMMKVPath() {
        let config = MM.config(with: .uuidUser(type: typeName), mode: .normal)
        let filePath = MM.filePath(with: config)
        log.debug("testMMKVPath filePath: \(filePath)")

        // remove old path
        try? FileManager.default.removeItem(atPath: filePath)
        try? FileManager.default.removeItem(atPath: filePath + ".crc")
        XCTAssert(!FileManager.default.fileExists(atPath: filePath))

        let store = MM.store(with: config)!
        store.set("foo", forKey: "foo")

        // test file exists
        XCTAssert(FileManager.default.fileExists(atPath: filePath))

        // finish test, remove file
        try? FileManager.default.removeItem(atPath: filePath)
        try? FileManager.default.removeItem(atPath: filePath + ".crc")
    }

    func testCommon() {
        runTesters {
            let space = Space.uuidUser(type: typeName)
            let config = MM.config(with: space)
            return MM.store(with: config)!.disposed(self)
        }
    }

}
