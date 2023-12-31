//
//  WebViewScrollViewObserver.swift
//  SpaceKit
//
//  Created by 边俊林 on 2019/4/15.
//

import UIKit

public protocol EditorScrollViewObserver: AnyObject {
    func editorViewScrollViewDidScroll(_ editorViewScrollViewProxy: EditorScrollViewProxy)

    func editorViewScrollViewDidZoom(_ editorViewScrollViewProxy: EditorScrollViewProxy)

    func editorViewScrollViewWillBeginDragging(_ editorViewScrollViewProxy: EditorScrollViewProxy)

    func editorViewScrollViewWillEndDragging(_ editorViewScrollViewProxy: EditorScrollViewProxy, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>)

    func editorViewScrollViewDidEndDragging(_ editorViewScrollViewProxy: EditorScrollViewProxy, willDecelerate decelerate: Bool)

    func editorViewScrollViewWillBeginDecelerating(_ editorViewScrollViewProxy: EditorScrollViewProxy)

    func editorViewScrollViewDidEndDecelerating(_ editorViewScrollViewProxy: EditorScrollViewProxy)

    func editorViewScrollViewDidEndScrollingAnimation(_ editorViewScrollViewProxy: EditorScrollViewProxy)

    func editorViewScrollViewWillBeginZooming(_ editorViewScrollViewProxy: EditorScrollViewProxy, with view: UIView?)

    func editorViewScrollViewDidEndZooming(_ editorViewScrollViewProxy: EditorScrollViewProxy, with view: UIView?, atScale scale: CGFloat)
    
    func editorViewScrollViewWillScrollToTop(_ editorViewScrollViewProxy: EditorScrollViewProxy)
    
    func editorViewScrollViewDidScrollToTop(_ editorViewScrollViewProxy: EditorScrollViewProxy)
}
public extension EditorScrollViewObserver {
    func editorViewScrollViewDidScroll(_ editorViewScrollViewProxy: EditorScrollViewProxy) {}
    func editorViewScrollViewDidZoom(_ editorViewScrollViewProxy: EditorScrollViewProxy) {}
    func editorViewScrollViewWillBeginDragging(_ editorViewScrollViewProxy: EditorScrollViewProxy) {}
    func editorViewScrollViewWillEndDragging(_ editorViewScrollViewProxy: EditorScrollViewProxy, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {}
    func editorViewScrollViewDidEndDragging(_ editorViewScrollViewProxy: EditorScrollViewProxy, willDecelerate decelerate: Bool) {}
    func editorViewScrollViewWillBeginDecelerating(_ editorViewScrollViewProxy: EditorScrollViewProxy) {}
    func editorViewScrollViewDidEndDecelerating(_ editorViewScrollViewProxy: EditorScrollViewProxy) {}
    func editorViewScrollViewDidEndScrollingAnimation(_ editorViewScrollViewProxy: EditorScrollViewProxy) {}
    func editorViewScrollViewWillBeginZooming(_ editorViewScrollViewProxy: EditorScrollViewProxy, with view: UIView?) {}
    func editorViewScrollViewDidEndZooming(_ editorViewScrollViewProxy: EditorScrollViewProxy, with view: UIView?, atScale scale: CGFloat) {}
    func editorViewScrollViewWillScrollToTop(_ editorViewScrollViewProxy: EditorScrollViewProxy) {}
    func editorViewScrollViewDidScrollToTop(_ editorViewScrollViewProxy: EditorScrollViewProxy) {}
}

//@objc protocol CRWWebViewScrollViewProxyObserver: WebViewScrollViewObserver {
//    @objc
//    optional func webViewScrollViewProxyDidSetScrollView(_ webViewScrollViewProxy: WebViewScrollViewProxy)
//}
