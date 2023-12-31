//
//  Convertible.swift
//  LarkLocalizations
//
//  Created by 李晨 on 2020/2/20.
//

import Foundation

/// 资源数据转化闭包
public typealias ConvertBlock<T> = (_ result: MetaResource, _ options: OptionsInfoSet) throws -> T

/// 资源转化协议
public protocol ResourceConvertible {
    static var convertEntry: ConvertibleEntryProtocol { get }
}

public func == (lhs: ConvertKey, rhs: ConvertKey) -> Bool {
    return lhs.resourceType == rhs.resourceType
}

/// 自定义资源转化协议
public protocol ConvertibleEntryProtocol: AnyObject {
    func convert<T>(result: MetaResource, options: OptionsInfoSet) throws -> T
}

/// 资源转化 key
/// 可以支持用户自定义资源转化方法
public struct ConvertKey {
    public let resourceType: Any.Type

    public init(
        resourceType: Any.Type
    ) {
        self.resourceType = resourceType
    }
}

extension ConvertKey: Hashable {
    public func hash(into hasher: inout Hasher) {
        ObjectIdentifier(resourceType).hash(into: &hasher)
    }
}

/// 对资源转化方法封装对象
/// 可以由自定义资源转化方法
public final class ConvertibleEntry<ResouceType>: ConvertibleEntryProtocol {
    var resouceType: Any.Type = ResouceType.self
    var transformBlock: ConvertBlock<ResouceType>

    public init(_ transformBlock: @escaping ConvertBlock<ResouceType>) {
        self.transformBlock = transformBlock
    }

    public func convert<T>(result: MetaResource, options: OptionsInfoSet) throws -> T {
        guard resouceType is T.Type else {
            throw ResourceError.resourceTypeError
        }
        guard let resource = try self.transformBlock(result, options) as? T else {
            throw ResourceError.transformFailed
        }
        return resource
    }
}
