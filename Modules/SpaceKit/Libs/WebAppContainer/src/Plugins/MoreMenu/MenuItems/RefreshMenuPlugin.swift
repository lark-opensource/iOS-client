//
//  RefreshMenuPlugin.swift
//  SKCommon
//
//  Created by lijuyou on 2023/11/8.
//

import SKFoundation
import UniverseDesignIcon
import LarkUIKit
import LKCommonsLogging
import SKResource

class RefreshMenuPlugin: MenuPlugin {
    
    private let menuContext: WAMenuContext

    private let identifier = "refresh"
    /// 插件的优先级
    private let priority: Float = 50


    required init?(menuContext: MenuContext, pluginContext: MenuPluginContext) {
        guard let waMenuContext = menuContext as? WAMenuContext else {
            return nil
        }
        self.menuContext = waMenuContext
    }

    func pluginDidLoad(handler: MenuPluginOperationHandler) {
        fetchMenuItemModel{
            item in
            handler.updateItemModels(for: [item])
        }
    }

    static var pluginID: String {
        "WARefreshMenuPlugin"
    }

    static var enableMenuContexts: [MenuContext.Type] {
        [WAMenuContext.self]
    }

    /// 获取菜单数据模型
    /// - Parameter updater: 更新菜单选项的回调
    private func fetchMenuItemModel(updater: @escaping (MenuItemModelProtocol) -> ()) {
        guard menuContext.container?.hostWebView?.url != nil else {
            return
        }
        let title = BundleI18n.SKResource.LarkCCM_Docs_ErrorRefresh_Button_Mob
        let image = UDIcon.refreshOutlined
        let badgeNumber: UInt = 0
        let imageModle = MenuItemImageModel(normalForIPhonePanel: image, normalForIPadPopover: image)
        let menuItem = MenuItemModel(title: title, imageModel: imageModle, itemIdentifier: self.identifier, badgeNumber: badgeNumber, disable: false, itemPriority: self.priority) {[weak self] _ in
            self?.refresh()
        }
        updater(menuItem)
    }

    private func refresh() {
        guard let hostVC = menuContext.container?.hostVC else {
            return
        }
        DocsLogger.info("refresh...")
        menuContext.container?.hostVC?.refreshPage()
    }
}
