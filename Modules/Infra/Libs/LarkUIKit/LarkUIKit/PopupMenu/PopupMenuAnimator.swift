//
//  PopupMenuAnimator.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/7/29.
//

import Foundation
import UIKit
import SnapKit

struct PopupMenuAnimateInfo {
    let rightConstraint: Constraint
    let topConstraint: Constraint
    let heightConstraint: Constraint
    let widthConstraint: Constraint

    let view: UIView
    let container: UIView
}

protocol PopupMenuAnimator {
    func showTimingFunction() -> CAMediaTimingFunction? // 优先timingfunction -> AnimationCurve -> defaultValue(linear)
    func showAnimationCurve() -> UIView.AnimationCurve?
    func hideTimingFunctionn() -> CAMediaTimingFunction?
    func hideAnimationCurve() -> UIView.AnimationCurve?

    func willShow(info: PopupMenuAnimateInfo)
    func showing(info: PopupMenuAnimateInfo)
    func didShow(info: PopupMenuAnimateInfo)

    func willHide(info: PopupMenuAnimateInfo)
    func hiding(info: PopupMenuAnimateInfo)
}

final class DefaultPopupMenuAnimator: PopupMenuAnimator {
    func showAnimationCurve() -> UIView.AnimationCurve? {
        return nil
    }

    func hideAnimationCurve() -> UIView.AnimationCurve? {
        return nil
    }

    func showTimingFunction() -> CAMediaTimingFunction? {
        return nil
    }

    func hideTimingFunctionn() -> CAMediaTimingFunction? {
        return nil
    }

    func willShow(info: PopupMenuAnimateInfo) {
        info.view.alpha = 0
        info.container.alpha = 0
        let width = info.container.frame.size.width
        info.container.transform = CGAffineTransform(translationX: width, y: 0)
    }

    func showing(info: PopupMenuAnimateInfo) {
        info.container.alpha = 1
        info.view.alpha = 1
        info.container.transform = .identity
    }

    func didShow(info: PopupMenuAnimateInfo) {}

    func willHide(info: PopupMenuAnimateInfo) {
        info.view.alpha = 1
        info.container.alpha = 1
        info.container.transform = .identity
    }

    func hiding(info: PopupMenuAnimateInfo) {
        info.container.alpha = 0
        info.view.alpha = 0
        let width = info.container.frame.size.width
        info.container.transform = CGAffineTransform(translationX: width, y: 0)
    }
}
