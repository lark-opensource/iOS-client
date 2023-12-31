//
//  ThreadKeyboardVoiceSubModule.swift
//  LarkThread
//
//  Created by liluobin on 2023/4/11.
//

import UIKit
import LarkOpenKeyboard
import LarkBaseKeyboard
import LarkChatOpenKeyboard
import LarkKeyboardView
import LarkAudio
import LarkFoundation
import LarkMessageCore
import LarkCore
import LarkModel
import LarkFeatureGating
import LarkKAFeatureSwitch
import RxCocoa
import RxSwift
import LarkSendMessage
import RustPB
import LarkContainer

/// TODO: IM的键盘没有删除helper
public class NormalThreadKeyboardVoiceSubModule: BaseThreadKeyboardVoiceSubModule {

    public override func audiokeybordSendMessage(_ audioData: AudioDataInfo) {
        guard let sendMessageAPI else { return }
        guard let parentMessage = self.threadPageItem?.getReplyMessage?(),
        let chat = self.metaModel?.chat,
        let threadId = self.threadPageItem?.thread.id else {
            assertionFailure("error data")
            return
        }
        sendMessageAPI.sendAudio(context: nil,
                                      audio: audioData,
                                      parentMessage: parentMessage,
                                      chatId: chat.id,
                                      threadId: threadId,
                                      stateHandler: nil)

    }
    public override func audiokeybordSendMessage(audioInfo: StreamAudioInfo) {
        guard let sendMessageAPI else { return }
        guard let parentMessage = self.threadPageItem?.getReplyMessage?(),
        let chat = self.metaModel?.chat,
        let threadId = self.threadPageItem?.thread.id else {
            assertionFailure("error data")
            return
        }
        sendMessageAPI.sendAudio(context: nil,
                                      audioInfo: audioInfo,
                                      parentMessage: parentMessage,
                                      chatId: chat.id,
                                      threadId: threadId,
                                      sendMessageTracker: nil,
                                      stateHandler: nil)
    }

    // 实现 Audio 的协议，发送文字
    public override func audioSendTextMessage(str: String) {
        guard let sendMessageAPI else { return }
        guard let parentMessage = self.threadPageItem?.getReplyMessage?(),
        let chat = self.metaModel?.chat,
        let threadId = self.threadPageItem?.thread.id,
        let richText = RichTextTransformKit.transformStringToRichText(string: NSAttributedString(string: str)) else {
            assertionFailure("error data")
            return
        }
        sendMessageAPI.sendText(context: nil,
                                content: richText,
                                parentMessage: parentMessage,
                                chatId: chat.id,
                                threadId: threadId,
                                stateHandler: nil)
    }
}

public class MessageThreadKeyboardVoiceSubModule: BaseThreadKeyboardVoiceSubModule {

    public override func audiokeybordSendMessage(_ audioData: AudioDataInfo) {
        guard let sendMessageAPI else { return }
        guard let parentMessage = self.threadPageItem?.getReplyMessage?(),
        let chat = self.metaModel?.chat,
        let threadId = self.threadPageItem?.thread.id  else {
            assertionFailure("error data")
            return
        }
        sendMessageAPI.sendAudio(context: defaultSendContext(),
                                      audio: audioData,
                                      parentMessage: parentMessage,
                                      chatId: chat.id,
                                      threadId: threadId) { [weak self] status in
            self?.trackReplyMsgSend(state: status, chatModel: self?.metaModel?.chat)
        }
    }

    public override func audiokeybordSendMessage(audioInfo: StreamAudioInfo) {
        guard let sendMessageAPI else { return }
        guard let parentMessage = self.threadPageItem?.getReplyMessage?(),
        let chat = self.metaModel?.chat,
        let threadId = self.threadPageItem?.thread.id  else {
            assertionFailure("error data")
            return
        }

        sendMessageAPI.sendAudio(context: defaultSendContext(),
                                      audioInfo: audioInfo,
                                      parentMessage: parentMessage,
                                      chatId: chat.id,
                                      threadId: threadId,
                                      sendMessageTracker: nil) {  [weak self] status in
            self?.trackReplyMsgSend(state: status, chatModel: self?.metaModel?.chat)
        }

    }

    // 实现 Audio 的协议，发送文字
    public override func audioSendTextMessage(str: String) {
        guard let sendMessageAPI else { return }
        guard let parentMessage = self.threadPageItem?.getReplyMessage?(),
        let chat = self.metaModel?.chat,
        let threadId = self.threadPageItem?.thread.id,
        let richText = RichTextTransformKit.transformStringToRichText(string: NSAttributedString(string: str)) else {
            assertionFailure("error data")
            return
        }
        sendMessageAPI.sendText(context: defaultSendContext(),
                                content: richText,
                                parentMessage: parentMessage,
                                chatId: chat.id,
                                threadId: threadId,
                                stateHandler: nil)
    }
}

open class BaseThreadKeyboardVoiceSubModule: KeyboardPanelVoiceSubModule<KeyboardContext, IMKeyboardMetaModel>,
                                                ThreadKeyboardViewPageItemProtocol,
                                                AudioKeyboardHelperDelegate,
                                                AudioSendMessageDelegate {

    var audioKeyboardHelper: AudioRecordPanelProtocol?
    private weak var audioToTextView: AudioToTextViewStopDelegate?

    @ScopedInjectedLazy var sendMessageAPI: SendMessageAPI?

    open override func didCreatePanelItem() -> InputKeyboardItem? {
        guard !Utils.isiOSAppOnMacSystem, let chat = self.metaModel?.chat else { return nil }
        let audioFS = context.getFeatureGating(.init(switch: .suiteVoice2Text))
        return AudioKeyboardFactory.createVoiceKeyboardItem(
            userResolver: context.userResolver, chat: chat, audioToTextEnable: audioFS, audioWithTextEnable: audioFS, supportStreamUpLoad: true,
            sendMessageDelegate: self, helperDelegate: self, iconColor: ThreadKeyboardPageItem.iconColor,
            audioToTextView: { [weak self] newView in
                self?.audioToTextView?.stopRecognize()
                self?.audioToTextView = newView
            },
            recordPanel: { panel in
                audioKeyboardHelper = panel
            }, updateIconCallBack: { [weak self] icons in
                guard let self = self else { return }
                self.reloadItemKeyboardIconIcons(icons)
            }, tappedBlock: { [weak self] in
                if let id = self?.threadPageItem?.thread.id {
                    ChannelTracker.TopicDetail.Click.VoiceMsg(chat, id)
                }
                LarkMessageCoreTracker.trackClickKeyboardInputItem(KeyboardItemKey.voice)
                self?.context.keyboardAppearForSelectedPanel(item: KeyboardItemKey.voice)
            })
    }

    public func audiokeybordPanelView() -> LKKeyboardView {
        return self.threadPageItem?.keyboardView ?? LKKeyboardView(frame: .zero,
                                                                      config: KeyboardLayouConfig(phoneStyle: InputAreaStyle.empty(),
                                                                                                  padStyle: InputAreaStyle.empty()))
    }

    public func sendMessageWhenRecognition() {
        self.threadPageItem?.keyboardView?.sendNewMessage()
    }

    public func audiokeybordSendMessage(_ audioData: AudioDataInfo) {
    }

    public func audiokeybordSendMessage(audioInfo: StreamAudioInfo) {

    }

    public func audioSendTextMessage(str: String) {

    }
}
