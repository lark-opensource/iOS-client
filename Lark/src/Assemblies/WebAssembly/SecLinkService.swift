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
import WebBrowser
import LarkFeatureGating
import EcosystemWeb
//仅挪动位置，未改变任何逻辑，code from lijuyou
/// SecLink服务实现类
/// 将Lark现有的URLDetectService桥接到LarkWebView

typealias DecisionHandler = (WKNavigationResponsePolicy) -> Swift.Void

final class SecLinkService: LarkWebViewSecLinkServiceProtocol {
    static let logger = LKCommonsLogging.Logger.log(SecLinkService.self, category: "secLink.Log")
    private let urlDetectService: URLDetectService?
    private let disposeBag: DisposeBag = DisposeBag()
    private var decisionWrapperArr: [DecisionWrapper] = []
    private var useHandlerOptimized: Bool {
        return LarkFeatureGating.shared.getFeatureBoolValue(for: "admin.security.seclink_handler_optimized")
    }

    init(urlDetectService: URLDetectService?) {
        self.urlDetectService = urlDetectService
    }
    deinit {
        if useHandlerOptimized {
            flushUncalledDecisionHandlers()
        }
    }

    func webView(_ webView: LarkWebView, decidePolicyFor navigationResponse: WKNavigationResponse) {
        urlDetectService?.webView(webView, decidePolicyFor: navigationResponse, isAsync: false)
    }

    func webView(_ webView: LarkWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping DecisionHandler) {
        guard let urlDetectService = self.urlDetectService else {
            Self.logger.error("seclink allow: urlDetect not found")
            decisionHandler(WKNavigationResponsePolicy.allow)
            return
        }
        if useHandlerOptimized {
            let decisionWrapper = DecisionWrapper(response: navigationResponse, decisionHandler: decisionHandler)
            decisionWrapperArr.append(decisionWrapper)
            urlDetectService.secLinkResultDriver
                .drive(onNext: { [weak self] (isAllow) in
                    Self.logger.info("seclink result:\(isAllow)")
                    if isAllow {
                        decisionHandler(WKNavigationResponsePolicy.allow)
                    } else {
                        decisionHandler(WKNavigationResponsePolicy.cancel)
                    }
                    self?.removeDecisionWrapperFor(navigationResponse)
                }).disposed(by: self.disposeBag)
        } else {
            urlDetectService.secLinkResultDriver
                .drive(onNext: { (isAllow) in
                    Self.logger.info("seclink result:\(isAllow)")
                    // 检测为恶意链接后cancel当前请求，检测服务会跳转到中间
                    if isAllow {
                        decisionHandler(WKNavigationResponsePolicy.allow)
                    } else {
                        decisionHandler(WKNavigationResponsePolicy.cancel)
                    }
                }).disposed(by: self.disposeBag)
        }
        let isAsync = webView.seclinkCheckCanBeAsync()
        Self.logger.info("seclink check can be async: \(isAsync)")
        urlDetectService.webView(webView, decidePolicyFor: navigationResponse, isAsync: isAsync)
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
    func seclinkPrecheck(url: URL, checkReuslt: @escaping (Bool) -> Swift.Void) {
        urlDetectService?.seclinkPrecheck(url: url, checkReuslt: checkReuslt)
    }
    private func removeDecisionWrapperFor(_ response: WKNavigationResponse) {
        guard !decisionWrapperArr.isEmpty,
              let matchIndex = (decisionWrapperArr.firstIndex { ref in ref.matchResponse(response) }) else { return }

        decisionWrapperArr.remove(at: matchIndex)
    }

    private func flushUncalledDecisionHandlers() {
        guard !decisionWrapperArr.isEmpty else { return }
        decisionWrapperArr.forEach { ref in
            ref.cancel()
        }
        decisionWrapperArr = []
    }
}

final class DecisionWrapper {
    private let decisionHandler: DecisionHandler
    private let response: WKNavigationResponse
    init(response: WKNavigationResponse, decisionHandler: @escaping DecisionHandler) {
        self.decisionHandler = decisionHandler
        self.response = response
    }
    func matchResponse(_ resposne: WKNavigationResponse) -> Bool {
        return self.response == response
    }
    func allow() {
        decisionHandler(WKNavigationResponsePolicy.allow)
    }
    func cancel() {
        decisionHandler(WKNavigationResponsePolicy.cancel)
    }
}
