//
//  WAContainerLifeCycle.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/11/14.
//

import Foundation
import WebKit
import SKFoundation

public final class WAContainerLifeCycleObserver: NSObject {
    let listeners = ObserverContainer<WAContainerLifeCycleListener>()
    
    public func addListener(_ listener: WAContainerLifeCycleListener) {
        listeners.add(listener)
    }
    
    public func removeListener(_ listener: WAContainerLifeCycleListener) {
        listeners.remove(listener)
    }
    
    public func removeAll() {
        listeners.removeAll()
    }
}

//MARK: WAContainerVCLifeCycle
extension WAContainerLifeCycleObserver {
    func containerViewDidLoad() {
        let allListeners = listeners.all
        for listener in allListeners {
            listener.containerViewDidLoad()
        }
    }
    
    func containerWillAppear() {
        let allListeners = listeners.all
        for listener in allListeners {
            listener.containerWillAppear()
        }
    }
    
    func containerDidAppear() {
        let allListeners = listeners.all
        for listener in allListeners {
            listener.containerDidAppear()
        }
    }
    
    func containerWillDisappear() {
        let allListeners = listeners.all
        for listener in allListeners {
            listener.containerWillDisappear()
        }
    }
    
    func containerDidDisappear() {
        let allListeners = listeners.all
        for listener in allListeners {
            listener.containerDidDisappear()
        }
    }
    
    func containerWillTransition(from: CGSize, to: CGSize) {
        let allListeners = listeners.all
        for listener in allListeners {
            listener.containerWillTransition(from: from, to: to)
        }
    }
    
    func containerDidTransition(from: CGSize, to: CGSize) {
        let allListeners = listeners.all
        for listener in allListeners {
            listener.containerDidTransition(from: from, to: to)
        }
    }
    
    func containerDidSplitModeChange() {
        let allListeners = listeners.all
        for listener in allListeners {
            listener.containerDidSplitModeChange()
        }
    }
    
    func containerWillChangeOrientation(from: UIInterfaceOrientation, to: UIInterfaceOrientation) {
        let allListeners = listeners.all
        for listener in allListeners {
            listener.containerWillChangeOrientation(from: from, to: to)
        }
    }
    
    func containerDidChangeOrientation(from: UIInterfaceOrientation, to: UIInterfaceOrientation) {
            let allListeners = listeners.all
            for listener in allListeners {
                listener.containerDidChangeOrientation(from: from, to: to)
            }
    }
    
    func containerAttachToPage() {
        let allListeners = listeners.all
        for listener in allListeners {
            listener.containerAttachToPage()
        }
    }
    
    func containerDettachFromPage() {
        let allListeners = listeners.all
        for listener in allListeners {
            listener.containerDettachFromPage()
        }
    }
}

//MARK: WAContainerLoaderLifeCycle
extension WAContainerLifeCycleObserver {
    func container(_ container: WAContainer, onChangeUrl url: URL) {
        let allListeners = listeners.all
        for listener in allListeners {
            listener.container(container, onChangeUrl: url)
        }
    }
}

//MARK: WKNavigationDelegate
extension WAContainerLifeCycleObserver {
    func container(_ container: WAContainer, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
//        guard let webView = container.hostWebView else { return }
        var actionPolicy = WKNavigationActionPolicy.allow
        let allListeners = listeners.all
        for listener in allListeners {
            listener.container(container, decidePolicyForAction: navigationAction) { policy in
                if policy != .allow {
                    actionPolicy = policy
                }
            }
            //出现cancel后直接中断
            if actionPolicy != .allow {
                break
            }
        }
        decisionHandler(actionPolicy)
    }
    
    func container(_ container: WAContainer, didStartProvisionalNavigation navigation: WKNavigation!) {
        let allListeners = listeners.all
        for listener in allListeners {
             listener.container(container, didStartProvisionalNavigation: navigation)
        }
    }
    
    func container(_ container: WAContainer, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let allListeners = listeners.all
        for listener in allListeners {
             listener.container(container, didFailProvisionalNavigation: navigation, withError: error)
        }
    }
    
    func container(_ container: WAContainer, didCommit navigation: WKNavigation!) {
        let allListeners = listeners.all
        for listener in allListeners {
             listener.container(container, didCommit: navigation)
        }
    }
    
    func container(_ container: WAContainer, didFinish navigation: WKNavigation!) {
        let allListeners = listeners.all
        for listener in allListeners {
             listener.container(container, didFinish: navigation)
        }
    }
    
    func container(_ container: WAContainer, didFail navigation: WKNavigation!, withError error: Error) {
        let allListeners = listeners.all
        for listener in allListeners {
             listener.container(container, didFail: navigation, withError: error)
        }
    }
    
    func container(_ container: WAContainer, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        let allListeners = listeners.all
        for listener in allListeners {
             listener.container(container, didReceiveServerRedirectForProvisionalNavigation: navigation)
        }
    }
    
    func container(_ container: WAContainer, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Swift.Void) {
        var actionPolicy = WKNavigationResponsePolicy.allow
        let allListeners = listeners.all
        for listener in allListeners {
             listener.container(container, decidePolicyForResponse: navigationResponse) { policy in
                if policy != .allow {
                    actionPolicy = policy
                }
            }
            //出现cancel后直接中断
            if actionPolicy != .allow {
                break
            }
        }
        decisionHandler(actionPolicy)
    }
    
    func containerWebContentProcessDidTerminate(_ container: WAContainer) {
        let allListeners = listeners.all
        for listener in allListeners {
            listener.containerWebContentProcessDidTerminate(container)
        }
    }
}


extension WAContainerLifeCycleObserver {
    func container(_ container: WAContainer, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        let allListeners = listeners.all
        for listener in allListeners {
            let view = listener.container(container,
                                           createWebViewWith: configuration,
                                           for: navigationAction,
                                           windowFeatures: windowFeatures)
            if view != nil {
                return view //某一个不为nil即返回
            }
        }
        return nil
    }
}
