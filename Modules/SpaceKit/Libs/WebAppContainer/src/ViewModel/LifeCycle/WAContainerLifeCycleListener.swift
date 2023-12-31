//
//  WAContainerLifeCycleListener.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/11/15.
//

import Foundation
import WebKit

public protocol WAContainerPageDelegate: AnyObject {
    func containerViewDidLoad()
    func containerWillAppear()
    func containerDidAppear()
    func containerWillDisappear()
    func containerDidDisappear()
    func containerWillTransition(from: CGSize, to: CGSize)
    func containerDidTransition(from: CGSize, to: CGSize)
    func containerDidSplitModeChange()
    func containerWillChangeOrientation(from: UIInterfaceOrientation, to: UIInterfaceOrientation)
    func containerDidChangeOrientation(from: UIInterfaceOrientation, to: UIInterfaceOrientation)
    func containerAttachToPage()
    func containerDettachFromPage()
}

public protocol WAContainerLoaderLifeCycle: AnyObject {
    func container(_ container: WAContainer, onChangeUrl url: URL)
    
}

public protocol WAContainerWebViewLifeCycle: AnyObject {
    func container(_ container: WAContainer, decidePolicyForAction navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void)
    
    func container(_ container: WAContainer, didStartProvisionalNavigation navigation: WKNavigation!)
    
    func container(_ container: WAContainer, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error)
    
    func container(_ container: WAContainer, didCommit navigation: WKNavigation!)
    
    func container(_ container: WAContainer, didFinish navigation: WKNavigation!)
    
    func container(_ container: WAContainer, didFail navigation: WKNavigation!, withError error: Error)
    
    func container(_ container: WAContainer, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!)
    
    func container(_ container: WAContainer, decidePolicyForResponse navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Swift.Void)
    
    func containerWebContentProcessDidTerminate(_ container: WAContainer)
    
    
    func container(_ container: WAContainer, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView?
}

public protocol WAContainerLifeCycleListener: WAContainerPageDelegate, WAContainerLoaderLifeCycle, WAContainerWebViewLifeCycle {
    
}


public extension WAContainerLifeCycleListener {
    
    //WAContainerPageDelegate
    func containerViewDidLoad() {}
    func containerWillAppear() {}
    func containerDidAppear() {}
    func containerWillDisappear() {}
    func containerDidDisappear() {}
    func containerWillTransition(from: CGSize, to: CGSize) {}
    func containerDidTransition(from: CGSize, to: CGSize) {}
    func containerDidSplitModeChange() {}
    func containerWillChangeOrientation(from: UIInterfaceOrientation, to: UIInterfaceOrientation) {}
    func containerDidChangeOrientation(from: UIInterfaceOrientation, to: UIInterfaceOrientation) {}
    func containerAttachToPage() {}
    func containerDettachFromPage() {}
    
    //WAContainerLoaderLifeCycle
    func container(_ container: WAContainer, onChangeUrl url: URL) {}
    
    func container(_ container: WAContainer, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? { return nil }
    
    //WKNavigationDelegate
    func container(_ container: WAContainer, decidePolicyForAction navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }
    
    func container(_ container: WAContainer, didStartProvisionalNavigation navigation: WKNavigation!) { }
    
    func container(_ container: WAContainer, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { }
    
    func container(_ container: WAContainer, didCommit navigation: WKNavigation!) {  }
    
    func container(_ container: WAContainer, didFinish navigation: WKNavigation!) { }
    
    func container(_ container: WAContainer, didFail navigation: WKNavigation!, withError error: Error) { }
    
    func container(_ container: WAContainer, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) { }
    
    func container(_ container: WAContainer, decidePolicyForResponse navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Swift.Void) { }
    
    func containerWebContentProcessDidTerminate(_ container: WAContainer) {}
    
}
