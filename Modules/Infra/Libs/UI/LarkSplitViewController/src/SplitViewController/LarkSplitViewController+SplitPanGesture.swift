//
//  SplitViewController+SplitPanGesture.swift
//  SplitViewControllerDemo
//
//  Created by Yaoguoguo on 2022/8/18.
//

import AnimatedTabBar
import Foundation
import UIKit

final class LarkSplitPanGestureRecognizer: UIPanGestureRecognizer {

    var touchBeginPoint: CGPoint?

    var translation: CGPoint? {
        guard let startPoint = self.touchBeginPoint,
            let gestureView = self.view else {
            return nil
        }
        let location = self.location(in: gestureView)
        return CGPoint(
            x: location.x - startPoint.x,
            y: location.y - startPoint.y
        )
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        self.touchBeginPoint = self.location(in: self.view)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        self.touchBeginPoint = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        self.touchBeginPoint = nil
    }

    @available(iOS 13.4, *)
    override func shouldReceive(_ event: UIEvent) -> Bool {
        self.touchBeginPoint = nil
        return super.shouldReceive(event)
    }
}

extension SplitViewController {
    /// 全屏手势的响应方法
    @objc
    func handlePan(ges: UIPanGestureRecognizer) {

        let location = ges.location(in: self.view)
        let velocity = ges.velocity(in: self.view)
        let realLocationX = location.x - panStartLocationX

        switch ges.state {
        case .began:
            Self.logger.info("SplitViewControllerLog/api/handlePan began")

            self.delegate?.splitViewControllerInteractivePresentationGestureWillBegin(self)
            for proxy in self.proxies.allObjects as? [SplitViewControllerProxy] ?? [] {
                proxy.splitViewControllerInteractivePresentationGestureWillBegin(self)
            }
            panGestureBegin(ges, location: location, velocity: velocity)
        case .changed:
            panGestureChanged(ges, realLocationX: realLocationX, location: location)
        case .cancelled, .ended, .failed:
            Self.logger.info("SplitViewControllerLog/api/handlePan ended")
            panGestureEnded(realLocationX: realLocationX, velocity: velocity)
            self.delegate?.splitViewControllerInteractivePresentationGestureDidEnd(self)
            for proxy in self.proxies.allObjects as? [SplitViewControllerProxy] ?? [] {
                proxy.splitViewControllerInteractivePresentationGestureDidEnd(self)
            }
        default:
            break
        }
    }

    func updatePanGestureViewOrigin() {
        self.panGestureView.frame.origin = CGPoint(x: panGestureViewMidX, y: 0)
        self.sidePanGestureView.frame.origin = CGPoint(x: sidePanGestureViewMidX, y: 0)
    }

    private func panGestureBegin(_ ges: UIPanGestureRecognizer, location: CGPoint, velocity: CGPoint) {
        if ges as? LarkSplitPanGestureRecognizer != nil,
           ges.view != nil {
            if !panGestureView.isHidden, panGestureViewContains(panGestureView, gestureRecognizer: ges) {
                Tracker.trackScrollBar(location: "right")
                panGestureView.dragging = true
                sidePanGestureView.alpha = 0
            }

            if !sidePanGestureView.isHidden, panGestureViewContains(sidePanGestureView, gestureRecognizer: ges) {
                Tracker.trackScrollBar(location: "left")
                sidePanGestureView.dragging = true
                panGestureView.alpha = 0
            }
        }

        // 记录拖拽开始时的 tabbar 显示状况
        if let tabbar = self.animatedTabBarController {
            panOriginTabbarShow = tabbar.showEdgeTabbar
        } else {
            panOriginTabbarShow = nil
        }

        self.panGestureAnimatedTag = UUID()
        // 记录初始位置
        panStartLocationX = location.x
        panOriginLocationX = calculateSideDisplayWidth()

        self.sideWrapperView.showBlurView()
        self.contentView.showBlurView()
    }

    private func panGestureChanged(_ ges: UIPanGestureRecognizer, realLocationX: CGFloat, location: CGPoint) {
        if ges == self.sidePanGesture, abs(realLocationX) > primaryWidth {
            return
        }

        let realSize: CGSize = self.view.frame.size

        if realLocationX + panOriginLocationX > sideWrapperWidth {
            self.sideWrapperView.frame.origin.x = 0
            self.sideWrapperView.frame.size.width = sideWrapperWidth + sqrt(realLocationX)
        } else if realLocationX + panOriginLocationX < -sideWrapperWidth || (self.sideWrapperView.frame.maxX <= 0 && realLocationX < 0) {
            self.sideWrapperView.frame.origin.x = -sideWrapperWidth
        } else {
            self.sideWrapperView.frame.origin.x = realLocationX + panOriginLocationX - sideWrapperWidth
        }

        switch self.splitBehavior {
        case .tile:
            self.contentView.frame.origin.x = self.sideWrapperView.frame.maxX
            self.contentView.frame.size.width = realSize.width - self.sideWrapperView.frame.maxX
        case .displace:
            self.contentView.frame.origin.x = self.sideWrapperView.frame.maxX
            var width: CGFloat = 0
            if supplementaryWidth != 0 {
                if self.contentView.frame.origin.x < supplementaryWidth {
                    width = realSize.width - self.sideWrapperView.frame.maxX
                } else {
                    width = realSize.width - supplementaryWidth
                }
            } else {
                width = realSize.width - primaryWidth
            }
            self.contentView.frame.size.width = width
        case .overlay:
            let alpha = 1 - abs(self.sideWrapperView.frame.origin.x) / sideWrapperWidth
            maskView.alpha = alpha
        }

        updatePanGestureViewOrigin()
    }

    private func panGestureEnded(realLocationX: CGFloat, velocity: CGPoint) {
        let oneSideWidth = supplementaryWidth == 0 ? primaryWidth : supplementaryWidth
        var newSplitMode = self.splitMode

        self.panGestureView.dragging = false
        self.sidePanGestureView.dragging = false
        self.panGestureView.alpha = 1
        self.sidePanGestureView.alpha = 1

        let realX = realLocationX + (velocity.x / 10)

        let locationX = abs(realX)
        self.sideWrapperView.hiddenBlurView()
        self.contentView.hiddenBlurView()

        switch splitMode {
        case .sideOnly:
            break
        case .secondaryOnly:
            if realX < 0 {
                newSplitMode = .secondaryOnly
            } else if supplementaryWidth > 0 && locationX >= supplementaryWidth + primaryWidth / 2 {
                newSplitMode = .twoBesideSecondary
            } else if locationX >= oneSideWidth / 2 {
                newSplitMode = .oneBesideSecondary
            }
        case .oneOverSecondary, .oneBesideSecondary:
            if realX <= -oneSideWidth / 2 {
                newSplitMode = .secondaryOnly
            } else if realX >= primaryWidth / 2 {
                newSplitMode = .twoBesideSecondary
            }
        case .twoBesideSecondary, .twoOverSecondary, .twoDisplaceSecondary:
            if realX > 0 {
                newSplitMode = .twoBesideSecondary
            } else if locationX >= primaryWidth + supplementaryWidth / 2 {
                newSplitMode = .secondaryOnly
            } else if locationX >= primaryWidth / 2 {
                newSplitMode = .oneBesideSecondary
            }
        }

        /// edgebar 显示时，当 displayMode 发生变化，最后需要同步一下全局配置
        if newSplitMode != self.splitMode ,
           self.panOriginTabbarShow == true,
           let tab = self.animatedTabBarController {
            AnimatedTabBarController.globalShowEdgeTabbar = tab.showEdgeTabbar
        }
        self.updateBehaviorAndSplitMode(behavior: self.splitBehavior, splitMode: newSplitMode, animated: true)
    }
}

extension SplitViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if panGestureView.isHidden && sidePanGestureView.isHidden {
            return false
        }
        guard gestureRecognizer as? LarkSplitPanGestureRecognizer != nil,
              gestureRecognizer.view != nil else {
            return false
        }

        if !panGestureView.isHidden, panGestureViewContains(panGestureView, gestureRecognizer: gestureRecognizer) {
            return true
        }

        if !sidePanGestureView.isHidden, panGestureViewContains(sidePanGestureView, gestureRecognizer: gestureRecognizer) {
            return true
        }

        return false
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if otherGestureRecognizer is UIPanGestureRecognizer ||
            otherGestureRecognizer is UIScreenEdgePanGestureRecognizer {
            return true
        }
        return false
    }

    private func panGestureViewContains(_ panGestureView: SplitPanView, gestureRecognizer: UIGestureRecognizer) -> Bool {

        guard let splitGesture = gestureRecognizer as? LarkSplitPanGestureRecognizer,
              let gestureView = gestureRecognizer.view else {
            return false
        }

        let hotspotView = panGestureView.hotAreaView
        var location = gestureRecognizer.location(in: hotspotView)
        if let touchBeginPoint = splitGesture.touchBeginPoint {
            location = gestureView.convert(touchBeginPoint, to: hotspotView)
        }
        let translation: CGPoint = splitGesture.translation ?? splitGesture.translation(in: gestureView)
        // 横向拖动才会生效
        if abs(translation.y) * 1.4 > abs(translation.x) {
            return false
        }
        let bounds = hotspotView.bounds

        return bounds.contains(location)
    }
}
