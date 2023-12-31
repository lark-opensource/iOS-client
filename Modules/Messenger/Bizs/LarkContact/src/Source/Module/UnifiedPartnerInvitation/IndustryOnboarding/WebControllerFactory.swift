//
//  WebControllerFactory.swift
//  LarkContact
//
//  Created by Yuri on 2023/6/28.
//

import UIKit
import WebKit
import RxSwift
import WebBrowser
import LarkWebViewContainer

class WebControllerFactory: NSObject, WebBrowserNavigationProtocol {
    typealias HandlerType = ((Result<WebBrowser, Error>) -> Void)
    typealias Module = ContactLogger.Module

    enum WebError: Error {
        case errorUrl(String)
        case timeout
        case loadError(Int)
    }

    var browser: WebBrowser?
    var handler: HandlerType?
    weak var timer: Timer?

    deinit {
        timer?.invalidate()
        timer = nil
        ContactLogger.shared.info(module: .onboarding, event: "\(Self.self) deinit")
    }

    func load(url: URL, handler: @escaping HandlerType) -> WebBrowser {
        self.handler = handler
        let configuration = WebBrowserConfiguration(webBizType: .ug)
        let browser = WebBrowser(url: url, configuration: configuration)
        self.browser = browser
        do {
            let loadItem = UGWebBrowserLoadItem(fallback: {
                handler(.failure(WebError.errorUrl(url.absoluteString)))
            })
            loadItem.navigationDelegate = self
            try browser.register(item: loadItem)
            let singleItem = UGSingleExtensionItem(browser: browser, stepInfo: nil)
            try? browser.register(singleItem: singleItem)
            try? browser.register(item: UniteRouterExtensionItem())
        } catch {
            handler(.failure(error))
        }
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(10), repeats: false, block: { [weak self] _ in
            self?.handler?(.failure(WebError.timeout))
        })
        return browser
    }

    func browser(_ browser: WebBrowser, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handler?(.failure(error))
    }

    func browser(_ browser: WebBrowser, didFinish navigation: WKNavigation!) {
        timer?.invalidate()
        timer = nil
        handler?(.success(browser))
    }

    func browser(_ browser: WebBrowser, didFail navigation: WKNavigation!, withError error: Error) {
        handler?(.failure(error))
    }

    func browser(_ browser: WebBrowser, decidePolicyFor navigationResponse: WKNavigationResponse) -> WKNavigationResponsePolicy {
        let code = navigationResponse.response.statusCode
        if code >= 400 {
            handler?(.failure(WebError.loadError(code)))
            return .cancel
        }
        return .allow
    }
}
