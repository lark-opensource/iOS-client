//
//  WebBrowserProtocol.swift
//  WebBrowser
//
//  Created by yinyuan on 2021/11/3.
//

import Foundation
import LarkWebViewContainer
import LarkOPInterface

/// 套件统一浏览器容器代理对象
public protocol WebBrowserProtocol {
    
    /// browser 即将开始加载 URL
    func browser(_ browser: WebBrowser, willLoadURL url: URL)
    
    /// browser URL 发生变化时调用
    func browser(_ browser: WebBrowser, didURLChanged url: URL?)
    /// browser 即将重新加载 URL
    func browser(_ browser: WebBrowser, didReloadURL url: URL)
    
    /// 网页 menu meta配置信息发生变化
    func browser(_ browser: WebBrowser, didHideMenuItemsChanged hideMuenItems: Array<String>?)
    
    /// 业务方插件发生变化
    func browser(_ browser: WebBrowser, didImBusinessPluginChanged imPlugin: BusinessBarItemsForWeb?, didDocBusinessPluginChanged docPlugin: BusinessBarItemsForWeb?)
    
    /// ipad 上视图状态发生变化
    ///  true - R视图切换为C视图
    ///  false - C视图切换为R视图
    func browser(_ browser: WebBrowser, didCollapseStateChangedTo state: Bool)
}

public extension WebBrowserProtocol {
    
    func browser(_ browser: WebBrowser, willLoadURL url: URL) {}
    
    func browser(_ browser: WebBrowser, didURLChanged url: URL?) {}
    
    func browser(_ browser: WebBrowser, didReloadURL url: URL) {}
    
    func browser(_ browser: WebBrowser, didHideMenuItemsChanged hideMuenItems: Array<String>?){}
    
    func browser(_ browser: WebBrowser, didImBusinessPluginChanged imPlugin: BusinessBarItemsForWeb?, didDocBusinessPluginChanged docPlugin: BusinessBarItemsForWeb?) {}
    
    func browser(_ browser: WebBrowser, didCollapseStateChangedTo: Bool) {}
}
