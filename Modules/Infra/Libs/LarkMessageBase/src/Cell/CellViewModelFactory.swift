//
//  CellViewModelFactory.swift
//  LarkMessageCore
//
//  Created by liuwanlin on 2019/3/19.
//

import Foundation
import class LarkModel.Chat
import class LarkModel.Message
import struct LarkModel.SystemContent
import LarkInteraction

final class FactoryEntry<C: PageContext> {
    let factory: MessageSubFactory<C>
    var isLoaded: Bool = false

    init(factory: MessageSubFactory<C>) {
        self.factory = factory
    }
}

/// Cell构造工厂处理Model需要符合x的协议
public protocol CellMetaModel {
    var message: Message { get }
    var getChat: () -> Chat { get }
}

// Cell构造模型依赖的信息，比如CellConfig，高亮信息等,不同场景、不同组件根据需求进行扩展
public protocol CellMetaModelDependency {
    /// 容器Padding
    var contentPadding: CGFloat { get }

    func getContentPreferMaxWidth(_ message: Message) -> CGFloat
}

/// Cell构造工厂（使用于消息场景）
open class CellViewModelFactory<M: CellMetaModel, D: CellMetaModelDependency, C: PageContext>: PageContextWrapper {
    public var pageContext: PageContext { context }

    private var loaded = false

    private let messageEntries: [FactoryEntry<C>]
    private let defaultMessageEntry: FactoryEntry<C>
    private let subEntries: [SubType: FactoryEntry<C>]

    public let context: C

    public private(set) var cellLifeCycleObseverRegister: CellLifeCycleObseverRegister?

    /// 需要直接创建成系统消息的可以前置判断打开，默认为false。
    open func canCreateSystemDirectly(with model: M, metaModelDependency: D) -> Bool {
        return false
    }

    // loadableKey: 启动框架_silgen_name使用的key, https://bytedance.feishu.cn/docx/doxcnyo40YshyZwRzYk5X0gptS1
    public init(context: C, registery: MessageSubFactoryRegistery<C>, cellLifeCycleObseverRegister: CellLifeCycleObseverRegister? = nil) {
        self.context = context

        self.defaultMessageEntry = FactoryEntry<C>(factory: registery.defaultFactory)
        self.messageEntries = registery.messageFactories
            .map { (factory) -> FactoryEntry<C> in
                factory.registerServices(pageContainer: context.pageContainer)
                return FactoryEntry<C>(factory: factory)
            }
            .sorted { (entry1, entry2) -> Bool in
                // entry1 是撤回或销毁的时候排在前面
                // entry1 如果不是，entry2 也不是的时候，entry1也排在前面
                return entry1.factory.priority || !entry2.factory.priority
            }

        self.subEntries = registery.subFactories.mapValues({ (factory) -> FactoryEntry<C> in
            factory.registerServices(pageContainer: context.pageContainer)
            return FactoryEntry<C>(factory: factory)
        })

        self.cellLifeCycleObseverRegister = cellLifeCycleObseverRegister
        self.registerServices()
    }

    /// 通过模型和配置创建CellViewModel
    /// 执行流程：
    /// - canCreateSystemDirectly() => createSystemCellVM
    /// - find the suitable contentFactory => createNormalCellVM
    /// - createSystemCellVM
    ///
    /// - Parameters:
    ///   - model: 数据模型
    ///   - dependency: 数据模型依赖信息
    /// - Returns: CellViewModel
    public func create(with model: M, metaModelDependency: D) -> CellViewModel<C> {
        DispatchQueue.main.async {
            self.onLoad(model, metaModelDependency: metaModelDependency)
        }

        if canCreateSystemDirectly(with: model, metaModelDependency: metaModelDependency) {
            return createSystemCellViewModel(with: model, metaModelDependency: metaModelDependency)
        }

        if let entry = self.filterCanCreateFactoryEntry(with: model, metaModelDependency: metaModelDependency) {
            return create(model: model, metaModelDependency: metaModelDependency, entry: entry)
        }
        return createSystemCellViewModel(with: model, metaModelDependency: metaModelDependency)
    }

    /// 创建消息相关的CellViewModel（必须重写）
    ///
    /// - Parameters:
    ///   - model: 数据模型
    ///   - dependency: 数据模型依赖信息
    ///   - factory: Content构造工厂
    ///   - subFactories: 小组件的构造工厂
    /// - Returns: CellViewModel
    open func createMessageCellViewModel(
        with model: M,
        metaModelDependency: D,
        contentFactory: MessageSubFactory<C>,
        subFactories: [SubType: MessageSubFactory<C>]
    ) -> CellViewModel<C> {
        assertionFailure("must override")
        return CellViewModel<C>(context: context, binder: ComponentBinder<C>(context: context))
    }

    /// 创建系统消息相关的CellViewModel（必须重写）
    ///
    /// - Parameters:
    ///   - model: 数据模型
    ///   - dependency: 数据模型依赖信息
    /// - Returns: CellViewModel
    open func createSystemCellViewModel(with model: M, metaModelDependency: D) -> CellViewModel<C> {
        assertionFailure("must override")
        return CellViewModel<C>(context: context, binder: ComponentBinder<C>(context: context))
    }

    /// 注册支持 drag 能力的 handler
    ///
    /// - Parameter dragManager: 菜单管理器
    /// - model: 数据模型
    /// - dependency: 数据模型依赖信息
    open func registerDragHandler<M: CellMetaModel, D: CellMetaModelDependency>(
        with dragManager: DragInteractionManager,
        metaModel: M,
        metaModelDependency: D) {}

    /// 注册页面级服务
    open func registerServices() {

    }

    public func getContentFactory(with model: M, metaModelDependency: D) -> MessageSubFactory<C> {
        let entry = self.filterCanCreateFactoryEntry(with: model, metaModelDependency: metaModelDependency) ?? defaultMessageEntry
        self.onLoadContentFactory(entry: entry, model: model, metaModelDependency: metaModelDependency)
        return entry.factory
    }

    private func filterCanCreateFactoryEntry(with model: M, metaModelDependency: D) -> FactoryEntry<C>? {
        let message = model.message
        let entry = self.messageEntries
            .first { $0.factory.canCreate(with: model) }
        // 不是系统消息
        if message.type != .system {
            return entry ?? defaultMessageEntry
        }
        // 是系统消息，先走普通消息逻辑，如果还是没有就返回nil，外面system兜底
        return entry
    }

    // Content 构造工厂注册
    private func onLoadContentFactory(entry: FactoryEntry<C>, model: M, metaModelDependency: D) {
        DispatchQueue.main.async {
            // 保证对象没有被释放，registerMenuItems
            guard self.context.dataSourceAPI != nil, self.context.pageAPI != nil else { return }
            // 内容加载
            if !entry.isLoaded {
                entry.factory.registerDragHandler(
                    with: self.context.dragManager,
                    metaModel: model,
                    metaModelDependency: metaModelDependency
                )
            }
            entry.isLoaded = true
        }
    }

    private func create(model: M, metaModelDependency: D, entry: FactoryEntry<C>) -> CellViewModel<C> {
        let subEntries = self.subEntries
        self.onLoadContentFactory(entry: entry, model: model, metaModelDependency: metaModelDependency)
        DispatchQueue.main.async {
            // 保证对象没有被释放，registerMenuItems
            guard self.context.dataSourceAPI != nil, self.context.pageAPI != nil else { return }
            // 子组件加载
            subEntries.filter { !$0.value.isLoaded }
                .forEach {
                    $0.value.isLoaded = true
                    $0.value.factory.registerDragHandler(
                        with: self.context.dragManager,
                        metaModel: model,
                        metaModelDependency: metaModelDependency
                    )
                }
        }

        return createMessageCellViewModel(
            with: model,
            metaModelDependency: metaModelDependency,
            contentFactory: entry.factory,
            subFactories: subEntries.mapValues { $0.factory }
        )
    }

    private func onLoad(_ model: M, metaModelDependency: D) {
        // 保证对象没有被释放，registerMenuItems
        guard context.dataSourceAPI != nil, context.pageAPI != nil else { return }

        if self.loaded { return }

        self.loaded = true
    }
}
