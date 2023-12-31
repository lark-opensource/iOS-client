//
//  WebViewScrollViewProxyImpl.swift
//  SKBrowser
//
//  Created by lijuyou on 2020/7/14.
//  


import Foundation
import SKCommon
import SKFoundation

//From WebViewScrollViewProxy.swift
class WebViewScrollViewProxyImpl: NSObject, EditorScrollViewProxy, UIScrollViewDelegate {
    // MARK: External variables
    var frame: CGRect {
        get { return _scrollView?.frame ?? .zero }
        set { _scrollView?.frame = newValue }
    }
    var bounds: CGRect {
        get { return _scrollView?.bounds ?? .zero }
        set { _scrollView?.bounds = newValue }
    }
    var contentOffset: CGPoint {
        get { return _scrollView?.contentOffset ?? .zero }
        set { _scrollView?.contentOffset = newValue }
    }
    var contentSize: CGSize {
        get { return _scrollView?.contentSize ?? .zero }
        set { _scrollView?.contentSize = newValue }
    }
    var contentInset: UIEdgeInsets {
        get { return _scrollView?.contentInset ?? .zero }
        set { _scrollView?.contentInset = newValue }
    }
    var adjustedContentInset: UIEdgeInsets {
        return _scrollView?.adjustedContentInset ?? .zero
    }
    var isDirectionalLockEnabled: Bool {
        return _scrollView?.isDirectionalLockEnabled ?? false
    }
    var contentInsetAdjustmentBehavior: UIScrollView.ContentInsetAdjustmentBehavior {
        get { return _scrollView?.contentInsetAdjustmentBehavior ?? UIScrollView.ContentInsetAdjustmentBehavior.always }
        set { _scrollView?.contentInsetAdjustmentBehavior = newValue }
    }
    var bounces: Bool {
        get { return _scrollView?.bounces ?? false }
        set { _scrollView?.bounces = newValue }
    }
    var alwaysBounceVertical: Bool {
        get { return _scrollView?.alwaysBounceVertical ?? false }
        set { _scrollView?.alwaysBounceVertical = newValue }
    }
    var alwaysBounceHorizontal: Bool {
        get { return _scrollView?.alwaysBounceHorizontal ?? false }
        set { _scrollView?.alwaysBounceHorizontal = newValue }
    }
    var isPagingEnabled: Bool {
        get { return _scrollView?.isPagingEnabled ?? false }
        set { _scrollView?.isPagingEnabled = newValue }
    }
    var isScrollEnabled: Bool {
        get { return _scrollView?.isScrollEnabled ?? false }
        set { _scrollView?.isScrollEnabled = newValue }
    }
    var showsHorizontalScrollIndicator: Bool {
        get { return _scrollView?.showsHorizontalScrollIndicator ?? false }
        set { _scrollView?.showsHorizontalScrollIndicator = newValue }
    }
    var showsVerticalScrollIndicator: Bool {
        get { return _scrollView?.showsVerticalScrollIndicator ?? false }
        set { _scrollView?.showsVerticalScrollIndicator = newValue }
    }
    var scrollIndicatorInsets: UIEdgeInsets {
        get { return _scrollView?.scrollIndicatorInsets ?? .zero }
        set { _scrollView?.scrollIndicatorInsets = newValue }
    }
    var isTracking: Bool {
        return _scrollView?.isTracking ?? false
    }
    var isDragging: Bool {
        return _scrollView?.isDragging ?? false
    }
    var isDecelerating: Bool {
        return _scrollView?.isDecelerating ?? false
    }
    var scrollsToTop: Bool {
        get { return _scrollView?.scrollsToTop ?? false }
        set { _scrollView?.scrollsToTop = newValue }
    }
    var keyboardDismissMode: UIScrollView.KeyboardDismissMode {
        get { return _scrollView?.keyboardDismissMode ?? .none }
        set { _scrollView?.keyboardDismissMode = newValue }
    }
    var clipsToBounds: Bool {
        get { return _scrollView?.clipsToBounds ?? false }
        set { _scrollView?.clipsToBounds = newValue }
    }
    var isHidden: Bool {
        get { return _scrollView?.isHidden ?? false }
        set { _scrollView?.isHidden = newValue }
    }
    var alpha: CGFloat {
        get { return _scrollView?.alpha ?? 0.0 }
        set { _scrollView?.alpha = newValue }
    }
    var superview: UIView? {
        return _scrollView?.superview
    }
    var subviews: [UIView] {
        return _scrollView?.subviews ?? []
    }
    var isBouncing: Bool {
        return isBouncingTop || isBouncingLeft || isBouncingBottom || isBouncingRight
    }
    var isBouncingTop: Bool {
        return contentOffset.y < -contentInset.top
    }
    var isBouncingLeft: Bool {
        return contentOffset.x < -contentInset.left
    }
    var isBouncingBottom: Bool {
        let contentFillsScrollEdges = contentSize.height + contentInset.top + contentInset.bottom >= bounds.height
        return contentFillsScrollEdges && contentOffset.y > contentSize.height - bounds.height + contentInset.bottom
    }
    var isBouncingRight: Bool {
        let contentFillsScrollEdges = contentSize.width + contentInset.left + contentInset.right >= bounds.width
        return contentFillsScrollEdges && contentOffset.x > contentSize.width - bounds.width + contentInset.right
    }

    // MARK: Internal Variables
    var observers: ObserverContainer = ObserverContainer<EditorScrollViewObserver>()
    private weak var _scrollView: UIScrollView?

    // MARK: External Method
    func setScrollView(_ scrollView: UIScrollView?) {
        _scrollView = scrollView
    }

    func getScrollView() -> UIScrollView? {
        return _scrollView
    }

    func isProxyEqual(_ editorViewScrollViewProxy: EditorScrollViewProxy) -> Bool {
        guard let proxyImpl = editorViewScrollViewProxy as? WebViewScrollViewProxyImpl else { return false }
        return _scrollView == proxyImpl._scrollView
    }

    func addObserver(_ observer: EditorScrollViewObserver) {
        observers.add(observer)
    }

    func removeObserver(_ observer: EditorScrollViewObserver) {
        observers.remove(observer)
    }

    func addGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        _scrollView?.addGestureRecognizer(gestureRecognizer)
    }

    func removeGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        _scrollView?.removeGestureRecognizer(gestureRecognizer)
    }

    func setContentOffset(_ contentOffset: CGPoint, animated: Bool) {
        _scrollView?.setContentOffset(contentOffset, animated: animated)
    }

    func scrollRectToVisible(_ rect: CGRect, animated: Bool) {
        _scrollView?.scrollRectToVisible(rect, animated: animated)
    }

    func flashScrollIndicators() {
        _scrollView?.flashScrollIndicators()

    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        observers.all.forEach {
            $0.editorViewScrollViewDidScroll(self)
        }
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        observers.all.forEach {
            $0.editorViewScrollViewDidZoom(self)
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        observers.all.forEach {
            $0.editorViewScrollViewWillBeginDragging(self)
        }
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        observers.all.forEach {
            $0.editorViewScrollViewWillEndDragging(self, withVelocity: velocity, targetContentOffset: targetContentOffset)
        }
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        observers.all.forEach {
            $0.editorViewScrollViewDidEndDragging(self, willDecelerate: decelerate)
        }
    }

    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        observers.all.forEach {
            $0.editorViewScrollViewWillBeginDecelerating(self)
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        observers.all.forEach {
            $0.editorViewScrollViewDidEndDecelerating(self)
        }
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        observers.all.forEach {
            $0.editorViewScrollViewDidEndScrollingAnimation(self)
        }
    }

    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        observers.all.forEach {
            $0.editorViewScrollViewWillBeginZooming(self, with: view)
        }
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        DocsLogger.info("webview end zooming to:\(scale)")
        observers.all.forEach {
            $0.editorViewScrollViewDidEndZooming(self, with: view, atScale: scale)
        }
    }

    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        observers.all.forEach {
            $0.editorViewScrollViewWillScrollToTop(self)
        }
        return true
    }
    
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        observers.all.forEach {
            $0.editorViewScrollViewDidScrollToTop(self)
        }
    }

}

class WebViewNoZoomScrollViewProxyImpl: WebViewScrollViewProxyImpl {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        //https://blog.csdn.net/abel_tu/article/details/12134261
        //增加双击编辑后，会触发webview的双击缩放手势导致多余的滚动
        return nil
    }
}
