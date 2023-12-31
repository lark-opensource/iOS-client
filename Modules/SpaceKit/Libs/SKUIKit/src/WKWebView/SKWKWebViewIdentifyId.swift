//
//  WKWebView+IdentifyId.swift
//  SKUIKit
//
//  Created by guoxinyi on 2022/6/1.
//

import Foundation
import WebKit

extension WKWebView {
    
    static var WKeditorIdentityKey = "WKeditorIdentityKey"
    
    public var editorIdentity: String? {
        
        get {
            return objc_getAssociatedObject(self, &WKWebView.WKeditorIdentityKey) as? String
        }
        set {
            objc_setAssociatedObject(self, &WKWebView.WKeditorIdentityKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
}
