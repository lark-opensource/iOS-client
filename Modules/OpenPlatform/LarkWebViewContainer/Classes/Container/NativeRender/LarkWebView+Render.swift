//
//  LarkWebView+Native.swift
//  WKWebViewContainer
//
//  Created by tefeng liu on 2020/9/14.
//
//  docs: https://bytedance.feishu.cn/docs/doccn68nnWFQ7IZGwksOLRtpSkd
//

import Foundation
import UIKit
import WebKit

// MARK: interface impletation
extension LarkWebView: LarkWebNativeRenderInterface {
    public func insertComponent(view: UIView, atIndex index: String, completion: ((Bool) -> Void)?) {
        // if object has been inserted. ignore it
        if let obj = renderObjs[index] {
            if obj.scrollView != nil {
                completion?(true)
                return
            }
        }

        attachWebScrollView(index: index, tryCount: 0) { [weak self] scroll in
            guard let self = self else {
                completion?(false)
                return
            }

            guard let scrollView = scroll else {
                completion?(false)
                return
            }

            let obj = NativeRenderObj()
            obj.scrollView = scrollView
            obj.nativeView = view
            obj.viewId = index
            obj.webview = self
            self.renderObjs[index] = obj

            scrollView.setContentOffset(CGPoint.zero, animated: false)
            scrollView.lkw_renderObject = obj
            var frame = view.frame
            frame.origin = CGPoint.zero
            frame.size = scrollView.frame.size
            view.frame = frame
            scrollView.addSubview(view)
            
            self.renderFixManager.hook(nativeView: view, superview: scrollView)

            // 添加size大小修改时的回调监听，将让native视图组件与scrollview大小保持一致。
            scrollView.lkwContentSizeObservation = scrollView.observe(\.contentSize,
                                                                      options: [.new, .old]) { [weak view, weak scrollView] _, change in
                if change.newValue != nil, let strongScrollView = scrollView {
                    view?.frame = strongScrollView.bounds
                }
            }

            self.lkw_hook()
            completion?(true)
        }
    }

    public func removeComponent(index: String) -> Bool {
        if let obj = renderObjs[index] {
            obj.nativeView?.removeFromSuperview()
            renderObjs.removeValue(forKey: index)
            return true
        }

        return false
    }

    public func component(fromIndex index: String) -> UIView? {
        let obj = renderObjs[index]
        return obj?.nativeView
    }
}

// MARK: render
extension LarkWebView {
    @objc public func renderAgain(index: String) {
        if let obj = renderObjs[index], let nativeView = obj.nativeView {
            insertComponent(view: nativeView, atIndex: obj.viewId, completion: nil)
        }
    }
}

// MARK: scrollview getter
extension LarkWebView {
    func attachWebScrollView(index: String, tryCount: Int, completion: (@escaping (UIScrollView?) -> Void)) {
        var count = tryCount
        let scroll = findScrollViews(view: scrollView, index: index)
        if scroll != nil {
            scroll?.isScrollEnabled = false
            completion(scroll)
        } else if count < 20 {
            // stupid code. retry :P
            count += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + .nanoseconds(count * 4 * 1000000)) { [weak self] in
                self?.attachWebScrollView(index: index, tryCount: count, completion: completion)
            }
        } else {
            completion(nil)
        }
    }

    func attachWebScrollView(index: String) -> UIView? {
        let view = findScrollViews(view: scrollView, index: index)
        view?.isScrollEnabled = false
        return view
    }

    func findScrollViews(view: UIView, index: String) -> UIScrollView? {
        if let scroll = view as? UIScrollView, view != self.scrollView {
            if calNativeView(index: index, scrollView: scroll) {
                return scroll
            }
        }

        for subview in view.subviews {
            if let ret = findScrollViews(view: subview, index: index) {
                return ret
            }
        }
        return nil
    }

    func findWebContentView(webview: UIView) -> UIView? {
        if let targetClass = NSClassFromString("WKContentView"), webview.isKind(of: targetClass) {
            return webview
        }

        for subview in webview.subviews {
            if let view = findWebContentView(webview: subview) {
                return view
            }
        }

        return nil
    }

    func calNativeView(index: String, scrollView: UIScrollView) -> Bool {
        if let superview = scrollView.superview,
            let targetClass = NSClassFromString("WKCompositingView"),
            superview.isKind(of: targetClass),
            let subLayers = superview.layer.sublayers
            {

            /*
             backgroundcolor layer 不一定总是在第一层
             如在文档场景，在iPad宽屏模式下全屏文档视图，渲染插入失败，找不到同层view，会出现同层白屏。web元素宽度写死不会有问题。
             原因是 在宽屏放大后，dom元素层级没有变，但是同层标记view 的layer 发生了非预期的变化，导致之前查找逻辑失效。
             小程序之前没有遇到这个问题是因为 同层标记view还在，因为没有发生hidden 的rerender操作，所以不会出问题。
             native在最后一层查找view的时候,只去拿第一个layer去对比backgroud，从而找不到
             */
            for layer in subLayers {
                if let color = layer.backgroundColor, let components = color.components, components.count >= 4 {
                    let red = (components[0] * 255).toHex()
                    let green = (components[1] * 255).toHex()
                    let blue = (components[2] * 255).toHex()
                    let alpha = (components[3] * 255).toHex()

                    if alpha == "01" {
                        let viewId = "\(red)\(green)\(blue)"
                        return index.lowercased() == viewId.lowercased()
                    }
                }
            }
        }
        return false
    }
}

// MARK: - LarkWebView + FG
private var kNativeComponentDOMChangeFocusFixFG: Void?
extension LarkWebView {
    
    // gadget.native_component.dom_change_focus_fix
    public var renderFixManager: RenderFixManager {
        get {
            if let manager = objc_getAssociatedObject(self, &kNativeComponentDOMChangeFocusFixFG) as? RenderFixManager {
                return manager
            } else {
                let manager = RenderFixManager()
                objc_setAssociatedObject(self, &kNativeComponentDOMChangeFocusFixFG, manager, .OBJC_ASSOCIATION_RETAIN)
                return manager
            }
        }
    }
}

// MARK: - CGFloat

extension CGFloat {
    func toHex() -> String {
        var res = String(format: "%0X", Int(self))
        if res.count == 1 {
            res = "0\(res)"
        }
        return res
    }
}
