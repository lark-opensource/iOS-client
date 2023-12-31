//
//  FuncContext.swift
//  LarkFoundation
//
//  Created by qihongye on 2019/11/21.
//

import Foundation

struct FuncContextKey: Hashable {
    let type: Any.Type
    let key: String

    init(_ key: String, _ type: Any.Type) {
        self.key = key
        self.type = type
    }

    func hash(into hasher: inout Hasher) {
        /// 这里使用这种方式，是因为测试方面虽然ObjectIdentify比unsafeBitCast + Int转换更快，但是综合hasher.combine配合后者比前者搭配hash(to:)更快
        hasher.combine(Int(bitPattern: unsafeBitCast(type, to: UnsafeRawPointer.self)))
        key.hash(into: &hasher)
    }

    static func == (lhs: FuncContextKey, rhs: FuncContextKey) -> Bool {
        return lhs.type == rhs.type && lhs.key == rhs.key
    }
}

public final class FuncContext {
    private var storage: [FuncContextKey: Any] = [:]

    public init() {}

    @inline(__always)
    public func set<T>(key: String, value: T) {
        storage[FuncContextKey(key, T.self)] = value
    }

    @inline(__always)
    public func get<T>(key: String) -> T? {
        return storage[FuncContextKey(key, T.self)] as? T
    }
}
