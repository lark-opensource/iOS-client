//
//  DocsWebViewEditMenuManager.swift
//  SKUIKit
//
//  Created by liujinwei on 2022/11/15.
//  


import Foundation
import LarkWebViewContainer
import WebKit
import SKFoundation

@available(iOS 16.0, *)
public final class DocsWebViewEditMenuManager: NSObject {
    
    public static let editMenuWillShowNotification = Notification.Name(rawValue: "docs.bytedance.notification.name.editMenuWillShow")
    
    public static let editMenuWillHideNotification = Notification.Name(rawValue: "docs.bytedance.notification.name.editMenuWillHide")
    
    public static var shared = DocsWebViewEditMenuManager()
    
    public var editMenuItems = [EditMenuCommand]()
    
    public private(set) var isMenuVisible: Bool = false
    
    private var menuIndentifier: String = ""
    
    public func getMenuIdentifier() -> String {
        let identifier = "customMenu_" + UUID().uuidString
        menuIndentifier = identifier
        return identifier
    }
    
}

@available(iOS 16.0, *)
extension DocsWebViewEditMenuManager: UIEditMenuInteractionDelegate {

    public func editMenuInteraction(_ interaction: UIEditMenuInteraction, menuFor configuration: UIEditMenuConfiguration, suggestedActions: [UIMenuElement]) -> UIMenu? {
        for element in suggestedActions {
            if let menu = element as? UIMenu, menu.identifier.rawValue == self.menuIndentifier {
                //已在buildMenu添加过自定义菜单项就不再重复添加
                return UIMenu(children: suggestedActions)
            }
        }
        let items = self.editMenuItems
        var menuElements: [UIMenuElement] = [UIMenuElement]()
        items.forEach { (item) in
            let command = UICommand(title: item.title, action: item.action)
            menuElements.append(command)
        }
        let customMenu = UIMenu(options: .displayInline, preferredElementSize: .medium, children: menuElements)
        var actions: [UIMenuElement] = [customMenu]
        actions.append(contentsOf: suggestedActions)
        return UIMenu(children: actions)
    }
    
    public func editMenuInteraction(_ interaction: UIEditMenuInteraction, willPresentMenuFor configuration: UIEditMenuConfiguration, animator: UIEditMenuInteractionAnimating) {
        NotificationCenter.default.post(name: DocsWebViewEditMenuManager.editMenuWillShowNotification, object: nil)
        self.isMenuVisible = true
    }
    
    public func editMenuInteraction(_ interaction: UIEditMenuInteraction, willDismissMenuFor configuration: UIEditMenuConfiguration, animator: UIEditMenuInteractionAnimating) {
        NotificationCenter.default.post(name: DocsWebViewEditMenuManager.editMenuWillHideNotification, object: nil)
        self.isMenuVisible = false
    }
}
