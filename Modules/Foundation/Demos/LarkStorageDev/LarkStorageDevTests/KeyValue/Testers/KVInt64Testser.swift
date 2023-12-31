//
//  KVInt64Testser.swift
//  LarkStorageDevTests
//
//  Created by 李昊哲 on 2023/8/14.
//  

import Foundation
import XCTest
@testable import LarkStorageCore
@testable import LarkStorage

class KVInt64Tester: Tester {
    let store: KVStore

    init(store: KVStore) {
        self.store = store
    }

    func run() {
        let intValue: Int = .min
        let int64Value: Int64 = .max

        // 1. 开启 FG 前不完全互通
        LarkStorageFG.Config.enableEquivalentInteger = false

        // 1.1 Int 写入, Int64 读出, UDKV 可以读出, MMKV 可能读出错误值
        do {
            store.set(intValue, forKey: "intToInt64_1")

            if store.findBase()! is UDKVStore {
                if let result: Int64 = store.value(forKey: "intToInt64_1") {
                    XCTAssert(result == intValue, "result: \(result) intValue: \(intValue)")
                } else {
                    XCTFail("result is nil")
                }
            } else {
                if let result: Int64 = store.value(forKey: "intToInt64_1") {
                    XCTAssert(result != intValue, "result: \(result) intValue: \(intValue)")
                }
            }
        }

        // 1.2 Int64 写入, Int 可能读出错误值
        do {
            store.set(int64Value, forKey: "int64ToInt_1")
            let result = store.integer(forKey: "int64ToInt_1")
            XCTAssert(result != int64Value, "result: \(result) int64Value: \(int64Value)")
        }

        // 2. 开启 FG 后互通
        LarkStorageFG.Config.enableEquivalentInteger = true

        // 2.1 Int 写入, Int64 读出
        do {
            store.set(intValue, forKey: "intToInt64_2")
            if let result: Int64 = store.value(forKey: "intToInt64_2") {
                XCTAssert(result == intValue, "result: \(result) intValue: \(intValue)")
            } else {
                XCTFail("result is nil")
            }
        }

        // 2.2 Int64 写入, Int 读出
        do {
            store.set(int64Value, forKey: "int64ToInt_2")
            let result: Int = store.integer(forKey: "int64ToInt_2")
            XCTAssert(result == int64Value, "result: \(result) int64Value: \(int64Value)")
        }

        // 2.3 Int64 写入, Int64 读出
        do {
            store.set(int64Value, forKey: "int64ToInt64_2")
            if let result: Int64 = store.value(forKey: "int64ToInt64_2") {
                XCTAssert(result == int64Value, "result: \(result) int64Value: \(int64Value)")
            } else {
                XCTFail("result is nil")
            }
        }
    }
}
