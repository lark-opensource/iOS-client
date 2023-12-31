//
//  WebBrowserExtensionSingleItemProtocol.swift
//  WebBrowser
//
//  Created by 新竹路车神 on 2021/7/29.
//

import Foundation

/**
 套件统一浏览器 Extension single Item 协议，满足该协议的对象在 Browser 内只能有一份
 */
public protocol WebBrowserExtensionSingleItemProtocol {
    /// API调用
    var callAPIDelegate: WebBrowserCallAPIProtocol? { get }
}

public extension WebBrowserExtensionSingleItemProtocol {
    var callAPIDelegate: WebBrowserCallAPIProtocol? { nil }
}
