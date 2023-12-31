//
//  WebViewScrollViewProxy.swift
//  SpaceKit
//
//  Created by 边俊林 on 2019/4/15.
//

import UIKit

public protocol EditorScrollViewProxy: AnyObject {
    var frame: CGRect { get set }
    var bounds: CGRect { get set }
    var contentOffset: CGPoint { get set }
    var contentSize: CGSize { get set }
    var contentInset: UIEdgeInsets { get set }
    var adjustedContentInset: UIEdgeInsets { get }
    var isDirectionalLockEnabled: Bool { get }
    var contentInsetAdjustmentBehavior: UIScrollView.ContentInsetAdjustmentBehavior { get set }
    var bounces: Bool { get set }
    var alwaysBounceVertical: Bool { get set }
    var alwaysBounceHorizontal: Bool { get set }
    var isPagingEnabled: Bool { get set }
    var isScrollEnabled: Bool { get set }
    var showsHorizontalScrollIndicator: Bool { get set }
    var showsVerticalScrollIndicator: Bool { get set }
    var scrollIndicatorInsets: UIEdgeInsets { get set }
    var isTracking: Bool { get }
    var isDragging: Bool { get }
    var isDecelerating: Bool { get }
    var scrollsToTop: Bool { get set }
    var keyboardDismissMode: UIScrollView.KeyboardDismissMode { get set }
    var clipsToBounds: Bool { get set }
    var isHidden: Bool { get set }
    var alpha: CGFloat { get set }
    var superview: UIView? { get }
    var subviews: [UIView] { get }
    var isBouncing: Bool { get }
    var isBouncingTop: Bool { get }
    var isBouncingLeft: Bool { get }
    var isBouncingBottom: Bool { get }
    var isBouncingRight: Bool { get }

    func setScrollView(_ scrollView: UIScrollView?)
    func getScrollView() -> UIScrollView?

    func addObserver(_ observer: EditorScrollViewObserver)

    func removeObserver(_ observer: EditorScrollViewObserver)

    func addGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer)

    func removeGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer)

    func setContentOffset(_ contentOffset: CGPoint, animated: Bool)

    func scrollRectToVisible(_ rect: CGRect, animated: Bool)

    func flashScrollIndicators()

    func isProxyEqual(_ editorViewScrollViewProxy: EditorScrollViewProxy) -> Bool
}
