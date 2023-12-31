//
//  UIImageView+Reaction.swift
//  Minutes
//
//  Created by lvdaqian on 2021/2/26.
//

import UIKit
import LarkEmotion

extension UIImageView {
    static func reactionView(for reactionKey: String?) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        if let key = reactionKey,
           let image = EmotionResouce.shared.imageBy(key: key) {
            imageView.image = image
        } else {
            imageView.image = BundleResources.Minutes.minutes_comment_tip
        }
        return imageView
    }
}
