//
//  BaseChatNavigationBarModule.swift
//  LarkOpenChat
//
//  Created by liluobin on 2022/11/23.
//

import UIKit
import Foundation
import Swinject
import LKLoadable
import LarkOpenIM

/**
 BaseChatNavigationBarModule: 负责数据的组织，下面会有默认的三个module
 1. left/right/contentModule各自负责自己区域的组织,每个module下面的subModule会各自负责具体的实现
 2. 业务放只需关心的subModule实现即可，相关使用可以参考 ChatNavigationBarRightModule
 */

public class BaseChatNavigationBarModule: Module<ChatNavgationBarContext, ChatNavigationBarMetaModel> {

    override open class var loadableKey: String {
        return "OpenChat"
    }

    /// 注册了的subModule
    open var subModuleTypes: [BaseNavigationBarRegionModule.Type] {
        return []
    }

    /// 所有实例化的直接SubModule
    var subModules: [BaseNavigationBarRegionModule] = []

    /// 所有能处理当前context的SubModule
    var canHandleSubModules: [BaseNavigationBarRegionModule] = []

    /// 实例化subModules
    public override func onInitialize() {
        self.subModules = self.subModuleTypes.filter({ $0.canInitialize(context: self.context) })
            .map({ $0.init(context: self.context) })
        self.subModules.forEach({ $0.registServices(container: self.context.container) })
    }

    public override static func onLoad(context: ChatNavgationBarContext) {
        launchLoad()
        // 对subModules依次调用onLoad
        getNormalSubModuleTypes().forEach({ $0.onLoad(context: context) })
    }

    /// 对subModules依次调用registGlobalServices
    public override class func registGlobalServices(container: Container) {
        getNormalSubModuleTypes().forEach({ $0.registGlobalServices(container: container) })
    }

    /// subModules -> canHandleSubModules
    @discardableResult
    public override func handler(model: ChatNavigationBarMetaModel) -> [Module<ChatNavgationBarContext, ChatNavigationBarMetaModel>] {
        self.canHandleSubModules = []
        self.subModules.forEach { (module) in
            // 如果能处理
            if module.canHandle(model: model) {
                // 遍历hander结果
                (module.handler(model: model) as? [BaseNavigationBarRegionModule] ?? []).forEach { (_) in
                    self.canHandleSubModules.append(module)
                }
            }
        }
        return [self]
    }

    ///MetaModel发生改变时候触发
    public override func modelDidChange(model: ChatNavigationBarMetaModel) {
        self.canHandleSubModules.forEach({ $0.modelDidChange(model: model) })
    }

    /// 所在的VC 生命周期 viewWillAppear
    public func viewWillAppear() {
        for module in self.canHandleSubModules {
            module.viewWillAppear()
        }
    }

    /// 所在的VC 生命周期 viewDidAppear
    public func viewDidAppear() {
        for module in self.canHandleSubModules {
            module.viewDidAppear()
        }
    }

    public func viewWillRealRenderSubView() {
        for module in self.canHandleSubModules {
            module.viewWillRealRenderSubView()
        }
    }

    public func viewFinishedMessageRender() {
        for module in self.canHandleSubModules {
            module.viewFinishedMessageRender()
        }
    }

    /// 所在的VC 生命周期 viewWillTransition
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

    /// 创建右侧按钮
    open func createRigthItems(metaModel: ChatNavigationBarMetaModel) {
        let module = self.subModules.first { module in
            return (module as? NavigationBarBaseRightModule) != nil
        }
        (module as? NavigationBarBaseRightModule)?.createItems(metaModel: metaModel)
    }

    /// 创建左侧按钮
    open func createLeftItems(metaModel: ChatNavigationBarMetaModel) {
        let module = self.subModules.first { module in
            return (module as? NavigationBarBaseLeftModule) != nil
        }
        (module as? NavigationBarBaseLeftModule)?.createItems(metaModel: metaModel)
    }

    /// 创建内容区域
    open func createContentView(metaModel: ChatNavigationBarMetaModel) {
        let module = self.subModules.first { module in
            return (module as? NavigationBarBaseContentModule) != nil
        }
        (module as? NavigationBarBaseContentModule)?.createContentView(metaModel: metaModel)
    }

    /// 获取可用的左侧按钮
    open func leftItems() -> [ChatNavigationExtendItem] {
        let module = self.subModules.first { module in
            return (module as? NavigationBarBaseLeftModule) != nil
        }
        return (module as? NavigationBarBaseLeftModule)?.getItems() ?? []
    }

    /// 获取可用的右侧按钮
    open func rightItems() -> [ChatNavigationExtendItem] {
        let module = self.subModules.first { module in
            return (module as? NavigationBarBaseRightModule) != nil
        }
        return (module as? NavigationBarBaseRightModule)?.getItems() ?? []
    }

    /// 获取可用的内容区域
    open func contentView() -> UIView? {
        let module = self.subModules.first { module in
            return (module as? NavigationBarBaseContentModule) != nil
        }
        return (module as? NavigationBarBaseContentModule)?.contentView
    }

    /// 注册左侧的SubModule
    public static func registerLeftSubModule(_ subtype: BaseNavigationBarItemSubModule.Type) {
        self.getNormalSubModuleTypes().forEach { type in
            if type.name == NavigationBarBaseLeftModule.name {
                type.register(subtype)
            }
        }
    }

    /// 注册右侧subModule
    public static func registerRightSubModule(_ subtype: BaseNavigationBarItemSubModule.Type) {
        self.getNormalSubModuleTypes().forEach { type in
            if type.name == NavigationBarBaseRightModule.name {
                type.register(subtype)
            }
        }
    }

    /// 注册contentView
    public static func registerContentSubModule(_ subtype: BaseNavigationBarContentSubModule.Type) {
        self.getNormalSubModuleTypes().forEach { type in
            if type.name == NavigationBarBaseContentModule.name {
                type.register(subtype)
            }
        }
    }

    class func getNormalSubModuleTypes() -> [BaseNavigationBarRegionModule.Type] {
        return []
    }
}
