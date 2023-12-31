//
//  OpenAPIContext+Extension.swift
//  OPPlugin
//
//  Created by yi on 2021/4/28.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import LKCommonsLogging
import OPSDK
import WebKit
import OPPluginManagerAdapter

extension OpenAPIContext {
    
    // 组件使用的hostPageView
    var enginePageForComponent: WKWebView? {
        guard let gadgetContext = gadgetContext as? GadgetAPIContext else {
            apiTrace.error("gadgetContext is nil")
            return nil
        }
        var engine: WKWebView?
        switch gadgetContext.engineType {
        case let .render(page: enginePage):
            engine = enginePage
        default:
            break
        }
        guard let page = engine else {
            apiTrace.error("current engine is not webview")
            return nil
        }
        return page
    }
}
