//
//  KVStoreBase.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation

// MARK: - KVStoreBase

public protocol KVStoreBaseDelegate: AnyObject {
    /// 判断 key 是否满足
    func judgeSatisfy(forKey key: String) -> Bool
}

/// 描述底层 store 类型
public enum KVStoreType: String {
    /// 对应 UserDefaults
    case udkv
    /// 对应 MMKV
    case mmkv
}

public typealias NSCodingObject = NSCoding & NSObjectProtocol

public protocol KVStoreBase: KVStore {
    static var type: KVStoreType { get }

    var delegate: KVStoreBaseDelegate? { get set }
    var filePaths: [String] { get }

    func loadValue(forKey key: String) -> Bool?
    func loadValue(forKey key: String) -> Int?
    func loadValue(forKey key: String) -> Int64?
    func loadValue(forKey key: String) -> Double?
    func loadValue(forKey key: String) -> Float?
    func loadValue(forKey key: String) -> String?
    func loadValue(forKey key: String) -> Data?
    func loadValue(forKey key: String) -> Date?
    func loadValue<T: NSCodingObject>(forKey key: String) -> T?

    func saveValue(_ value: Bool, forKey key: String)
    func saveValue(_ value: Int, forKey key: String)
    func saveValue(_ value: Int64, forKey key: String)
    func saveValue(_ value: Double, forKey key: String)
    func saveValue(_ value: Float, forKey key: String)
    func saveValue(_ value: String, forKey key: String)
    func saveValue(_ value: Data, forKey key: String)
    func saveValue(_ value: Date, forKey key: String)
    func saveValue(_ value: NSCodingObject, forKey key: String)
}

extension KVStoreBase {

    func value<T: Codable>(forKey key: String) -> T? {
        if let type = T.self as? KVStoreBasicType.Type {
            return type.load(from: self, forKey: key) as? T
        } else {
            return codableGet(forKey: key)
        }
    }

    func set<T: Codable>(_ value: T, forKey key: String) {
        if let model = value as? KVStoreBasicType {
            model.save(in: self, forKey: key)
        } else {
            if let optional = value as? KVOptional, optional.isNil {
                removeValue(forKey: key)
            } else {
                codableSet(value, forKey: key)
            }
        }
    }

    func codableGet<T: Codable>(forKey key: String) -> T? {
        guard let jsonData: Data = loadValue(forKey: key) else {
            return nscodingGet(forKey: key)
        }
        do {
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(T.self, from: jsonData)
            return decoded
        } catch {
            if #unavailable(iOS 13.0), case DecodingError.typeMismatch = error {
                do {
                    let type = KVStoreCryptoProxy.JsonWrapper<T>.self
                    let decoded = try JSONDecoder().decode(type, from: jsonData)
                    return decoded.value
                } catch {
                    let logKey = KVStoreLogProxy.encoded(for: key)
                    let msg = "JSONDecoder error when handling typeMismatch: \(error), key: \(logKey)"
                    KVStores.assert(false, msg, event: .loadValue)
                }
            } else {
                let logKey = KVStoreLogProxy.encoded(for: key)
                KVStores.assert(false, "JSONDecoder error: \(error), key: \(logKey)", event: .loadValue)
            }
        }
        return nil
    }

    func codableSet<T: Codable>(_ value: T, forKey key: String) {
        do {
            let data = try JSONEncoder().encode(value)
            saveValue(data, forKey: key)
        } catch {
            if #unavailable(iOS 13.0), case EncodingError.invalidValue = error {
                do {
                    let wrapped = KVStoreCryptoProxy.JsonWrapper(value: value)
                    let data = try JSONEncoder().encode(wrapped)
                    saveValue(data, forKey: key)
                } catch {
                    let logKey = KVStoreLogProxy.encoded(for: key)
                    let msg = "JSONEncoder error when handling invalidValue: \(error), key: \(logKey)"
                    KVStores.assert(false, msg, event: .saveValue)
                }
            } else {
                let logKey = KVStoreLogProxy.encoded(for: key)
                KVStores.assert(false, "JSONEncoder error: \(error), key: \(logKey)", event: .saveValue)
            }
        }
    }

    private func nscodingGet<T: Codable>(forKey key: String) -> T? {
        guard contains(key: key) else { return nil }

        if let dicObject: NSDictionary = loadValue(forKey: key) {
            if let result = dicObject as? T {
                return result
            } else if let decoded: T = parseFromJsonObject(dicObject) {
                return decoded
            }
        }
        if let arrayObject: NSArray = loadValue(forKey: key) {
            if let result = arrayObject as? T {
                return result
            } else if let decoded: T = parseFromJsonObject(arrayObject) {
                return decoded
            }
        }
        if let numObject: NSNumber = loadValue(forKey: key), let ret = numObject as? T {
            return ret
        }
        return nil
    }

    private func parseFromJsonObject<T: Codable>(_ object: Any) -> T? {
        guard JSONSerialization.isValidJSONObject(object) else {
            KVStores.assert(false, "is not a valid json object", event: .loadValue)
            return nil
        }
        var ret: T?
        do {
            let data = try JSONSerialization.data(withJSONObject: object, options: .fragmentsAllowed)
            ret = try JSONDecoder().decode(T.self, from: data)
        } catch {
            KVStores.assert(false, "serialize or decode failed, error: \(error)", event: .loadValue)
        }
        return ret
    }

}
