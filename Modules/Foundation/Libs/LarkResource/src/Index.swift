//
//  Index.swift
//  LarkLocalizations
//
//  Created by 李晨 on 2020/2/20.
//

import Foundation

/// 索引值
public struct IndexValue {
    /// 索引值的类型
    public enum TypeEnum: String {
        case assetPath = "asset-path"
        case bundlePath = "bundle-path"
        case color = "color"
        case table = "table-name"
    }
    /// 索引值
    public enum Value {
        case string(String)
        case boolean(Bool)
        case data(Data)
        case number(NSNumber)
    }

    /// 索引值类型
    public var type: TypeEnum
    /// 索引值
    public var value: Value
    /// 索引值对应的 bundle
    public var bundle: Bundle
}

/// 索引表，每一个索引文件是一个单独的索引表
public protocol IndexTable {
    /// 索引表唯一 id
    var identifier: String { get }
    /// 根据 key 查找资源方法
    func resourceIndex(key: ResourceKey) -> MetaResource?
}
