//
//  LarkWebView+ContentView.swift
//  LarkWebViewContainer
//
//  Created by lijuyou on 2020/9/29.
//  

import Foundation

private var innerContentViewKey: UInt8 = 0

public extension LarkWebView {
    /// 获取WKContentView
    @objc var contentView: UIView? {
        if let view = objc_getAssociatedObject(self, &innerContentViewKey) as? UIView {
            return view
        }
        guard let wkContentViewClass = NSClassFromString("WKContentView") else { assertionFailure(); return nil }
        for view in self.scrollView.subviews {
            if view.isKind(of: wkContentViewClass) {
                objc_setAssociatedObject(self, &innerContentViewKey, view, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return view
            }
        }
        return nil
    }

    /// 自定义的WKContentView类
    var contentViewNickClass: AnyClass? {
        let name = "WKContentView_uj73d9f3d"
        var cls: AnyClass? = NSClassFromString(name)
        if cls == nil,
            let contentView = self.contentView,
            let newCls = objc_allocateClassPair(type(of: contentView).self, name, 0) {
            objc_registerClassPair(newCls)
            cls = newCls
        }
        return cls
    }
}
