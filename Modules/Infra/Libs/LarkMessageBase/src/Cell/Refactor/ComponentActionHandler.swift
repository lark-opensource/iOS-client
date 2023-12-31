//
//  ComponentActionHandler.swift
//  LarkMessageBase
//
//  Created by Ping on 2023/1/28.
//

import Foundation
import AsyncComponent

open class ComponentActionHandler<C: AsyncComponent.Context> {
    /// 上下文（提供全局能力和页面接口）
    public let context: C
    public weak var binderAbility: ComponentBinderAbility?

    public init(context: C) {
        self.context = context
    }
}

extension ComponentActionHandler: PageContextWrapper where C: PageContext {
    public var pageContext: PageContext { context }
}
