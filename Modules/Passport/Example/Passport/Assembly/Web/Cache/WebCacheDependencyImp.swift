//
//  WebCacheDependencyImp.swift
//  LarkOpenPlatform
//
//  Created by Miaoqi Wang on 2020/12/20.
//

import Foundation
import LarkWebViewController
import LarkWebCache
import Swinject
import WebKit

class WebCacheDependencyImp: WebCacheDependency {

    let wrapper: LoadWebCacheServiceWrapper

    init?(resolver: Resolver, bizName: String?) {
        guard let wp = LoadWebCacheServiceWrapper(resolver: resolver, bizName: bizName) else {
            return nil
        }
        self.wrapper = wp
    }

    func enableHTTPHandler(for config: WKWebViewConfiguration) {
        wrapper.enableHTTPHandler(for: config)
    }

    func bindBizInfoToWebView(_ webView: WKWebView) {
        wrapper.setBizInfoToTable(webView)
    }

    func recordStartLoad() {
        wrapper.service.recordStartLoad()
    }

    func recordStopLoad(url: URL) {
        wrapper.service.recordStopLoad(url: url)
    }
}
