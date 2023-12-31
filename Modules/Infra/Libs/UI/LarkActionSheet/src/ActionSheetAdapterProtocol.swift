//
//  ActionSheetAdapterProtocol.swift
//  LarkUIKit
//
//  Created by Jiayun Huang on 2019/9/12.
//

import UIKit
import Foundation
import LarkActionSheet

protocol ActionSheetAdapterProtocol {
    func addActionItem(
        title: String,
        textColor: UIColor?,
        icon: UIImage?,
        entirelyCenter: Bool,
        action: @escaping (() -> Void)
    ) -> NSObject?

    func addCancelActionItem(title: String, textColor: UIColor?, icon: UIImage?, entirelyCenter: Bool, action: (() -> Void)?) -> NSObject?

    func addRedCancelActionItem(title: String, icon: UIImage?, cancelAction: (() -> Void)?) -> NSObject?
}

extension ActionSheet: ActionSheetAdapterProtocol {
    func addActionItem(title: String,
                 textColor: UIColor? = nil,
                 icon: UIImage? = nil,
                 entirelyCenter: Bool = false,
                 action: @escaping (() -> Void)) -> NSObject? {
        return addItem(title: title, textColor: textColor, icon: icon, entirelyCenter: entirelyCenter, action: action)
    }

    func addCancelActionItem(title: String,
                             textColor: UIColor? = nil,
                             icon: UIImage? = nil,
                             entirelyCenter: Bool = false,
                             action: (() -> Void)? = nil) -> NSObject? {
        return addCancelItem(title: title, textColor: textColor, icon: icon, entirelyCenter: entirelyCenter, cancelAction: action)
    }

    func addRedCancelActionItem(title: String,
                                icon: UIImage? = nil,
                                cancelAction: (() -> Void)? = nil) -> NSObject? {
        return addRedCancelItem(title: title, icon: icon, cancelAction: cancelAction)
    }
}

extension UIAlertController {
    enum UIStyle {
        static let titleColor: UIColor = UIColor.ud.textPlaceholder
        static let actionTextColor: UIColor = UIColor.ud.textTitle
        static let actionEmphasisTextColor: UIColor = UIColor.ud.functionDangerContentDefault
        static let titleFontSize: CGFloat = 13
    }
}

extension UIAlertController: ActionSheetAdapterProtocol {
    func addActionItem(title: String,
                       textColor: UIColor? = nil,
                       icon: UIImage? = nil,
                       entirelyCenter: Bool = false,
                       action: @escaping (() -> Void)) -> NSObject? {
        let alertAction = UIAlertAction(title: title, style: .default) { (_) in
            action()
        }
        let actionTextColor = textColor ?? UIStyle.actionTextColor
        alertAction.setValue(actionTextColor, forKey: "titleTextColor")
        if icon != nil {
            alertAction.setValue(icon?.withRenderingMode(.alwaysOriginal), forKey: "image")
        }
        addAction(alertAction)
        return alertAction
    }

    func addCancelActionItem(title: String,
                             textColor: UIColor? = nil,
                             icon: UIImage? = nil,
                             entirelyCenter: Bool = false,
                             action: (() -> Void)? = nil) -> NSObject? {
        let alertAction = UIAlertAction(title: title, style: .cancel) { (_) in
            action?()
        }
        let actionTextColor = textColor ?? UIStyle.actionTextColor
        alertAction.setValue(actionTextColor, forKey: "titleTextColor")
        if icon != nil {
            alertAction.setValue(icon?.withRenderingMode(.alwaysOriginal), forKey: "image")
        }
        addAction(alertAction)
        return alertAction
    }

    func addRedCancelActionItem(title: String,
                                icon: UIImage? = nil,
                                cancelAction: (() -> Void)? = nil) -> NSObject? {
        return addCancelActionItem(title: title, textColor: UIStyle.actionEmphasisTextColor, icon: icon, action: cancelAction)
    }
}
