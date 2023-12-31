//
//  CCMExtension.swift
//  SKFoundation
//
//  Created by ByteDance on 2023/8/24.
//

import Foundation
import LarkContainer

public struct CCMExtension<Base> {
    public var base: Base
    init(_ base: Base) {
        self.base = base
    }
}

public protocol CCMExtensionCompatible {
    associatedtype CCMCompatibleType
    var docs: CCMCompatibleType { get }
    static var docs: CCMCompatibleType.Type { get }
}

public extension CCMExtensionCompatible {
    var docs: CCMExtension<Self> { CCMExtension(self) }
    static var docs: CCMExtension<Self>.Type { CCMExtension<Self>.self }
}

extension UserResolver: CCMExtensionCompatible {}
