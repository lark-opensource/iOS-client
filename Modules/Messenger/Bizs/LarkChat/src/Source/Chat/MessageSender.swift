//
//  MessageSender.swift
//  LarkChat
//
//  Created by zc09v on 2018/10/23.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import LarkModel
import Photos
import LarkAIInfra
import LarkMessageCore
import LarkSDKInterface
import LarkMessengerInterface
import LarkFoundation
import LarkContainer
import EENavigator
import RustPB
import LarkTracing
import LKCommonsLogging
import LarkFeatureGating
import LarkSendMessage
import LarkCore
import Homeric
import LKCommonsTracker

final class MessageSender: UserResolverWrapper {
    let userResolver: UserResolver
    @ScopedInjectedLazy var sendMessageAPI: SendMessageAPI?
    @ScopedInjectedLazy var postSendService: PostSendService?
    @ScopedInjectedLazy var docSDKAPI: ChatDocDependency?
    @ScopedInjectedLazy var videoMessageSendService: VideoMessageSendService?

    private let actionPosition: ActionPosition
    private let sendMessageTracker: SendMessageTracker
    private let chatBehaviorRelay: BehaviorRelay<Chat>
    private var chat: Chat {
        return chatBehaviorRelay.value
    }

    static let logger = Logger.log(MessageSender.self, category: "MessageSender")

    init(userResolver: UserResolver, actionPosition: ActionPosition, chatInfo: ChatKeyPointTrackerInfo, chat: BehaviorRelay<Chat>) {
        self.userResolver = userResolver
        self.actionPosition = actionPosition
        self.chatBehaviorRelay = chat
        self.sendMessageTracker = SendMessageTracker(userResolver: userResolver, chatInfo: chatInfo, actionPosition: actionPosition)
        self.onInitialize()
    }

    private func onInitialize() {
        // 解除LarkSendMessage对LarkCore的依赖
        self.sendMessageTracker.trackMsgDetailClick = { message, chat in
            guard let chat = chat, !chat.isCrypto, let message = message else { return }
            var params: [AnyHashable: Any] = ["click": "reply", "target": "none"]
            params += IMTracker.Param.chat(chat)
            params += IMTracker.Param.message(message)
            Tracker.post(TeaEvent(Homeric.IM_MSG_DETAIL_CLICK, params: params))
        }
    }

    /// APIContext属性调整
    private var contextModifiers: [APIContextModifier] = []
    public func addModifier(modifier: APIContextModifier) {
        self.contextModifiers.append(modifier)
    }

    // MARK: - 消息发送
    @inline(__always)
    private func genContextAndTrackSendMessageStart(params: [String: Any]? = nil, parentMessage: Message?) -> APIContext {
        let context = APIContext(contextID: self.sendMessageTracker.generateIndentify())
        let extraInfo = ExtraInfo(parentMessage: parentMessage)
        self.contextModifiers.forEach({ $0.modify(for: context, info: extraInfo) })
        self.sendMessageTracker.startSendMessage(context: context, params: params)
        return context
    }

    /// 发送快捷指令（API、Prompt 类型）
    func sendAIQuickAction(content: RustPB.Basic_V1_RichText,
                           chatId: String,
                           position: Int32,
                           quickActionID: String,
                           quickActionParams: [String: String]?,
                           quickActionBody: AIQuickAction?,
                           callback: ((SendMessageState) -> Void)?) {
        // 构建快捷指令参数
        var quickActionInfo = Basic_V1_QuickActionInfo()
        quickActionInfo.actionID = quickActionID
        quickActionInfo.inputMap = quickActionParams ?? [:]
        // TODO: @wanghaidong Caller 废弃了，但是 RustPB 还没标 optional，此处不传的话 req 会序列化失败
        quickActionInfo.caller = ""
        // 将快捷指令放入 context 中，透传到 RustSendMessageModule
        let context = genContextAndTrackSendMessageStart(parentMessage: nil)
        context.lastMessagePosition = position
        context.quasiMsgCreateByNative = false
        context.set(key: APIContext.myAIQuickActionInfo, value: quickActionInfo)
        // context 中附上 QuickAction 原始信息
        if let quickActionBody = quickActionBody {
            context.set(key: APIContext.myAIQuickActionBody, value: quickActionBody)
        }
        // 发送消息
        let params = SendTextParams(content: content,
                                    lingoInfo: nil,
                                    parentMessage: nil,
                                    chatId: chatId,
                                    threadId: nil,
                                    createScene: nil,
                                    scheduleTime: nil)
        self.sendMessageAPI?.sendText(context: context,
                                     sendTextParams: params,
                                     sendMessageTracker: sendMessageTracker,
                                     stateHandler: { callback?($0) })
    }

    /// 发送快捷指令（Query 类型：直接作文本发送）
    func sendAIQuery(content: RustPB.Basic_V1_RichText,
                     chatId: String,
                     position: Int32,
                     quickActionBody: AIQuickAction?,
                     callback: ((SendMessageState) -> Void)?) {
        let context = genContextAndTrackSendMessageStart(parentMessage: nil)
        context.lastMessagePosition = position
        context.quasiMsgCreateByNative = false
        // context 中附上 QuickAction 原始信息，透传到 RustSendMessageModule
        if let quickActionBody = quickActionBody {
            context.set(key: APIContext.myAIQuickActionBody, value: quickActionBody)
        }
        // 发送消息
        let params = SendTextParams(content: content,
                                    lingoInfo: nil,
                                    parentMessage: nil,
                                    chatId: chatId,
                                    threadId: nil,
                                    createScene: nil,
                                    scheduleTime: nil)
        self.sendMessageAPI?.sendText(context: context,
                                     sendTextParams: params,
                                     sendMessageTracker: sendMessageTracker,
                                     stateHandler: { callback?($0) })
    }

    func sendText(content: RustPB.Basic_V1_RichText,
                  lingoInfo: RustPB.Basic_V1_LingoOption?,
                  parentMessage: Message?,
                  chatId: String,
                  position: Int32,
                  scheduleTime: Int64? = nil,
                  quasiMsgCreateByNative: Bool,
                  callback: ((SendMessageState) -> Void)?) {
        Self.logger.info("sendTrace sendText start \(chatId) \(quasiMsgCreateByNative)")
        if let parentMessage = parentMessage {
            ChatTracker.trackMessageReply(
                parentMessage: parentMessage,
                messageType: .text,
                chatId: chatId,
                length: content.innerText.count,
                actionPosition: actionPosition,
                docSDKAPI: self.docSDKAPI,
                chat: chat)
        }
        let context = genContextAndTrackSendMessageStart(parentMessage: parentMessage)
        context.lastMessagePosition = position
        context.quasiMsgCreateByNative = quasiMsgCreateByNative
        let params = SendTextParams(content: content,
                                    lingoInfo: lingoInfo,
                                    parentMessage: parentMessage,
                                    chatId: chatId,
                                    threadId: nil,
                                    createScene: nil,
                                    scheduleTime: scheduleTime)
        self.sendMessageAPI?.sendText(context: context,
                                     sendTextParams: params,
                                     sendMessageTracker: sendMessageTracker,
                                     stateHandler: { callback?($0) })
    }

    func sendSticker(sticker: RustPB.Im_V1_Sticker, parentMessage: Message?, chat: Chat, stickersCount: Int) {
        let chatId = chat.id
        if let parentMessage = parentMessage {
            ChatTracker.trackMessageReply(parentMessage: parentMessage, messageType: .sticker, chatId: chatId, actionPosition: actionPosition, docSDKAPI: self.docSDKAPI, chat: chat)
        }

        let context = genContextAndTrackSendMessageStart(parentMessage: parentMessage)
        self.sendMessageAPI?.sendSticker(context: context,
                                        sticker: sticker,
                                        parentMessage: parentMessage,
                                        chatId: chat.id,
                                        threadId: nil,
                                        sendMessageTracker: sendMessageTracker,
                                        stateHandler: { state in
            if case .beforeSendMessage(let message, _) = state {
                ChatTracker.trackSendSticker(chat, sticker: sticker, message: message, stickersCount: stickersCount)
            }
        })
    }

    func sendAudio(audio: AudioDataInfo, parentMessage: Message?, chatId: String, lastMessagePosition: Int32?, quasiMsgCreateByNative: Bool) {
        if let parentMessage = parentMessage {
            ChatTracker.trackMessageReply(parentMessage: parentMessage, messageType: .audio, chatId: chatId, actionPosition: actionPosition, docSDKAPI: self.docSDKAPI, chat: chat)
        }

        let context = genContextAndTrackSendMessageStart(parentMessage: parentMessage)
        context.lastMessagePosition = lastMessagePosition
        context.quasiMsgCreateByNative = quasiMsgCreateByNative
        self.sendMessageAPI?.sendAudio(context: context,
                                      audio: audio,
                                      parentMessage: parentMessage,
                                      chatId: chatId,
                                      threadId: nil,
                                      sendMessageTracker: sendMessageTracker,
                                      stateHandler: nil)
    }

    func sendAudio(audioInfo: StreamAudioInfo, parentMessage: Message?, chatId: String) {
        if let parentMessage = parentMessage {
            ChatTracker.trackMessageReply(parentMessage: parentMessage, messageType: .audio, chatId: chatId, actionPosition: actionPosition, docSDKAPI: self.docSDKAPI, chat: chat)
        }

        let context = genContextAndTrackSendMessageStart(parentMessage: parentMessage)
        self.sendMessageAPI?.sendAudio(context: context,
                                      audioInfo: audioInfo,
                                      parentMessage: parentMessage,
                                      chatId: chatId,
                                      threadId: nil,
                                      sendMessageTracker: sendMessageTracker,
                                      stateHandler: nil)
    }

    func sendFile(path: String,
                  name: String,
                  parentMessage: Message?,
                  removeOriginalFileAfterFinish: Bool,
                  chatId: String,
                  lastMessagePosition: Int32?,
                  quasiMsgCreateByNative: Bool?,
                  preprocessResourceKey: String? = nil) {
        if let parentMessage = parentMessage {
            ChatTracker.trackMessageReply(parentMessage: parentMessage, messageType: .file, chatId: chatId, actionPosition: actionPosition, docSDKAPI: self.docSDKAPI, chat: chat)
        }

        let context = genContextAndTrackSendMessageStart(parentMessage: parentMessage)
        context.lastMessagePosition = lastMessagePosition
        context.quasiMsgCreateByNative = quasiMsgCreateByNative
        context.preprocessResourceKey = preprocessResourceKey
        self.sendMessageAPI?.sendFile(context: context,
                                     path: path,
                                     name: name,
                                     parentMessage: parentMessage,
                                     removeOriginalFileAfterFinish: removeOriginalFileAfterFinish,
                                     chatId: chatId,
                                     threadId: nil,
                                     sendMessageTracker: sendMessageTracker,
                                     stateHandler: nil)
    }

    func sendPost(title: String,
                  content: RustPB.Basic_V1_RichText,
                  lingoInfo: RustPB.Basic_V1_LingoOption?,
                  parentMessage: Message?,
                  chatId: String,
                  isGroupAnnouncement: Bool = false,
                  scheduleTime: Int64? = nil,
                  stateHandler: ((SendMessageState) -> Void)?) {
        if let parentMessage = parentMessage {
            ChatTracker.trackMessageReply(
                parentMessage: parentMessage,
                messageType: .post,
                chatId: chatId,
                length: content.innerText.count,
                actionPosition: actionPosition,
                docSDKAPI: self.docSDKAPI,
                chat: chat)
        }

        let context = genContextAndTrackSendMessageStart(parentMessage: parentMessage)
        postSendService?.sendMessage(
            context: context,
            title: title,
            content: content,
            lingoInfo: lingoInfo,
            parentMessage: parentMessage,
            chatId: chatId,
            threadId: nil,
            isGroupAnnouncement: isGroupAnnouncement,
            // MessageSender只在Chat和MessageDetail使用，这两处不支持设置匿名
            isAnonymous: false,
            isReplyInThread: false,
            transmitToChat: false,
            scheduleTime: scheduleTime,
            sendMessageTracker: sendMessageTracker,
            stateHandler: { stateHandler?($0) })
    }

    // extraTrackerContext：埋点补充参数
    func sendImages(parentMessage: Message?,
                    useOriginal: Bool,
                    imageMessageInfos: [ImageMessageInfo],
                    chatId: String,
                    lastMessagePosition: Int32,
                    quasiMsgCreateByNative: Bool,
                    extraTrackerContext: [String: Any] = [:],
                    stateHandler: ((Int, SendMessageState) -> Void)? = nil) {
        if let parentMessage = parentMessage {
            imageMessageInfos.forEach { (_) in
                ChatTracker.trackMessageReply(parentMessage: parentMessage, messageType: .image, chatId: chatId, actionPosition: actionPosition, docSDKAPI: self.docSDKAPI, chat: chat)
            }
        }

        var extraTrackerContext = extraTrackerContext
        extraTrackerContext["useOriginal"] = "\(useOriginal)"
        let contextArray: [APIContext] = imageMessageInfos.map { info -> APIContext in
            let context = genContextAndTrackSendMessageStart(params: extraTrackerContext, parentMessage: parentMessage)
            context.lastMessagePosition = lastMessagePosition
            context.quasiMsgCreateByNative = quasiMsgCreateByNative
            context.preprocessResourceKey = info.preprocessResourceKey
            return context
        }
        self.sendMessageAPI?.sendImages(contexts: contextArray,
                                       parentMessage: parentMessage,
                                       useOriginal: useOriginal,
                                       imageMessageInfos: imageMessageInfos,
                                       chatId: chatId,
                                       threadId: nil,
                                       sendMessageTracker: sendMessageTracker,
                                       stateHandler: { index, state in
                                            stateHandler?(index, state)
                                      })
    }

    // extraTrackerContext：埋点补充参数
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
                   extraTrackerContext: [String: Any] = [:]) {
        if let parentMessage = parentMessage {
            ChatTracker.trackMessageReply(parentMessage: parentMessage, messageType: .media, chatId: chatId, actionPosition: actionPosition, docSDKAPI: self.docSDKAPI, chat: chat)
        }

        // 真正的发送逻辑处理部分
        let context = genContextAndTrackSendMessageStart(params: extraTrackerContext, parentMessage: parentMessage)
        var extraParam: [String: Any] = ["": ""]
        if let lastMessagePosition = lastMessagePosition, let quasiMsgCreateByNative = quasiMsgCreateByNative {
            extraParam = ["lastMessagePosition": lastMessagePosition,
                          "quasiMsgCreateByNative": quasiMsgCreateByNative,
                          APIContext.chatDisplayModeKey: context.chatDisplayMode]
        }
        let params = SendVideoParams(content: content,
                                     isCrypto: isCrypto,
                                     isOriginal: isOriginal,
                                     forceFile: forceFile,
                                     chatId: chatId,
                                     threadId: nil,
                                     parentMessage: parentMessage,
                                     from: from)
        self.videoMessageSendService?.sendVideo(with: params,
                                               extraParam: extraParam,
                                               context: context,
                                               createScene: nil,
                                               sendMessageTracker: sendMessageTracker,
                                               resourceManager: preProcessManager,
                                               stateHandler: nil)
    }
    // swiftlint:enable function_parameter_count

    func sendLocation(parentMessage: Message?, chatId: String, screenShot: UIImage, location: LocationContent) {
        let context = genContextAndTrackSendMessageStart(parentMessage: parentMessage)
        self.sendMessageAPI?.sendLocation(context: context,
                                         parentMessage: parentMessage,
                                         chatId: chatId,
                                         threadId: nil,
                                         screenShot: screenShot,
                                         location: location,
                                         sendMessageTracker: sendMessageTracker,
                                         stateHandler: nil)
    }

    func sendUserCard(shareChatterId: String, chatId: String) {
        let context = genContextAndTrackSendMessageStart(parentMessage: nil)
        self.sendMessageAPI?.sendShareUserCardMessage(context: context,
                                                     shareChatterId: shareChatterId,
                                                     sendChannelType: .chat(id: chatId),
                                                     sendMessageTracker: sendMessageTracker,
                                                     stateHandler: nil)
    }
}
