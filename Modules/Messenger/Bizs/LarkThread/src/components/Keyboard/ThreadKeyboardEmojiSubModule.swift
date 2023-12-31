//
//  ThreadKeyboardEmojiSubModule.swift
//  LarkThread
//
//  Created by liluobin on 2023/4/10.
//

import UIKit
import LarkBaseKeyboard
import LarkChatOpenKeyboard
import LarkOpenKeyboard
import LarkKeyboardView
import LarkMessageCore
import LarkCore
import RustPB
import LarkContainer
import LarkSendMessage
import LarkMessageBase
import AppReciableSDK

public class NormalThreadKeyboardEmojiSubModule: BaseThreadKeyboardEmojiSubModule {

    @ScopedInjectedLazy var dependency: ThreadDependency?

    public override func didSendUpdatedSticker(_ sticker: Im_V1_Sticker, stickersCount: Int) {
        guard let message = self.threadPageItem?.getReplyMessage?(),
        let chat = self.metaModel?.chat,
            let thread = self.threadPageItem?.thread else {
            assertionFailure("data error")
            return
        }
        guard let sendMessageAPI, let isSupportURLType = dependency?.isSupportURLType(url:) else { return }
        ThreadTracker.trackSendMessage(parentMessage: message,
                                       type: .sticker,
                                       chatId: chat.id,
                                       isSupportURLType: isSupportURLType,
                                       chat: chat)
        let context = APIContext(contextID: "")
        sendMessageAPI.sendSticker(context: context,
                                        sticker: sticker,
                                        parentMessage: message,
                                        chatId: chat.id,
                                        threadId: thread.id,
                                        sendMessageTracker: nil) { state in
            if case .beforeSendMessage(let message, _) = state {
                ThreadTracker.trackSendSticker(chat, sticker: sticker, message: message, stickersCount: stickersCount)
            }
        }
    }
}

public class MessageThreadKeyboardEmojiSubModule: BaseThreadKeyboardEmojiSubModule {
    public override func didSendUpdatedSticker(_ sticker: Im_V1_Sticker, stickersCount: Int) {
        guard let sendMessageAPI else { return }
        guard let message = self.threadPageItem?.getReplyMessage?(),
        let chat = self.metaModel?.chat,
            let thread = self.threadPageItem?.thread else {
            assertionFailure("data error")
            return
        }
        sendMessageAPI.sendSticker(context: defaultSendContext(),
                                        sticker: sticker,
                                        parentMessage: message,
                                        chatId: chat.id,
                                        threadId: thread.id,
                                        sendMessageTracker: nil,
                                        stateHandler: nil)
    }
}

public class BaseThreadKeyboardEmojiSubModule: KeyboardPanelEmojiSubModule<KeyboardContext, IMKeyboardMetaModel>, ThreadKeyboardViewPageItemProtocol {

    @ScopedInjectedLazy var sendMessageAPI: SendMessageAPI?

    var emotionKeyboard: EmotionKeyboardProtocol? {
        didSet {
            if oldValue === emotionKeyboard {
                return
            }
            if let currentJob = self.threadPageItem?.keyboardStatusManager.currentKeyboardJob {
                emotionKeyboard?.updateSendBtnIfNeed(hidden: !currentJob.needPanelSendBtn)
            }
        }
    }

    /// 是否支持emoji的LeftViewInfo, 设置之后会将当前 Item清空
    public var supportLeftViewInfo = true {
        didSet {
            if oldValue != supportLeftViewInfo {
                item = nil
            }
        }
    }

    public override var trackInfo: (logId: String, sence: Scene) {
        return (self.metaModel?.chat.id ?? "", .Thread)
    }

    public override func canHandle(model: IMKeyboardMetaModel) -> Bool {
        return super.canHandle(model: model)
    }

    public override func didCreatePanelItem() -> InputKeyboardItem? {
        var support: [LarkKeyboard.EmotionKeyboardType] = [
            LarkKeyboard.EmotionKeyboardType.emojiWith(self)
        ]
        var leftViewInfo: LarkKeyboard.EmotionLeftViewInfo?
        if supportLeftViewInfo {
            leftViewInfo = LarkKeyboard.EmotionLeftViewInfo(
                width: 60,
                image: LarkMessageCore.Resources.emotion_show_list_icon,
                clickCallBack: { [weak self] (_: UIView) -> Void in
                    self?.showShopList()
                })
            support.append(LarkKeyboard.EmotionKeyboardType.stickerWith(self))
            support.append(LarkKeyboard.EmotionKeyboardType.stickerSetWith(self))
        }

        let config = LarkKeyboard.EmotionKeyboardConfig(
            support: support,
            actionBtnHidden: false,
            leftViewInfo: leftViewInfo,
            iconColor: ThreadKeyboardPageItem.iconColor,
            chatId: self.metaModel?.chat.id ?? "",
            scene: .im,
            selectedBlock: { [weak self] () -> Bool in
                LarkMessageCoreTracker.trackClickKeyboardInputItem(KeyboardItemKey.emotion)
                IMTracker.Chat.Main.Click.InputEmoji(self?.metaModel?.chat,
                                                     isFullScreen: false,
                                                     self?.threadPageItem?.thread.id,
                                                     nil)
                self?.context.keyboardAppearForSelectedPanel(item: .emotion)
                return true
            },
            emotionViewCallBack: { [weak self] (emotionKeyboard) -> Void in
                self?.emotionKeyboard = emotionKeyboard
            }
        )
        return LarkKeyboard.buildEmotion(config)
    }

    func showShopList() {
        StickerTracker.trackEmotionShopListShow()
        self.itemServiceImp?.pushEmotionShopListVC(from: context.displayVC)
    }

    public override func switchEmojiSuccess() {
        StickerTracker.trackSwitchEmoji()
    }
    public override func clickStickerSetting() {
        super.clickStickerSetting()
        ThreadTracker.trackEmotionSettingShow(from: .fromPannel)
    }

    open override func didSendUpdatedSticker(_ sticker: Im_V1_Sticker, stickersCount: Int) {
    }

    public override func emojiEmotionInputViewDidTapSend() {
        threadPageItem?.keyboardView?.sendNewMessage()
    }
}
