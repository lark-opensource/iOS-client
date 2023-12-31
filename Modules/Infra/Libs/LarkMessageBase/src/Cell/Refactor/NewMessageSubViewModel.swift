//
//  NewMessageSubViewModel.swift
//  LarkMessageBase
//
//  Created by Ping on 2023/1/28.
//

import Foundation
import LarkModel
import AsyncComponent

/// 消息子内容ViewModel（例如点赞、URL预览、Docs预览等）
open class NewMessageSubViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: ViewModelContext>: ViewModel {
    /// 重用标识符（会拼接到外层消息cell的重用标识符中）
    open var identifier: String {
        fatalError("must override")
    }

    public var metaModel: M
    public var metaModelDependency: D
    public weak var binderAbility: ComponentBinderAbility?

    /// 消息实体
    open var message: Message {
        return metaModel.message
    }

    /// 上下文（提供全局能力和页面接口）
    public let context: C

    /// 内容配置(目前只在内容区域有效)
    open var contentConfig: ContentConfig? { return nil }

    /// 通过Message和Binder初始化VM
    ///
    /// - Parameters:
    ///   - metaModel: 数据实体
    ///   - dependency: 数据依赖信息
    ///   - context: 上下文（提供全局能力和页面接口）
    ///   - binder: 绑定VM和Component
    public init(metaModel: M, metaModelDependency: D, context: C) {
        self.metaModel = metaModel
        self.context = context
        self.metaModelDependency = metaModelDependency
        super.init()
        self.initialize()
    }

    /// 新消息变化时，是否应该更新当前组件
    ///
    /// - Parameter new: 新消息
    /// - Returns: 是否应该更新
    open func shouldUpdate(_ new: Message) -> Bool {
        return true
    }

    /// 帮助完成非message context binder的其他属性的初始化工作
    /// 调用时机: init之后，binder.update之前
    open func initialize() {}

    /// 消息更新接口
    ///
    /// - Parameter metaModel: 变化后的数据实体
    ///   - dependency: 数据依赖信息
    open func update(metaModel: M, metaModelDependency: D?) {
        self.metaModel = metaModel
        if let metaModelDependency = metaModelDependency {
            self.metaModelDependency = metaModelDependency
        }
        binderAbility?.syncToBinder()
    }

    /// size 发生变化, 更新 binder
    override open func onResize() {
        binderAbility?.syncToBinder()
        super.onResize()
    }
}

extension NewMessageSubViewModel: PageContextWrapper where C: PageContext {
    public var pageContext: PageContext { context }
}
