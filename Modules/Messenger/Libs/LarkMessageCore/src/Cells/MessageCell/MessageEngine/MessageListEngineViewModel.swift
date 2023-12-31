//
//  MessageListEngineViewModel.swift
//  LarkMessageCore
//
//  Created by Ping on 2023/3/28.
//

import AsyncComponent
import LarkMessageBase
import ThreadSafeDataStructure

public struct MessageListEngineConfig {
    // 元素上下间距
    public var componentSpacing: CGFloat?
    // 与列表容器的上间距
    public var marginTop: CGFloat?
    // 与列表容器的下间距
    public var marginBottom: CGFloat?

    public init() {}
}

public final class MessageListEngineViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: PageContext> {
    public let renderer: ASComponentRenderer
    let engineComponentProps: MessageListEngineComponentProps<C>
    let engineComponent: MessageListEngineComponent<C>
    private var cellViewModels: SafeArray<CellViewModel<C>> = [] + .readWriteLock
    let vmFactory: CellViewModelFactory<M, D, C>

    public init(
        metaModels: [M],
        metaModelDependency: (ASComponentRenderer) -> D, // 卡片上渲染多条Message时，Renderer需要外部注入
        vmFactory: CellViewModelFactory<M, D, C>,
        config: MessageListEngineConfig = .init()
    ) {
        let engineComponentProps = MessageListEngineComponentProps<C>(subComponents: [])
        engineComponentProps.componentSpacing = config.componentSpacing
        engineComponentProps.marginTop = config.marginTop
        engineComponentProps.marginBottom = config.marginBottom
        let engineComponent = MessageListEngineComponent(props: engineComponentProps, style: ASComponentStyle())
        let renderer = ASComponentRenderer(engineComponent)
        self.engineComponentProps = engineComponentProps
        self.engineComponent = engineComponent
        self.renderer = renderer
        self.vmFactory = vmFactory
        reset(metaModels: metaModels, metaModelDependency: metaModelDependency(renderer))
    }

    @discardableResult
    public func update(metaModels: [M], metaModelDependency: D) -> Bool {
        var hasUpdate = false
        for metaModel in metaModels {
            if let cellVM = first(metaModel: metaModel) as? MessageCellViewModel<M, D, C> {
                cellVM.update(metaModel: metaModel, metaModelDependency: metaModelDependency)
                hasUpdate = true
            }
        }
        if hasUpdate {
            let subComponents = cellViewModels.map { $0.binder.component }
            resetSubComponents(subComponents: subComponents)
        }
        return hasUpdate
    }

    public func reset(metaModels: [M], metaModelDependency: D) {
        let cellVMs = metaModels.map({ vmFactory.create(with: $0, metaModelDependency: metaModelDependency) })
        self.cellViewModels.replaceInnerData(by: cellVMs)
        let subComponents = cellVMs.map { $0.binder.component }
        resetSubComponents(subComponents: subComponents)
    }

    public func updateRootComponent() {
        renderer.update(rootComponent: engineComponent)
    }

    private func resetSubComponents(subComponents: [ComponentWithContext<C>]) {
        // 消息链接化场景会展示多条消息，需要移除自定义key，否则key重复可能导致UI异常
        var children = subComponents
        while !children.isEmpty {
            if let sub = children.popLast() {
                sub.getProps()?.key = nil
                if let component = sub as? ComponentWithSubContext<C, C> {
                    children.append(contentsOf: component.children)
                }
            }
        }
        engineComponentProps.subComponents = subComponents
        engineComponent.props = engineComponentProps
        renderer.update(rootComponent: engineComponent)
    }

    private func first(metaModel: M) -> CellViewModel<C>? {
        return cellViewModels.first(where: { cellVM in
            if let messageCellVM = cellVM as? MessageCellViewModel<M, D, C> {
                return messageCellVM.metaModel.message.id == metaModel.message.id
            }
            return false
        })
    }

    public func willDisplay() {
        cellViewModels.forEach { vm in
            vm.willDisplay()
        }
    }

    public func didEndDisplay() {
        cellViewModels.forEach { vm in
            vm.didEndDisplay()
        }
    }

    public func onResize() {
        cellViewModels.forEach { vm in
            vm.onResize()
        }
        let subComponents = cellViewModels.map({ $0.binder.component })
        resetSubComponents(subComponents: subComponents)
    }
}
