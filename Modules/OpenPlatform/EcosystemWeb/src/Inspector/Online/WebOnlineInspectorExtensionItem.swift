//
//  WebOnlineInspectorExtensionItem.swift
//  EcosystemWeb
//
//  Created by jiangzhongping on 2023/9/7.
//

import UIKit
import LKCommonsLogging
import WebBrowser
import ECOProbe
import ECOInfra
import LarkUIKit

private let logger = Logger.ecosystemWebLog(WebOnlineInspectorExtensionItem.self, category: "WebOnlineInspect")

final public class WebOnlineInspectorExtensionItem: WebBrowserExtensionItemProtocol {
    
    public var itemName: String? = "WebOnlineInspector"
    
    weak var webBrowser: WebBrowser?
    
    public var onlineConnIDs: Set<String> = []
    
    public var hasExecCloseConnections = false
    
    public init(browser: WebBrowser) {
        self.webBrowser = browser
    }
    
    public lazy var lifecycleDelegate: WebBrowserLifeCycleProtocol? = WebOnlineInspectorWebBrowserLifeCycle(item: self)
    
    deinit {
        
    }
}

final public class WebOnlineInspectorWebBrowserLifeCycle: WebBrowserLifeCycleProtocol {
    
    weak var item: WebOnlineInspectorExtensionItem?
        
    init(item: WebOnlineInspectorExtensionItem) {
        self.item = item
    }
    
    public func viewWillDisappear(browser: WebBrowser, animated: Bool) {
        
        let isInspectorPage = self.isInspectorPage(browser: browser)
        //适配处理ipad网页标签页保活容器不及时销毁
        if isInspectorPage, Display.pad, let item = self.item {
            self.closeConnections(item: item, browser: browser)
        }
    }
    
    public func webBrowserDeinit(browser: WebBrowser) {
        
        let isInspectorPage = self.isInspectorPage(browser: browser)
        //处理iphone情形
        if isInspectorPage, !Display.pad, let item = self.item {
            self.closeConnections(item: item, browser: browser)
        }
    }
    
    private func closeConnections(item: WebOnlineInspectorExtensionItem, browser: WebBrowser) {
        
        logger.info("handle closeConnections in iphone")
        let connectionCount = item.onlineConnIDs.count
        if connectionCount <= 0 {
            logger.info("inspector connections is empty")
            return
        }
        
        if item.hasExecCloseConnections {
            logger.info("not trigger close connections again")
            return
        }
        
        item.hasExecCloseConnections = true
        logger.info("clear all inspector connections, count: \(connectionCount)")
        let networkContext = OpenECONetworkWebContext(trace: browser.getTrace(), source: .web)
        for connId in item.onlineConnIDs {
            logger.info("browser deinit: closeConnection,connId:\(connId)")
            WebOnlineInspectNetwork.closeConnection(connId: connId, debugScene: 1, context: networkContext){ _ in }
        }
    }
    
    private func isInspectorPage(browser: WebBrowser) -> Bool {
        var result = false
        if let params = browser.browserURL?.lf.queryDictionary, let debugSession = params["debugSession"], !debugSession.isEmpty {
            result = true
        }
        return result
    }
}
