//
//  DKWebView.swift
//  SKDrive
//
//  Created by Weston Wu on 2023/9/18.
//

import UIKit
import LarkEMM
import WebKit
import SKFoundation

// TODO: 后续考虑推动 Drive 也接入 LarkWebView
class DKWebView: WKWebView {

    var hideSystemMenu = true

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if let remainItems = SCPasteboard.general(SCPasteboard.defaultConfig()).canRemainActionsDescrption(ignorePreCheck: true),
           remainItems.contains(action.description) {
            return super.canPerformAction(action, withSender: sender)
        }
        if hideSystemMenu && UserScopeNoChangeFG.WWJ.ccmSecurityMenuProtectEnable {
            return false
        }
        return super.canPerformAction(action, withSender: sender)
    }

    @available(iOS 13.0, *)
    override func buildMenu(with builder: UIMenuBuilder) {
        super.buildMenu(with: builder)
        guard hideSystemMenu && UserScopeNoChangeFG.WWJ.ccmSecurityMenuProtectEnable else { return }
        guard let hiddenItems = SCPasteboard.general(SCPasteboard.defaultConfig()).hiddenItemsDescrption(ignorePreCheck: true) else {
            return
        }
        hiddenItems.forEach { identifier in
            builder.remove(menu: identifier)
        }
    }
}
