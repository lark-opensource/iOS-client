//
//  BaseMomentFeedListSubCellViewModel.swift
//  Moment
//
//  Created by zc09v on 2021/1/6.
//

import UIKit
import Foundation
import LarkMessageBase
import AsyncComponent

protocol HasId {
    var id: String { get }
}

class BaseMomentSubCellViewModel<M: HasId, C: BaseMomentContextInterface>: ViewModel {
    /// 重用标识符（会拼接到外层消息cell的重用标识符中）
    open var identifier: String {
        fatalError("must override")
    }

    /// 消息实体
    var entity: M

    /// 上下文（提供全局能力和页面接口）
    public let context: C

    /// 负责绑定VM和Component，避免Component对VM造成污染
    public let binder: ComponentBinder<C>

    weak var renderer: ASComponentRenderer?

    ///
    /// - Parameters:
    ///   - entity: 数据实体
    ///   - context: 上下文（提供全局能力和页面接口）
    ///   - binder: 绑定VM和Component
    init(entity: M, context: C, binder: ComponentBinder<C>) {
        self.entity = entity
        self.context = context
        self.binder = binder
        super.init()
        self.initialize()
        self.syncToBinder()
    }

    /// 定义如何向binder同步数据
    open func syncToBinder() {
        self.binder.update(with: self)
    }

    /// 初始化渲染引擎（父亲初始化或者重新设置的时候调用）
    ///
    /// - Parameter renderer: 渲染引擎
    public func initRenderer(_ renderer: ASComponentRenderer) {
        self.renderer = renderer
    }

    /// 局部更新component
    ///
    /// - Parameter component: 更新后的component
    enum UpdateComponentMode {
        case reloadAllData
        case reloadRow(UITableView.RowAnimation)
    }

    public func update(component: Component, mode: UpdateComponentMode = .reloadRow(.none)) {
        renderer?.update(component: component, rendererNeedUpdate: { [weak self] in
            switch mode {
            case .reloadAllData:
                self?.context.reloadData()
            case .reloadRow(let animation):
                if let entityId = self?.entity.id {
                    self?.context.reloadRow(by: entityId, animation: animation)
                }
            }
        })
    }

    /// 新消息变化时，是否应该更新当前组件
    ///
    /// - Parameter new: 新消息
    /// - Returns: 是否应该更新
    func shouldUpdate(_ new: M) -> Bool {
        return true
    }

    /// 帮助完成非message context binder的其他属性的初始化工作
    /// 调用时机: init之后，binder.update之前
    open func initialize() {}

    /// 消息更新接口
    ///
    /// - Parameter metaModel: 变化后的数据实体
    ///   - dependency: 数据依赖信息
    func update(entity: M) {
        self.entity = entity
        syncToBinder()
    }

    /// 对应的Component
    var component: ComponentWithContext<C> {
        return binder.component
    }

    /// size 发生变化, 更新 binder
    override open func onResize() {
        syncToBinder()
        super.onResize()
    }
}
