//
//  CopyLinkMenuPlugin.swift
//  SKCommon
//
//  Created by lijuyou on 2023/11/9.
//

import Foundation
import SKFoundation
import UniverseDesignIcon
import LarkUIKit
import LKCommonsLogging
import LarkEMM
import LarkSensitivityControl
import UniverseDesignToast
import SKResource

class CopyLinkMenuPlugin: MenuPlugin {
    
    private let menuContext: WAMenuContext

    private let identifier = "copylink"
    /// 插件的优先级
    private let priority: Float = 51


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
        "CopyLinkMenuPlugin"
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
        let title = BundleI18n.SKResource.Doc_Facade_CopyLink
        let image = UDIcon.copyOutlined
        let badgeNumber: UInt = 0
        let imageModle = MenuItemImageModel(normalForIPhonePanel: image, normalForIPadPopover: image)
        let menuItem = MenuItemModel(title: title, imageModel: imageModle, itemIdentifier: self.identifier, badgeNumber: badgeNumber, disable: false, itemPriority: self.priority) {[weak self] _ in
            self?.copyLink()
        }
        updater(menuItem)
    }

    private func copyLink() {
        guard let hostVC = menuContext.container?.hostVC,
              let url = menuContext.container?.hostWebView?.url else {
            return
        }
        
        let config = PasteboardConfig(token: Token("LARK-PSDA-docs_share_link_do_copy"),
                                      pointId: nil,
                                      shouldImmunity: false)
        do {
            let pasteboard = try SCPasteboard.generalUnsafe(config)
            pasteboard.string = url.absoluteString
            UDToast.showSuccess(with: BundleI18n.SKResource.Doc_Facade_CopyLinkSuccessfully, on: hostVC.view).observeKeyboard = false
            DocsLogger.info("copyLink")
        } catch {
            DocsLogger.error("copyLink get Pasteboard error, \(error)")
        }
    }
}
