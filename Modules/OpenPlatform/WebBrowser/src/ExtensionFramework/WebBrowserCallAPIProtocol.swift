//
//  WebBrowserCallAPIProtocol.swift
//  WebBrowser
//
//  Created by 新竹路车神 on 2021/7/29.
//

import Foundation
import LarkWebViewContainer

/// API调用
public protocol WebBrowserCallAPIProtocol {
    
    /// 收到API调用
    /// - Parameters:
    ///   - webBrowser: The browser invoking the delegate method.
    ///   - message: API 数据结构
    ///   - callback: 回调对象
    func recieveAPICall(webBrowser: WebBrowser, message: APIMessage, callback: APICallbackProtocol)
}
