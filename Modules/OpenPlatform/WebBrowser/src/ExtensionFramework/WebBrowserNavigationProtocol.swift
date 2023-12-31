//
//  WebBrowserNavigationProtocol.swift
//  WebBrowser
//
//  Created by 新竹路车神 on 2021/7/29.
//

import WebKit

/// 网页navigation生命周期协议
public protocol WebBrowserNavigationProtocol {
    /// Decides whether to allow or cancel a navigation.
    /// - Parameters:
    ///  - browser: The browser invoking the delegate method.
    ///  - navigationAction: Descriptive information about the action triggering the navigation request.
    func browser(_ browser: WebBrowser, decidePolicyFor navigationAction: WKNavigationAction) -> WKNavigationActionPolicy
    
    /// Decides whether to allow or cancel a navigation after its response is known.
    /// - Parameters:
    ///  - browser: The browser invoking the delegate method.
    ///  - navigationResponse: Descriptive information about the navigation response.
    func browser(_ browser: WebBrowser, decidePolicyFor navigationResponse: WKNavigationResponse) -> WKNavigationResponsePolicy
    
    /// Invoked when a main frame navigation starts.
    /// - Parameters:
    ///  - browser: The browser invoking the delegate method.
    ///  - navigation: The navigation.
    func browser(_ browser: WebBrowser, didStartProvisionalNavigation navigation: WKNavigation!)
    
    /// Invoked when a server redirect is received for the main frame.
    /// - Parameters:
    ///  - browser: The browser invoking the delegate method.
    ///  - navigation: The navigation.
    func browser(_ browser: WebBrowser, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!)
    
    /// Invoked when an error occurs while starting to load data for the main frame.
    /// - Parameters:
    ///  - browser: The browser invoking the delegate method.
    ///  - navigation: The navigation.
    ///  - error: The error that occurred.
    func browser(_ browser: WebBrowser, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error)
    
    /// Invoked when content starts arriving for the main frame.
    /// - Parameters:
    ///  - browser: The browser invoking the delegate method.
    ///  - navigation: The navigation.
    func browser(_ browser: WebBrowser, didCommit navigation: WKNavigation!)
    
    /// Invoked when a main frame navigation completes.
    /// - Parameters:
    ///  - browser: he browser invoking the delegate method.
    ///  - navigation: The navigation.
    func browser(_ browser: WebBrowser, didFinish navigation: WKNavigation!)
    
    /// Invoked when an error occurs during a committed main frame
    /// - Parameters:
    ///  - browser: The browser invoking the delegate method.
    ///  - navigation: The navigation.
    ///  - error: The error that occurred.
    func browser(_ browser: WebBrowser, didFail navigation: WKNavigation!, withError error: Error)
    
    /// Invoked when the browser's web view's web content process is terminated.
    /// - Parameter browser: The browser invoking the delegate method.
    func browserWebContentProcessDidTerminate(_ browser: WebBrowser)
}

public extension WebBrowserNavigationProtocol {
    func browser(_ browser: WebBrowser, decidePolicyFor navigationAction: WKNavigationAction) -> WKNavigationActionPolicy {
        .allow
    }

    func browser(_ browser: WebBrowser, decidePolicyFor navigationResponse: WKNavigationResponse) -> WKNavigationResponsePolicy {
        .allow
    }

    func browser(_ browser: WebBrowser, didStartProvisionalNavigation navigation: WKNavigation!) {}

    func browser(_ browser: WebBrowser, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {}

    func browser(_ browser: WebBrowser, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {}

    func browser(_ browser: WebBrowser, didCommit navigation: WKNavigation!) {}

    func browser(_ browser: WebBrowser, didFinish navigation: WKNavigation!) {}

    func browser(_ browser: WebBrowser, didFail navigation: WKNavigation!, withError error: Error) {}
    
    func browserWebContentProcessDidTerminate(_ browser: WebBrowser) {}
}
