//
//  ClippingBridgeTask.swift
//  SKCommon
//
//  Created by huayufan on 2022/6/27.
//  

import SKFoundation
import WebBrowser

public final class ClippingBridgeFactory {

    private static var handlers: NSHashTable<DocMenuPluginAPIHandler> = NSHashTable(options: .weakMemory)

    static func generateBridgeHandler(webBrowser: WebBrowser) -> DocMenuPluginAPIHandler {
        let identifier = "\(ObjectIdentifier(webBrowser))"
        if handlers.allObjects.count == 0 {
            // 清空之前的缓存
            cleanClippingResource()
        }
        for handler in handlers.allObjects where handler.identifier == identifier {
            DocsLogger.info("handler:\(identifier) exists", component: LogComponents.clippingDoc)
            return handler
        }
        DocsLogger.info("create handler:\(identifier)", component: LogComponents.clippingDoc)
        let handler = DocMenuPluginAPIHandler(webBrowser: webBrowser)
        handlers.add(handler)
        return handler
    }
    
    public static func cleanClippingResource() {
        // 清空之前的缓存
        ClippingDocFileSubPlugin.clearAllFile()
        // 清空老旧js文件
        try? ClippingResourceTool().clearOldResource()
    }
}
