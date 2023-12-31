//
//  LarkFoundation+Extension.swift
//  LarkFoundation
//
//  Created by ChalrieSu on 24/12/2017.
//  Copyright © 2017 com.bytedance.lark. All rights reserved.
//

import Foundation
public final class LarkFoundationExtension<BaseType> {
    public var base: BaseType
    public init(_ base: BaseType) {
        self.base = base
    }
}

// swiftlint:disable identifier_name

public protocol LarkFoundationExtensionCompatible {
    associatedtype LarkFoundationCompatibleType

    var lf: LarkFoundationCompatibleType { get }
    static var lf: LarkFoundationCompatibleType.Type { get }
}

public extension LarkFoundationExtensionCompatible {
    var lf: LarkFoundationExtension<Self> {
        return LarkFoundationExtension(self)
    }

    static var lf: LarkFoundationExtension<Self>.Type {
        return LarkFoundationExtension.self
    }
}

// swiftlint:enable identifier_name
