//
//  LarkWebViewPreLoadDetector.swift
//  LarkWebViewContainer
//
//  Created by bytedance on 2022/12/20.
//

import UIKit

final class LarkWebViewPreLoadDetector: NSObject {
    public static let shared = LarkWebViewPreLoadDetector()
    var docsPreloadCount = 0
    var gadgetPreloadCount = 0
    var othersPreloadCount = 0
    var startDetect = false
    
    weak var baseWebview:LarkWebView?
    
    var webviewHasPreloaded:Bool {
        return (self.docsPreloadCount != 0 || self.gadgetPreloadCount != 0 || self.othersPreloadCount != 0)
    }
    
    public var preloadInfo:String {
        return "docs:\(docsPreloadCount),gadget:\(gadgetPreloadCount),others:\(othersPreloadCount)"
    }
    
    public func startDetect(webview:LarkWebView) {
        self.p_clearContext()
        self.baseWebview = webview
        self.startDetect = true
    }
    
    public func finishDetect() {
        self.p_clearContext()
    }
    
    @objc
    public func webviewMaybePreloaded(webview:LarkWebView) {
        guard self.startDetect == true else {
            return
        }
        guard webview != self.baseWebview else {
            return
        }
        let bizType = webview.config.bizType
        if (bizType == LarkWebViewBizType.docs) {
            self.docsPreloadCount += 1
        }else if (bizType == LarkWebViewBizType.gadget) {
            self.gadgetPreloadCount += 1
        }else {
            self.othersPreloadCount += 1
        }
    }
    
    //MARK: PrivateMethod
    private func p_clearContext() {
        self.docsPreloadCount = 0
        self.gadgetPreloadCount = 0
        self.othersPreloadCount = 0
        self.baseWebview = nil
        self.startDetect = false
    }
}
