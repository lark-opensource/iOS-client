//
//  WebBrowserExtensionItemProtocol.swift
//  WebBrowser
//
//  Created by 新竹路车神 on 2021/7/29.
//

import Foundation

/**
 套件统一浏览器 Extension Item 协议
 请不要在 item 的 init 触发 WebBrowser 的生命周期。例如：调用 browser.view 会触发 loadView 和 viewDidLoad。
 请不要持有 browser 对象，避免内存泄漏
 */
public protocol WebBrowserExtensionItemProtocol {
    /// 套件统一浏览器容器生命周期实例
    var lifecycleDelegate: WebBrowserLifeCycleProtocol? { get }
    
    /// 网页navigation生命周期实例
    var navigationDelegate: WebBrowserNavigationProtocol? { get }
    
    /// 套件统一浏览器容器代理对象
    var browserDelegate: WebBrowserProtocol? { get }
    
    var itemName: String? { get }
    
}

public extension WebBrowserExtensionItemProtocol {
    var lifecycleDelegate: WebBrowserLifeCycleProtocol? { nil }

    var navigationDelegate: WebBrowserNavigationProtocol? { nil }
    
    var browserDelegate: WebBrowserProtocol? { nil }
    
    var itemName: String? { nil }
}
