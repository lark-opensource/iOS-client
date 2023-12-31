//
//  SKBaseTextView.swift
//  SKCommon
//
//  Created by huangzhikai on 2022/9/13.
//

import Foundation
import UIKit
import LarkEMM
import SKFoundation

open class SKBaseTextView: UITextView {

    open var hideSystemMenu: Bool = true
    
    open override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        self.pointId = self.getEncryptId()
        if let remainItems = SCPasteboard.general(SCPasteboard.defaultConfig()).canRemainActionsDescrption(ignorePreCheck: true), remainItems.contains(action.description) {
            return super.canPerformAction(action, withSender: sender)
        } else if hideSystemMenu && UserScopeNoChangeFG.WWJ.ccmSecurityMenuProtectEnable {
            return false
        }
        return super.canPerformAction(action, withSender: sender)
    }
    
    @available(iOS 13.0, *)
    open override func buildMenu(with builder: UIMenuBuilder) {
        super.buildMenu(with: builder)
        guard hideSystemMenu && UserScopeNoChangeFG.WWJ.ccmSecurityMenuProtectEnable else { return }
        guard let hiddenItems = SCPasteboard.general(SCPasteboard.defaultConfig()).hiddenItemsDescrption(ignorePreCheck: true) else {
            return
        }
        hiddenItems.forEach { identifier in
            builder.remove(menu: identifier)
        }
    }
    
    open override func paste(_ sender: Any?) {
        self.pointId = self.getEncryptId()
        super.paste(sender)
    }
    
    open override func cut(_ sender: Any?) {
        self.pointId = self.getEncryptId()
        super.cut(sender)
    }
    
    open override func copy(_ sender: Any?) {
        self.pointId = self.getEncryptId()
        super.copy(sender)
    }
}
