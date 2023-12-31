//
//  ComponentGenerator.swift
//  LarkMessageCore
//
//  Created by liuwanlin on 2019/3/19.
//

import UIKit
import Foundation
import EEFlexiable
import AsyncComponent

/// Component体系下用的VM绑定类
/// 职责：根据VM+Context 更新和创建期望的Component
open class ComponentBinder<C: AsyncComponent.Context> {
    open var component: ComponentWithContext<C> {
        assertionFailure("must override")
        return UIViewComponent<C>(props: .empty, style: ASComponentStyle())
    }

    public init(key: String? = nil, context: C? = nil) {
        buildComponent(key: key, context: context)
    }

    /// 更新VM到Component的绑定
    ///
    /// - Parameters:
    ///   - vm: 必须继承自ViewModel
    ///   - key: Component可能的key
    open func update<VM: ViewModel>(with vm: VM, key: String? = nil) {

    }

    /// 初始化Component
    ///
    /// - Parameters:
    ///   - key: Component的key
    ///   - context: Context上下文
    open func buildComponent(key: String? = nil, context: C? = nil) {

    }
}
