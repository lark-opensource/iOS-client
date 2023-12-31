//
//  WebMetaSafeAreaExtensionItem.swift
//  WebBrowser
//
//  Created by dengbo on 2022/6/13.
//

import EENavigator
import Foundation
import LarkUIKit
import LarkWebViewContainer
import LKCommonsLogging
import UIKit

fileprivate let logger = Logger.webBrowserLog(WebMetaSafeAreaExtensionItem.self, category: "WebMetaSafeAreaExtensionItem")

final public class WebMetaSafeAreaExtensionItem: WebBrowserExtensionItemProtocol {
    public var itemName: String? = "WebMetaSafeArea"
    public lazy var lifecycleDelegate: WebBrowserLifeCycleProtocol? = WebMetaSafeAreaWebBrowserLifeCycle(item: self)

    private weak var webBrowser: WebBrowser?
    private var needFix = false
    private var jsInjected = false
    public init(browser: WebBrowser) {
        self.webBrowser = browser
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func setupObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(orientationDidChange),
                                               name: UIApplication.didChangeStatusBarOrientationNotification,
                                               object: nil)
    }
    
    func applyMetaContent(metaContent: String?) {
        logger.info("apply meta content fixSafeArea \(metaContent ?? "")")
        guard let webBrowser = webBrowser else {
            logger.error("browser is nil")
            return
        }
        guard webBrowser.configuration.acceptWebMeta else {
            logger.info("browser do not accept webmeta")
            return
        }
        guard let fixSafeArea = metaContent else {
            logger.info("fixSafeArea is nil")
            return
        }
        needFix = fixSafeArea.lowercased() == "true"
        setupSafeAreaVarFunc()
        updateSafeAreaVarFunc()
    }
    
    func setupSafeAreaVarFunc() {
        logger.info("setup safearea var func")
        guard needFix else {
            logger.info("do not need fix")
            return
        }
        guard !jsInjected else {
            logger.info("js has injected")
            return
        }
        jsInjected = true
        webBrowser?.webview.configuration.userContentController.addUserScript(WKUserScript(
            source: fetchJSString(),
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        ))
    }
    
    func updateSafeAreaVarFunc() {
        logger.info("update safearea var func")
        guard needFix else { return }
        webBrowser?.webview.evaluateJavaScript(fetchJSString()) { (result, error) in
            guard error == nil else {
                logger.error("evaluate js failed", error: error)
                return
            }
            logger.info("evalute js success")
        }
    }
    
    func fetchJSString() -> String {
        let safeAreaInset = webBrowser?.view.window?.safeAreaInsets ?? .zero
        logger.info("fetchJSString with safearea inset: \(safeAreaInset)")
        let jsString = setupVarFuncJSString
            .replacingOccurrences(of: "lk-safearea-top-placeholder", with: "\(safeAreaInset.top)px")
            .replacingOccurrences(of: "lk-safearea-bottom-placeholder", with: "\(safeAreaInset.bottom)px")
            .replacingOccurrences(of: "lk-safearea-left-placeholder", with: "\(safeAreaInset.left)px")
            .replacingOccurrences(of: "lk-safearea-right-placeholder", with: "\(safeAreaInset.right)px")
        return jsString
    }
    
    @objc
    private func orientationDidChange() {
        logger.info("orientationDidChange \(UIApplication.shared.statusBarOrientation)")
        updateSafeAreaVarFunc()
    }
}

final public class WebMetaSafeAreaWebBrowserLifeCycle: WebBrowserLifeCycleProtocol {
    private weak var item: WebMetaSafeAreaExtensionItem?
    
    init(item: WebMetaSafeAreaExtensionItem) {
        self.item = item
    }
    
    public func viewDidLoad(browser: WebBrowser) {
        guard browser.configuration.acceptWebMeta else {
            return
        }
        item?.setupObserver()
    }
}


private let setupVarFuncJSString = """
;(function () {
    function LarkDOMHeadObserver() { }

    LarkDOMHeadObserver.prototype.setStyle = function () {
        var r = document.querySelector(':root');

        r.style.setProperty('--lk-safearea-top', 'lk-safearea-top-placeholder');
        r.style.setProperty('--lk-safearea-bottom', 'lk-safearea-bottom-placeholder');
        r.style.setProperty('--lk-safearea-left', 'lk-safearea-left-placeholder');
        r.style.setProperty('--lk-safearea-right', 'lk-safearea-right-placeholder');
    }

    LarkDOMHeadObserver.prototype.setup = function () {
        if (document.head) {
            this.setStyle();
            return;
        }

        const option = {
            attributes: false,
            childList: true,
            characterData: false,
            subtree: true,
            attributeOldValue: false,
            characterDataOldValue: false
        };

        const that = this;

        const callback = function (mutationsList, observer) {
            for (const mutation of mutationsList) {
                if (mutation.type !== 'childList') continue;
                if (mutation.addedNodes && mutation.addedNodes.length > 0) {
                    mutation.addedNodes.forEach((element) => {
                        if (element.nodeName === "HEAD") {
                            that.setStyle();
                            that.rootObserver.disconnect();
                        }
                    });
                }
            }
        };
        this.rootObserver = new MutationObserver(callback);
        this.rootObserver.observe(document, option);
    }

    new LarkDOMHeadObserver().setup();
})();
"""
