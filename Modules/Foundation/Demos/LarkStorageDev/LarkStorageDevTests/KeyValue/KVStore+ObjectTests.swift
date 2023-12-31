//
//  KVStore+ObjectTests.swift
//  LarkStorageDevTests
//
//  Created by 7Up on 2023/1/14.
//

import Foundation
import XCTest
import MMKV
@testable import LarkStorageCore
@testable import LarkStorage

class KVStoreObjectTests: KVTestCase {

    /// 测试基本的 get/set
    func testGetSet() {
        let _testGetSet = { (store: KVStore) in
            let keyPrefix = String(UUID().uuidString.prefix(5))
            do {
                let key = keyPrefix + "nsdict"
                // set: preparing
                let dict = NSDictionary(dictionaryLiteral: ("int", 42), ("str", "no"))
                store.setObject(dict, forKey: key)
                // get: testing
                let test: NSDictionary = store.object(forKey: key)!
                XCTAssert((test["int"] as! Int) == 42)
                XCTAssert((test["str"] as! String) == "no")
            }

            do {
                let key = keyPrefix + "nsarray"
                // set: preparing
                let arr = NSArray(
                    objects: KVItems.bool.value, KVItems.int.value, KVItems.float.value,
                    KVItems.double.value, KVItems.string.value
                )
                store.setObject(arr, forKey: key)
                // get: testing
                let test: NSArray = store.object(forKey: key)!
                XCTAssert((test[0] as! Bool) == KVItems.bool.value)
                XCTAssert((test[1] as! Int) == KVItems.int.value)
                XCTAssert((test[2] as! Float) == KVItems.float.value)
                XCTAssert((test[3] as! Double) == KVItems.double.value)
                XCTAssert((test[4] as! String) == KVItems.string.value)
            }
        }
        let domain = classDomain.funcChild().uuidChild()

        let udkv = KVStores.udkv(space: .global, domain: domain).disposed(self)
        _testGetSet(udkv)

        let mmkv = KVStores.mmkv(space: .global, domain: domain).disposed(self)
        _testGetSet(mmkv)
    }

    /// 测试 UDKV 的 migrate，包括：
    /// - 旧数据能迁移：旧 UserDefaults 的数据，能从 KVStore 读到
    /// - 新数据能同步：新 KVStore set 操作的数据，会同步到旧 UserDefaults
    func testUDMigrate() {
        let domain = classDomain.uuidChild()
        let uid = String(UUID().uuidString.prefix(7))
        let udkvs = (
            global: UserDefaults.standard,
            user: UserDefaults(suiteName: uid)!
        )
        // 1. prepare data
        udkvs.global.set(
            ["gbool": true, "gint": 42, "gstr": "ok"],
            forKey: domain.isolationId + "_k1"
        )
        udkvs.user.set(
            ["ubool": false, "uint": 43, "ustr": "no"],
            forKey: domain.isolationId + "_k2"
        )
        // 2. register config
        KVMigrationRegistry.registerMigration(forDomain: domain, strategy: .sync) { space in
            switch space {
            case .global:
                return [.from(userDefaults: .standard, items: [
                    .init(oldKey: domain.isolationId + "_k1", newKey: "k1")
                ])]
            case .user(let uid):
                return [.from(userDefaults: .suiteName(uid), items: [
                    .init(oldKey: domain.isolationId + "_k2", newKey: "k2")
                ])]
            }
        }
        // 3. test migrate (from & sync)
        do { // global space
            let store = KVStores.udkv(space: .global, domain: domain).disposed(self)

            // 测试旧数据迁移
            let new: [String: Any]! = store.dictionary(forKey: "k1")
            XCTAssert((new["gbool"] as! Bool) == true)
            XCTAssert((new["gint"] as! Int) == 42)
            XCTAssert((new["gstr"] as! String) == "ok")

            // 测试写数据同步
            store.setDictionary(["gbool_new": false, "gint_new": 73, "gstr_new": "no"], forKey: "k1")
            let oldKey = domain.isolationId + "_k1"
            let old = udkvs.global.dictionary(forKey: oldKey)!
            XCTAssert((old["gbool_new"] as! Bool) == false)
            XCTAssert((old["gint_new"] as! Int) == 73)
            XCTAssert((old["gstr_new"] as! String) == "no")
        }
        do {  // user space
            let store = KVStores.udkv(space: .user(id: uid), domain: domain).disposed(self)

            // 测试旧数据迁移
            let new: [String: Any]! = store.dictionary(forKey: "k2")
            XCTAssert((new["ubool"] as! Bool) == false)
            XCTAssert((new["uint"] as! Int) == 43)
            XCTAssert((new["ustr"] as! String) == "no")

            // 测试写数据同步
            store.setDictionary(["ubool_new": false, "uint_new": 17, "ustr_new": "jj"], forKey: "k2")
            let oldKey = domain.isolationId + "_k2"
            let old = udkvs.user.dictionary(forKey: oldKey)!
            XCTAssert((old["ubool_new"] as! Bool) == false)
            XCTAssert((old["uint_new"] as! Int) == 17)
            XCTAssert((old["ustr_new"] as! String) == "jj")
        }
        // clear data
        udkvs.global.removeObject(forKey: domain.isolationId + "_k1")
        try? UserDefaults.removeFile(udkvs.user, suiteName: "uid")
    }

    /// 测试 MMKV 的 migrate，包括：
    /// - 旧数据能迁移：旧 MMKV 的数据，能从 KVStore 读到
    /// - 新数据能同步：新 KVStore set 操作的数据，会同步到旧 MMKV
    func testMMMigrate() {
        let domain = classDomain.uuidChild()
        let rootPath = (AbsPath.library + String(UUID().uuidString.prefix(5)))
        let rootPathStr = rootPath.absoluteString
        let mmapIds = (global: UUID().uuidString, user: UUID().uuidString)
        let mmkvs = (
            global: MMKV(mmapID: mmapIds.global, rootPath: rootPathStr)!,
            user: MMKV(mmapID: mmapIds.user, rootPath: rootPathStr)!
        )
        // 1. prepare data
        do {
            let nsdict = ["gbool": true, "gint": 42, "gstr": "ok"] as NSDictionary
            mmkvs.global.set(nsdict, forKey: domain.isolationId + "_k1")
        }
        do {
            let nsdict = ["ubool": false, "uint": 43, "ustr": "no"] as NSDictionary
            mmkvs.user.set(nsdict, forKey: domain.isolationId + "_k2")
        }
        // 2. register config
        KVMigrationRegistry.registerMigration(forDomain: domain) { space in
            switch space {
            case .global:
                return [.from(mmkv: .custom(mmapId: mmapIds.global, rootPath: rootPathStr), items: [
                    .init(oldKey: domain.isolationId + "_k1", newKey: "k1", type: NSDictionary.self)
                ])]
            case .user(let uid):
                return [.from(mmkv: .custom(mmapId: uid, rootPath: rootPathStr), items: [
                    .init(oldKey: domain.isolationId + "_k2", newKey: "k2", type: NSDictionary.self)
                ])]
            }
        }
        // 3. test migrate (from & sync)
        do { // global space
            let store = KVStores.mmkv(space: .global, domain: domain).disposed(self)

            // 测试旧数据迁移
            let new: [String: Any]! = store.dictionary(forKey: "k1")
            XCTAssert((new["gbool"] as! Bool) == true)
            XCTAssert((new["gint"] as! Int) == 42)
            XCTAssert((new["gstr"] as! String) == "ok")

            // 测试写数据同步
            store.setDictionary(["gbool_new": false, "gint_new": 73, "gstr_new": "no"], forKey: "k1")
            let oldKey = domain.isolationId + "_k1"
            let old = (mmkvs.global.object(of: NSDictionary.self, forKey: oldKey) as? NSDictionary)!
            XCTAssert((old["gbool_new"] as! Bool) == false)
            XCTAssert((old["gint_new"] as! Int) == 73)
            XCTAssert((old["gstr_new"] as! String) == "no")
        }
        do { // user space
            let store = KVStores.mmkv(space: .user(id: mmapIds.user), domain: domain).disposed(self)

            // 测试旧数据迁移
            let new: [String: Any]! = store.dictionary(forKey: "k2")
            XCTAssert((new["ubool"] as! Bool) == false)
            XCTAssert((new["uint"] as! Int) == 43)
            XCTAssert((new["ustr"] as! String) == "no")

            // 测试写数据同步
            store.setDictionary(["ubool_new": false, "uint_new": 7, "ustr_new": "ff"], forKey: "k2")
            let oldKey = domain.isolationId + "_k2"
            let old = (mmkvs.user.object(of: NSDictionary.self, forKey: oldKey) as? NSDictionary)!
            XCTAssert((old["ubool_new"] as! Bool) == false)
            XCTAssert((old["uint_new"] as! Int) == 7)
            XCTAssert((old["ustr_new"] as! String) == "ff")
        }
        // clear data
        try? (rootPath + mmapIds.global).notStrictly.removeItem()
        try? (rootPath + "\(mmapIds.global).crc").notStrictly.removeItem()
        try? (rootPath + mmapIds.user).notStrictly.removeItem()
        try? (rootPath + "\(mmapIds.user).crc").notStrictly.removeItem()
    }

}
