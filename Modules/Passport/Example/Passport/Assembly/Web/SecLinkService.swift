//
//  SecLinkService.swift
//  LarkWebViewController
//
//  Created by lijuyou on 2020/9/11.
//

import Foundation
import LarkWebViewContainer
import RxSwift
import WebKit
import Swinject
import LarkOPInterface
import LKCommonsLogging
import LarkWebViewController
//仅挪动位置，未改变任何逻辑，code from lijuyou
//可以抽离到飞书源码
/**
 Lark接入 LarkWebView
    1. 注册
    2. 接入Lark SecLink服务
 */

/// LarkWebView组装类
class LarkWebViewContainerAssembly {
    static let log = Logger.log(LarkWebViewContainerAssembly.self, category: "LarkWebView")

    static func register(resolver: Resolver) {
        //注册SecLink服务
        log.info("larkwebview inject seclink service")
        LarkWebViewServiceManager.shared.register(LarkWebViewSecLinkServiceProtocol.self) { () -> LarkWebViewSecLinkServiceProtocol in
            let urlDetectService = resolver.resolve(URLDetectService.self)
            return SecLinkService(urlDetectService: urlDetectService)
        }
    }
}

/// SecLink服务实现类
/// 将Lark现有的URLDetectService桥接到LarkWebView
class SecLinkService: LarkWebViewSecLinkServiceProtocol {

    private let urlDetectService: URLDetectService?
    private let disposeBag: DisposeBag = DisposeBag()

    init(urlDetectService: URLDetectService?) {
        self.urlDetectService = urlDetectService
    }

    func webView(_ webView: LarkWebView, decidePolicyFor navigationResponse: WKNavigationResponse) {
        urlDetectService?.webView(webView, decidePolicyFor: navigationResponse)
    }

    func webView(_ webView: LarkWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Swift.Void) {
        guard let urlDetectService = self.urlDetectService else {
            decisionHandler(WKNavigationResponsePolicy.allow)
            return
        }
        urlDetectService.secLinkResultDriver
            .drive(onNext: { (isAllow) in
                // 检测为恶意链接后cancel当前请求，检测服务会跳转到中间页
                if isAllow {
                    decisionHandler(WKNavigationResponsePolicy.allow)
                } else {
                    decisionHandler(WKNavigationResponsePolicy.cancel)
                }
            }).disposed(by: self.disposeBag)
        urlDetectService.webView(webView, decidePolicyFor: navigationResponse)
    }

    func webViewDidFinish(url: URL?) {
        urlDetectService?.webViewDidFinish(url: url)
    }

    func webViewDidFailProvisionalNavigation(error: Error, url: URL?) {
        urlDetectService?.webViewDidFailProvisionalNavigation(error: error, url: url)
    }

    func webViewDidFail(error: Error, url: URL?) {
        urlDetectService?.webViewDidFail(error: error, url: url)
    }
}
