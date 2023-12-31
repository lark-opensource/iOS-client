//
//  LarkWebView+MulticastDelegate.swift
//  LarkWebViewContainer
//
//  Created by houjihu on 2020/9/8.
//

import WebKit

/// 支持多播代理的属性重写
extension LarkWebView {
    /// 允许外部直接设置/清空自身设置的delegate，内部通过service的方式来实现代理功能
    open override weak var uiDelegate: WKUIDelegate? {
        get {
            return uiDelegateProxy.internUIDelegate
        }
        set {
            // 允许SDK外部设置或清空其本身设置的delegate
            uiDelegateProxy.internUIDelegate = newValue
            self.updateUIDelegate()
        }
    }

    /// 允许外部直接设置/清空自身设置的delegate，内部通过service的方式来实现代理功能
    open override weak var navigationDelegate: WKNavigationDelegate? {
        get {
            return navigationDelegateProxy.internNavigationDelegate
        }
        set {
            // 允许SDK外部清空其本身设置的delegate
            navigationDelegateProxy.internNavigationDelegate = newValue
            self.updateNavigationDelegate()
        }
    }

    /// webview delegate被赋值时，系统会首先检查其支持哪些代理方法，
    /// 在具体执行相关事件时不再进行检查，
    /// 故这里每次增删代理时，需要触发一次赋值操作
    @objc public func updateUIDelegate() {
        super.uiDelegate = nil
        super.uiDelegate = uiDelegateProxy
    }

    /// webview delegate被赋值时，系统会首先检查其支持哪些代理方法，
    /// 在具体执行相关事件时不再进行检查，
    /// 故这里每次增删代理时，需要触发一次赋值操作
    @objc public func updateNavigationDelegate() {
        super.navigationDelegate = nil
        super.navigationDelegate = navigationDelegateProxy
    }

    /// 由于本地重写了uiDelegate和navigationDelegate，故需要调用super的属性来置空
    func clearDelegates() {
        super.uiDelegate = nil
        super.navigationDelegate = nil
    }
}
