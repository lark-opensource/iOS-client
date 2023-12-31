//
//  CALayer+LarkUIKit.swift
//  LarkUIKit
//
//  Created by chengzhipeng-bytedance on 2018/3/15.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation
import LarkCompatible
import UIKit

extension CALayer: LarkUIKitExtensionCompatible {}

public extension LarkUIKitExtension where BaseType: CALayer {
    func bounceAnimation(
        frames: [CGFloat] = [1, 0.8, 1],
        duration: TimeInterval,
        key: String? = nil,
        onCompleted: (() -> Void)? = nil) {
        CATransaction.begin()
        let bounceAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
        bounceAnimation.values = frames
        bounceAnimation.timingFunctions = [
            CAMediaTimingFunction(name: .easeIn),
            CAMediaTimingFunction(name: .easeIn)
        ]
        bounceAnimation.duration = duration
        bounceAnimation.calculationMode = .cubic
        CATransaction.setCompletionBlock(onCompleted)

        self.base.add(bounceAnimation, forKey: key)
        CATransaction.commit()
    }
}
