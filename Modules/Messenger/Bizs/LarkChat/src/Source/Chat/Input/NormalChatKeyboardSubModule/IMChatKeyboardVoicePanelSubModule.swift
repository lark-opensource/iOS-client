//
//  IMChatKeyboardVoicePanelSubModule.swift
//  LarkChat
//
//  Created by liluobin on 2023/4/6.
//

import UIKit
import LarkAudio
import LarkChatOpenKeyboard
import LarkOpenKeyboard
import LarkBaseKeyboard
import LarkKeyboardView
import LarkMessageCore
import LarkModel
import LarkFeatureGating
import LarkKAFeatureSwitch
import LarkSendMessage
import RustPB
import RxCocoa
import RxSwift
import LarkCore
import LarkChatKeyboardInterface

public class IMChatKeyboardVoicePanelSubModule: KeyboardPanelVoiceSubModule<KeyboardContext, IMKeyboardMetaModel>,
                                                AudioKeyboardHelperDelegate,
                                                ChatKeyboardViewPageItemProtocol,
                                                AudioSendMessageDelegate {
    var audioKeyboardHelper: AudioRecordPanelProtocol?
    private weak var audioToTextView: AudioToTextViewStopDelegate?

    private lazy var itemConfig: ChatKeyboardVoiceItemConfig? = {
        return try? context.userResolver.resolve(assert: ChatOpenKeyboardItemConfigService.self).getChatKeyboardItemFor(self.panelItemKey)
    }()

    private var supprtVoiceToText: Bool {
        return itemConfig?.uiConfig?.supprtVoiceToText ?? true
    }

    public override func didCreatePanelItem() -> InputKeyboardItem? {
        guard let chat = self.metaModel?.chat else {
            return nil
        }
        let from = chatPageItem?.chatFromWhere
        let uiConfig = self.itemConfig?.uiConfig
        let audioFS = userResolver.fg.staticFeatureGatingValue(with: .init(switch: .suiteVoice2Text))
        let audioWithTextEnable: Bool = audioFS && !chat.isPrivateMode && supprtVoiceToText
        let audioToTextEnable: Bool = audioFS && !chat.isPrivateMode && supprtVoiceToText
        return AudioKeyboardFactory.createVoiceKeyboardItem(
            userResolver: context.userResolver, chat: chat, audioToTextEnable: audioToTextEnable, audioWithTextEnable: audioWithTextEnable,
            supportStreamUpLoad: true, sendMessageDelegate: self, helperDelegate: self, iconColor: UIColor.ud.iconN2,
            audioToTextView: { [weak self] newView in
                self?.audioToTextView?.stopRecognize()
                self?.audioToTextView = newView
            },
            recordPanel: { panel in
                audioKeyboardHelper = panel
            }, updateIconCallBack: { [weak self] icons in
                guard let self = self else { return }
                self.reloadItemKeyboardIconIcons(icons)
            }, tappedBlock: {
                IMTracker.Chat.Main.Click.VoiceMsg(chat, nil, from)
                LarkMessageCoreTracker.trackClickKeyboardInputItem(KeyboardItemKey.voice)
                uiConfig?.tappedBlock?()
            })
    }

    public func audiokeybordPanelView() -> LKKeyboardView {
        return self.chatPageItem?.keyboardView ?? LKKeyboardView(frame: .zero,
                                                                 config: KeyboardLayouConfig(phoneStyle: InputAreaStyle.empty(),
                                                                                             padStyle: InputAreaStyle.empty()))
    }

    public func sendMessageWhenRecognition() {
        self.chatPageItem?.keyboardView?.sendNewMessage()
    }

    public func audiokeybordSendMessage(_ audioData: AudioDataInfo) {
        guard let chat = self.metaModel?.chat else { return }
        let lastMessagePosition: Int32 = chat.lastMessagePosition
        self.itemConfig?.sendService?.sendAudio(audio: audioData,
                                                parentMessage: self.chatPageItem?.getReplyInfo?()?.message,
                                                chatId: chat.id,
                                                lastMessagePosition: lastMessagePosition,
                                                quasiMsgCreateByNative: chat.anonymousId.isEmpty && !chat.isP2PAi)
        self.chatPageItem?.afterSendMessage?()
    }

    public func audiokeybordSendMessage(audioInfo: StreamAudioInfo) {
        guard let chat = self.metaModel?.chat else { return }
        self.itemConfig?.sendService?.sendAudio(audioInfo: audioInfo,
                                                parentMessage: self.chatPageItem?.getReplyInfo?()?.message,
                                                chatId: chat.id)
        self.chatPageItem?.afterSendMessage?()
    }

    public func audioSendTextMessage(str: String) {
        if let chat = self.metaModel?.chat,
           let richText = RichTextTransformKit.transformStringToRichText(string: NSAttributedString(string: str)) {
            self.itemConfig?.sendService?.sendText(
                content: richText,
                lingoInfo: nil,
                parentMessage: self.chatPageItem?.getReplyInfo?()?.message,
                chatId: chat.id,
                position: chat.lastMessagePosition,
                quasiMsgCreateByNative: chat.anonymousId.isEmpty && !chat.isP2PAi,
                callback: nil)
        }
    }
}
