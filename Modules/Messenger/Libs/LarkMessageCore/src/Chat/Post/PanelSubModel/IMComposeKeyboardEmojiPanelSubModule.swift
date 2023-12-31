//
//  IMComposeKeyboardEmojiPanelSubModule.swift
//  LarkMessageCore
//
//  Created by liluobin on 2023/4/20.
//

import UIKit
import LarkBaseKeyboard
import LarkOpenKeyboard
import LarkChatOpenKeyboard
import LarkKeyboardView
import LarkCore

class IMComposeKeyboardEmojiPanelSubModule: KeyboardPanelEmojiSubModule<IMComposeKeyboardContext, IMKeyboardMetaModel>, ComposeKeyboardViewPageItemProtocol {

    override func didCreatePanelItem() -> InputKeyboardItem? {
        guard let metaModel = self.metaModel else { return nil }
        let support: [LarkBaseKeyboard.LarkKeyboard.EmotionKeyboardType] = [LarkBaseKeyboard.LarkKeyboard.EmotionKeyboardType.emojiWith(self)]
        let config = LarkKeyboard.EmotionKeyboardConfig(
            support: support,
            actionBtnHidden: true,
            iconColor: ComposeKeyboardPageItem.iconColor,
            chatId: metaModel.chat.id,
            scene: .im,
            selectedBlock: { [weak self] () -> Bool in
                LarkMessageCoreTracker.trackComposePostInputItem(KeyboardItemKey.emotion)
                IMTracker.Chat.Main.Click.InputEmoji(metaModel.chat,
                                                     isFullScreen: true,
                                                     self?.context.keyboardStatusManager.getRelatedDispalyMessage()?.id,
                                                     self?.pageItem?.chatFromWhere)
                return true
            },
            emotionViewCallBack: { (_) -> Void in }
        )
        return LarkKeyboard.buildEmotion(config)
    }

    override func emojiEmotionInputViewDidTapCell(emojiKey: String) {
        super.emojiEmotionInputViewDidTapCell(emojiKey: emojiKey)
        if let chat = self.metaModel?.chat {
            PostTracker.trackSelectFace(chat: chat, face: "[\(emojiKey)]")
        }
    }

    override func emojiEmotionInputViewDidTapSend() {
        assertionFailure("error to emojiEmotionInputViewDidTapSend")
    }

    override func emojiEmotionActionEnable() -> Bool {
        return true
    }

    override func canHandle(model: IMKeyboardMetaModel) -> Bool {
        return !model.chat.isP2PAi
    }
}
