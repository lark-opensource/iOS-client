//
//  IsoPath+Ext.swift
//  LarkStorage
//
//  Created by 7Up on 2022/9/22.
//

import Foundation

public struct IsoPathBuilder {
    var space: Space
    var domain: DomainType

    /// 根据指定 rootPathType 构建 `IsoPath`
    ///
    /// - Parameter type: root path type
    /// - Returns: `IsoPath`
    public func build(_ type: RootPathType.Normal) -> IsoPath {
        return build(forType: type)
    }

    /// 根据指定 rootPathType 构建 `IsoPath`
    ///
    /// - Parameters:
    ///   - type: root path type
    ///   - relativePart: 相对路径部分
    /// - Returns: `IsoPath`
    public func build(forType type: RootPathType.Normal, relativePart: String? = nil) -> IsoPath {
        let sandbox = IsolateSandbox(space: space, domain: domain)
        if let relativePart = relativePart, !relativePart.isEmpty {
            return sandbox.path(forType: type, relativePart: relativePart)
        } else {
            return sandbox.rootPath(forType: type)
        }
    }

    /// 根据指定 rootPathType 构建 `IsoPath`
    ///
    /// - Parameters:
    ///   - type: root path type
    ///   - relativePart: 相对路径部分
    /// - Returns: `IsoPath?`
    public func buildShared(forType type: RootPathType.Shared = .root, relativePart: String? = nil) -> IsoPath? {
        let sandbox = IsolateSandbox(space: space, domain: domain)
        if let relativePart, !relativePart.isEmpty {
            return sandbox.sharedPath(forType: type, relativePart: relativePart)
        } else {
            return sandbox.sharedRootPath(forType: type)
        }
    }
}

public struct IsoPathBuilder0 {
    var space: Space
    public func `in`(domain: DomainType) -> IsoPathBuilder {
        return .init(space: space, domain: domain)
    }
}

public extension IsoPath {
    /// 指定 space
    static func `in`(space: Space) -> IsoPathBuilder0 {
        return .init(space: space)
    }

    /// 指定 global space
    static var global: IsoPathBuilder0 {
        return `in`(space: .global)
    }

    /// 指定 user space
    static func user(id: String) -> IsoPathBuilder0 {
        return `in`(space: .user(id: id))
    }

    /// 指定 space 和 domain
    static func `in`(space: Space, domain: DomainType) -> IsoPathBuilder {
        return `in`(space: space).in(domain: domain)
    }
}
