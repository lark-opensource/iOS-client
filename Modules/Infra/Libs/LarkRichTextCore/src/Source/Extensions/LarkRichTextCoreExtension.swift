//
//  LarkRichTextCoreExtension.swift
//  LarkRichTextCore
//
//  Created by liuwanlin on 2018/4/26.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation

public final class LarkRichTextCoreExtension<BaseType> {
    var base: BaseType
    init(_ base: BaseType) {
        self.base = base
    }
}

public protocol LarkRichTextCoreExtensionCompatible {
    associatedtype LarkRichTextCoreCompatibleType
    var lc: LarkRichTextCoreCompatibleType { get }
    static var lc: LarkRichTextCoreCompatibleType.Type { get }
}

public extension LarkRichTextCoreExtensionCompatible {
    var lc: LarkRichTextCoreExtension<Self> {
        return LarkRichTextCoreExtension(self)
    }

    static var lc: LarkRichTextCoreExtension<Self>.Type {
        return LarkRichTextCoreExtension.self
    }
}
