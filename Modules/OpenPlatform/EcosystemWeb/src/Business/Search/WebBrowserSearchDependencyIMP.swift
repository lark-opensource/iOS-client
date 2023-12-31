//
//  WebBrowserSearchDependencyIMP.swift
//  EcosystemWeb
//
//  Created by zhaojingxin on 2023/10/26.
//

import WebBrowser
import TTMicroApp

final class WebBrowserSearchDependencyIMP: WebBrowserSearchDependency {
    
    func highlightSearchScript() -> String? {
        return CommonComponentResourceManager().fetchJSWithSepcificKey(componentName: "js_for_web_highlight_search")
    }
}
