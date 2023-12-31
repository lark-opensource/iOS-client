//
//  ForwardMenuPlugin.swift
//  SKCommon
//
//  Created by lijuyou on 2023/11/9.
//

import Foundation
import SKFoundation
import UniverseDesignIcon
import LarkUIKit
import SKUIKit
import LKCommonsLogging
import SKResource

class ForwardMenuPlugin: MenuPlugin {
    
    private let menuContext: WAMenuContext

    private let identifier = "forward"
    /// 插件的优先级
    private let priority: Float = 52


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
        "ForwardMenuPlugin"
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
        let title = BundleI18n.SKResource.Doc_Doc_SendToChat
        let image = UDIcon.forwardOutlined
        let badgeNumber: UInt = 0
        let imageModle = MenuItemImageModel(normalForIPhonePanel: image, normalForIPadPopover: image)
        let menuItem = MenuItemModel(title: title, imageModel: imageModle, itemIdentifier: self.identifier, badgeNumber: badgeNumber, disable: false, itemPriority: self.priority) {[weak self] _ in
            self?.foward()
        }
        updater(menuItem)
    }

    private func foward() {
        guard let hostVC = menuContext.container?.hostVC,
            let webview = menuContext.container?.hostWebView, let url = webview.url else {
            return
        }
        let title = webview.title ?? url.absoluteString
        let delay = 0.05
        LKDeviceOrientation.forceInterfaceOrientationIfNeed(to: .portrait, delay: delay) {
            HostAppBridge.shared.call(ShareToLarkService(contentType: .link(title: title, content: url.absoluteString), fromVC: hostVC, type: .feishu))
        }
    }
}
