//
//  WebBrowserLifeCycleProtocol.swift
//  WebBrowser
//
//  Created by 新竹路车神 on 2021/7/29.
//

import Foundation
import LarkWebViewContainer

/// 套件统一浏览器容器生命周期协议
public protocol WebBrowserLifeCycleProtocol {
    
    /// Called after the WebBrowser's view is loaded into memory.
    /// - Parameter browser: 触发该生命周期的套件统一浏览器对象
    func viewDidLoad(browser: WebBrowser)
    
    /// browser webview 刚刚创建完成（尚未完成其他初始化工作或添加到view中）
    func webviewDidCreated(_ browser: WebBrowser, webview: LarkWebView)
    
    /// Notifies the WebBrowser that its view is about to be added to a view hierarchy.
    /// - Parameter browser: 触发该生命周期的套件统一浏览器对象
    func viewWillAppear(browser: WebBrowser, animated: Bool)
    
    /// Notifies the WebBrowser that its view was added to a view hierarchy.
    /// - Parameter browser: 触发该生命周期的套件统一浏览器对象
    func viewDidAppear(browser: WebBrowser, animated: Bool)
    
    /// Notifies the WebBrowser that its view is about to be removed from a view hierarchy.
    /// - Parameter browser: 触发该生命周期的套件统一浏览器对象
    func viewWillDisappear(browser: WebBrowser, animated: Bool)
    
    /// Notifies the WebBrowser that its view was removed from a view hierarchy.
    /// - Parameter browser: 触发该生命周期的套件统一浏览器对象
    func viewDidDisappear(browser: WebBrowser, animated: Bool)
    
    func viewDidLayoutSubviews()
    
    /// Notifies the WebBrowser is destory.
    /// - Parameter browser: 触发该生命周期的套件统一浏览器对象
    func webBrowserDeinit(browser: WebBrowser)
    
    func traitCollectionDidChange(browser: WebBrowser, previousTraitCollection: UITraitCollection?)
}

public extension WebBrowserLifeCycleProtocol {
    func viewDidLoad(browser: WebBrowser) {}
    
    func webviewDidCreated(_ browser: WebBrowser, webview: LarkWebView) {}

    func viewWillAppear(browser: WebBrowser, animated: Bool) {}

    func viewDidAppear(browser: WebBrowser, animated: Bool) {}

    func viewWillDisappear(browser: WebBrowser, animated: Bool) {}

    func viewDidDisappear(browser: WebBrowser, animated: Bool) {}
    
    func viewDidLayoutSubviews() {}

    func webBrowserDeinit(browser: WebBrowser) {}
    
    func traitCollectionDidChange(browser: WebBrowser, previousTraitCollection: UITraitCollection?) {}
}
