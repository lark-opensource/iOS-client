//
//  NewComponentBinder.swift
//  LarkMessageBase
//
//  Created by Ping on 2023/1/28.
//

import UIKit
import Foundation
import AsyncComponent

/// 提供给ViewModel和ActionHandler的能力
public protocol ComponentBinderAbility: AnyObject {
    /// 同步数据
    func syncToBinder(key: String?)
    /// 更新当前Component
    func updateComponent(animation: UITableView.RowAnimation)
    /// 更新当前Component
    func updateComponentAndRoloadTable()
}

extension ComponentBinderAbility {
    public func syncToBinder() {
        syncToBinder(key: nil)
    }

    public func updateComponent() {
        updateComponent(animation: .fade)
    }
}

/// Binder对外依赖
public protocol ComponentBinderDependency: AnyObject {
    /// 更新当前Component
    func update(component: Component, animation: UITableView.RowAnimation)
    /// 更新当前Component
    func updateComponentAndRoloadTable(component: Component)
}

open class NewComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: ViewModelContext> {
    private weak var dependency: ComponentBinderDependency?

    open var component: ComponentWithContext<C> {
        assertionFailure("must override")
        return UIViewComponent<C>(props: .empty, style: ASComponentStyle())
    }

    public let viewModel: NewMessageSubViewModel<M, D, C>?

    public let actionHandler: ComponentActionHandler<C>?

    public init(
        key: String? = nil,
        context: C? = nil,
        viewModel: NewMessageSubViewModel<M, D, C>?,
        actionHandler: ComponentActionHandler<C>?
    ) {
        self.viewModel = viewModel
        self.actionHandler = actionHandler
        viewModel?.binderAbility = self
        actionHandler?.binderAbility = self
        buildComponent(key: key, context: context)
        syncToBinder(key: key)
    }

    public func setDependency(_ dependency: ComponentBinderDependency) {
        self.dependency = dependency
    }

    /// 构造Compoent，Binder init时会调用
    open func buildComponent(key: String? = nil, context: C? = nil) {}

    /// 数据绑定
    open func syncToBinder(key: String?) {
    }
}

extension NewComponentBinder: ComponentBinderAbility {
    /// 局部更新当前Component
    public func updateComponent(animation: UITableView.RowAnimation) {
        self.dependency?.update(component: component, animation: animation)
    }

    /// 局部更新当前Component
    public func updateComponentAndRoloadTable() {
        self.dependency?.updateComponentAndRoloadTable(component: component)
    }
}
