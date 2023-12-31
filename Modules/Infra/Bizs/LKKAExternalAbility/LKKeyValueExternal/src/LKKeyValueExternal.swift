//
//  LKKeyValueExternal.swift
//  LKKeyValueExternal
//
//  Created by ByteDance on 2022/8/16.
//

import Foundation

@objc
public protocol KAKeyValueProtocol: AnyObject {
    func has(key: String) -> Bool
    func set(key: String, stringValue: String) -> Bool
    func set(key: String, intValue: Int) -> Bool
    func set(key: String, floatValue: Float) -> Bool
    func set(key: String, doubleValue: Double) -> Bool
    func set(key: String, boolValue: Bool) -> Bool
    func set(key: String, dataValue: Data) -> Bool
    func getString(key: String) -> String
    func getInt(key: String) -> Int
    func getFloat(key: String) -> Float
    func getDouble(key: String) -> Double
    func getBool(key: String) -> Bool
    func getData(key: String) -> Data
    func clear(key: String) -> Bool
    func clearAll() -> Bool
}

@objcMembers
public class KAKeyValueExternal: NSObject {
    public override init() {
    }
    public static let shared = KAKeyValueExternal()
    public var store: KAKeyValueProtocol?
    public static func getKVStore() -> KAKeyValueProtocol? {
        shared.store
    }
}
