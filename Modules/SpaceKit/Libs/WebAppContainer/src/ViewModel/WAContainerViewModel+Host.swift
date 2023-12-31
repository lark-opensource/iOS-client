//
//  WAContainerViewModel+Host.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/11/15.
//

import Foundation
import LarkWebViewContainer

extension WAContainerViewModel: WAPluginHost {
    var container: WAContainer { self }
}

extension WAContainerViewModel: WAContainer {
    
    var hostWebView: LarkWebView? { self.webView }
    
    var hostVC: WAContainerUIDelegate? { self.delegate }
    
    var hostBridge: WABridge? {
        self.bridge
    }
    
    var hostPluginManager: WAPluginManager? {
        self.pluginManager
    }
    
    var hostOfflineManager: WAOfflineManager? {
        self.offlineManager
    }
    
    var hostURL: URL? {
        self.currentURL
    }
}

