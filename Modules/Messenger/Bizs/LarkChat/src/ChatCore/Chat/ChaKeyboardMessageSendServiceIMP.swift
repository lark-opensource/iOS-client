//
//  ChaKeyboardMessageSendServiceIMP.swift
//  LarkChat
//
//  Created by liluobin on 2023/5/15.
//

import UIKit
import LarkModel
import RustPB
import LarkChatOpenKeyboard
import LarkChatKeyboardInterface
import LarkAIInfra
import LarkSendMessage
import EENavigator
import LarkMessengerInterface
import LarkSDKInterface

class ChatKeyboardMessageSendServiceIMP: KeyboardMoreItemSendService,
                                         ChatOpenKeyboardSendService,
                                         KeyboardAudioItemSendService,
                                         KeyboardEmojiItemSendService,
                                         KeyboardPictureItemSendService,
                                         ChatKeyboardMessageSendService,
                                         KeyboardCanvasItemSendService {

    private let _messageSender: () -> MessageSender

    lazy var messageSender: MessageSender = {
        let sender = self._messageSender()
        sender.addModifier(modifier: PartialReplyInfoModifier(getReplyInfoForMessage: self.getReplyInfoForMessage))
        return sender
    }()

    var getReplyInfoForMessage: ((Message?) -> PartialReplyInfo?)?

    /// init
    init(messageSender: @escaping () -> MessageSender) {
        self._messageSender = messageSender
    }

    /// KeyboardEmojiItemSendService
    func sendSticker(sticker: RustPB.Im_V1_Sticker, parentMessage: Message?, chat: Chat, stickersCount: Int) {
        self.messageSender.sendSticker(sticker: sticker, parentMessage: parentMessage, chat: chat, stickersCount: stickersCount)
    }

    /// KeyboardPictureItemSendService
    // swiftlint:disable function_parameter_count
    func sendVideo(with content: SendVideoContent,
                   isCrypto: Bool,
                   forceFile: Bool,
                   isOriginal: Bool,
                   chatId: String,
                   parentMessage: Message?,
                   lastMessagePosition: Int32?,
                   quasiMsgCreateByNative: Bool?,
                   preProcessManager: ResourcePreProcessManager?,
                   from: NavigatorFrom,
                   extraTrackerContext: [String: Any]) {
        self.messageSender.sendVideo(with: content,
                                     isCrypto: isCrypto,
                                     forceFile: forceFile,
                                     isOriginal: isOriginal,
                                     chatId: chatId,
                                     parentMessage: parentMessage,
                                     lastMessagePosition: lastMessagePosition,
                                     quasiMsgCreateByNative: quasiMsgCreateByNative,
                                     preProcessManager: preProcessManager,
                                     from: from,
                                     extraTrackerContext: extraTrackerContext)
    }
    // swiftlint:enable function_parameter_count

    func sendImages(parentMessage: Message?,
                    useOriginal: Bool,
                    imageMessageInfos: [ImageMessageInfo],
                    chatId: String,
                    lastMessagePosition: Int32,
                    quasiMsgCreateByNative: Bool,
                    extraTrackerContext: [String: Any],
                    stateHandler: ((Int, SendMessageState) -> Void)?) {
        self.messageSender.sendImages(parentMessage: parentMessage,
                        useOriginal: useOriginal,
                        imageMessageInfos: imageMessageInfos,
                        chatId: chatId,
                        lastMessagePosition: lastMessagePosition,
                        quasiMsgCreateByNative: quasiMsgCreateByNative,
                        extraTrackerContext: extraTrackerContext,
                        stateHandler: stateHandler)
    }

    /// KeyboardAudioItemSendService
    func sendAudio(audio: LarkSendMessage.AudioDataInfo,
                   parentMessage: LarkModel.Message?,
                   chatId: String,
                   lastMessagePosition: Int32?,
                   quasiMsgCreateByNative: Bool) {
        self.messageSender.sendAudio(audio: audio,
                                     parentMessage: parentMessage,
                                     chatId: chatId,
                                     lastMessagePosition: lastMessagePosition,
                                     quasiMsgCreateByNative: quasiMsgCreateByNative)
    }

    func sendAudio(audioInfo: LarkSendMessage.StreamAudioInfo,
                   parentMessage: LarkModel.Message?,
                   chatId: String) {
        self.messageSender.sendAudio(audioInfo: audioInfo, parentMessage: parentMessage, chatId: chatId)
    }

    /// ChatOpenKeyboardSendService
    func sendFile(path: String,
                  name: String,
                  parentMessage: Message?,
                  removeOriginalFileAfterFinish: Bool,
                  chatId: String,
                  lastMessagePosition: Int32?,
                  quasiMsgCreateByNative: Bool?,
                  preprocessResourceKey: String?) {
        self.messageSender.sendFile(path: path,
                      name: name,
                      parentMessage: parentMessage,
                      removeOriginalFileAfterFinish: removeOriginalFileAfterFinish,
                      chatId: chatId,
                      lastMessagePosition: lastMessagePosition,
                      quasiMsgCreateByNative: quasiMsgCreateByNative,
                      preprocessResourceKey: preprocessResourceKey)
    }

    func sendText(content: RustPB.Basic_V1_RichText,
                  lingoInfo: RustPB.Basic_V1_LingoOption?,
                  parentMessage: Message?,
                  chatId: String,
                  position: Int32,
                  scheduleTime: Int64?,
                  quasiMsgCreateByNative: Bool,
                  callback: ((SendMessageState) -> Void)?) {
        self.messageSender.sendText(content: content,
                                    lingoInfo: lingoInfo,
                                    parentMessage: parentMessage,
                                    chatId: chatId,
                                    position: position,
                                    scheduleTime: scheduleTime,
                                    quasiMsgCreateByNative: quasiMsgCreateByNative,
                                    callback: callback)
    }

    func sendText(content: RustPB.Basic_V1_RichText,
                  lingoInfo: RustPB.Basic_V1_LingoOption?,
                  parentMessage: Message?,
                  chatId: String,
                  position: Int32,
                  quasiMsgCreateByNative: Bool,
                  callback: ((SendMessageState) -> Void)?) {
        self.messageSender.sendText(content: content,
                                    lingoInfo: lingoInfo,
                                    parentMessage: parentMessage,
                                    chatId: chatId,
                                    position: position,
                                    quasiMsgCreateByNative: quasiMsgCreateByNative,
                                    callback: callback)
    }

    func sendAIQuickAction(content: RustPB.Basic_V1_RichText,
                           chatId: String,
                           position: Int32,
                           quickActionID: String,
                           quickActionParams: [String: String]?,
                           quickActionBody: AIQuickAction?,
                           callback: ((SendMessageState) -> Void)?) {
        self.messageSender.sendAIQuickAction(content: content,
                                             chatId: chatId,
                                             position: position,
                                             quickActionID: quickActionID,
                                             quickActionParams: quickActionParams,
                                             quickActionBody: quickActionBody,
                                             callback: callback)
    }

    func sendAIQuery(content: Basic_V1_RichText,
                     chatId: String,
                     position: Int32,
                     quickActionBody: AIQuickAction?,
                     callback: ((SendMessageState) -> Void)?) {
        self.messageSender.sendAIQuery(
            content: content,
            chatId: chatId,
            position: position,
            quickActionBody: quickActionBody,
            callback: callback
        )
    }

    func sendPost(title: String,
                  content: RustPB.Basic_V1_RichText,
                  lingoInfo: RustPB.Basic_V1_LingoOption?,
                  parentMessage: LarkModel.Message?,
                  chatId: String,
                  scheduleTime: Int64?,
                  stateHandler: ((LarkSendMessage.SendMessageState) -> Void)?) {
        self.messageSender.sendPost(title: title,
                                    content: content,
                                    lingoInfo: lingoInfo,
                                    parentMessage: parentMessage,
                                    chatId: chatId,
                                    scheduleTime: scheduleTime,
                                    stateHandler: stateHandler)
    }

    func sendUserCard(shareChatterId: String, chatId: String) {
        self.messageSender.sendUserCard(shareChatterId: shareChatterId, chatId: chatId)
    }

    func sendLocation(parentMessage: Message?, chatId: String, screenShot: UIImage, location: LocationContent) {
        self.messageSender.sendLocation(parentMessage: parentMessage, chatId: chatId, screenShot: screenShot, location: location)
    }
}
