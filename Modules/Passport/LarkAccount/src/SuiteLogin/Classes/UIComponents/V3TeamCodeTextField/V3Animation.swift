//
//  V3Animation.swift
//  SuiteLogin
//
//  Created by quyiming on 2020/1/5.
//

import Foundation

class V3Animation {
    // 闪动动画
    static func opacityAnimation() -> CABasicAnimation? {
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 1.0
        opacityAnimation.toValue = 0.0
        opacityAnimation.duration = 1
        opacityAnimation.repeatCount = HUGE
        opacityAnimation.isRemovedOnCompletion = true
        opacityAnimation.fillMode = .forwards
        opacityAnimation.timingFunction = CAMediaTimingFunction(name: .easeIn)
        return opacityAnimation
    }
}
