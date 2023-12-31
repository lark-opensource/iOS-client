//
//  DayInstanceEditViewController+Animator.swift
//  Calendar
//
//  Created by 张威 on 2020/9/28.
//

import UIKit
import Foundation

/// DayScene - InstanceEdit - ViewController: Animator
/// 处理拖拽日程块时，ContainerView 和 PageView 的交互动画（滚动）

extension DayInstanceEditViewController {

    typealias ContainerViewWillScrollContext = (fromOffsetY: CGFloat, toOffsetY: CGFloat)

    /// 处理 containerView 的纵向 scrolling
    final class ContainerViewScrollAnimator {
        let targetView: UIScrollView

        private var displayLink: CADisplayLink?
        private var beginContext: (timestamp: CFTimeInterval, offsetY: CGFloat)?
        private var targetOffset: CGFloat = 0.0
        private var duration: TimeInterval = 0.25
        private var alongside: ((ContainerViewWillScrollContext) -> Void)?

        init(targetView: UIScrollView) {
            self.targetView = targetView
        }

        deinit {
            displayLink?.invalidate()
        }

        /// Scroll targetView to top
        ///
        /// - Parameters:
        ///   - duration: 动画时长
        ///   - alongside: 跟随动画执行的 closure
        /// - Returns: `false` 表示已处于 top
        @discardableResult
        func scrollToTop(
            duration: TimeInterval = 0.25,
            alongside: ((ContainerViewWillScrollContext) -> Void)? = nil
        ) -> Bool {
            guard !isAtTop() else { return false }
            scroll(to: offsetAtTop(), duration: duration, alongside: alongside)
            return true
        }

        /// Scroll targetView to bottom
        ///
        /// - Parameters:
        ///   - duration: 动画时长
        ///   - alongside: 跟随动画执行的 closure
        /// - Returns: `false` 表示已处于 bottom
        @discardableResult
        func scrollToBottom(
            duration: TimeInterval = 0.25,
            alongside: ((ContainerViewWillScrollContext) -> Void)? = nil
        ) -> Bool {
            guard !isAtBottom() else { return false }
            scroll(to: offsetAtBottom(), duration: duration, alongside: alongside)
            return true
        }

        /// 结束动画
        func pause() {
            displayLink?.isPaused = true
            beginContext = nil
        }

        private func scroll(
            to offsetY: CGFloat,
            duration: TimeInterval = 0.25,
            alongside: ((ContainerViewWillScrollContext) -> Void)? = nil
        ) {
            if displayLink == nil {
                displayLink = CADisplayLink(target: self, selector: #selector(updateContentOffset))
                displayLink?.add(to: .main, forMode: .common)
            }
            self.duration = duration
            self.alongside = alongside
            targetOffset = min(max(offsetAtTop(), offsetY), offsetAtBottom())
            displayLink?.isPaused = false
        }

        @objc
        private func updateContentOffset() {
            guard let displayLink = displayLink else { return }
            if beginContext == nil {
                beginContext = (displayLink.timestamp, targetView.contentOffset.y)
            }
            let progress = (displayLink.timestamp - beginContext!.timestamp) / duration
            if progress < 1.0 {
                let deltaOffset = targetOffset - beginContext!.offsetY
                var contentOffset = targetView.contentOffset
                contentOffset.y = beginContext!.offsetY + CGFloat(progress) * deltaOffset
                let fromOffsetY = targetView.contentOffset.y
                alongside?((fromOffsetY, contentOffset.y))
                targetView.contentOffset = contentOffset
            } else {
                var contentOffset = targetView.contentOffset
                contentOffset.y = targetOffset
                let fromOffsetY = targetView.contentOffset.y
                alongside?((fromOffsetY, contentOffset.y))
                targetView.contentOffset = contentOffset
                pause()
            }
        }

        private func isAtTop() -> Bool {
            return targetView.contentOffset.y <= offsetAtTop() + 0.1
        }

        private func offsetAtTop() -> CGFloat {
            return 0 - targetView.contentInset.top
        }

        private func isAtBottom() -> Bool {
            return targetView.contentOffset.y >= offsetAtBottom() - 0.1
        }

        private func offsetAtBottom() -> CGFloat {
            return targetView.contentSize.height + targetView.contentInset.bottom - targetView.bounds.height
        }
    }
}

extension DayInstanceEditViewController {

    /// 处理 pageView 的 paging
    final class PageViewPagingAnimator {
        let targetView: PageView
        private(set) var isAnimating = false

        private var displayLink: CADisplayLink?
        private var beginContext: (timestamp: CFTimeInterval, pageOffset: PageOffset)?
        private var targetOffset: PageOffset = 0.0
        private let duration = TimeInterval(0.4)

        init(targetView: PageView) {
            self.targetView = targetView
        }

        deinit {
            displayLink?.invalidate()
        }

        /// Paging 到上一页
        func pageToPrev() {
            scroll(to: round(targetView.pageOffset - 1))
        }

        /// Paging 到下一页
        func pageToNext() {
            scroll(to: round(targetView.pageOffset + 1))
        }

        /// 获取当前动画未完成的时间
        /// - Returns: 描述当前动画还剩余的时间，`nil` 表示当前没有动画
        func currentAnimationLeftDuration() -> TimeInterval? {
            guard let beginContext = beginContext,
                let displayLink = displayLink else {
                return nil
            }
            let leftDuration = duration - (displayLink.timestamp - beginContext.timestamp)
            return max(min(duration, leftDuration), 0)
        }

        private func scroll(to pageOffset: PageOffset) {
            if displayLink == nil {
                displayLink = CADisplayLink(target: self, selector: #selector(updatePageOffset))
                displayLink?.add(to: .main, forMode: .common)
            }
            targetOffset = pageOffset
            displayLink?.isPaused = false
            isAnimating = true
        }

        private func pause() {
            displayLink?.isPaused = true
            beginContext = nil
            isAnimating = false
        }

        @objc
        private func updatePageOffset() {
            guard let displayLink = displayLink else { return }
            if beginContext == nil {
                beginContext = (displayLink.timestamp, targetView.pageOffset)
            }
            let progress = (displayLink.timestamp - beginContext!.timestamp) / duration
            if progress < 1.0 {
                let deltaOffset = targetOffset - beginContext!.pageOffset
                let targetOffset = beginContext!.pageOffset + CGFloat(progress) * deltaOffset
                targetView.scroll(to: targetOffset)
            } else {
                targetView.scroll(to: targetOffset)
                pause()
            }
        }

    }

}
