//
//  RustSendMessageModule.swift
//  Lark
//
//  Created by liuwanlin on 2017/12/27.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift // Observable
import RustPB // Basic_V1_Trace
import LarkModel // Message
import LarkSDKInterface // SDKRustService
import LarkRustClient // RequestPacket
import LarkTracing // LarkTracingUtil
import LKCommonsLogging // Logger
import LarkAIInfra // MyAIChatModeConfig

/// sendMessage结果封装
struct SendResult {
    let contextId: String
    /// 消息发送成功时有值
    var messageId: String?
    /// 消息发送成功时有值
    var netCost: UInt64 = 0
    ///trace
    var trace: Basic_V1_Trace?

    init(contextId: String) {
        self.contextId = contextId
    }
}

public enum CreateQuasiMsgType {
    // 端上创建假消息
    case native
    // Rust创建假消息
    case rust
}

final class RustSendMessageModule {
    static let logger = Logger.log("RustSendMessageModule")

    class func genCreateQuasiMsgType(_ input: SendMessageProcessInput<SendTextModel>) -> CreateQuasiMsgType {
        // 如果有@则不在端上创建假消息：RichText中name存的是原名，需要Rust替换为备注等其他名
        if input.useNativeCreate, input.model.content.atIds.isEmpty {
            return .native
        }
        return .rust
    }

    class func createQuasiMessage(
        chatId: String,
        threadId: String = "",
        rootId: String = "",
        parentId: String = "",
        type: LarkModel.Message.TypeEnum,
        content: QuasiContent,
        shouldNotify: Bool = true,
        imageCompressedSize: Int64 = 0,
        uploadID: String? = nil,
        cid: String? = nil,
        position: Int32? = nil,
        client: SDKRustService,
        scheduleTime: Int64? = nil,
        transmitToChat: Bool = false,
        createScene: Basic_V1_CreateScene? = nil,
        context: APIContext?) throws -> (LarkModel.Message, contextId: String) {
        var req = CreateQuasiMessageRequest()
        logger.info("[SendMessage]: createQuasiMessage \(String(describing: createScene))")
        if let scene = createScene {
            req.createScene = scene
        }
        req.rootID = rootId
        req.parentID = parentId
        req.content = content
        // scheduleTime如果有值，表示定时消息发送
        if let scheduleTime = scheduleTime {
            req.scheduleTime = scheduleTime
        }
        req.transmitToChat = transmitToChat
        req.type = type
        req.isAnonymous = context?.get(key: APIContext.anonymousKey) ?? false
        req.isReplyInThread = context?.get(key: APIContext.replyInThreadKey) ?? false
        req.shouldNotify = shouldNotify
        req.threadID = threadId
        if let uploadID = uploadID {
            req.uploadID = uploadID
        }
        if let cid = cid {
            req.cid = cid
        }
        if let position = position {
            req.position = position
        }
        if req.isReplyInThread {
            req.position = replyInThreadMessagePosition
        }
        // ChatMode场景，带上aiChatModeID、aiAppContextData，position设置为-3，避免假消息在主会场上屏
        let chatModeConfig: MyAIChatModeConfig? = context?.get(key: APIContext.myAIChatModeConfig)
        // MyAI主会场相关参数，发消息时决定是否触发新话题
        let myAIMainChatConfig: MyAIMainChatConfig? = context?.get(key: APIContext.myAIMainChatConfig)
        if let chatModeConfig = chatModeConfig {
            req.aiChatModeID = chatModeConfig.aiChatModeId
            var aiInfoContext = RustPB.Basic_V1_AIInfoContext()
            aiInfoContext.aiChatModeID = chatModeConfig.aiChatModeId
            aiInfoContext.chatContext = chatModeConfig.getCurrentChatContext()
            req.aiInfoContext = aiInfoContext
            req.position = replyInThreadMessagePosition
            req.isReplyInThread = true
        } else if let myAIMainChatConfig = myAIMainChatConfig {
            var aiInfoContext = RustPB.Basic_V1_AIInfoContext()
            aiInfoContext.isNewTopic = if case .notShow = myAIMainChatConfig.onBoardInfoSubject.value { false } else { true }
            req.aiInfoContext = aiInfoContext
        }
        let partialReplyInfo: PartialReplyInfo? = context?.get(key: APIContext.partialReplyInfo)
        if let partialReplyInfo = partialReplyInfo {
            req.partialReplyInfo = partialReplyInfo
        }
        // 如果是走发送快捷指令流程，填充快捷指令参数
        if let quickAction: AIQuickAction = context?.get(key: APIContext.myAIQuickActionBody) {
            // 透传快捷指令 extraMap 中所携带的召回源等参数（Query、Prompt、API 类型的快捷指令都要传）
            let recallMap = quickAction.serverRecallMap
            if !recallMap.isEmpty {
                req.aiInfoContext.chatContext.extraMap.merge(recallMap, uniquingKeysWith: { old, _ in old })
                RustSendMessageAPI.logger.info("[MyAI.QuickAction][Send][\(#function)] fill quick action request by extra map: \(recallMap)")
            }
            // Request 中填充快捷指令 ID 及参数信息（非 Query 类型的快捷指令才要传）
            if var quickActionInfo: Basic_V1_QuickActionInfo = context?.get(key: APIContext.myAIQuickActionInfo), !quickAction.typeIsQuery {
                if let chatModeConfig = chatModeConfig {
                    // 分会场场景下，需要从业务方获取默认快捷指令参数，并补充到 inputMap 中
                    // NOTE: 业务方自定的默认参数（文档权限，选区信息等）不需要用户输入，自动从 ChatModeConfig 获取并填充
                    let businessParams = chatModeConfig.quickActionsParamsProvider?(quickAction) ?? [:]
                    let updatedParams = quickActionInfo.inputMap.merging(businessParams, uniquingKeysWith: { _, new in new })
                    quickActionInfo.inputMap = updatedParams
                    RustSendMessageAPI.logger.info("[MyAI.QuickAction][Send][\(#function)] fill quick action request by business params: \(businessParams)")
                }
                req.aiInfoContext.quickActionInfo = quickActionInfo
            }
        }
        var channelPb = RustPB.Basic_V1_Channel()
        channelPb.id = chatId
        channelPb.type = .chat
        req.channel = channelPb
        if imageCompressedSize > 0 {
            req.imageCompressedSizeKb = imageCompressedSize
        }
        var pack = RequestPacket(message: req)
        pack.parentID = context?.contextID
        if let cid = cid {
            pack.spanID = LarkTracingUtil.sendMessageGetSpanIDByName(spanName: LarkTracingUtil.createQuasiMessage, cid: cid)
        }
        let res: ResponsePacket<CreateQuasiMessageResponse> = client.sync(pack)
        let response = try res.result.get()
        RustSendMessageAPI.logger.info("sendTrace createQuasiMessage_getResponse-cid-\(response.cid)")
        let message = try RustAggregatorTransformer.transformToQuasiMessage(
            entity: response.entity,
            cid: response.cid
        )
        RustSendMessageAPI.logger.info("sendTrace createQuasiMessage_getMessage-contextId-\(res.contextID)-cid-\(message.cid)")
        message.localStatus = .process
        message.meRead = true
        return (message, contextId: context?.contextID ?? "")
    }

    class func updateQuasiMessage(cid: String, status: RustPB.Basic_V1_QuasiMessage.Status, client: SDKRustService, context: APIContext?) {
        var request = UpdateQuasiMessageRequest()
        request.cid = cid
        request.status = status
        var pack = RequestPacket(message: request)
        pack.parentID = context?.contextID
        // 更新假消息状态，允许在主线程调用，本身操作很轻量
        pack.allowOnMainThread = true
        client.sync(pack)
    }

    class func cancelSendMessage(cid: String, client: SDKRustService, context: APIContext?) {
        var request = Im_V1_CancelSendMessageRequest()
        request.cid = cid
        var pack = RequestPacket(message: request)
        pack.parentID = context?.contextID
        client.sync(pack)
    }

    class func createQuasiThreadMessage(
        to threadType: SendThreadToType,
        chatId: String,
        type: LarkModel.Message.TypeEnum,
        content: QuasiContent,
        client: SDKRustService,
        context: APIContext?) throws -> ThreadMessage? {
        var channelPb = RustPB.Basic_V1_Channel()
        channelPb.id = chatId
        channelPb.type = .chat

        var request: CreateQuasiMessageRequest
        // 小组发帖，支持匿名
        var req = CreateQuasiMessageRequest()
        req.content = content
        req.type = type
        req.isAnonymous = context?.get(key: APIContext.anonymousKey) ?? false
        req.channel = channelPb
        req.isReplyInThread = context?.get(key: APIContext.replyInThreadKey) ?? false
        if req.isReplyInThread {
            req.position = replyInThreadMessagePosition
        }
        request = req
        var pack = RequestPacket(message: request)
        pack.parentID = context?.contextID

        let response: (cid: String, entity: RustPB.Basic_V1_Entity)
        let tmpResponse: CreateQuasiMessageResponse = try client.sync(pack).result.get()
        response = (tmpResponse.cid, tmpResponse.entity)

        let message = try RustAggregatorTransformer.transformToQuasiMessage(
            entity: response.entity,
            cid: response.cid
        )
        message.localStatus = .process
        message.meRead = true

        if let quasiThread = response.entity.quasiThreads[message.cid]?.transformToRustThread(),
            let chatPB = response.entity.chats[message.channel.id] {
            let chat = Chat.transform(pb: chatPB)

            var topicGroup: TopicGroup?
            if let topicGroupPB = response.entity.topicGroups[message.channel.id] {
                topicGroup = TopicGroup.transform(pb: topicGroupPB)
            }
            return ThreadMessage(chat: chat, topicGroup: topicGroup, thread: quasiThread, rootMessage: message)
        } else {
            RustSendThreadAPI.logger.error(
                """
                LarkThread create quasiMessage fail
                \(chatId)
                \(message.cid)
                \(response.entity.quasiThreads.keys.contains(message.cid))
                \(response.entity.chats.keys.contains(message.channel.id)))
                """
            )
        }
        return nil
    }

    class func sendMessage(cid: String,
                           client: SDKRustService,
                           context: APIContext?,
                           multiSendSerialToken: UInt64? = nil,
                           multiSendSerialDelay: TimeInterval? = nil)
    -> Observable<SendResult> {
        var req = SendMessageRequest()
        req.cid = cid
        if let preprocessKey = context?.preprocessResourceKey {
            req.preprocessKey = preprocessKey
        }
        var pack = RequestPacket(message: req)
        pack.parentID = context?.contextID
        // 多选发送的时候使用一个串行队列去发送，这里用SerialToken来标记
        if let token = multiSendSerialToken {
            pack.serialToken = token
        }
        if let multiSendSerialDelay {
            pack.serialDelay = multiSendSerialDelay
        }
        pack.spanID = LarkTracingUtil.sendMessageGetSpanIDByName(spanName: LarkTracingUtil.callSendMessageAPI, cid: cid)
        pack.collectTrace = true
        return client.async(pack).map { (res: ResponsePacket<SendMessageResponse>) in
            _ = try res.result.get()
            var response = SendResult(contextId: res.contextID)
            if case .success(let res) = res.result {
                response.messageId = res.messageID
                response.netCost = res.netCost
                response.trace = res.trace
            }
            return response
        }
    }

    class func resendMessage(cid: String, client: SDKRustService, context: APIContext?) -> Observable<Void> {
        var req = ResendMessageRequest()
        req.cid = cid

        var pack = RequestPacket(message: req)
        pack.parentID = context?.contextID
        return client.async(pack).map { (_: ResendMessageResponse) -> Void in }
    }

    class func getRootId(parentMessage: Message?,
                         replyInThread: Bool) -> String {
        var rootId = parentMessage?.rootId ?? ""
        /// replyInThread情况下，rootId就是当前消息 parentMessage?.id
        if replyInThread {
            rootId = parentMessage?.id ?? ""
        } else {
            let parentId = parentMessage?.id ?? ""
            rootId = rootId.isEmpty ? parentId : rootId
        }
        return rootId
    }
}

// request
public typealias QuasiContent = RustPB.Basic_V1_QuasiContent
typealias CreateQuasiMessageRequest = RustPB.Im_V1_CreateQuasiMessageRequest
typealias UpdateQuasiMessageRequest = RustPB.Im_V1_UpdateQuasiMessageRequest
typealias ShareAppCardRequest = RustPB.Im_V1_ShareAppCardRequest
typealias SendMessageRequest = RustPB.Im_V1_SendMessageRequest
typealias ResendMessageRequest = RustPB.Im_V1_ResendMessageRequest
// reponse
typealias CreateQuasiMessageResponse = RustPB.Im_V1_CreateQuasiMessageResponse
typealias ShareAppCardResponse = RustPB.Im_V1_ShareAppCardResponse
typealias SendMessageResponse = RustPB.Im_V1_SendMessageResponse
typealias ResendMessageResponse = RustPB.Im_V1_ResendMessageResponse
