//
//  WABridgeHost.swift
//  WebAppBridge
//
//  Created by lijuyou on 2023/10/30.
//

import Foundation
import LarkWebViewContainer

public protocol WABridgeServiceHost: AnyObject  {
    
    var dataAgent: WABridgeDataDelegate? { get }
    
    var loaderAgent: WABridgeLoaderDelegate? { get }
    
    var uiAgent: WABridgeUIDelegate? { get }
}

public protocol WABridgeDataDelegate: AnyObject {
    var hostURL: URL? { get }
}

public protocol WABridgeLoaderDelegate: AnyObject {
    
    func onTemplateReady()
}

public protocol WABridgeUIDelegate: AnyObject  {
    var bridgeWebView: LarkWebView? { get }
    
    /// 真正打开页面时才会有值。在预加载时hostVC为nil
    var bridgeVC: UIViewController? { get }
}
