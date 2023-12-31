//
//  MMKVType.swift
//  LarkStorage
//
//  Created by 7Up on 2023/9/1.
//

import Foundation

// NOTE: 因为 LarkStorageCore 的（基本上）零依赖诉求（主要是考虑 extension 场景）
// 将对 MMKV 的依赖变成注入方式，抽象 `MMKVType` 交由真正的 MMKV 实现；
// FIXME: 长期看，需要从架构层面优化，避免这种不优雅的实现

public struct MMKVIndex: Hashable {
    public var mmapId: String
    public var rootPath: String

    public init(mmapId: String, rootPath: String) {
        self.mmapId = mmapId
        self.rootPath = rootPath
    }
}

extension MMKVIndex {
    /// 是否跨进程
    public var isMultiProcess: Bool {
        return KVStores.isMultiProcessPath(rootPath)
    }
}

public protocol MMKVType: AnyObject {
    func valueSize(forKey key: String, actualSize: Bool) -> Int

    func contains(key: String) -> Bool

    func allKeys() -> [Any]

    func removeValue(forKey key: String)

    func sync()

    func close()

    func bool(forKey key: String) -> Bool
    func set(_ bool: Bool, forKey key: String)

    func int64(forKey key: String) -> Int64
    func set(_ int64: Int64, forKey key: String)

    func float(forKey key: String) -> Float
    func set(_ float: Float, forKey key: String)

    func double(forKey key: String) -> Double
    func set(_ double: Double, forKey key: String)

    func string(forKey key: String) -> String?
    func set(_ string: String, forKey key: String)

    func data(forKey key: String) -> Data?
    func set(_ data: Data, forKey key: String)

    func date(forKey key: String) -> Date?
    func set(_ date: Date, forKey key: String)

    func object(of cls: AnyClass, forKey key: String) -> Any?
    func set(_ object: NSCodingObject, forKey key: String)
}
