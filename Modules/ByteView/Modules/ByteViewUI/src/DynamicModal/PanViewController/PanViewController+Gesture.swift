//
//  PanViewController+Gesture.swift
//  ByteRtcRenderDemo
//
//  Created by huangshun on 2019/10/17.
//  Copyright © 2019 huangshun. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

extension PanViewController {

    func panGestureRecognizerDidMove(_ top: CGFloat) {
        belowWare?.updateLayout(top, view: view)
        insertWare(aboveWare, below: belowWare)
    }

    func resetRoadWareLayout() {
        belowWare?.resetLayout(self.currentLayout, view: self.view)
        // nolint-next-line: magic number
        UIView.animate(withDuration: 0.25, animations: {
            self.view.layoutIfNeeded()
        }, completion: { _ in
            self.aboveWare?.wrapper.removeFromSuperview()
        })
    }

    func panGestureRecognizerDidEnd(_ top: CGFloat) {
        guard let trigger = belowWare?.panProxy.roadTrigger else {
            return
        }
        let yMove = beginTop - top
        if yMove < -trigger { // 达到峰值消失
            pop(animated: true)
            return
        }
        if yMove > trigger && currentLayout == .shrink {
            currentLayout = .expand
        }
        resetRoadWareLayout()
    }

    @objc
    func handleTapGesture(gesture: UIPanGestureRecognizer) {
        pop(animated: true)
    }

    @objc
    func handlePanGesture(gesture: UIPanGestureRecognizer) {

        guard
        /** 临时去掉新滑动交互, 滚动时pan手势state 终止于 change 导致未能还原真实高度 **/
//            let current = belowWare,
//            current.shouldRespond(to: gesture),
            let panGestureView = gesture.view
            else {
                gesture.setTranslation(.zero, in: gesture.view)
                return
        }

        let point = gesture.translation(in: view)
        let top = panGestureView.frame.origin.y + point.y
        gesture.setTranslation(CGPoint.zero, in: panGestureView)
        switch gesture.state {
        case .changed:
            panGestureRecognizerDidMove(top)
        case .ended:
            panGestureRecognizerDidEnd(top)
        case .cancelled, .failed:
            resetRoadWareLayout()
        case .began:
            let point = gesture.translation(in: view)
            beginTop = panGestureView.frame.origin.y + point.y
        case .possible: break
        @unknown default: break
        }
    }

}
