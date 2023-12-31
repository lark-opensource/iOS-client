//
//  DKTextView.swift
//  SKDrive
//
//  Created by ByteDance on 2022/9/20.
//

import SKUIKit
import LarkEMM
import SKFoundation

class DKTextView: UITextView {

    var hideSystemMenu: Bool = true
    weak var systemMenuInterceptor: SKSystemMenuInterceptorProtocol?

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if let remainItems = SCPasteboard.general(SCPasteboard.defaultConfig()).canRemainActionsDescrption(ignorePreCheck: true), remainItems.contains(action.description) {
            return systemMenuInterceptor?.canPerformSystemMenuAction(action, withSender: sender)
                ?? super.canPerformAction(action, withSender: sender)
        }
        if hideSystemMenu && UserScopeNoChangeFG.WWJ.ccmSecurityMenuProtectEnable { return false }
        return systemMenuInterceptor?.canPerformSystemMenuAction(action, withSender: sender)
            ?? super.canPerformAction(action, withSender: sender)
    }

    override func copy(_ sender: Any?) {
        guard let interceptor = systemMenuInterceptor else {
            super.copy(sender)
            return
        }
        if !interceptor.interceptCopy(sender) {
            super.copy(sender)
        }
    }
}
