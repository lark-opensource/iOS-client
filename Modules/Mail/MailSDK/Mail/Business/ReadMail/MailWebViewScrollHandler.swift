//
//  MailWebViewScrollHandler.swift
//  MailSDK
//
//  Created by zhaoxiongbin on 2021/4/8.
//

import Foundation
import UIKit
import WebKit

/// 为 WKScrollVIew 内滑动区域添加 pan 手势，实现滑动到边缘时停止滑动，让上层页面响应滑动
class MailWebViewScrollHandler: NSObject, UIGestureRecognizerDelegate {
    private let wkChildScrollViewClassNamePrefix = "<WKChildScrollView"
    private weak var _webView: WKWebView?

    func handleWebView(_ webView: WKWebView, shouldRetry: Bool = true) {
        _webView = webView
        var childScrollViews = [UIScrollView]()
        self.findAllWKChildScrollViews(webView, result: &childScrollViews)
        if childScrollViews.count > 0 {
            childScrollViews.forEach { handleWKScrollView($0) }
        } else if shouldRetry {
            DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.normal) { [weak self, weak webView] in
                guard let self = self, let webView = webView else { return }
                self.handleWebView(webView, shouldRetry: false)
            }
        }
    }

    func handleWKScrollView(_ scrollView: UIScrollView) {
        guard checkScrollViewNeedHandle(scrollView) else {
            return
        }
        scrollView.bounces = false
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.panGestureRecognizerAction(gestureRecognizer:)))
        panGesture.delegate = self
        scrollView.addGestureRecognizer(panGesture)
    }

    private var startOffsetX = [UIPanGestureRecognizer: CGFloat]()
    @objc
    func panGestureRecognizerAction(gestureRecognizer: UIPanGestureRecognizer) {
        if let wkChildScrollView = gestureRecognizer.view as? UIScrollView {
            switch gestureRecognizer.state {
            case .began, .changed, .possible:
                if gestureRecognizer.state == .began {
                    // 记录开始时的offsetX
                    startOffsetX[gestureRecognizer] = wkChildScrollView.contentOffset.x
                }
                break
            case .ended, .cancelled, .failed:
                if gestureRecognizer.state == .ended, let startX = startOffsetX[gestureRecognizer] {
                    //滑动结束，打点
                    let deltaX = Int(wkChildScrollView.contentOffset.x - startX)
                    let width = Int(wkChildScrollView.contentSize.width)
                    _webView?.evaluateJavaScript("window.trackForScroll(\(deltaX),\(width))")
                }
                startOffsetX[gestureRecognizer] = nil
                
                if !wkChildScrollView.panGestureRecognizer.isEnabled {
                    // 手势结束时，重新开启wkscrollView的滑动手势，避免用户下次操作无法滑动
                    wkChildScrollView.panGestureRecognizer.isEnabled = true
                }
            @unknown default:
                return
            }
        }
    }

    // MARK: private
    private func checkScrollViewNeedHandle(_ scrollView: UIScrollView) -> Bool {
        // 只处理可左右滑动的 scrollView，避免上下滑动卡顿，如:翻译的滚动页面
        let canHorizontalScroll = scrollView.contentSize.width > scrollView.bounds.width
        if canHorizontalScroll,
           String(describing: scrollView).starts(with: wkChildScrollViewClassNamePrefix),
           scrollView.gestureRecognizers?.contains(where: { $0.delegate === self }) != true,
           scrollView.subviews.contains(where: { $0.isKind(of: NativeAvatarComponent.self) != true }) {
            return true
        } else {
            return false
        }
    }

    private func findAllWKChildScrollViews(_ v: UIView, result: inout [UIScrollView]) {
        for subView in v.subviews {
            if let wkChildScrollView = subView as? UIScrollView,
               String(describing: wkChildScrollView).starts(with: wkChildScrollViewClassNamePrefix),
               wkChildScrollView.gestureRecognizers?.contains(where: { $0.delegate === self }) != true,
               wkChildScrollView.subviews.contains(where: { $0.isKind(of: NativeAvatarComponent.self) != true }) {
                result.append(wkChildScrollView)
            }
            findAllWKChildScrollViews(subView, result: &result)
        }
    }

    // MARK: UIGestureRecognizerDelegate
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let gestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer,
           let wkChildScrollView = gestureRecognizer.view as? UIScrollView,
           String(describing: wkChildScrollView).starts(with: wkChildScrollViewClassNamePrefix) {
            let translation = gestureRecognizer.translation(in: wkChildScrollView)
            var shouldEnablePan = true
            if (translation.x < 0 && wkChildScrollView.contentOffset.x >= wkChildScrollView.contentSize.width - wkChildScrollView.bounds.width) /// 向右滑，且到达右边缘
                || (translation.x > 0 && wkChildScrollView.contentOffset.x <= 0) /// 向左滑，且到达左边缘
            {
                // 到达左右边缘时，关闭wkScrollView的滑动手势，停止识别滑动
                shouldEnablePan = false
            }

            if wkChildScrollView.panGestureRecognizer.isEnabled != shouldEnablePan {
                wkChildScrollView.panGestureRecognizer.isEnabled = shouldEnablePan
            }
        }
        return true
    }
}
