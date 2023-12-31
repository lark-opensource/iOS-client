//
//  TestCaseExtensionItem.swift
//  WebBrowser
//
//  Created by 新竹路车神 on 2021/8/15.
//
#if DEBUG
import LarkWebViewContainer
import LKCommonsLogging
import WebKit

private let logger = Logger.webBrowserLog(TestCaseExtensionItem.self, category: "TestCaseExtensionItem")

final public class TestCaseExtensionItem: WebBrowserExtensionItemProtocol {
    public var itemName: String? = "TestCase"
    public var lifecycleDelegate: WebBrowserLifeCycleProtocol? = TestCaseWebBrowserLifeCycle()
    
    public var navigationDelegate: WebBrowserNavigationProtocol? = TestCaseWebBrowserNavigation()
    
    public var browserDelegate: WebBrowserProtocol? = TestCaseWebBrowserDelegate()
}

final public class TestCaseWebBrowserLifeCycle: WebBrowserLifeCycleProtocol {
    public func viewDidLoad(browser: WebBrowser) {
        logger.info("viewDidLoad")
    }
    
    public func webviewDidCreated(_ browser: WebBrowser, webview: LarkWebView) {
        logger.info("webviewDidCreated")
    }

    public func viewWillAppear(browser: WebBrowser, animated: Bool) {
        logger.info("viewWillAppear")
    }

    public func viewDidAppear(browser: WebBrowser, animated: Bool) {
        logger.info("viewDidAppear")
    }

    public func viewWillDisappear(browser: WebBrowser, animated: Bool) {
        logger.info("viewWillDisappear")
    }

    public func viewDidDisappear(browser: WebBrowser, animated: Bool) {
        logger.info("viewDidDisappear")
    }

    public func webBrowserDeinit(browser: WebBrowser) {
        logger.info("webBrowserDeinit")
    }
}

final public class TestCaseWebBrowserNavigation: WebBrowserNavigationProtocol {
    public func browser(_ browser: WebBrowser, decidePolicyFor navigationAction: WKNavigationAction) -> WKNavigationActionPolicy {
        logger.info("decidePolicyFor navigationAction")
        return .allow
    }

    public func browser(_ browser: WebBrowser, decidePolicyFor navigationResponse: WKNavigationResponse) -> WKNavigationResponsePolicy {
        logger.info("decidePolicyFor navigationResponse")
        return .allow
    }

    public func browser(_ browser: WebBrowser, didStartProvisionalNavigation navigation: WKNavigation!) {
        logger.info("didStartProvisionalNavigation")
    }

    public func browser(_ browser: WebBrowser, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        logger.info("didReceiveServerRedirectForProvisionalNavigation")
    }

    public func browser(_ browser: WebBrowser, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        logger.info("didFailProvisionalNavigation")
    }

    public func browser(_ browser: WebBrowser, didCommit navigation: WKNavigation!) {
        logger.info("didCommit navigation")
    }

    public func browser(_ browser: WebBrowser, didFinish navigation: WKNavigation!) {
        logger.info("didFinish navigation")
    }

    public func browser(_ browser: WebBrowser, didFail navigation: WKNavigation!, withError error: Error) {
        logger.info("didFail navigation")
    }
    
    public func browserWebContentProcessDidTerminate(_ browser: WebBrowser) {
        logger.info("browserWebContentProcessDidTerminate")
    }
}

final public class TestCaseWebBrowserDelegate: WebBrowserProtocol {
    
    public func browser(_ browser: WebBrowser, willLoadURL url: URL) {
        logger.info("willLoadURL")
    }
    
    public func browser(_ browser: WebBrowser, didURLChanged url: URL?) {
        logger.info("didURLChanged")
    }
}
#endif
