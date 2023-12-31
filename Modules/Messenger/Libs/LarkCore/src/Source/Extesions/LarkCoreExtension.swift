//
//  LarkCoreExtension.swift
//  LarkCore
//
//  Created by liuwanlin on 2018/4/26.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation

public final class LarkCoreExtension<BaseType> {
    var base: BaseType
    init(_ base: BaseType) {
        self.base = base
    }
}

public protocol LarkCoreExtensionCompatible {
    associatedtype LarkCoreCompatibleType
    var lc: LarkCoreCompatibleType { get }
    static var lc: LarkCoreCompatibleType.Type { get }
}

public extension LarkCoreExtensionCompatible {
    var lc: LarkCoreExtension<Self> {
        return LarkCoreExtension(self)
    }

    static var lc: LarkCoreExtension<Self>.Type {
        return LarkCoreExtension.self
    }
}
