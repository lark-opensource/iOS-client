//
//  EmotionKeyboardPushHandler.swift
//  LarkEmotionKeyboard
//
//  Created by phoenix on 2022/9/23.
//

import Foundation
import RustPB
import LarkRustClient

final class UserMruReactionPushHandler: UserPushHandler {
    func process(push message: Im_V1_PushUserMRUReactions) throws {
        let emojiDataService = EmojiImageService.default
        emojiDataService?.handleMRUReactionPush(keys: message.userMruReactions)
    }
}

final class AllReactionPushHandler: UserPushHandler {
    func process(push message: Im_V1_PushEmojiPanel) throws {
        let emojiDataService = EmojiImageService.default
        emojiDataService?.handleAllReactionPush(panel: message.emojiPanel)
    }
}


