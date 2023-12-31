//
//  WebTextSizeExtensionItem.swift
//  WebBrowser
//
//  Created by ByteDance on 2023/6/12.
//

import Foundation
import LKCommonsLogging
import LarkZoomable
import LarkWebViewContainer
import UniverseDesignFont

final public class WebTextSizeExtensionItem: WebBrowserExtensionItemProtocol {
    fileprivate static let logger = Logger.webBrowserLog(WebTextSizeExtensionItem.self, category: "WebTextSizeExtensionItem")
    
    public var itemName: String? = "WebTextSize"
    
    public lazy var lifecycleDelegate: WebBrowserLifeCycleProtocol? = WebTextSizeLifeCycleImpl(item: self)
    public lazy var navigationDelegate: WebBrowserNavigationProtocol? = WebTextSizeNavigationImpl(item: self)
    
    fileprivate weak var browser: WebBrowser?
    
    public init(browser: WebBrowser) {
        self.browser = browser
    }
}

final class WebTextSizeLifeCycleImpl: WebBrowserLifeCycleProtocol {
    private weak var item: WebTextSizeExtensionItem?
    
    init(item: WebTextSizeExtensionItem) {
        self.item = item
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func viewDidLoad(browser: WebBrowser) {
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateTextSize),
            name:WebZoom.didChangeNotification,
            object: nil)
    }
    
    @objc fileprivate func updateTextSize() {
        guard let item = item, let browser = item.browser else {
            WebTextSizeExtensionItem.logger.error("[WebTextSize] the browser is nil when text size did change notification")
            return
        }
        let percent = Int(WebZoom.currentZoom.scale * 100)
        let scriptStr = TextSizeContentCons.textSizeUserScript(percent: percent)
        browser.webview.evaluateJavaScript(scriptStr) { [weak browser] _, error in
            guard let browser = browser else {
                WebTextSizeExtensionItem.logger.error("[WebTextSize] evaluate web text size adjust \(percent)% js failure because browser is nil")
                return
            }
            guard error == nil else {
                WebTextSizeExtensionItem.logger.error("[WebTextSize] \(browser) evaluate web text size adjust \(percent)% js failure)", error: error)
                return
            }
            WebTextSizeExtensionItem.logger.info("[WebTextSize] \(browser) evaluate web text size adjust \(percent)% js success")
        }
    }
}

final class WebTextSizeNavigationImpl: WebBrowserNavigationProtocol {
    private weak var item: WebTextSizeExtensionItem?
    
    init(item: WebTextSizeExtensionItem) {
        self.item = item
    }
    
    func browser(_ browser: WebBrowser, didFinish navigation: WKNavigation!) {
        guard let item = item,
              let lifecycleDelegate = item.lifecycleDelegate as? WebTextSizeLifeCycleImpl else {
            return
        }
        lifecycleDelegate.updateTextSize()
    }
}
