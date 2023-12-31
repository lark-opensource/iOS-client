//
//  BrowserViewController+TemplatePreview.swift
//  SKBrowser
//
//  Created by 曾浩泓 on 2021/5/28.
//  


import SKFoundation
import SKCommon
import SKUIKit

extension BrowserViewController: TemplatePreviewBrowser {
    private struct AssociatedKeys {
        static var FromTemplatePreviewKey = "TemplatePreviewBrowser.FromTemplatePreviewKey"
        static var TemplatesPreviewNavigationBarDelegateKey = "TemplatePreviewBrowser.TemplatesPreviewNavigationBarDelegateKey"
    }
    
    public func templatePreviewBrowserLoad(url: URL) {
        self.browerEditor?.load(url: url)
    }
    
    public func templatePreviewDidClickDone() {
        onDoneBarButtonClick()
    }

    public func shouldTemplatePreviewBrowserOpen(url: URL) -> Bool {
        return false
    }
    public var isFromTemplatePreview: Bool {
        get {
            if let num = objc_getAssociatedObject(self, &AssociatedKeys.FromTemplatePreviewKey) as? NSNumber {
                return num.boolValue
            }
            return false
        }
        set {
            if newValue {
                topContainerState = .fixedShowing
            }
            objc_setAssociatedObject(self, &AssociatedKeys.FromTemplatePreviewKey, NSNumber(value: newValue), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    public var templatesPreviewNavigationBarDelegate: TemplatePreviewNavigationBarProtocol? {
        get {
            if let weakValue = objc_getAssociatedObject(self, &AssociatedKeys.TemplatesPreviewNavigationBarDelegateKey) as? Weak<AnyObject> {
                return weakValue.value as? TemplatePreviewNavigationBarProtocol
            }
            return nil
        }
        set {
            if let value = newValue {
                objc_setAssociatedObject(self, &AssociatedKeys.TemplatesPreviewNavigationBarDelegateKey, Weak<AnyObject>(value), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            } else {
                objc_setAssociatedObject(self, &AssociatedKeys.TemplatesPreviewNavigationBarDelegateKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
            
        }
    }
}
