//
//  BubbleReactionConfig.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/10/17.
//

import Foundation

struct BubbleReactionConfig: ReactionConfig {
    let reactionQueueCapacity = 10

    var animator: ReactionAnimator {
        // 旧版表情动画逻辑与所在视图强耦合，不方便封装，依然维护在原来的视图层
        fatalError("FloatingReactionConfig.animator should not be used.")
    }

    private static let maxReactionDuration: TimeInterval = 6
    private static let minReactionDuration: TimeInterval = 0.5

    func reactionAnimationDuration(for pendingReactionsCount: Int) -> TimeInterval {
        max(Self.maxReactionDuration - TimeInterval(pendingReactionsCount) / 10, Self.minReactionDuration)
    }
}
