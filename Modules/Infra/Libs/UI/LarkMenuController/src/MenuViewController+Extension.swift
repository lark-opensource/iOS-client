//
//  MenuViewController+Extension.swift
//  LarkMenuController
//
//  Created by 李晨 on 2019/6/11.
//

import UIKit
import Foundation
import LarkEmotionKeyboard

extension MenuViewController: UIGestureRecognizerDelegate {

    open func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if !self.menuView.isHidden && self.menuView.alpha > 0 {
            let point = gestureRecognizer.location(in: self.menuView)
            if self.menuView.bounds.contains(point) {
                return false
            }
        }

        if let handleTouchArea = self.handleTouchArea,
            handleTouchArea(gestureRecognizer.location(in: self.view), self) {
            return false
        }

        if let handleTouchView = self.handleTouchView,
            handleTouchView(gestureRecognizer.location(in: self.view), self) != nil {
            return false
        }
        return true
    }

    open func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            if String(describing: type(of: otherGestureRecognizer)).hasPrefix("_") || otherGestureRecognizer.name == emotionKeyboardHighPriorityGesture {
            return true
        }
        return false
    }

    open func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
        if String(describing: type(of: otherGestureRecognizer)).hasPrefix("_") || otherGestureRecognizer.name == emotionKeyboardHighPriorityGesture {
            return false
        }
        return true
    }
}
