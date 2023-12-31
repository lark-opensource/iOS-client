//
//  IMCryptoChatKeyboardVoicePanelSubModule.swift
//  LarkChat
//
//  Created by liluobin on 2023/4/7.
//

import UIKit
import LarkMessageCore
import LarkOpenKeyboard
import LarkChatOpenKeyboard
import LarkMessengerInterface
import LarkContainer
import LarkAudio
import LarkModel
import LarkKeyboardView
import LarkFeatureGating
import LarkKAFeatureSwitch
import LarkSendMessage
import LarkCore
import RxSwift
import RxCocoa
import RustPB
import LarkBaseKeyboard
import LarkChatKeyboardInterface

public class IMCryptoChatKeyboardVoicePanelSubModule: KeyboardPanelVoiceSubModule<KeyboardContext, IMKeyboardMetaModel>,
                                                        AudioKeyboardHelperDelegate,
                                                        ChatKeyboardViewPageItemProtocol,
                                                        AudioSendMessageDelegate {

    @ScopedInjectedLazy private var secretChatService: SecretChatService?

    var messageSender: KeyboardAudioItemSendService? {
        return try? self.context.userResolver.resolve(type: KeyboardAudioItemSendService.self)
    }

    var audioKeyboardHelper: AudioRecordPanelProtocol?
    private weak var audioToTextView: AudioToTextViewStopDelegate?

    public override func didCreatePanelItem() -> InputKeyboardItem? {
        guard let chat = self.metaModel?.chat else { return nil }
        let from = chatPageItem?.chatFromWhere
        return AudioKeyboardFactory.createVoiceKeyboardItem(
            userResolver: context.userResolver, chat: chat, audioToTextEnable: false, audioWithTextEnable: false, supportStreamUpLoad: false,
            sendMessageDelegate: self, helperDelegate: self, iconColor: secretChatService?.keyboardItemsTintColor ?? UIColor.ud.iconN2,
            audioToTextView: { [weak self] newView in
                self?.audioToTextView?.stopRecognize()
                self?.audioToTextView = newView
            },
            recordPanel: { panel in
                audioKeyboardHelper = panel
            }, updateIconCallBack: nil, tappedBlock: {
                IMTracker.Chat.Main.Click.VoiceMsg(chat, nil, from)
                LarkMessageCoreTracker.trackClickKeyboardInputItem(KeyboardItemKey.voice)
            })
    }

    public func audiokeybordPanelView() -> LKKeyboardView {
        return self.chatPageItem?.keyboardView ?? LKKeyboardView(frame: .zero,
                                                                config: KeyboardLayouConfig(phoneStyle: InputAreaStyle.empty(),
                                                                                            padStyle: InputAreaStyle.empty()))
    }

    public func audiokeybordSendMessage(_ audioData: AudioDataInfo) {
        guard let chat = self.metaModel?.chat else { return }
        let lastMessagePosition: Int32 = chat.lastMessagePosition
        self.messageSender?.sendAudio(audio: audioData,
                                      parentMessage: self.chatPageItem?.getReplyInfo?()?.message,
                                      chatId: chat.id,
                                      lastMessagePosition: lastMessagePosition,
                                      quasiMsgCreateByNative: false)
        self.chatPageItem?.afterSendMessage?()
    }

    public func audiokeybordSendMessage(audioInfo: StreamAudioInfo) {
        guard let chat = self.metaModel?.chat else { return }
        self.messageSender?.sendAudio(audioInfo: audioInfo,
                                      parentMessage: self.chatPageItem?.getReplyInfo?()?.message,
                                      chatId: chat.id)
        self.chatPageItem?.afterSendMessage?()
    }

    public func sendMessageWhenRecognition() {
        self.chatPageItem?.keyboardView?.sendNewMessage()
    }

    public func audioSendTextMessage(str: String) {
        if let chat = self.metaModel?.chat,
           let richText = RichTextTransformKit.transformStringToRichText(string: NSAttributedString(string: str)) {
            self.messageSender?.sendText(
                content: richText,
                lingoInfo: nil,
                parentMessage: self.chatPageItem?.getReplyInfo?()?.message,
                chatId: chat.id,
                position: chat.lastMessagePosition,
                quasiMsgCreateByNative: false,
                callback: nil)
        }
    }
}
