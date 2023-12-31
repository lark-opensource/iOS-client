//
//  Protocol.swift
//  LarkResource
//
//  Created by 李晨 on 2020/2/21.
//

import Foundation

public typealias MetaResourceResult = Result<MetaResource, ResourceError>
public typealias ResourceResult<T> = Result<Resource<T>, ResourceError>

public struct DefaultIndexTable {
    enum TypeEnum: String {
        case app
        case sandbox
    }

    struct Value {
        var indexTable: IndexTable?

        init(_ indexTable: IndexTable?) {
            self.indexTable = indexTable
        }
    }
}

protocol ResouceAPI {

    /// 默认全局索引表
    var defaultIndexTables: [IndexTable] { get }

    /// 全局设置索引表
    var indexTables: [IndexTable] { get }

    /// 重新加载框架默认资源索引
    func reloadDefaultIndexTables(
        _ info: [DefaultIndexTable.TypeEnum: DefaultIndexTable.Value]
    )

    /// 获取 meta resource 接口，如果查询到资源
    func metaResource(key: ResourceKey, options: OptionsInfo) -> MetaResourceResult

    /// 获取 meta resource 接口，如果查询到资源，返回 MetaResource, 否则返回 nil
    func metaResource(key: ResourceKey, options: OptionsInfo) -> MetaResource?

    /// 获取 resource 接口， 支持通过泛型获取转化过的资源，如果查询并且转化成功
    func resource<T: ResourceConvertible>(key: ResourceKey, options: OptionsInfo) -> ResourceResult<T>

    /// 获取 resource 接口， 支持通过泛型获取转化过的资源，如果查询并且转化成功，则返回泛型资源, 否则返回 nil
    func resource<T: ResourceConvertible>(key: ResourceKey, options: OptionsInfo) -> T?

    /// 初始化全局索引表,  数组中索引优先级依次降低
    func setup(indexTables: [IndexTable])

    /// 插入或者更新索引表, 新插入优先级高于之前的索引，数组中索引优先级依次降低
    func insertOrUpdate(indexTables: [IndexTable])

    /// 删除全局索引表
    func remove(indexTableIDs: [String])
}
