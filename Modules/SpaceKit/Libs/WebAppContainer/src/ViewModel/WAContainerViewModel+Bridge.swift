//
//  WAContainerViewModel+Bridge.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/11/15.
//

import Foundation
import LarkWebViewContainer

extension WAContainerViewModel: WABridgeServiceContext {
    
    var bizName: String { self.config.appName }
    
    var host: WABridgeServiceHost { self }
}

extension WAContainerViewModel: WABridgeServiceHost {
    
    var dataAgent: WABridgeDataDelegate? { self }
    
    var loaderAgent: WABridgeLoaderDelegate? { self.loader }
    
    var uiAgent: WABridgeUIDelegate? { self }
}


extension WAContainerViewModel: WABridgeDataDelegate {

}


extension WAContainerViewModel: WABridgeUIDelegate {
    var bridgeWebView: LarkWebView? { self.webView }
    
    /// 真正打开页面时才会有值。在预加载时hostV为nil
    var bridgeVC: UIViewController? { self.delegate }
}
