//
//  AnimationManager.swift
//  LarkUIKit
//
//  Created by 刘晚林 on 2017/1/6.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

final class AnimationManager: NSObject {
    var animationDuration: CGFloat = 0.5

    init(animationDuration: CGFloat) {
        super.init()
        self.animationDuration = animationDuration
    }

    func fillAnimation(withBounces bounces: Int, amplitude: CGFloat, reverse: Bool) -> CAKeyframeAnimation {
        var values: [Any] = []
        var keyTimes: [NSNumber] = []

        if reverse {
            values.append(CATransform3DMakeScale(1, 1, 1))
        } else {
            values.append(CATransform3DMakeScale(0, 0, 0))
        }
        keyTimes.append(0.0)

        for i in 1...bounces {
            let scale = (i % 2) == 1 ? (1 + amplitude / CGFloat(i)) : (1 - amplitude / CGFloat(i))
            let time = CGFloat(i) * 1.0 / CGFloat(bounces + 1)

            values.append(CATransform3DMakeScale(scale, scale, scale))
            keyTimes.append(NSNumber(value: Float(time)))
        }

        if reverse {
            values.append(CATransform3DMakeScale(0, 0, 0))
        } else {
            values.append(CATransform3DMakeScale(1, 1, 1))
        }
        keyTimes.append(1.0)

        let animation = CAKeyframeAnimation(keyPath: "transform")
        animation.values = values
        animation.keyTimes = keyTimes
        animation.duration = CFTimeInterval(self.animationDuration)
        animation.fillMode = .forwards
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)

        return animation
    }

    func opacityAnimation(reverse: Bool) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "opacity")
        if reverse {
            animation.fromValue = 1.0
            animation.toValue = 0.0
        } else {
            animation.fromValue = 0.0
            animation.toValue = 1.0
        }

        animation.duration = CFTimeInterval(self.animationDuration)
        animation.fillMode = .forwards
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)

        return animation
    }
}
