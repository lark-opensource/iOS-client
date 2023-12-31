//
//  MessageSubFactory.swift
//  Pods
//
//  Created by liuwanlin on 2019/3/20.
//

import Foundation
import AsyncComponent
import LarkInteraction
import LKLoadable

/// 消息内容工厂注册，用户外部集成内容区域的实现
open class MessageSubFactoryRegistery<C: PageContext> {
    public let defaultFactory: MessageSubFactory<C>
    public let messageFactories: [MessageSubFactory<C>]
    public let subFactories: [SubType: MessageSubFactory<C>]

    public init(
        defaultFactory: MessageSubFactory<C>,
        messageFactories: [MessageSubFactory<C>],
        subFactories: [SubType: MessageSubFactory<C>]
    ) {
        self.defaultFactory = defaultFactory
        self.messageFactories = messageFactories
        self.subFactories = subFactories
    }

    //启动优化https://bytedance.feishu.cn/docx/doxcnyo40YshyZwRzYk5X0gptS1 子类在inint时调用，延迟加载注册
    public static func lazyLoadRegister(_ loadableKey: String) {
        if !loadableKey.isEmpty {
            SwiftLoadable.startOnlyOnce(key: "\(loadableKey)")
        }
    }
}

/// 消息子内容工厂
open class MessageSubFactory<C: ViewModelContext> {

    /// 消息子组件的类型
    open class var subType: SubType {
        fatalError("must overrid")
    }

    /// 内容的特化接口，撤回、销毁、解密失败等优先
    open var priority: Bool {
        return false
    }

    /// 是否能创建Binder，为true时调用createBinder()，走新框架
    /// 默认为false，调用create()方法创建MessageSubViewModel，走老框架
    open var canCreateBinder: Bool {
        return false
    }

    /// 上下文（提供全局能力和页面接口）
    public let context: C

    /// [required]构造方法
    ///
    /// - Parameter context: 上下文（提供全局能力和页面接口）
    public required init(context: C) {
        self.context = context
    }

    /// 该消息是否可以创建对应类型的消息（子类必须覆盖）
    ///
    /// - Parameter metaModel: 数据实体
    /// - Returns: 是否可以创建
    open func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        assertionFailure("must override")
        return true
    }

    /// 通过消息创建对应的ContentViewModel（子类必须覆盖）
    ///
    /// - Parameter metaModel: 数据实体
    /// - dependency: 数据模型依赖信息
    /// - Returns: ContentViewModel
    open func create<M: CellMetaModel, D: CellMetaModelDependency>(
        with metaModel: M,
        metaModelDependency: D
    ) -> MessageSubViewModel<M, D, C> {
        assertionFailure("must override")
        return MessageSubViewModel(metaModel: metaModel,
                                   metaModelDependency: metaModelDependency,
                                   context: context,
                                   binder: ComponentBinder<C>(context: context))
    }

    open func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(
        with metaModel: M,
        metaModelDependency: D
    ) -> NewComponentBinder<M, D, C> {
        assertionFailure("must override")
        return NewComponentBinder(viewModel: nil, actionHandler: nil)
    }


    /// 注册支持 drag 能力的 handler
    ///
    /// - Parameter dragManager: 菜单管理器
    /// - model: 数据模型
    /// - dependency: 数据模型依赖信息
    open func registerDragHandler<M: CellMetaModel, D: CellMetaModelDependency>(
        with dargManager: DragInteractionManager,
        metaModel: M,
        metaModelDependency: D
    ) {}

    /// 注册页面级服务
    open func registerServices(pageContainer: PageContainer) {

    }
}
