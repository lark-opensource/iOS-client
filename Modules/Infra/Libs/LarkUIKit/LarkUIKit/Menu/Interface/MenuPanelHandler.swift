//
//  MenuPanelHandler.swift
//  LarkUIKit
//
//  Created by 刘洋 on 2021/2/2.
//

import Foundation
import UIKit
import LarkBadge
import LKCommonsLogging
import LarkFeatureGating

private let logger = Logger.log(MenuPanelHandler.self, category: "LarkUIKit")
/// 菜单面板的操作句柄
final class MenuPanelHandler {

    /// 从哪个VC中弹出
    private weak var container: UIViewController?
    /// 弹出的菜单面板控制器
    private weak var panel: MenuPanelViewController?

    public weak var delegate: MenuPanelDelegate?
    public var identifier: String?

    /// 是否是iPad
    private let isIPad: Bool

    /// 菜单的插件上下文和插件以及插件的操作句柄，以插件ID进行索引
    private var pluginInformation: [String: (plugin: MenuPlugin, handler: MenuPluginOperationHandler)] = [:]

    /// 菜单是否弹出
    public var display = false

    /// 菜单的presentedViewController
    public var presentedViewController: UIViewController? {
        self.panel?.presentedViewController
    }

    /// 需要隐藏的menuItem的pluginID数组
    private var menuItemsIdentifiersToBeRemoved: [String] = []

    /// 当前的选项数据模型
    private var currentItemModels: [MenuItemModelProtocol] = []

    /// 当前菜单的附加视图，当菜单没有显示时临时持有，显示后这个变量一直处于nil
    private var cachedAdditionView: MenuAdditionView?

    init(in container: UIViewController) {
        self.container = container
        self.isIPad = Display.pad
    }

    /// 将选项数据模型按照优先级排序
    /// - Parameter models: 待排序的选项数据模型
    /// - Returns: 已经排好序的选项数据模型
    private func sortItemModelsWithPriority(for models: [MenuItemModelProtocol]) -> [MenuItemModelProtocol] {
        return models.sorted(by: {
            $0.itemPriority > $1.itemPriority
        })
    }

    /// 让action在主队列执行，如果当前为主队列则立即执行，否则会触发assert，直接返回，不会执行action
    /// - Parameter action: 需要在主队列执行的action
    private func executeInMainThreadIfNeeded(action: () -> Void) {
        guard Thread.isMainThread else {
            let errorMsg = "handler action must be executed in main thread, but now you aren't in \(Thread.current.description)"
            assertionFailure(errorMsg)
            logger.error(errorMsg)
            return
        }
        action()
    }

}

extension MenuPanelHandler {

    /// 通知插件提供者面板将显示
    private func notifyPluginProviderWhenMenuWillShow() {
        for information in self.pluginInformation {
            information.value.plugin.menuWillShow?(handler: information.value.handler)
        }
    }

    /// 通知插件提供者面板已经显示
    private func notifyPluginProviderWhenMenuDidShow() {
        for information in self.pluginInformation {
            information.value.plugin.menuDidShow?(handler: information.value.handler)
        }
    }

    /// 通知插件提供者面板将消失
    private func notifyPluginProviderWhenWillHide() {
        for information in self.pluginInformation {
            information.value.plugin.menuWillHide?(handler: information.value.handler)
        }
    }

    /// 通知插件提供者面板已经消失
    private func notifyPluginProviderWhenMenuDidHide() {
        for information in self.pluginInformation {
            information.value.plugin.menuDidHide?(handler: information.value.handler)
        }
    }

    /// 通知插件提供者面板已经销毁
    private func notifyPluginProviderWhenMenuDealloc() {
        for information in self.pluginInformation {
            information.value.plugin.menuDealloc?()
        }
    }
}

extension MenuPanelHandler: MenuPanelDelegate {

    func menuPanelWillShow() {
        self.delegate?.menuPanelWillShow?()
        notifyPluginProviderWhenMenuWillShow()
    }

    func menuPanelDidShow() {
        notifyPluginProviderWhenMenuDidShow()
        self.delegate?.menuPanelDidShow?()
    }

    func menuPanelWillHide() {
        self.delegate?.menuPanelWillHide?()
        notifyPluginProviderWhenWillHide()
    }

    func menuPanelDidHide() {
        self.currentItemModels = []
        /// 因为隐藏操作有可能来自选项的点击或者点击空白区域消失或者Popover空白区域。
        /// 如果这样子就不会调用handler的hide，但是可以在这个代理方法中去改变自己的状态
        display = false
        notifyPluginProviderWhenMenuDidHide()
        self.delegate?.menuPanelDidHide?()
    }

    func menuPanelItemModelsDidChanged(models: [MenuItemModelProtocol]) {
        self.delegate?.menuPanelItemModelsDidChanged?(models: models)
    }

    func menuPanelItemDidClick(identifier: String?, model: MenuItemModelProtocol?) {
        let model = model ?? currentItemModels.first { item in
            item.itemIdentifier == identifier
        }
        delegate?.menuPanelItemDidClick?(identifier: identifier, model: model)
    }

    func menuPanelHeaderDidChanged(view: MenuAdditionView?) {
        delegate?.menuPanelHeaderDidChanged?(view: view)
    }

    func menuPanelFooterDidChanged(view: MenuAdditionView?) {
        delegate?.menuPanelFooterDidChanged?(view: view)
    }
}

extension MenuPanelHandler: MenuPanelOperationHandler {

    func updateMenuItemsToBeRemoved(with disabled_menus: [String]) {
        self.menuItemsIdentifiersToBeRemoved = disabled_menus
    }

    func hide(animation: Bool, complete: (() -> Void)? = nil) {
        executeInMainThreadIfNeeded {
            guard let panel = self.panel, display else {
                return
            }
            display = false
            panel.hide(animation: animation, complete: complete)
        }
    }

    func show(from sourceView: MenuPanelSourceViewModel, parentPath: MenuBadgePath, animation: Bool = true, complete: (() -> Void)? = nil) {
        executeInMainThreadIfNeeded {
            guard let container = self.container, !display else {
                return
            }
            var handler: MenuPanelHandler?
            switch sourceView.type {
            case .showMorePanelAPI:
                handler = self
            default:
                break
            }
            let panel = MenuPanelViewController(parentPath: parentPath.path, itemModels: self.currentItemModels, additionView: cachedAdditionView, handler: handler)
            self.cachedAdditionView = nil // 将临时持有的附加视图变量置为nil，因此菜单面板已经生成
            self.panel = panel
            self.panel?.delegate = self

            display = true
            panel.show(from: container, in: sourceView, animation: animation, complete: {
                complete?()
            })
        }
    }

    func updateItemModels(for models: [MenuItemModelProtocol]) {
        executeInMainThreadIfNeeded {
            var currentItemModels = self.currentItemModels
            let remainModels = currentItemModels.filter({
                oldModel in
                !models.contains(where: {
                    newModel in
                    oldModel.itemIdentifier == newModel.itemIdentifier
                })
            })
            currentItemModels = remainModels + models
            self.resetItemModels(with: currentItemModels)
        }
    }

    func updatePanelHeader(for view: MenuAdditionView?) {
        executeInMainThreadIfNeeded {
            // 如果菜单面板已经被初始化，那么就直接将附加视图传入面板
            if let panel = self.panel {
                panel.updatePanelHeader(for: view)
            } else {
                // 如果菜单面板没有初始化，则使用cachedAdditionView变量临时持有
                self.cachedAdditionView = view
            }
            self.menuPanelHeaderDidChanged(view: view)
        }
    }

    func updatePanelFooter(for view: MenuAdditionView?) {
        executeInMainThreadIfNeeded {
            // 如果菜单面板已经被初始化，那么就直接将附加视图传入面板
            if let panel = self.panel {
                panel.updatePanelFooter(for: view)
            } else {
                // 如果菜单面板没有初始化，则使用cachedAdditionView变量临时持有
                self.cachedAdditionView = view
            }
            self.menuPanelFooterDidChanged(view: view)
        }
    }

    func resetItemModels(with models: [MenuItemModelProtocol]) {
        executeInMainThreadIfNeeded {
            let remainModels = models.filter({
                oldModel in
                !self.menuItemsIdentifiersToBeRemoved.contains(where: {
                    removedItemIdentifier in
                    oldModel.itemIdentifier == removedItemIdentifier
                })
            })
            self.currentItemModels = sortItemModelsWithPriority(for: remainModels)
            self.menuPanelItemModelsDidChanged(models: self.currentItemModels)
            if let panel = self.panel {
                panel.updateItemModels(for: self.currentItemModels)
            }
        }
    }

    func removeItemModels(for modelIDs: [String]) {
        executeInMainThreadIfNeeded {
            let currentItemModels = self.currentItemModels
            let remainModels = currentItemModels.filter({
                oldModel in
                !modelIDs.contains(where: {
                    modelID in
                    oldModel.itemIdentifier == modelID
                })
            })
            self.resetItemModels(with: remainModels)
        }
    }

    func makePlugins(with menuContext: MenuContext) {
        executeInMainThreadIfNeeded {
            // 修复makePlugins重置菜单内所有插件，但在获取其他菜单数据模型时仍然会带着上次旧数据currentItemModels来显示面板, 导致第一次面板无法隐藏某些入口
            if !LarkFeatureGating.shared.getFeatureBoolValue(for: "openplatform.larkuikit.menu_panel_clean_model.disable") { //Global 纯UI相关，成本比较大，先不改
            self.currentItemModels = []
            }
            let domainPlugins = MenuPluginPool.makePlugins(for: menuContext)

            var updateInformation: [String: (plugin: MenuPlugin, handler: MenuPluginOperationHandler)] = [:]
            for plugin in domainPlugins {
                let key = type(of: plugin).pluginID
                let handler = MenuPluginHandler()
                handler.operationDelegate = self
                updateInformation[key] = (plugin, handler)
            }
            updateInformation.forEach({
                $0.value.plugin.pluginDidLoad?(handler: $0.value.handler)
            })

            self.pluginInformation = updateInformation
        }
    }

    func remakePlugins(with menuContext: MenuContext) {
        makePlugins(with: menuContext)
    }

    func disableCurrentAllItemModels(with: Bool) {
        executeInMainThreadIfNeeded {
            var result: [MenuItemModelProtocol] = []
            for item in currentItemModels {
                var newItem = item
                item.disable = with
                result.append(newItem)
            }
            self.resetItemModels(with: result)
        }
    }
}
