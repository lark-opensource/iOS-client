//
//  Resource.swift
//  LarkLocalizations
//
//  Created by 李晨 on 2020/2/20.
//

import Foundation

/// 索引表中取出的原始数据
public struct MetaResource {
    public let key: ResourceKey
    public let index: IndexValue

    public init(key: ResourceKey, index: IndexValue) {
        self.key = key
        self.index = index
    }
}
/// 资源模型，支持通过泛型定义资源类型
public struct Resource<T> {
    public let key: ResourceKey
    public let index: IndexValue
    public let value: T

    public init(key: ResourceKey, index: IndexValue, value: T) {
        self.key = key
        self.index = index
        self.value = value
    }
}
