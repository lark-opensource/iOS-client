//
//  MessageCellViewModel.swift
//  LarkMessageCore
//
//  Created by liuwanlin on 2019/6/5.
//

import UIKit
import Foundation
import class LarkModel.Message
import class LarkModel.Chat
import class LarkModel.MergeForwardContent
import struct LarkModel.FileContent
import struct LarkModel.FolderContent
import struct LarkModel.CardContent
import struct LarkModel.TodoContent
import LarkNavigation
import LarkContainer
import LarkFeatureGating
import AsyncComponent
import LKCommonsLogging

private let logger = Logger.log(NSObject(), category: "LarkMessageBase.MessageCellViewModel")

public protocol HasMessage {
    var message: Message { get }
}

open class MessageCellViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: ViewModelContext>: CellViewModel<C>, HasMessage {
    public private(set) var metaModel: M
    public private(set) var metaModelDependency: D

    public var message: Message {
        return metaModel.message
    }

    private var contentBinder: NewComponentBinder<M, D, C>?
    public private(set) var content: NewMessageSubViewModel<M, D, C> {
        didSet {
            self.resetContent(with: content, old: oldValue)
        }
    }
    public var contentComponent: ComponentWithContext<C> {
        if let contentVM = content as? MessageSubViewModel<M, D, C> {
            return contentVM.component
        }
        if let binder = contentBinder {
            return binder.component
        }
        assertionFailure("unknown type")
        return UIViewComponent<C>(props: .empty, style: ASComponentStyle())
    }

    /// 为了兼容新老架构，不对外暴露subvms
    private var subvms: [SubType: MessageSubViewModel<M, D, C>]
    private var subBinders: [SubType: NewComponentBinder<M, D, C>]

    public let subFactories: [SubType: MessageSubFactory<C>]
    private var vaildFactoryTypes: Set<SubType>
    public var contentFactory: MessageSubFactory<C>
    private let getContentFactory: (M, D) -> MessageSubFactory<C>

    public var cellLifeCycleObseverRegister: CellLifeCycleObseverRegister?

    /// - Parameters:
    ///   - contentFactory: Content 构造工厂
    ///   - getContentFactory: 根据 metaModel 和 metaModelDependency 动态获取 Content 构造工厂
    ///   - renderer: 渲染能力，对于消息链接化等场景渲染能力需要支持注入
    public init(
        metaModel: M,
        metaModelDependency: D,
        context: C,
        contentFactory: MessageSubFactory<C>,
        getContentFactory: @escaping (M, D) -> MessageSubFactory<C>,
        subFactories: [SubType: MessageSubFactory<C>],
        initBinder: (ComponentWithContext<C>) -> ComponentBinder<C>,
        cellLifeCycleObseverRegister: CellLifeCycleObseverRegister?,
        renderer: ASComponentRenderer? = nil
    ) {
        self.metaModel = metaModel
        self.metaModelDependency = metaModelDependency
        self.contentFactory = contentFactory

        let contentVM: NewMessageSubViewModel<M, D, C>
        let contentComponent: ComponentWithContext<C>
        if contentFactory.canCreateBinder {
            let contentBinder = contentFactory.createBinder(with: metaModel, metaModelDependency: metaModelDependency)
            contentVM = contentBinder.viewModel ?? NewMessageSubViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context)
            self.contentBinder = contentBinder
            contentComponent = contentBinder.component
        } else {
            let subVM = contentFactory.create(with: metaModel, metaModelDependency: metaModelDependency)
            contentVM = subVM
            contentComponent = subVM.component
        }
        self.content = contentVM

        self.getContentFactory = getContentFactory
        self.subFactories = subFactories
        let vaildSubfactories = subFactories.filter {
            return $0.value.canCreate(with: metaModel)
        }
        vaildFactoryTypes = Set(vaildSubfactories.keys)
        let subvmsFactories = vaildSubfactories.filter({ !$0.value.canCreateBinder })
        let subBindersFactories = vaildSubfactories.filter({ $0.value.canCreateBinder })
        self.subvms = subvmsFactories
            .mapValues({ $0.create(with: metaModel, metaModelDependency: metaModelDependency) })
        self.subBinders = subBindersFactories.mapValues({ $0.createBinder(with: metaModel, metaModelDependency: metaModelDependency) })
        super.init(context: context, binder: initBinder(contentComponent), renderer: renderer)
        self.resetContent(with: content, old: nil)
        self.subvms.values.forEach { (vm) in
            self.addChild(vm)
            vm.initRenderer(self.renderer)
        }
        self.subBinders.values.forEach { binder in
            if let vm = binder.viewModel {
                self.addChild(vm)
            }
            binder.setDependency(self)
        }
        self.cellLifeCycleObseverRegister = cellLifeCycleObseverRegister
    }

    open func update(metaModel: M, metaModelDependency: D?) {
        if self.metaModel.message.type != metaModel.message.type {
            logger.info("message type changed \(self.metaModel.message.id)")
            self.contentFactory = self.getContentFactory(metaModel, metaModelDependency ?? self.metaModelDependency)
            let contentVM: NewMessageSubViewModel<M, D, C>
            let metaModelDependency = metaModelDependency ?? self.metaModelDependency
            if contentFactory.canCreateBinder {
                self.contentBinder = contentFactory.createBinder(with: metaModel, metaModelDependency: metaModelDependency)
                contentVM = self.contentBinder?.viewModel ?? NewMessageSubViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context)
            } else {
                contentVM = contentFactory.create(with: metaModel, metaModelDependency: metaModelDependency)
            }
            self.content = contentVM
        }
        self.metaModel = metaModel
        if let metaModelDependency = metaModelDependency {
            self.metaModelDependency = metaModelDependency
        }
        let newVaildSubfactories = subFactories.filter {
            return $0.value.canCreate(with: metaModel)
        }
        let newVaildFactoryTypes = Set(newVaildSubfactories.keys)
        //删除的vm
        let deleteFactoryTypes = self.vaildFactoryTypes.subtracting(newVaildFactoryTypes)
        if !deleteFactoryTypes.isEmpty {
            self.subvms = self.subvms.filter { (key, vm) -> Bool in
                if deleteFactoryTypes.contains(key) {
                    vm.removeFromParent()
                    return false
                }
                return true
            }
            self.subBinders = self.subBinders.filter { (key, binder) -> Bool in
                if deleteFactoryTypes.contains(key) {
                    binder.viewModel?.removeFromParent()
                    return false
                }
                return true
            }
        }

        //留下的,进行更新
        for (_, subvm) in self.subvms where subvm.shouldUpdate(metaModel.message) {
            subvm.update(metaModel: metaModel, metaModelDependency: metaModelDependency)
        }
        for (_, subBinder) in self.subBinders {
            if let subvm = subBinder.viewModel, subvm.shouldUpdate(metaModel.message) {
                subvm.update(metaModel: metaModel, metaModelDependency: metaModelDependency)
            }
        }

        //新增vm
        let addFactoryTypes = newVaildFactoryTypes.subtracting(self.vaildFactoryTypes)
        if !addFactoryTypes.isEmpty {
            newVaildSubfactories.filter { (key, _) -> Bool in
                return addFactoryTypes.contains(key)
            }.forEach { (key, factory) in
                if factory.canCreateBinder {
                    let binder = factory.createBinder(with: metaModel, metaModelDependency: self.metaModelDependency)
                    if let vm = binder.viewModel {
                        self.addChild(vm)
                    }
                    binder.setDependency(self)
                    self.subBinders[key] = binder
                } else {
                    let vm = factory.create(with: metaModel, metaModelDependency: self.metaModelDependency)
                    self.addChild(vm)
                    vm.initRenderer(renderer)
                    self.subvms[key] = vm
                }
            }
        }
        self.vaildFactoryTypes = newVaildFactoryTypes
    }

    /// 更新content
    public func updateContent(metaModel: M, metaModelDependency: D?) {
        // 兼容新老框架
        if self.content.shouldUpdate(metaModel.message) {
            self.content.update(metaModel: metaModel, metaModelDependency: metaModelDependency)
        }
    }

    /// 替换content：旧结构
    public func updateContent(content: MessageSubViewModel<M, D, C>) {
        self.content = content
    }

    /// 替换content：新结构
    public func updateContent(contentBinder: NewComponentBinder<M, D, C>) {
        self.contentBinder = contentBinder
        if let vm = contentBinder.viewModel {
            self.content = vm
        } else {
            assertionFailure("content vm can not be nil")
        }
    }

    /// 获取所有的SubComponent
    public func getSubComponents() -> [SubType: ComponentWithContext<C>] {
        var subComponents = self.subvms.mapValues({ $0.component })
        // Dictionary.merge会触发iOS 15.4的Bug：https://t.wtturl.cn/SyA4VPj/
        // subComponents.merge(self.subBinders.mapValues({ $0.component }), uniquingKeysWith: { l, _ in l })
        let subBinderComponents = self.subBinders.mapValues({ $0.component })
        for (subType, component) in subBinderComponents {
            subComponents[subType] = component
        }
        return subComponents
    }

    public func getSubComponent(subType: SubType) -> ComponentWithContext<C>? {
        return self.subvms[subType]?.component ?? self.subBinders[subType]?.component
    }

    public func getSubViewModel(subType: SubType) -> NewMessageSubViewModel<M, D, C>? {
        return self.subvms[subType] ?? self.subBinders[subType]?.viewModel
    }

    private func resetContent(with new: NewMessageSubViewModel<M, D, C>, old: NewMessageSubViewModel<M, D, C>?) {
        old?.removeFromParent()
        self.addChild(new)
        if let newVM = new as? MessageSubViewModel<M, D, C> {
            // reset
            self.contentBinder = nil
            newVM.initRenderer(renderer)
        } else {
            self.contentBinder?.setDependency(self)
        }
    }
}

extension MessageCellViewModel: ComponentBinderDependency {
    /// 更新当前Component
    public func update(component: Component, animation: UITableView.RowAnimation) {
        renderer.update(component: component, rendererNeedUpdate: { [weak self] in
            guard let self = self else { return }
            self.context.reloadRow(by: self.metaModel.message.id, animation: animation)
        })
    }

    /// 更新当前Component
    public func updateComponentAndRoloadTable(component: Component) {
        renderer.update(component: component, rendererNeedUpdate: { [weak self] in
            self?.context.reloadTable()
        })
    }
}

extension MessageCellViewModel: PageContextWrapper where C: PageContext {
    public var pageContext: PageContext { context }
}
