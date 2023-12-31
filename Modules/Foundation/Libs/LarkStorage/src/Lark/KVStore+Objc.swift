//
//  KVStore+Objc.swift
//  LarkStorage
//
//  Created by 7Up on 2023/2/20.
//

import Foundation

@objc
public class KVStoreObjc: NSObject, KVStoreProxy {
    public static var type: KVStoreProxyType { .objc }

    public var wrapped: KVStore

    public init(wrapped: KVStore) {
        self.wrapped = wrapped
    }
}

// MARK: - Objc

extension KVStoreObjc {
    // MARK: Bool

    @objc
    public func getBool(forKey key: String) -> Bool {
        return wrapped.bool(forKey: key)
    }

    @objc
    public func setBool(_ bool: Bool, forKey key: String) {
        wrapped.set(bool, forKey: key)
    }

    // MARK: Integer

    @objc
    public func getInteger(forKey key: String) -> Int {
        return wrapped.integer(forKey: key)
    }

    @objc
    public func setInteger(_ int: Int, forKey key: String) {
        wrapped.set(int, forKey: key)
    }

    // MARK: Float

    @objc
    public func getFloat(forKey key: String) -> Float {
        return wrapped.float(forKey: key)
    }

    @objc
    public func setFloat(_ float: Float, forKey key: String) {
        wrapped.set(float, forKey: key)
    }

    // MARK: Double

    @objc
    public func getDouble(forKey key: String) -> Double {
        return wrapped.double(forKey: key)
    }

    @objc
    public func setDouble(_ double: Double, forKey key: String) {
        wrapped.set(double, forKey: key)
    }

    // MARK: String

    @objc
    public func getString(forKey key: String) -> String? {
        return wrapped.string(forKey: key)
    }

    @objc
    public func setString(_ str: String, forKey key: String) {
        wrapped.set(str, forKey: key)
    }

    // MARK: Data

    @objc
    public func getData(forKey key: String) -> Data? {
        return wrapped.data(forKey: key)
    }

    @objc
    public func setData(_ data: Data, forKey key: String) {
        wrapped.set(data, forKey: key)
    }

    // MARK: Array<String/Double/Float/Int/Bool>

    @objc
    public func getStringArray(forKey key: String) -> Array<String>? {
        return wrapped.value(forKey: key)
    }

    @objc
    public func setStringArray(_ arr: Array<String>, forKey key: String) {
        wrapped.set(arr, forKey: key)
    }

    @objc
    public func getDoubleArray(forKey key: String) -> Array<Double>? {
        return wrapped.value(forKey: key)
    }

    @objc
    public func setDoubleArray(_ arr: Array<Double>, forKey key: String) {
        wrapped.set(arr, forKey: key)
    }

    @objc
    public func getFloatArray(forKey key: String) -> Array<Float>? {
        return wrapped.value(forKey: key)
    }

    @objc
    public func setFloatArray(_ arr: Array<Float>, forKey key: String) {
        wrapped.set(arr, forKey: key)
    }

    @objc
    public func getIntegerArray(forKey key: String) -> Array<Int>? {
        return wrapped.value(forKey: key)
    }

    @objc
    public func setIntegerArray(_ arr: Array<Int>, forKey key: String) {
        wrapped.set(arr, forKey: key)
    }

    @objc
    public func getBoolArray(forKey key: String) -> Array<Bool>? {
        return wrapped.value(forKey: key)
    }

    @objc
    public func setBoolArray(_ arr: Array<Bool>, forKey key: String) {
        wrapped.set(arr, forKey: key)
    }

    // MARK: Dictionary

    @objc
    public func getDictionary(forKey key: String) -> [String: Any]? {
        return wrapped.dictionary(forKey: key)
    }

    @objc
    public func setDictionary(_ dict: [String: Any], forKey key: String) {
        wrapped.setDictionary(dict, forKey: key)
    }

    // MARK: Remove

    @objc
    public func removeObject(forKey key: String) {
        wrapped.removeValue(forKey: key)
    }
}
