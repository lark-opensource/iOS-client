//
//  File.swift
//  LarkSearch
//
//  Created by SuPeng on 5/8/19.
//

import Foundation

public final class LarkSearchExtension<BaseType> {
    public var base: BaseType
    public init(_ base: BaseType) {
        self.base = base
    }
}

// swiftlint:disable identifier_name
public protocol LarkSearchExtensionCompatible {
    associatedtype LarkSearchCompatibleType
    var ls: LarkSearchCompatibleType { get }
    static var ls: LarkSearchCompatibleType.Type { get }
}

public extension LarkSearchExtensionCompatible {
    var ls: LarkSearchExtension<Self> {
        return LarkSearchExtension(self)
    }

    static var ls: LarkSearchExtension<Self>.Type {
        return LarkSearchExtension.self
    }
}
// swiftlint:enable identifier_name
