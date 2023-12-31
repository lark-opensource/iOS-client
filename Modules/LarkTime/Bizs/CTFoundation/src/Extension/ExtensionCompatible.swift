//
//  ExtensionCompatible.swift
//  CTFoundation
//
//  Created by 张威 on 2020/11/19.
//

// swiftlint:disable all

import Foundation

public final class CTFoundationExtension<BaseType> {
    public var base: BaseType
    public init(_ base: BaseType) {
        self.base = base
    }
}

public protocol CTFoundationExtensionCompatible {
    associatedtype CTFoundationCompatibleType
    var ctf: CTFoundationCompatibleType { get }
    static var ctf: CTFoundationCompatibleType.Type { get }
}

public extension CTFoundationExtensionCompatible {
    var ctf: CTFoundationExtension<Self> {
        return CTFoundationExtension(self)
    }

    static var ctf: CTFoundationExtension<Self>.Type {
        return CTFoundationExtension.self
    }
}

// swiftlint:enable all
