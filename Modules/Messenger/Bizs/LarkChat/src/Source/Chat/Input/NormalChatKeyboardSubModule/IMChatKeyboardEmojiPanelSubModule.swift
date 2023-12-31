//
//  IMChatKeyboardEmojiPanelSubModule.swift
//  LarkMessageCore
//
//  Created by liluobin on 2023/4/4.
//

import UIKit
import LarkChatOpenKeyboard
import LarkBaseKeyboard
import LarkOpenKeyboard
import RxSwift
import LarkCore
import LarkSDKInterface
import LarkEmotion
import LarkEmotionKeyboard
import LarkUIKit
import LarkRichTextCore
import EENavigator
import LarkContainer
import LarkMessengerInterface
import RustPB
import LarkOpenIM
import LarkMessageCore
import LarkKeyboardView
import LarkMessageBase
import AppReciableSDK
import LarkChatKeyboardInterface

public class IMChatKeyboardEmojiPanelSubModule: KeyboardPanelEmojiSubModule<KeyboardContext, IMKeyboardMetaModel>, ChatKeyboardViewPageItemProtocol {

    var chatFromWhere: ChatFromWhere? {
        return chatPageItem?.chatFromWhere
    }

    private var itemConfig: ChatKeyboardEmojiItemConfig? {
        return try? context.userResolver.resolve(assert: ChatOpenKeyboardItemConfigService.self).getChatKeyboardItemFor(self.panelItemKey)
    }

    /// 是否支持emoji的LeftViewInfo, 设置之后会将当前 Item清空
    public var supportLeftViewInfo = true {
        didSet {
            if oldValue != supportLeftViewInfo {
                item = nil
            }
        }
    }

    var emotionKeyboard: EmotionKeyboardProtocol? {
        didSet {
            if oldValue === emotionKeyboard {
                return
            }
            if let currentJob = self.chatPageItem?.keyboardStatusManager.currentKeyboardJob {
                emotionKeyboard?.updateSendBtnIfNeed(hidden: !currentJob.needPanelSendBtn)
            }
        }
    }

    let disposeBag = DisposeBag()

    public override var trackInfo: (logId: String, sence: Scene) {
        return (self.metaModel?.chat.id ?? "", .Chat)
    }

    public override func canHandle(model: IMKeyboardMetaModel) -> Bool {
        return !model.chat.isCrypto && !model.chat.isP2PAi
    }

    public override func didCreatePanelItem() -> InputKeyboardItem? {
        var support: [LarkKeyboard.EmotionKeyboardType] = [
            LarkKeyboard.EmotionKeyboardType.emojiWith(self)
        ]
        var leftInfo: LarkKeyboard.EmotionLeftViewInfo?
        if supportLeftViewInfo, itemConfig?.uiConfig?.supportSticker ?? true {
            leftInfo = LarkKeyboard.EmotionLeftViewInfo(
                width: 60,
                image: LarkMessageCore.Resources.emotion_show_list_icon.ud.withTintColor(UIColor.ud.iconN1),
                clickCallBack: { [weak self] (_: UIView) -> Void in
                    self?.showShopList()
                })
            support.append(LarkKeyboard.EmotionKeyboardType.stickerWith(self))
            support.append(LarkKeyboard.EmotionKeyboardType.stickerSetWith(self))
        }
        let config = LarkKeyboard.EmotionKeyboardConfig(
            support: support,
            actionBtnHidden: false,
            leftViewInfo: leftInfo,
            iconColor: UIColor.ud.iconN2,
            chatId: self.metaModel?.chat.id ?? "",
            scene: .im,
            selectedBlock: { [weak self] () -> Bool in
                LarkMessageCoreTracker.trackClickKeyboardInputItem(KeyboardItemKey.emotion)
                IMTracker.Chat.Main.Click.InputEmoji(self?.metaModel?.chat, isFullScreen: false, nil, self?.chatFromWhere)
                self?.context.keyboardAppearForSelectedPanel(item: KeyboardItemKey.emotion)
                self?.itemConfig?.uiConfig?.tappedBlock?()
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
        let emoji = "[\(emojiKey)]"
        guard let chat = self.metaModel?.chat else {
            return
        }
        ChatTracker.trackSelectFace(chat: chat, face: emoji)
    }

    func showShopList() {
        StickerTracker.trackEmotionShopListShow()
        self.itemServiceImp?.pushEmotionShopListVC(from: context.displayVC)
    }

    open override func didSendUpdatedSticker(_ sticker: Im_V1_Sticker, stickersCount: Int) {
        guard let chat = self.metaModel?.chat else { return }
        self.itemConfig?.sendConfig?.sendService.sendSticker(sticker: sticker,
                                                             parentMessage: self.chatPageItem?.getReplyInfo?()?.message,
                                                             chat: chat,
                                                             stickersCount: stickersCount)
        chatPageItem?.afterSendMessage?()
    }

    public override func emojiEmotionInputViewDidTapSend() {
        chatPageItem?.keyboardView?.sendNewMessage()
    }
}
