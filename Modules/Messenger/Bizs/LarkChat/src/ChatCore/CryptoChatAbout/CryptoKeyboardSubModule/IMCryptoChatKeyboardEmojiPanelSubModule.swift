//
//  IMCryptoChatKeyboardEmojiPanelSubModule.swift
//  LarkChat
//
//  Created by liluobin on 2023/4/4.
//

import UIKit
import LarkOpenKeyboard
import LarkBaseKeyboard
import LarkChatOpenKeyboard
import LarkEmotion
import LarkEmotionKeyboard
import LarkContainer
import LarkMessengerInterface
import LarkKeyboardView
import LarkMessageCore
import LarkCore
import LarkOpenIM
import RustPB
import AppReciableSDK

public class IMCryptoChatKeyboardEmojiPanelSubModule: KeyboardPanelEmojiSubModule<KeyboardContext, IMKeyboardMetaModel>, ChatKeyboardViewPageItemProtocol {

    @ScopedInjectedLazy private var secretChatService: SecretChatService?

    var emotionKeyboard: EmotionKeyboardProtocol?

    var chatFromWhere: ChatFromWhere? {
        return chatPageItem?.chatFromWhere
    }

    public override var trackInfo: (logId: String, sence: Scene) {
        return (self.metaModel?.chat.id ?? "", .Chat)
    }

    public override func canHandle(model: IMKeyboardMetaModel) -> Bool {
        return model.chat.isCrypto
    }

    public override func didCreatePanelItem() -> InputKeyboardItem? {
        var support: [LarkKeyboard.EmotionKeyboardType] = [
            LarkKeyboard.EmotionKeyboardType.emojiWith(self)
        ]
        let config = LarkKeyboard.EmotionKeyboardConfig(
            support: support,
            actionBtnHidden: false,
            leftViewInfo: nil,
            iconColor: secretChatService?.keyboardItemsTintColor,
            chatId: self.metaModel?.chat.id,
            scene: .im,
            selectedBlock: { [weak self] () -> Bool in
                LarkMessageCoreTracker.trackClickKeyboardInputItem(KeyboardItemKey.emotion)
                IMTracker.Chat.Main.Click.InputEmoji(self?.metaModel?.chat,
                                                     isFullScreen: false, nil,
                                                     self?.chatFromWhere)
                self?.context.keyboardAppearForSelectedPanel(item: KeyboardItemKey.emotion)
                return true
            },
            emotionViewCallBack: { [weak self] (emotionKeyboard) -> Void in
                self?.emotionKeyboard = emotionKeyboard
            }
        )
        return LarkKeyboard.buildEmotion(config)
    }

    public override func emojiEmotionInputViewDidTapCell(emojiKey: String) {
        super.emojiEmotionInputViewDidTapCell(emojiKey: emojiKey)
        if let chat = self.metaModel?.chat {
            ChatTracker.trackSelectFace(chat: chat, face: "[\(emojiKey)]")
        }
    }
    public override func allStickerItems() -> [Im_V1_Sticker] {
        assertionFailure("crypto not support allStickerItems")
        return []
    }
    public override func allStickerSetItems() -> [Im_V1_StickerSet] {
        assertionFailure("crypto not support allStickerItems")
        return []
    }

    open override func didSendUpdatedSticker(_ sticker: Im_V1_Sticker, stickersCount: Int) {
        assertionFailure("crypto not support didSendUpdatedSticker")
    }

    public override func emojiEmotionInputViewDidTapSend() {
        chatPageItem?.keyboardView?.sendNewMessage()
    }
}
