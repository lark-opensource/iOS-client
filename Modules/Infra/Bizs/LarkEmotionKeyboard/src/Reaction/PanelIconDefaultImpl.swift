//
//  PanelIconDefaultImpl.swift
//  LarkReactionPanel
//
//  Created by 王元洵 on 2021/2/9.
//

import UIKit
import Foundation
import LarkEmotion
import ByteWebImage
import LarkContainer

@objc(PanelIconDefaultImpl)
final class PanelIconDefaultImpl: NSObject, ReactionImageDelegate {

    public static func reactionViewImage(_ reactionKey: String, callback: @escaping (UIImage?) -> Void) {
        let start = CACurrentMediaTime()
        if let image = EmotionResouce.shared.imageBy(key: reactionKey) {
            LarkReactionPanelTracker.trackerEmojiLoadDuration(duration: CACurrentMediaTime() - start,
                                                              emojiKey: reactionKey, isLocalImage: true)
            callback(image)
        } else {
            var imageView: UIImageView? = UIImageView()
            // 尽量用imageKey发起请求
            var isEmojis: Bool = false; var key: String = reactionKey
            if let imageKey = EmotionResouce.shared.imageKeyBy(key: reactionKey) {
                isEmojis = true; key = imageKey
            }
            let resource = LarkImageResource.reaction(key: key, isEmojis: isEmojis)
            let isCache = LarkImageService.shared.isCached(resource: resource)
            imageView?.bt.setLarkImage(with: resource, completion: { result in
                LarkReactionPanelTracker.trackerEmojiLoadDuration(duration: CACurrentMediaTime() - start,
                                                                  emojiKey: reactionKey, isLocalImage: isCache)
                callback(try? result.get().image)
                imageView = nil
            })
        }
    }
}
