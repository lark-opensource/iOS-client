//
//  MailWebViewSchemeManager.swift
//  MailSDK
//
//  Created by majx on 2019/6/20.
//

import Foundation
import WebKit
import LarkWebViewContainer
import LarkWebviewNativeComponent

class MailWebViewSchemeManager {
    fileprivate static var isWKSchemeRegistered = false
    fileprivate static var isWKProtocolRegistered = false

    class func makeDefaultNewWebView(config: WKWebViewConfiguration, provider: MailSharedServicesProvider?, nativeComponentManager: NativeComponentManageable? = nil) -> MailNewBaseWebView {
        config.websiteDataStore = WKWebsiteDataStore.default()
        config.processPool = MailNewBaseWebView.defaultWKProcessPool
        // 增加对自定义协议的支持
        MailCustomURLProtocolService.schemes.forEach {
            config.setURLSchemeHandler($0.makeSchemeHandler(provider: provider), forURLScheme: $0.rawValue)
        }
        let builder = LarkWebViewConfigBuilder()
        let _ = builder.setWebViewConfig(config)
        let web = MailNewBaseWebView(frame: CGRect.zero, config: builder.build(bizType: LarkWebViewBizType.mail))
        NativeRenderService.shared.enableNativeRender(webview: web, componentManager: nativeComponentManager)
        return web
    }
}
