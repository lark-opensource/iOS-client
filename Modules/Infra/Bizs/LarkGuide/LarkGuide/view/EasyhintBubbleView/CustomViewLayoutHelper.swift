//
//  UIViewLayoutHelper.swift
//  LarkUIKit
//
//  Created by sniperj on 2018/12/9.
//

import Foundation
import UIKit

public final class CustomViewLayoutHelper: NSObject {
    public func isValidArrowPosition(targetView: UIView,
                                      forView: UIView,
                                      arrowPosition: ArrowPosition,
                                      otherInset: CGFloat = 0,
                                      superview: UIView,
                                      layoutFinish: (() -> Void)? = nil) -> Bool {
        let refViewFrame = forView.convert(forView.bounds, to: superview)
        switch arrowPosition {
        case .bottom:
            return isValidArrowPosition(targetView: targetView,
                        focusPosition: CGPoint(x: refViewFrame.origin.x + refViewFrame.width / 2,
                                               y: refViewFrame.origin.y),
                        arrowPosition: arrowPosition,
                        superview: superview,
                        otherInset: otherInset,
                        layoutFinish: layoutFinish)
        case .top:
            return isValidArrowPosition(targetView: targetView,
                        focusPosition: CGPoint(x: refViewFrame.origin.x + refViewFrame.width / 2,
                                               y: refViewFrame.origin.y + refViewFrame.height),
                        arrowPosition: arrowPosition,
                        superview: superview,
                        otherInset: otherInset,
                        layoutFinish: layoutFinish)
        case .right:
            return isValidArrowPosition(targetView: targetView,
                        focusPosition: CGPoint(x: refViewFrame.origin.x,
                                               y: refViewFrame.origin.y + refViewFrame.height / 2),
                        arrowPosition: arrowPosition,
                        superview: superview,
                        otherInset: otherInset,
                        layoutFinish: layoutFinish)
        case .left:
            return isValidArrowPosition(targetView: targetView,
                        focusPosition: CGPoint(x: refViewFrame.origin.x + refViewFrame.width,
                                               y: refViewFrame.origin.y + refViewFrame.height / 2),
                        arrowPosition: arrowPosition,
                        superview: superview,
                        otherInset: otherInset,
                        layoutFinish: layoutFinish)
        case .any:
            return false
        }
    }

    public func isValidArrowPosition(targetView: UIView,
                                      focusPosition: CGPoint,
                                      arrowPosition: ArrowPosition,
                                      superview: UIView,
                                      otherInset: CGFloat = 0,
                                      railingOffset: CGPoint = CGPoint(x: 0, y: 0),
                                      layoutFinish: (() -> Void)? = nil) -> Bool {
        let originX = focusPosition.x
        let originy = focusPosition.y
        let superviewW = superview.frame.size.width
        let superviewH = superview.frame.size.height
        let selfW = targetView.frame.size.width
        let selfH = targetView.frame.size.height
        switch arrowPosition {
        case .bottom:
            if originy - selfH - 2 * otherInset > 0 {
                targetView.center = CGPoint(x: originX,
                                      y: originy - selfH / 2 - otherInset)
                checkTargetViewPositionValidInSuperview(targetView: targetView, superview: superview, railingOffset: railingOffset)
                layoutFinish?()
                return true
            } else {
                return false
            }
        case .top:
            if originy + selfH + 2 * otherInset < superviewH {
                targetView.center = CGPoint(x: originX,
                                      y: originy + selfH / 2 + otherInset)
                checkTargetViewPositionValidInSuperview(targetView: targetView, superview: superview, railingOffset: railingOffset)
                layoutFinish?()
                return true
            } else {
                return false
            }
        case .left:
            if originX + selfW + 2 * otherInset < superviewW {
                targetView.center = CGPoint(x: originX + selfW / 2 + otherInset,
                                      y: originy)
                checkTargetViewPositionValidInSuperview(targetView: targetView, superview: superview, railingOffset: railingOffset)
                layoutFinish?()
                return true
            } else {
                return false
            }
        case .right:
            if originX - selfW - 2 * otherInset > 0 {
                targetView.center = CGPoint(x: originX - selfW / 2 - otherInset,
                                      y: originy)
                checkTargetViewPositionValidInSuperview(targetView: targetView, superview: superview, railingOffset: railingOffset)
                layoutFinish?()
                return true
            } else {
                return false
            }
        case .any:
            return false
        }
    }

    private func checkTargetViewPositionValidInSuperview(targetView: UIView,
                                                         superview: UIView,
                                                         railingOffset: CGPoint) {
        let originX = targetView.frame.origin.x
        let originy = targetView.frame.origin.y
        if originX < 0 {
            targetView.center = CGPoint(x: targetView.center.x - originX + 1,
                                  y: targetView.center.y)
        }

        if originX + targetView.frame.width > superview.frame.width {
            targetView.center = CGPoint(x: targetView.center.x - originX - targetView.frame.width + superview.frame.width - 1,
                                  y: targetView.center.y)
        }

        if originy < 0 {
            targetView.center = CGPoint(x: targetView.center.x,
                                  y: targetView.center.y - originy + 1)
        }

        if originy + targetView.frame.height > superview.frame.height {
            targetView.center = CGPoint(x: targetView.center.x,
                                  y: targetView.center.y - originy - targetView.frame.height + superview.frame.height)
        }
        targetView.center = CGPoint(x: targetView.center.x + railingOffset.x,
                                    y: targetView.center.y + railingOffset.y)
    }

    public override init() {}
}
