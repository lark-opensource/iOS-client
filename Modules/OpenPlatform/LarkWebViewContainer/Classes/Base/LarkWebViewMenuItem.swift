//
//  LarkWebViewMenuItem.swift
//  LarkWebViewContainer
//
//  Created by ByteDance on 2023/8/14.
//

import Foundation


public enum LarkWebViewMenuIdentifier: String {
    /// My AI（浮窗面板）
    case myAI = "myAI"
    ///  解释（快捷指令）
    case explain = "explain"
}

@objc
public final class LarkWebViewMenuItem:NSObject {
    public var identifier: LarkWebViewMenuIdentifier
    public var title: String
    
    public init(identifier: LarkWebViewMenuIdentifier, title: String) {
        self.identifier = identifier
        self.title = title
    }
}

@objc
public protocol LarkWebViewMenuDelegate {
    
    /// 自定义菜单设置（iOS16及以上）
    /// - Parameter builder: menu builder
    @available(iOS 13.0, *)
    @objc optional func lk_buildMenu(with builder: UIMenuBuilder) -> [LarkWebViewMenuItem]
    
    /// 过滤长按菜单项
    @objc optional func lk_canPerformAction(_ action: Selector, withSender sender: Any?, withDefault result: Bool) -> Bool
    
    /// 是否可以为第一响应者
    @objc optional var lk_canBecomeFirstResponder: Bool { get set }
    
    /// myAI菜单点击
    @objc optional func myAIAction(sender: Any?)
    
    /// 解释菜单点击
    @objc optional func explainAction(sender: Any?)
}
