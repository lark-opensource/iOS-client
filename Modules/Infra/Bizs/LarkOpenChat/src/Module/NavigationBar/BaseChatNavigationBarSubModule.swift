//
//  BaseChatNavigationBarSubModule.swift
//  LarkOpenChat
//
//  Created by liluobin on 2022/11/23.
//

import UIKit
import Foundation
import Swinject
import LarkOpenIM

open class BaseNavigationBarRegionModule: Module<ChatNavgationBarContext, ChatNavigationBarMetaModel> {

    var subModuleTypes: [BaseNavigationBarSubModule.Type] {
        return Self.getRegisterSubModuleTypes()
    }
    /// 所有实例化的直接SubModule
    var subModules: [BaseNavigationBarSubModule] = []
    /// 所有能处理当前context的SubModule
    var canHandleSubModules: [BaseNavigationBarSubModule] = []

    /// 实例化subModules
    public override func onInitialize() {
        self.subModules = subModuleTypes.filter({ $0.canInitialize(context: self.context) })
            .map({ $0.init(context: self.context) })
        self.subModules.forEach({ $0.registServices(container: self.context.container) })
    }

    open override func canHandle(model: ChatNavigationBarMetaModel) -> Bool {
        return true
    }
    /// subModules -> canHandleSubModules
    @discardableResult
    public override func handler(model: ChatNavigationBarMetaModel) -> [Module<ChatNavgationBarContext, ChatNavigationBarMetaModel>] {
        self.canHandleSubModules = []
        self.subModules.forEach { (module) in
            // 如果能处理
            if module.canHandle(model: model) {
                // 遍历hander结果
                (module.handler(model: model) as? [BaseNavigationBarSubModule] ?? []).forEach { (_) in
                    self.canHandleSubModules.append(module)
                }
            }
        }
        return [self]
    }

    public override func modelDidChange(model: ChatNavigationBarMetaModel) {
        self.canHandleSubModules.forEach({ $0.modelDidChange(model: model) })
    }

    public func viewWillAppear() {
        for module in self.canHandleSubModules {
            module.viewWillAppear()
        }
    }

    public func viewDidAppear() {
        for module in self.canHandleSubModules {
            module.viewDidAppear()
        }
    }

    public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        for module in self.canHandleSubModules {
            module.viewWillTransition(to: size, with: coordinator)
        }
    }

    public func splitDisplayModeChange() {
        for module in self.canHandleSubModules {
            module.splitDisplayModeChange()
        }
    }

    public func splitSplitModeChange() {
        for module in self.canHandleSubModules {
            module.splitSplitModeChange()
        }
    }

    public func barStyleDidChange() {
        for module in self.canHandleSubModules {
            module.barStyleDidChange()
        }
    }

    /// 对于有中间态的页面，页面开始真正进入渲染
    public func viewWillRealRenderSubView() {
        for module in self.canHandleSubModules {
            module.viewWillRealRenderSubView()
        }
    }

    /// 页面完成对数据的渲染
    public func viewFinishedMessageRender() {
        for module in self.canHandleSubModules {
            module.viewFinishedMessageRender()
        }
    }

    public override static func onLoad(context: ChatNavgationBarContext) {
        launchLoad()
        // 对subModules依次调用onLoad
        getRegisterSubModuleTypes().forEach({ $0.onLoad(context: context) })
    }

    /// 注册subModule
    public static func register(_ type: BaseNavigationBarSubModule.Type) {
        #if DEBUG
        if getRegisterSubModuleTypes().contains(where: { $0 == type }) {
            assertionFailure("ChatNavigationBarSubModule \(type) has already been registered")
        }
        #endif
        addRegisterSubModuleType(type)
    }

    open override class func registGlobalServices(container: Container) {
        getRegisterSubModuleTypes().forEach({ $0.registGlobalServices(container: container) })
    }

    class func getRegisterSubModuleTypes() -> [BaseNavigationBarSubModule.Type] {
        return []
    }

    class func addRegisterSubModuleType(_ type: BaseNavigationBarSubModule.Type) {
        assertionFailure("need override")
    }
}

public class NavigationBarBaseRightModule: NavigationBarBaseItemsRegionModule {
    public override class var name: String { return "right" }
}

public class NavigationBarBaseLeftModule: NavigationBarBaseItemsRegionModule {
    public override class var name: String { return "left" }
}

public class NavigationBarBaseItemsRegionModule: BaseNavigationBarRegionModule {
    public var itemsOrder: [ChatNavigationExtendItemType] {
        return []
    }
    /// 创建右侧的按钮
    public func createItems(metaModel: ChatNavigationBarMetaModel) {
        self.canHandleSubModules.forEach { subModule in
            if let subModule = subModule as? BaseNavigationBarItemSubModule {
                subModule.createItems(metaModel: metaModel)
            }
        }
    }

    /// 获取右侧创建的按钮
    public func getItems() -> [ChatNavigationExtendItem] {
        let modules = self.canHandleSubModules
        var items: [ChatNavigationExtendItem] = []
        for module in modules  {
            if let module = module as? BaseNavigationBarItemSubModule {
                items.append(contentsOf: module.items)
            }
        }

        var info: [ChatNavigationExtendItemType: ChatNavigationExtendItem] = [:]
        items.forEach { item in
            info[item.type] = item
        }
        #if DEBUG
        /// Debug模式下 如果出现了itemsOrder没有指定的type给出异常
        info.keys.forEach { type in
            if !self.itemsOrder.contains(type) {
                assertionFailure("need to config type for itemsOrder in left or right module")
            }
        }
        #endif
        return self.itemsOrder.compactMap { type in
            return info[type]
        }
    }

    public override class func canInitialize(context: ChatNavgationBarContext) -> Bool {
        return true
    }
}

public class NavigationBarBaseContentModule: BaseNavigationBarRegionModule {

    public override class var name: String { return "content" }

    public override class func canInitialize(context: ChatNavgationBarContext) -> Bool {
        return true
    }

    /// 获取当前可用的contentView
    open var contentView: UIView? {
        return getContentView()
    }

    /// 创建可用contentView
    open func createContentView(metaModel: ChatNavigationBarMetaModel) {
        self.canHandleSubModules.forEach { module in
            if let module = module as? BaseNavigationBarContentSubModule {
                module.createContentView(metaModel: metaModel)
            }
        }
    }

    func getContentView() -> UIView? {
        let contentViews = self.canHandleSubModules.compactMap { module in
            if let module = module as? BaseNavigationBarContentSubModule {
                return module.contentView
            }
            return nil
        }
        if contentViews.count > 1 {
            assertionFailure("error data content only can be one or empty")
        }
        return contentViews.first
    }
}
/// 子items base 通用方法
open class BaseNavigationBarSubModule: Module<ChatNavgationBarContext, ChatNavigationBarMetaModel> {

    open func viewWillAppear() {
    }

    open func viewDidAppear() {
    }

    open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    }

    open func viewWillRealRenderSubView() {
    }

    open func viewFinishedMessageRender() {
    }

    open func splitDisplayModeChange() {
    }

    open func splitSplitModeChange() {
    }

    open func barStyleDidChange() {
    }
}
/// 子item
open class BaseNavigationBarItemSubModule: BaseNavigationBarSubModule {

    open override class var name: String { return "BaseNavigationBarItemSubModule" }
    /// 创建Items
    open func createItems(metaModel: ChatNavigationBarMetaModel) {
        assertionFailure("must override")
    }

    /// 获取items
    open var items: [ChatNavigationExtendItem] {
        return []
    }

    open override func canHandle(model: ChatNavigationBarMetaModel) -> Bool {
        return true
    }

    open override class func canInitialize(context: ChatNavgationBarContext) -> Bool {
        return true
    }
}

open class BaseNavigationBarContentSubModule: BaseNavigationBarSubModule {

    open override class var name: String { return "BaseNavigationBarContentSubModule" }

    /// 获取当前的contentView
    open var contentView: UIView? {
        return nil
    }

    /// 创建当前的contentView
    open func createContentView(metaModel: ChatNavigationBarMetaModel) {
        assertionFailure("must override")
    }

    open override func canHandle(model: ChatNavigationBarMetaModel) -> Bool {
        return true
    }

    open override class func canInitialize(context: ChatNavgationBarContext) -> Bool {
        return true
    }
}
