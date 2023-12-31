//
//  KVStore+Compatible.swift
//  LarkStorage
//
//  Created by 7Up on 2022/11/1.
//

import Foundation

/// Compatible get Apis
public extension KVStore {

    func bool(forKey key: String) -> Bool {
        return value(forKey: key) ?? false
    }

    func integer(forKey key: String) -> Int {
        return value(forKey: key) ?? 0
    }

    func float(forKey key: String) -> Float {
        return value(forKey: key) ?? 0.0
    }

    func double(forKey key: String) -> Double {
        return value(forKey: key) ?? 0.0
    }

    func string(forKey key: String) -> String? {
        return value(forKey: key)
    }

    func data(forKey key: String) -> Data? {
        return value(forKey: key)
    }

    func date(forKey key: String) -> Date? {
        return value(forKey: key)
    }

}

/// Compatible Apis based on `NSCodingObject`
public extension KVStore {

    /// ⚠️**除非不得已，不要使用该接口**⚠️
    /// 尽可能使用 `value<T: Codable>(forKey:) -> T?` 接口
    /// 譬如：
    ///
    ///     `let dict: [String: String]? = store.value(forKey: "someKey")`
    ///     `let dict: [String: Int]? = store.value(forKey: "someKey")`
    ///
    /// 本接口适用于多种 value 类型的 `Dictionary`，譬如：
    ///
    ///     ```Swift
    ///     let dict = ["int": 42, "str": "42"]
    ///     store.set(dict, forKey: "someKey")
    ///     ```
    func dictionary(forKey key: String) -> [String: Any]? {
        if let nsDict: NSDictionary = object(forKey: key) {
            return nsDict as? [String: Any]
        } else {
            return nil
        }
    }

    /// ⚠️**除非不得已，不要使用该接口**⚠️
    /// 尽可能使用 `set<T: Codable>(_:T,forKey:)` 接口
    func setDictionary(_ dict: [String: Any], forKey key: String) {
        let nsDict = dict as NSDictionary
        setObject(nsDict, forKey: key)
    }

    /// ⚠️**除非不得已，不要使用该接口**⚠️
    /// 尽可能使用 `value<T: Codable>(forKey:) -> T?` 接口
    /// 譬如：
    ///
    ///     `let arr: [String]? = store.value(forKey: "someKey")`
    ///     `let arr: [Int]? = store.value(forKey: "someKey")`
    ///
    /// 本接口适用于多种 value 类型的 `Array`，譬如：
    ///
    ///     ```Swift
    ///     let arr = [42, "42"]
    ///     store.set(arr, forKey: "someKey")
    ///     ``
    func array(forKey key: String) -> [Any]? {
        if let nsArr: NSArray = object(forKey: key) {
            return nsArr as? [Any]
        } else {
            return nil
        }
    }

    /// ⚠️**除非不得已，不要使用该接口**⚠️
    /// 尽可能使用 `set<T: Codable>(_:T,forKey:)` 接口
    func setArray(_ arr: [Any], forKey key: String) {
        let nsArr = arr as NSArray
        setObject(nsArr, forKey: key)
    }

}
