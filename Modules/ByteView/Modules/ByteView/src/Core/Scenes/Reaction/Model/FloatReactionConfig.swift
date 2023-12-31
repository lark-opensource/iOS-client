//
//  FloatReactionConfig.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/10/17.
//

import Foundation
import ByteViewSetting
import ByteViewUI

struct FloatReactionConfig: ReactionConfig {
    let animator: ReactionAnimator
    let duration: TimeInterval
    let displayDensity: CGFloat
    let heightRatio: CGFloat

    // disable-lint: magic number
    init(setting: MeetingSettingManager) {
        let isLowDevice = setting.featurePerformanceConfig.isLowDevice ?? false
        let reactionConfig = setting.floatReactionConfig
        self.heightRatio = reactionConfig.heightRatio
        self.displayDensity = CGFloat(reactionConfig.displayDensity == 0 ? 5580 : reactionConfig.displayDensity)
        self.duration = TimeInterval(reactionConfig.duration) / 1000

        if isLowDevice {
            self.animator = LinearFloatReactionAnimator(heightRatio: heightRatio)
        } else {
            self.animator = FloatReactionAnimator(heightRatio: heightRatio)
        }
    }
    // enable-lint: magic number

    func reactionAnimationDuration(for pendingReactionsCount: Int) -> TimeInterval {
        duration
    }

    var reactionQueueCapacity: Int {
        Int(VCScene.bounds.width * VCScene.bounds.height * heightRatio / displayDensity)
    }
}
