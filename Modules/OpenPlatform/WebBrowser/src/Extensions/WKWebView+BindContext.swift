//
//  WKWebView+BindContext.swift
//  WebBrowser
//
//  Created by yinyuan on 2022/5/9.
//

import Foundation
import WebKit

extension WKWebView {
    
    private class WeakWebBrowser {
        private(set) weak var value : WebBrowser?
        init (_ value: WebBrowser) {
            self.value = value
        }
    }
    
    private static var _wkBindWebBrowserKey: Void?
    
    public internal(set) var wkWeakBindWebBrowser: WebBrowser? {
        get {
            let weakWrapper =  objc_getAssociatedObject(self, &WKWebView._wkBindWebBrowserKey) as? WeakWebBrowser
            return weakWrapper?.value
        }
        set {
            let weakWrapper: WeakWebBrowser?
            if let value = newValue {
                weakWrapper = WeakWebBrowser(value)
            } else {
                weakWrapper = nil
            }
            objc_setAssociatedObject(self, &WKWebView._wkBindWebBrowserKey, weakWrapper, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
}
