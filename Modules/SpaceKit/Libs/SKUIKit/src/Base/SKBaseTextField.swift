//
//  SKBaseTextField.swift
//  SKCommon
//
//  Created by huangzhikai on 2022/9/13.
//

import Foundation
import UIKit
import LarkEMM
import SKFoundation

open class SKBaseTextField: UITextField {
    open var hideSystemMenu: Bool = true
    // block 存在时，会阻止复制、剪切操作，并调用 block
    open var copyForbiddenBlock: (() -> Void)?

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
        if let copyForbiddenBlock {
            copyForbiddenBlock()
            return
        }
        self.pointId = self.getEncryptId()
        super.cut(sender)
    }
    
    open override func copy(_ sender: Any?) {
        if let copyForbiddenBlock {
            copyForbiddenBlock()
            return
        }
        self.pointId = self.getEncryptId()
        super.copy(sender)
    }
    
}
