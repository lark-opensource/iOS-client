//
//  DocsSDK+Ext.swift
//  Docs
//
//  Created by weidong fu on 1/3/2018.
//

import Foundation

public final class PrivateFoundationExtension<BaseType> {
    public var base: BaseType
    public init(_ base: BaseType) {
        self.base = base
    }
}

public protocol PrivateFoundationExtensionCompatible {
    associatedtype PrivateFoundationCompatibleType
    var ext: PrivateFoundationCompatibleType { get }
    static var ext: PrivateFoundationCompatibleType.Type { get }
}

public extension PrivateFoundationExtensionCompatible {
    var ext: PrivateFoundationExtension<Self> {
        return PrivateFoundationExtension(self)
    }
    static var ext: PrivateFoundationExtension<Self>.Type {
        return PrivateFoundationExtension.self
    }
}
