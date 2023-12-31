//
//  Dictionary+Ext.swift
//  SpaceKit
//
//  Created by weidong fu on 15/3/2018.
//

import Foundation

// MARK: -
extension Dictionary: PrivateFoundationExtensionCompatible {}

// MARK: -
public extension PrivateFoundationExtension {
    func toString() -> String? {
        do {
            if JSONSerialization.isValidJSONObject(base) {
                let jsonData = try JSONSerialization.data(withJSONObject: base, options: [])
                return String(data: jsonData, encoding: .utf8)
            } else {
                DocsLogger.error("dictionary to string err, dic=\(base)")
                spaceAssert(false) //遇到assert请在群里抛出来看下
                return nil
            }
        } catch let error {
            DocsLogger.error("dictionary to string, catch err=\(error), dic=\(base)")
            spaceAssert(false) //遇到assert请在群里抛出来看下
        }
        return nil
    }
}

// MARK: -
extension Dictionary {
    /// Merges the given dictionary into this dictionary while using newer value for any duplicate keys.
    public mutating func merge(other: [Key: Value]?, coverKey: String? = nil) {
        guard let mergedDic = other else {
            return
        }
        for (k, v) in mergedDic {
            /// 直接用新的 value 覆盖
            if let key = k as? String, key == coverKey {
                updateValue(v, forKey: k)
                continue
            }
            if let value = v as? [String: Any], var dic = self[k] as? [String: Any] {
                dic.merge(other: value)
                self[k] = dic as? Value
                continue
            }
            updateValue(v, forKey: k)
        }
    }
}

public extension Dictionary where Key: RawRepresentable, Key.RawValue: Hashable {
    func mapKeyWithRawValue() -> [Key.RawValue: Value] {
        var result: [Key.RawValue: Value] = [:]
        self.forEach { (key, value) in
            result[key.rawValue] = value
        }
        return result
    }
}

// 以下代码中的方法用到的时候再放开，以节省包体积
public extension Dictionary where Key == String {
    
    @inlinable
    func getInt(for key: String) -> Int { (self[key] as? Int) ?? 0 }
    @inlinable
    func getIntOrNil(for key: String) -> Int? { self[key] as? Int }
    func getInt(keyPath: String) -> Int {
        if let tuple = Self.getPathsAndLastKey(keyPath) {
            return (getDictionary(paths: tuple.0)[tuple.1] as? Int) ?? 0
        }
        return (self[keyPath] as? Int) ?? 0
    }
//    func getIntOrNil(keyPath: String) -> Int? {
//        if let tuple = Self.getPathsAndLastKey(keyPath) {
//            return getDictionary(paths: tuple.0)[tuple.1] as? Int
//        }
//        return self[keyPath] as? Int
//    }
    
    @inlinable
    func getBool(for key: String) -> Bool { (self[key] as? Bool) ?? false }
    @inlinable
    func getBoolOrNil(for key: String) -> Bool? { self[key] as? Bool }
//    func getBool(keyPath: String) -> Bool {
//        if let tuple = Self.getPathsAndLastKey(keyPath) {
//            return (getDictionary(paths: tuple.0)[tuple.1] as? Bool) ?? false
//        }
//        return (self[keyPath] as? Bool) ?? false
//    }
//    func getBoolOrNil(keyPath: String) -> Bool? {
//        if let tuple = Self.getPathsAndLastKey(keyPath) {
//            return getDictionary(paths: tuple.0)[tuple.1] as? Bool
//        }
//        return self[keyPath] as? Bool
//    }
    
    @inlinable
    func getDouble(for key: String) -> Double { (self[key] as? Double) ?? 0 }
    @inlinable
    func getDoubleOrNil(for key: String) -> Double? { self[key] as? Double }
//    func getDouble(keyPath: String) -> Double {
//        if let tuple = Self.getPathsAndLastKey(keyPath) {
//            return (getDictionary(paths: tuple.0)[tuple.1] as? Double) ?? 0
//        }
//        return (self[keyPath] as? Double) ?? 0
//    }
    func getDoubleOrNil(keyPath: String) -> Double? {
        if let tuple = Self.getPathsAndLastKey(keyPath) {
            return getDictionary(paths: tuple.0)[tuple.1] as? Double
        }
        return self[keyPath] as? Double
    }
    
    @inlinable
    func getString(for key: String) -> String { (self[key] as? String) ?? "" }
    @inlinable
    func getStringOrNil(for key: String) -> String? { self[key] as? String }
    func getString(keyPath: String) -> String {
        if let tuple = Self.getPathsAndLastKey(keyPath) {
            return (getDictionary(paths: tuple.0)[tuple.1] as? String) ?? ""
        }
        return (self[keyPath] as? String) ?? ""
    }
    func getStringOrNil(keyPath: String) -> String? {
        if let tuple = Self.getPathsAndLastKey(keyPath) {
            return getDictionary(paths: tuple.0)[tuple.1] as? String
        }
        return self[keyPath] as? String
    }
    
    @inlinable
    func getArray(for key: String) -> [[String: Any]] { (self[key] as? [[String: Any]]) ?? [] }
    @inlinable
    func getArrayOrNil(for key: String) -> [[String: Any]]? { self[key] as? [[String: Any]] }
//    func getArray(keyPath: String) -> [[String: Any]] {
//        if let tuple = Self.getPathsAndLastKey(keyPath) {
//            return (getDictionary(paths: tuple.0)[tuple.1] as? [[String: Any]]) ?? []
//        }
//        return (self[keyPath] as? [[String: Any]]) ?? []
//    }
    func getArrayOrNil(keyPath: String) -> [[String: Any]]? {
        if let tuple = Self.getPathsAndLastKey(keyPath) {
            return getDictionary(paths: tuple.0)[tuple.1] as? [[String: Any]]
        }
        return self[keyPath] as? [[String: Any]]
    }
    
    // MARK: private
    private func getDictionary(paths: [String]) -> [String: Any] {
        var dict: [String: Any]? = self
        for key in paths {
            dict = dict?[key] as? [String: Any]
        }
        return dict ?? [:]
    }
    
    // 获取 keyPath 中的前后两部分，例如 "aaa.bbb.ccc" -> (["aaa", "bbb"], "ccc")
    private static func getPathsAndLastKey(_ keyPath: String) -> ([String], String)? {
        let paths = keyPath.components(separatedBy: ".")
        let count = paths.count
        if count >= 2 {
            return (Array(paths.prefix(count - 1)), paths[count - 1])
        } else {
            return nil
        }
    }
}
