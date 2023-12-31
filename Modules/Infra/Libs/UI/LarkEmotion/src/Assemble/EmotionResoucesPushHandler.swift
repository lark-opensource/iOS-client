//
//  EmotionResoucesPushHandler.swift
//  LarkEmotion
//
//  Created by 李勇 on 2021/3/3.
//

import UIKit
import Foundation
import RustPB
import LarkRustClient
import LarkContainer

final class EmotionResoucesPushHandler: UserPushHandler {

    private var pushCenter: PushNotificationCenter? {
        return try? userResolver.userPushCenter
    }

    func process(push message: Im_V1_PushEmojis) throws {
        var resouces: [String: Resouce] = [:]
        message.emojis.forEach { (key, imV1Emoji) in
            if !imV1Emoji.skinKeys.isEmpty {
                EmotionUtils.logger.info("EmotionResoucesPush: \(key) skinKeys = \(imV1Emoji.skinKeys)")
            }
            let resouce = Resouce(i18n: imV1Emoji.text,
                                  imageKey: imV1Emoji.imageKey,
                                  isDelete: imV1Emoji.isDeleted,
                                  skinKeys: imV1Emoji.skinKeys,
                                  size: CGSize(width: CGFloat (imV1Emoji.width),
                                               height: CGFloat(imV1Emoji.height)))
            resouces[key] = resouce
            if resouce.isDelete {
                EmotionUtils.logger.error("EmotionResoucesPush: \(key) isDeleted = \(resouce.isDelete)")
            }
        }
        EmotionUtils.logger.info("EmotionResoucesPush: message.emojis count: \(message.emojis.count)")
        EmotionResouce.shared.mergeResouces(resouces: resouces, version: message.version)
    }
}
