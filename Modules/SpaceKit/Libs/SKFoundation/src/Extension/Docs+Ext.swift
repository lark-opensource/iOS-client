//
//  Docs+Ext.swift
//  DocsCommon
//
//  Created by weidong fu on 25/11/2017.
//

import Foundation

public final class DocsExtension<BaseType> {
    public var base: BaseType
    init(_ base: BaseType) {
        self.base = base
    }
}

public protocol DocsExtensionCompatible {
    associatedtype DocsCompatibleType
    var docs: DocsCompatibleType { get }
    static var docs: DocsCompatibleType.Type { get }
}

public extension DocsExtensionCompatible {
    var docs: DocsExtension<Self> {
        return DocsExtension(self)
    }
    static var docs: DocsExtension<Self>.Type {
        return DocsExtension.self
    }
}
