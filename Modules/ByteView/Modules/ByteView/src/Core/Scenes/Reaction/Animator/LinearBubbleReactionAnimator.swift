//
//  LinearFloatReactionAnimator.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/10/17.
//

import Foundation
import ByteViewUI

class LinearFloatReactionAnimator: ReactionAnimator {
    let heightRatio: CGFloat

    init(heightRatio: CGFloat) {
        self.heightRatio = heightRatio
    }

    func showReaction(_ reaction: UIView, duration: TimeInterval, completion: @escaping () -> Void) {
        UIView.animate(withDuration: duration, animations: {
            reaction.transform = CGAffineTransformMakeTranslation(0, -self.heightRatio * VCScene.bounds.height)
        }, completion: { _ in
            completion()
        })
    }
}
