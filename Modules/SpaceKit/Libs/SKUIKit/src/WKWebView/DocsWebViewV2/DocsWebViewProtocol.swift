//
//  DocsWebViewProtocol.swift
//  SKUIKit
//
//  Created by lijuyou on 2020/10/9.
//  


import Foundation
import WebKit


@objc public protocol SKInputAccessory {
    var realInputAccessoryView: UIView? { get set }
    var realInputView: UIView? { get set }
}

@objc public protocol SKProtocol {
    var skEditorViewInputAccessory: SKInputAccessory { get }
}

public struct EditMenuCommand {
    public let uid: String
    public let title: String
    public let action: Selector
    public init(uid: String, title: String, action: Selector) {
        self.uid = uid
        self.title = title
        self.action = action
    }
}

/// DocsWebViewProtocol的ContextMenu
public protocol SKWebViewContextMenuProtocol {
    var items: [UIMenuItem] { get set }
    var editMenuItems: [EditMenuCommand] { get set }
}


/// LKW: 抽象现有WebView功能, 实现DocsWebView和DocsWebViewV2的动态切换
public protocol DocsWebViewProtocol: WKWebView, DocsEditorViewProtocol {

    var contentView: UIView? { get }
    
    ///webview.contentView上系统默认的UIEditMenuInteraction
    @available(iOS 16.0, *)
    var contentEditMenuInteraction: UIEditMenuInteraction? { get }
    
    ///自定义添加到webview的UIEditMenuInteraction
    @available(iOS 16.0, *)
    var editMenuInteraction: UIEditMenuInteraction? { get }

    var skContextMenu: SKWebViewContextMenuProtocol { get set }

    var skActionHelper: SKWebViewActionHelper { get }

    func safeSendMethod(selector: Selector!)

    func wkMenuItem(uid: String, title: String, action: @escaping () -> Void) -> UIMenuItem
    
    var identifyId: String { get set }
}
