//
//  DataAssigner.swift
//  SKFoundation
//
//  Created by Weston Wu on 2020/8/6.
//

import Foundation

// 配合 struct 对象使用时，因 struct 是值类型，需要执行完赋值操作后，取出 target
/// 解析 data 的值并通过 KeyPath 的方式赋值给 target
public struct DataAssigner<T> {
    public var target: T
    public let data: [String: Any]

    public init(target: T, data: [String: Any]) {
        self.target = target
        self.data = data
    }
}

/// 适配 struct 对象
public extension DataAssigner {
    mutating func assignIfPresent<U>(key: String, keyPath: WritableKeyPath<T, U>) {
        guard let value = data[key] as? U else { return }
        target[keyPath: keyPath] = value
    }

    /// 若 KeyPath 对应属性的类型是 Optional 类型，需要从 data 中解析出非可选值
    mutating func assignIfPresent<U>(key: String, keyPath: WritableKeyPath<T, U?>) {
        guard let value = data[key] as? U else { return }
        target[keyPath: keyPath] = value
    }
}

/// 适配 class 对象
public extension DataAssigner where T: AnyObject {
    func assignIfPresent<U>(key: String, keyPath: ReferenceWritableKeyPath<T, U>) {
        guard let value = data[key] as? U else { return }
        target[keyPath: keyPath] = value
    }

    /// 若 KeyPath 对应属性的类型是 Optional 类型，需要从 data 中解析出非可选值
    func assignIfPresent<U>(key: String, keyPath: ReferenceWritableKeyPath<T, U?>) {
        guard let value = data[key] as? U else { return }
        target[keyPath: keyPath] = value
    }
}
