//
//  SharedKvStorage.swift
//  LarkMeego
//
//  Created by shizhengyu on 2023/2/24.
//

import Foundation
import RxSwift
import meego_rust_ios
import LarkMeegoLogger

public typealias KeyProcessor = (String) -> String

/// Native / Rust / Dart 共享 kv 缓存（molten-db）
public protocol SharedKvStorage {
    var domain: String { get }

    var database: MeegoDb? { get }

    var keyProcessor: KeyProcessor? { get }

    func getBool(with key: String) throws -> Bool?

    func getBoolAsync(with key: String) -> RxSwift.Observable<Bool?>

    func setBool(key: String, with value: Bool, expiredMillis: Int64?) throws

    func setBoolAsync(key: String, with value: Bool, expiredMillis: Int64?) -> RxSwift.Observable<Void>

    func getString(with key: String) throws -> String?

    func getStringAsync(with key: String) -> RxSwift.Observable<String?>

    func setString(key: String, with value: String, expiredMillis: Int64?) throws

    func setStringAsync(key: String, with value: String, expiredMillis: Int64?) -> RxSwift.Observable<Void>

    func getInt(with key: String) throws -> Int64?

    func getIntAsync(with key: String) -> RxSwift.Observable<Int64?>

    func setInt(key: String, with value: Int64, expiredMillis: Int64?) throws

    func setIntAsync(key: String, with value: Int64, expiredMillis: Int64?) -> RxSwift.Observable<Void>

    func getDouble(with key: String) throws -> Double?

    func getDoubleAsync(with key: String) -> RxSwift.Observable<Double?>

    func setDouble(key: String, with value: Double, expiredMillis: Int64?) throws

    func setDoubleAsync(key: String, with value: Double, expiredMillis: Int64?) -> RxSwift.Observable<Void>
}

public extension SharedKvStorage {
    func getBool(with key: String) throws -> Bool? {
        try get(with: key, dataType: Bool.self)
    }

    func getBoolAsync(with key: String) -> Observable<Bool?> {
        return getAsync(with: key, dataType: Bool.self)
    }

    func setBool(key: String, with value: Bool, expiredMillis: Int64?) throws {
        try set(key: key, with: .ofBool(value), expiredMillis: expiredMillis)
    }

    func setBoolAsync(key: String, with value: Bool, expiredMillis: Int64?) -> RxSwift.Observable<Void> {
        return setAsync(key: key, with: .ofBool(value), expiredMillis: expiredMillis)
    }

    func getString(with key: String) throws -> String? {
        try get(with: key, dataType: String.self)
    }

    func getStringAsync(with key: String) -> RxSwift.Observable<String?> {
        return getAsync(with: key, dataType: String.self)
    }

    func setString(key: String, with value: String, expiredMillis: Int64?) throws {
        try set(key: key, with: .ofString(value), expiredMillis: expiredMillis)
    }

    func setStringAsync(key: String, with value: String, expiredMillis: Int64?) -> RxSwift.Observable<Void> {
        return setAsync(key: key, with: .ofString(value), expiredMillis: expiredMillis)
    }

    func getInt(with key: String) throws -> Int64? {
        try get(with: key, dataType: Int64.self)
    }

    func getIntAsync(with key: String) -> RxSwift.Observable<Int64?> {
        return getAsync(with: key, dataType: Int64.self)
    }

    func setInt(key: String, with value: Int64, expiredMillis: Int64?) throws {
        try set(key: key, with: .ofInt(value), expiredMillis: expiredMillis)
    }

    func setIntAsync(key: String, with value: Int64, expiredMillis: Int64?) -> RxSwift.Observable<Void> {
        return setAsync(key: key, with: .ofInt(value), expiredMillis: expiredMillis)
    }

    func getDouble(with key: String) throws -> Double? {
        try get(with: key, dataType: Double.self)
    }

    func getDoubleAsync(with key: String) -> RxSwift.Observable<Double?> {
        return getAsync(with: key, dataType: Double.self)
    }

    func setDouble(key: String, with value: Double, expiredMillis: Int64?) throws {
        try set(key: key, with: .ofDouble(value), expiredMillis: expiredMillis)
    }

    func setDoubleAsync(key: String, with value: Double, expiredMillis: Int64?) -> RxSwift.Observable<Void> {
        return setAsync(key: key, with: .ofDouble(value), expiredMillis: expiredMillis)
    }
}

private extension SharedKvStorage {
    func getAsync<T>(with key: String, dataType: T.Type) -> Observable<T?> {
        return Observable.create { ob in
            do {
                let value: T? = try self._get(with: key, dataType: dataType)
                ob.end(value)
            } catch let error as KvStorageOptError {
                ob.end(with: error)
            } catch let otherError {
                ob.end(with: KvStorageOptError.uncategorizedError(rawError: otherError))
            }
            return Disposables.create()
        }.subscribeOn(kvStorageOptScheduler)
    }

    func get<T>(with key: String, dataType: T.Type) throws -> T? {
        return try _get(with: key, dataType: dataType)
    }

    func _get<T>(with key: String, dataType: T.Type) throws -> T? {
        guard let dataType = DataType.transform(with: dataType) else {
            let debugMsg = "T must be included in [Bool, String, Int64, Double]"
            MeegoLogger.warnWithAssert(debugMsg, domain: domain)
            throw KvStorageOptError.mismatchedType(debugMsg: debugMsg)
        }

        guard let database = database else {
            MeegoLogger.warnWithAssert("read failed due to database is nil", domain: domain)
            throw KvStorageOptError.databaseNotExist
        }

        do {
            let res = try rustKvGet(dataType: dataType, db: database, domain: domain, key: keyProcessor?(key) ?? key)
            MeegoLogger.debug("get value(\((res != nil) ? "\(res!)" : "nil")) for key(\(keyProcessor?(key) ?? key) success, db handle = \(database.handle)", domain: domain)

            if case .ofBool(let value) = res, dataType == .ofBool {
                return value as? T
            } else if case .ofString(let value) = res, dataType == .ofString {
                return value as? T
            } else if case .ofInt(let value) = res, dataType == .ofInt {
                return value as? T
            } else if case .ofDouble(let value) = res, dataType == .ofDouble {
                return value as? T
            } else if res == nil {
                // 未查询到结果
                return nil
            } else {
                // 想要的类型和查询出来的数据类型不匹配
                let debugMsg = "read failed due to mismatched data type, expect \(dataType) but get \(res!.type)"
                MeegoLogger.warnWithAssert(debugMsg, domain: domain)
                throw KvStorageOptError.mismatchedType(debugMsg: debugMsg)
            }
        } catch let error where !(error is KvStorageOptError) {
            // TODO：由于 `rustKvGet` 没有传递 throwError 到内部，InternalError 类型又是 private
            // 所以目前没法得知更具体的 rust 错误码，这块需要进一步完善
            let debugMsg = "read failed due to rust call error = \(error.localizedDescription)"
            MeegoLogger.warnWithAssert(debugMsg, domain: domain)
            throw KvStorageOptError.rustInnerError(debugMsg: debugMsg)
        }
    }

    func set(key: String, with value: DataValue, expiredMillis: Int64?) throws {
        try _set(key: key, with: value, expiredMillis: expiredMillis)
    }

    func setAsync(key: String, with value: DataValue, expiredMillis: Int64?) -> Observable<Void> {
        return Observable.create { ob in
            do {
                try self._set(key: key, with: value, expiredMillis: expiredMillis)
                ob.end(())
            } catch let error as KvStorageOptError {
                ob.end(with: error)
            } catch let otherError {
                ob.end(with: KvStorageOptError.uncategorizedError(rawError: otherError))
            }
            return Disposables.create()
        }.subscribeOn(kvStorageOptScheduler)
    }

    func _set(key: String, with value: DataValue, expiredMillis: Int64?) throws {
        guard let database = database else {
            MeegoLogger.warnWithAssert("write failed due to database is nil", domain: domain)
            throw KvStorageOptError.databaseNotExist
        }

        do {
            try rustKvSet(isAsync: false, db: database, domain: domain, key: keyProcessor?(key) ?? key, value: value, expiredMillis: expiredMillis)
            MeegoLogger.debug("set value(\(value) for key(\(keyProcessor?(key) ?? key) success, db handle = \(database.handle)", domain: domain)
        } catch let error where !(error is KvStorageOptError) {
            let debugMsg = "write failed due to rust call error = \(error.localizedDescription)"
            MeegoLogger.warnWithAssert(debugMsg, domain: domain)
            throw KvStorageOptError.rustInnerError(debugMsg: debugMsg)
        }
    }
}

private extension DataValue {
    var type: String {
        switch self {
        case .ofBool(_): return "Bool"
        case .ofInt(_): return "Int"
        case .ofDouble(_): return "Double"
        case .ofString(_): return "String"
        @unknown default: return "unknown type"
        }
    }

    var typeWithValue: String {
        switch self {
        case .ofBool(let bool): return "Bool|\(bool.stringValue)"
        case .ofInt(let int64): return "Int|\(int64)"
        case .ofDouble(let double): return "Double|\(double)"
        case .ofString(let string): return "String|\(string)"
        @unknown default: return "unknown type"
        }
    }
}

private extension DataType {
    static func transform<T>(with type: T.Type) -> DataType? {
        if type == Bool.self {
            return .ofBool
        } else if type == String.self {
            return .ofString
        } else if type == Int64.self {
            return .ofInt
        } else if type == Double.self {
            return .ofDouble
        } else {
            return nil
        }
    }
}
