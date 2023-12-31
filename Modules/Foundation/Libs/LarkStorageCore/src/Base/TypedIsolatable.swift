//
//  TypedIsolatable.swift
//  LarkStorage
//
//  Created by 7Up on 2022/9/22.
//

import Foundation

public struct TypedSpace<T> {
    var value: Space
    var type: T.Type
    public init(_ value: Space, type: T.Type) {
        self.value = value
        self.type = type
    }
}

public struct TypedIsolatable<T> {
    var space: TypedSpace<T>
    var domain: DomainType
    public init(space: TypedSpace<T>, domain: DomainType) {
        self.space = space
        self.domain = domain
    }
}

public protocol TypedSpaceCompatible { }

public extension TypedSpaceCompatible {
    /// 指定 space
    static func `in`(space: Space) -> TypedSpace<Self> {
        return .init(space, type: Self.self)
    }

    /// 指定 space 和 domain
    static func `in`(space: Space, domain: DomainType) -> TypedIsolatable<Self> {
        return `in`(space: space).in(domain: domain)
    }

    /// 指定 global space
    static var global: TypedSpace<Self> {
        return `in`(space: .global)
    }

    static func global(in domain: DomainType) -> TypedIsolatable<Self> {
        return `in`(space: .global, domain: domain)
    }

    /// 指定 user space
    static func user(id: String) -> TypedSpace<Self> {
        return `in`(space: .user(id: id))
    }

    static func user(id: String, in domain: DomainType) -> TypedIsolatable<Self> {
        return `in`(space: .user(id: id), domain: domain)
    }
}

extension TypedSpace {
    /// 指定 domain
    public func `in`(domain: DomainType) -> TypedIsolatable<T> {
        return .init(space: self, domain: domain)
    }
}
