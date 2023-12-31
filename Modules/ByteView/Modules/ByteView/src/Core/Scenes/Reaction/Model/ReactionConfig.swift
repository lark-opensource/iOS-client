//
//  ReactionConfig.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/10/17.
//

import Foundation

protocol ReactionAnimator {
    func showReaction(_ reaction: UIView, duration: TimeInterval, completion: @escaping () -> Void)
}

protocol ReactionConfig {
    var reactionQueueCapacity: Int { get }
    var animator: ReactionAnimator { get }
    func reactionAnimationDuration(for pendingReactionsCount: Int) -> TimeInterval
}
