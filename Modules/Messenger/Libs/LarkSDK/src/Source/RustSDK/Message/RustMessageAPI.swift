//
//  RustMessageAPI.swift
//  Lark
//
//  Created by linlin on 2017/10/27.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RustPB
import ServerPB
import LarkModel
import LarkSDKInterface
import LKCommonsLogging
import LarkAccountInterface
import LarkRustClient

final class RustMessageAPI: LarkAPI, MessageAPI {

    static let NoChatPosition: Int32 = -1

    static let logger = Logger.log(RustMessageAPI.self, category: "RustMessageAPI")

    private let currentChatterId: String
    private let urlPreviewService: MessageURLPreviewService

    init(client: SDKRustService, urlPreviewService: MessageURLPreviewService, currentChatterId: String, onScheduler: ImmediateSchedulerType? = nil) {
        self.currentChatterId = currentChatterId
        self.urlPreviewService = urlPreviewService
        super.init(client: client, onScheduler: onScheduler)
    }

    func fetchLocalMessage(id: String) -> Observable<LarkModel.Message> {
        if id.isEmpty {
            return .empty()
        }
        var request = RustPB.Im_V1_MGetMessagesRequest()
        request.messageIds = [id]
        request.syncDataStrategy = .local
        let currentChatterId = self.currentChatterId
        return client.sendAsyncRequest(request, transform: { (res: RustPB.Im_V1_MGetMessagesResponse) -> [String: LarkModel.Message] in
            return RustAggregatorTransformer.transformToMessageModel(fromEntity: res.entity, currentChatterId: currentChatterId)
        }).flatMap { (map) -> Observable<LarkModel.Message> in
            if let messageModel = map[id] {
                return Observable.just(messageModel)
            } else {
                return Observable.error(APIError(type: .entityIncompleteData(message: "no message found.")))
            }
        }.do(onNext: { [weak self] message in
            self?.urlPreviewService.fetchMissingURLPreviews(messages: [message])
        }).subscribeOn(scheduler)
    }

    func fetchMessage(id: String) -> Observable<LarkModel.Message> {
        return self.fetchMessagesMap(ids: [id], needTryLocal: true).flatMap { (map) -> Observable<LarkModel.Message> in
            if let messageModel = map[id] {
                return Observable.just(messageModel)
            } else {
                return Observable.error(APIError(type: .entityIncompleteData(message: "no message found.")))
            }
        }.subscribeOn(scheduler)
    }

    func fetchMessagesMap(ids: [String], needTryLocal: Bool) -> Observable<[String: LarkModel.Message]> {
        if ids.isEmpty {
            return Observable.just([:]).subscribeOn(scheduler)
        }

        let currentChatterId = self.currentChatterId
        return RustMessageModule
                .fetchMessages(messageIds: ids, client: self.client, needTryLocal: needTryLocal)
                .map({ (entity) -> [String: LarkModel.Message] in
                    return RustAggregatorTransformer.transformToMessageModel(fromEntity: entity, currentChatterId: currentChatterId)
                })
                .do(onNext: { [weak self] messageMap in
                    self?.urlPreviewService.fetchMissingURLPreviews(messages: Array(messageMap.values))
                })
                .subscribeOn(scheduler)
    }

    func fetchMessages(ids: [String]) -> Observable<[LarkModel.Message]> {
        if ids.isEmpty {
            return Observable.just([]).subscribeOn(scheduler)
        }

        let currentChatterId = self.currentChatterId
        return RustMessageModule
                .fetchMessages(messageIds: ids, client: self.client)
                .map({ (entity) -> [LarkModel.Message] in
                    let map = RustAggregatorTransformer.transformToMessageModel(
                        fromEntity: entity,
                        currentChatterId: currentChatterId
                    )
                    return ids.compactMap({ (id) -> LarkModel.Message? in
                        return map[id]
                    })
                })
                .do(onNext: { [weak self] messages in
                    self?.urlPreviewService.fetchMissingURLPreviews(messages: messages)
                })
                .subscribeOn(scheduler)
    }

    /// 拉取一条消息全部的回复，entity中不含message中的User
    ///
    /// - Parameter messageId: rootMessageId
    /// - Returns: Observable<[LarkModel.Message]>
    func fetchReplies(messageId: String) -> Observable<[LarkModel.Message]> {
        var request = RustPB.Im_V1_GetRepliesRequest()
        request.rootID = messageId

        let currentChatterId = self.currentChatterId
        return self.client.sendAsyncRequest(request) { (res: RustPB.Im_V1_GetRepliesResponse) -> [LarkModel.Message] in
            let replies = RustAggregatorTransformer.transformToMessageModels(
                fromEntity: res.entity,
                messageIds: res.childIds,
                currentChatterId: currentChatterId
            )
            let quasiReplies = RustAggregatorTransformer.transformToQuasiMessageMap(entity: res.entity).map({ $1 })
            return replies + quasiReplies
        }
        .do(onNext: { [weak self] messages in
            self?.urlPreviewService.fetchMissingURLPreviews(messages: messages)
        })
        .subscribeOn(scheduler)
    }

    func getReplies(messageId: String) throws -> [LarkModel.Message] {
        var request = RustPB.Im_V1_GetRepliesRequest()
        request.rootID = messageId

        let currentChatterId = self.currentChatterId
        let messages: [LarkModel.Message] = try self.client.sendSyncRequest(request, transform: { (res: RustPB.Im_V1_GetRepliesResponse) -> [LarkModel.Message] in
            let replies = RustAggregatorTransformer.transformToMessageModels(
                fromEntity: res.entity,
                messageIds: res.childIds,
                currentChatterId: currentChatterId
            )
            let quasiReplies = RustAggregatorTransformer.transformToQuasiMessageMap(entity: res.entity).map({ $1 })
            return replies + quasiReplies
        })
        self.urlPreviewService.fetchMissingURLPreviews(messages: messages)
        return messages
    }

    func getMessagesMap(ids: [String]) throws -> [String: LarkModel.Message] {
        if ids.isEmpty {
            return [:]
        }

        var request = RustPB.Im_V1_MGetMessagesRequest()
        request.messageIds = ids
        request.syncDataStrategy = .local
        let currentChatterId = self.currentChatterId
        let res: Im_V1_MGetMessagesResponse = try client.sendSyncRequest(request, allowOnMainThread: true).response
        let messagesMap = RustAggregatorTransformer.transformToMessageModel(
            fromEntity: res.entity, currentChatterId: currentChatterId
        ).filter({ (key, _) -> Bool in
            return ids.contains(key)
        })
        self.urlPreviewService.fetchMissingURLPreviews(messages: Array(messagesMap.values))
        return messagesMap
    }

    func recall(messageId: String) -> Observable<Void> {
        var request = RustPB.Im_V1_RecallMessageRequest()
        request.id = messageId
        return self.client.sendAsyncRequest(request, transform: { (_: RustPB.Im_V1_RecallMessageResponse) -> Void in
                return
            })
            .subscribeOn(scheduler)
    }

    func recallGroupMessage(messageId: String) -> Observable<Void> {
        var request = RustPB.Im_V1_RecallGroupMessageRequest()
        request.id = messageId
        return self.client.sendAsyncRequest(request)
    }

    func multiEditMessage(messageId: Int64, chatId: String, type: Basic_V1_Message.TypeEnum,
                          richText: Basic_V1_RichText, title: String?, lingoInfo: Basic_V1_LingoOption,
                          uploadMediaBlock: ((Basic_V1_RichTextElement.MediaProperty) -> Void)) -> Observable<RustPB.Basic_V1_RichText> {
        var request = RustPB.Im_V1_EditMessageRequest()
        request.msgID = messageId
        //cid用于请求去重；每次有效的请求cid应该不同
        request.cid = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        request.type = type
        request.content.richText = richText
        request.content.lingoOption = lingoInfo
        request.chatID = Int64(chatId) ?? 0
        var disposeBag: DisposeBag = DisposeBag()
        for childElement in richText.elements.values where childElement.tag == .media {
            let uploadID = childElement.property.media.mediaUploadID
            if !uploadID.isEmpty {
                uploadMediaBlock(childElement.property.media)
            }
        }
        if let title = title {
            request.content.title = title
        }
        return client.sendAsyncRequest(request)
    }

    func putReadMessages(channel: RustPB.Basic_V1_Channel,
                         messageIds: [String],
                         maxPosition: Int32,
                         maxPositionBadgeCount: Int32) {
        self.putReadMessages(channel: channel,
                             messageIds: messageIds,
                             maxPosition: maxPosition,
                             maxPositionBadgeCount: maxPositionBadgeCount,
                             foldIds: [])
    }

    func putReadMessages(channel: RustPB.Basic_V1_Channel,
                         messageIds: [String],
                         maxPosition: Int32,
                         maxPositionBadgeCount: Int32,
                         foldIds: [Int64]) {
        var request = RustPB.Im_V1_UpdateMessagesMeReadRequest()
        request.messageIds = messageIds
        request.channel = channel
        request.maxPosition = maxPosition
        request.maxPositionBadgeCount = maxPositionBadgeCount
        request.foldIds = foldIds
        var disposeBag: DisposeBag = DisposeBag()
        self.client.sendAsyncRequest(request).subscribeOn(scheduler).subscribe(onError: { (error) in
            RustMessageAPI.logger.error("UpdateMessagesMeReadRequest报错: ", error: error)
            disposeBag = DisposeBag()
        }).disposed(by: disposeBag)
    }

    func delete(messageIds: [String]) -> Observable<Void> {
        var request = RustPB.Im_V1_DeleteMessagesRequest()
        request.ids = messageIds

        return self.client.sendAsyncRequest(request) { (_: DeleteMessagesResponse) -> Void in
            return
        }
        .subscribeOn(scheduler)
    }

    func deleteByNoTrace(with messageId: String) -> Observable<Void> {
        var request = RustPB.Im_V1_DeleteMessageNoTraceRequest()
        request.messageID = messageId

        return self.client.sendAsyncRequest(request) { (_: DeleteMessagesResponse) -> Void in
            return
        }.subscribeOn(scheduler)
    }

    func delete(quasiMessageId: String) -> Observable<Void> {
        var request = RustPB.Im_V1_DeleteQuasiMessageRequest()
        request.cid = quasiMessageId
        return self.client.sendAsyncRequest(request) { (_: DeleteQuasiMessageResponse) -> Void in
            return
        }.subscribeOn(scheduler)
    }

    func deleteEphemeral(messageId: String) -> Observable<Void> {
        var request = RustPB.Im_V1_DeleteEphemeralMessageRequest()
        request.messageID = messageId
        return self.client.sendAsyncRequest(request) { (_: Im_V1_DeleteEphemeralMessageResponse) -> Void in
            return
        }.subscribeOn(scheduler)
    }

    func hideUrlPreview(messageId: String) -> Observable<Void> {
        var request = RustPB.Im_V1_HideMessageUrlPreviewRequest()
        request.messageID = messageId
        return self.client.sendAsyncRequest(request) { (_: HideMessageUrlPreviewResponse) -> Void in
            return
        }
        .subscribeOn(scheduler)
    }

    func fetchUnreadAtMessages(chatIds: [String]?, ignoreBadged: Bool, needResponse: Bool) -> Observable<[String: [LarkModel.Message]]> {
        var request = RustPB.Im_V1_GetUnreadAtMessagesRequest()
        request.ignoreBadged = ignoreBadged
        // 如果为空，返回所有的未读 at 消息；否则，只返回指定 chat_ids 的未读 at 消息。
        request.chatIds = chatIds ?? []
        request.needResponse = needResponse
        let currentChatterId = self.currentChatterId
        return client.sendAsyncRequest(request, transform: { (res: RustPB.Im_V1_GetUnreadAtMessagesResponse) -> [String: [LarkModel.Message]] in
            return RustAggregatorTransformer.transformToChatMessageMap(
                fromEntity: res.entity,
                orderedMessageIds: res.orderedMessageIds,
                currentChatterId: currentChatterId
            )
        }).do(onNext: { [weak self] messageMaps in
            let messages = messageMaps.values.flatMap({ $0 })
            self?.urlPreviewService.fetchMissingURLPreviews(messages: messages)
        }).subscribeOn(scheduler)
    }

    func getChatMessages(
        chatId: String,
        scene: FetchChatMessagesScene,
        redundancyCount: Int32,
        count: Int32,
        expectDisplayWeights: Int32?,
        redundancyDisplayWeights: Int32?,
        needResponse: Bool,
        subscribChatEvent: Bool) -> Observable<GetChatMessagesResult?> {
        var request = RustPB.Im_V1_GetChatMessagesRequest()
        request.chatID = chatId
        self.set(request: &request, scene: scene)
        request.count = count
        request.redundancyCount = redundancyCount
        request.strategy = .returnLocalData
        request.needResponse = needResponse
        request.subscribChatEvent = subscribChatEvent
        request.weightsForFilter = expectDisplayWeights ?? 0
        request.redundancyWeightsForFilter = redundancyDisplayWeights ?? 0
        return client.sendAsyncRequest(request) { [weak self] (res: ContextResponse<RustPB.Im_V1_GetChatMessagesResponse>) -> GetChatMessagesResult? in
            //本地数据不完整,且一条消息都没有返回
            if !res.response.dataComplete && res.response.messageItems.isEmpty {
                return nil
            }
            // GetChatMessagesRequest接口会返回本地缓存的template数据
            self?.urlPreviewService.handleURLTemplates(templates: res.response.entity.previewTemplates)
            return self?.handle(res: res, localData: true, chatId: chatId)
        }.subscribeOn(scheduler)
    }

    func fetchChatMessages(
        chatId: String,
        scene: FetchChatMessagesScene,
        redundancyCount: Int32,
        count: Int32,
        expectDisplayWeights: Int32?,
        redundancyDisplayWeights: Int32?,
        needResponse: Bool) -> Observable<GetChatMessagesResult> {
        var request = RustPB.Im_V1_GetChatMessagesRequest()
        request.chatID = chatId
        self.set(request: &request, scene: scene)
        request.count = count
        request.redundancyCount = redundancyCount
        request.strategy = .syncServerData
        request.needResponse = needResponse
        request.weightsForFilter = expectDisplayWeights ?? 0
        request.redundancyWeightsForFilter = redundancyDisplayWeights ?? 0
        return client.sendAsyncRequest(request) { [weak self] (res: ContextResponse<RustPB.Im_V1_GetChatMessagesResponse>) -> GetChatMessagesResult? in
            guard let self = self else { return nil }
            // GetChatMessagesRequest接口会返回本地缓存的template数据
            self.urlPreviewService.handleURLTemplates(templates: res.response.entity.previewTemplates)
            return self.handle(res: res, localData: false, chatId: chatId)
        }.compactMap { $0 }.subscribeOn(scheduler)
    }

    func fetchMessagesBy(positions: [Int32], channel: RustPB.Basic_V1_Channel) -> Observable<([LarkModel.Message], invisiblePositions: [Int32])> {
        var request = RustPB.Im_V1_GetMessagesByPositionsRequest()
        request.channel = channel
        request.positions = positions
        let currentChatterId = self.currentChatterId
        return client.sendAsyncRequest(request) { [weak self] (res: RustPB.Im_V1_GetMessagesByPositionsResponse) -> ([LarkModel.Message], invisiblePositions: [Int32]) in
            let entity = res.entity
            var messages = RustAggregatorTransformer.transformToMessageModels(fromEntity: entity, currentChatterId: currentChatterId).sorted(by: { (msg1, msg2) -> Bool in
                return msg1.position < msg2.position
            })
            let messagePositions = messages.reduce("") { (result, msg) -> String in
                return result + " \(msg.position)"
            }
            let invalidPositions = res.invalidPositions.reduce("") { (result, position) -> String in
                return result + " \(position)"
            }
            /// 这里SDK会正常返回消息
            messages = messages.map { message in
                if message.foldId > 0,
                    "\(message.foldId)" == message.id,
                   let detail = entity.messageFoldDetails[message.foldId] {
                    message.foldDetailInfo = detail
                    RustMessageAPI.logger.info("chatTrace handleMessages fetchedByPositions foldInfo: \(message.foldId) postion\(message.position) ")
                }
                return message
            }
            RustMessageAPI.logger.info("chatTrace handleMessages fetchedByPositions",
                                       additionalData: ["channelId": "\(channel.id)",
                                                        "positions": messagePositions,
                                                        "invalidPositions": invalidPositions])
            // GetMessagesByPositionsRequest接口会返回本地缓存的template数据
            self?.urlPreviewService.handleURLTemplates(templates: entity.previewTemplates)
            self?.urlPreviewService.fetchMissingURLPreviews(messages: messages)
            return (messages, invisiblePositions: res.invalidPositions)
        }.subscribeOn(scheduler)
    }

    func getMessageReadStatus(messageId: String,
                              listType: RustPB.Im_V1_GetMessageReadStateRequest.ListType,
                              query: String?,
                              readCursor: String?,
                              unreadCursor: String?,
                              needUsers: Bool) -> Observable<RustPB.Im_V1_GetMessageReadStateResponse> {
        var request = GetMessageReadStateRequest()
        request.messageID = messageId
        request.needUsers = needUsers
        request.listType = listType
        if let query = query { request.query = query }
        if let readCursor = readCursor { request.readCursor = readCursor }
        if let unreadCursor = unreadCursor { request.unreadCursor = unreadCursor }
        return client.sendAsyncRequest(request)
    }

    func getSystemMessageActionPayload(messageID: String, actionType: SystemContent.ActType) -> Observable<SystemContent.ActionPayload> {
        var request = GetMessageActionPayloadRequest()
        request.messageID = messageID
        request.actionType = actionType
        return client.sendAsyncRequest(request)
    }

    func setMessageDisplay(weights: [Int32: Double], maxWeights: [Int32: Double]) -> Observable<Void> {
        var request = RustPB.Settings_V1_SetDataDisplayWeightRequest()
        var displayWeight = RustPB.Settings_V1_SetDataDisplayWeightRequest.DisplayWeight()
        displayWeight.type2Weights = weights
        displayWeight.type2MaxWeights = maxWeights
        request.dataDisplayWeights = [Int32(RustPB.Settings_V1_SetDataDisplayWeightRequest.DataType.chatMessage.rawValue): displayWeight]
        return self.client.sendAsyncRequest(request)
    }

    func getMessageIdsByPosition(chatId: String, startPosition: Int32, count: Int32) -> Observable<RustPB.Im_V1_GetMessageIdsByPositionResponse> {
        var request = RustPB.Im_V1_GetMessageIdsByPositionRequest()
        request.chatID = chatId
        request.startPosition = startPosition
        request.count = count
        request.syncDataStrategy = .tryLocal
        return self.client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    func sendLarkCommandPayload(cmd: Int32, payload: Data) -> Observable<RustPB.Basic_V1_SendLarkCommandPayloadResponse> {
        var request = Basic_V1_SendLarkCommandPayloadRequest()
        request.cmd = cmd
        request.payload = payload
        return self.client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    // 获取聚合消息详情页列表
    func messageFoldFollowListWith(foldId: Int64,
                                   count: Int32,
                                   chatId: Int64,
                                   startTimeMs: Int64) -> Observable<RustPB.Im_V1_GetMessageFoldFollowListResponse> {
        var request = RustPB.Im_V1_GetMessageFoldFollowListRequest()
        request.foldID = foldId
        request.limit = count
        request.chatID = chatId
        request.startTimeMs = startTimeMs
        return self.client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    // 撤回卡片
    func recallMessageFold(foldId: Int64, recallByGroupAdmin: Bool) -> Observable<ServerPB.ServerPB_Messages_RecallMessageFoldResponse> {
        var request = ServerPB.ServerPB_Messages_RecallMessageFoldRequest()
        request.foldID = foldId
        request.recallByGroupAdmin = recallByGroupAdmin
        return self.client.sendPassThroughAsyncRequest(request,
                                                       serCommand: .recallMessageFold).subscribeOn(scheduler)
    }

    // 点击 +1的接口
    func putMessageFoldFollow(foldId: Int64, count: Int32) -> Observable<ServerPB.ServerPB_Messages_PutMessageFoldFollowResponse> {
        var request = ServerPB.ServerPB_Messages_PutMessageFoldFollowRequest()
        request.foldID = foldId
        request.count = count
        return self.client.sendPassThroughAsyncRequest(request,
                                                       serCommand: .putMessageFoldFollow).subscribeOn(scheduler)
    }

    // 消息链接化：获取是否有消息链接权限
    func getMessageLinkPermission(token: String) -> Observable<ServerPB.ServerPB_Messages_GetMessageLinkPermissionResponse> {
        var request = ServerPB.ServerPB_Messages_GetMessageLinkPermissionRequest()
        request.token = token
        return self.client.sendPassThroughAsyncRequest(request, serCommand: .getMessageLinkPermission).subscribeOn(scheduler)
    }

    /// 消息链接化：对一组消息生成链接
    /// fromID: chatID/threadID
    /// from:
    /// copiedIDs: messageIDs
    func putMessageLink(fromID: String,
                        from: ServerPB_Messages_PutMessageLinkRequest.LinkFrom,
                        copiedIDs: [String]) -> Observable<ServerPB.ServerPB_Messages_PutMessageLinkResponse> {
        var request = ServerPB.ServerPB_Messages_PutMessageLinkRequest()
        if let id = Int64(fromID) {
            request.fromID = id
        }
        request.from = from
        let copiedIDs = copiedIDs.compactMap({ Int64($0) })
        request.copiedID = copiedIDs
        return self.client.sendPassThroughAsyncRequest(request, serCommand: .putMessageLink).subscribeOn(scheduler)
    }

    // 获取定时消息
    func getScheduleMessages(chatId: Int64,
                             threadId: Int64?,
                             rootId: Int64?,
                             isForceServer: Bool,
                             scene: GetScheduleMessagesScene) -> Observable<GetScheduleMessagesResponse> {
        var request = RustPB.Im_V1_GetScheduleMessagesRequest()
        request.chatID = chatId
        if let threadId = threadId {
            request.threadID = threadId
        }
        request.syncDataStrategy = isForceServer ? .forceServer : .local
        if let rootId = rootId {
            request.rootID = rootId
        }
        request.scene = scene
        return self.client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    // 获取定时消息
    func getScheduleMessages(chatId: Int64,
                             threadId: Int64?,
                             rootId: Int64?,
                             scene: GetScheduleMessagesScene) -> Observable<GetScheduleMessagesResponse> {
        struct D: MergeDep {
            func isEmpty(response: GetScheduleMessagesResponse) -> Bool {
                response.messageItems.isEmpty
            }
        }
        let localObservable = getScheduleMessages(chatId: chatId,
                                                  threadId: threadId,
                                                  rootId: rootId,
                                                  isForceServer: false,
                                                  scene: scene)
        let remoteObservable = getScheduleMessages(chatId: chatId,
                                                   threadId: threadId,
                                                   rootId: rootId,
                                                   isForceServer: true,
                                                   scene: scene)
        return mergedObservables(local: localObservable, remote: remoteObservable, delegate: D()).map({ $0.0 })
    }

    // 修改定时消息
    func patchScheduleMessageRequest(chatID: Int64,
                                     messageType: Basic_V1_Message.TypeEnum?,
                                     patchObject: ScheduleMessageItem,
                                     patchType: PatchScheduleMessageType,
                                     scheduleTime: Int64?,
                                     isSendImmediately: Bool,
                                     needSuspend: Bool,
                                     content: QuasiContent?) -> Observable<PatchScheduleMessageResponse> {
        var request = RustPB.Im_V1_PatchScheduleMessageRequest()
        request.chatID = chatID
        if let messageType = messageType {
            request.messageType = messageType
        }
        request.isSendImmediately = isSendImmediately
        request.needSuspend = needSuspend
        request.patchObject = patchObject
        request.patchType = patchType
        if let scheduleTime = scheduleTime {
            request.scheduleTime = scheduleTime
        }
        if let content = content {
            request.content = content
        }
        return self.client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    // 将消息「设为保密」或「取消保密」
    func updateRestrictedMessage(chatId: Int64,
                                 messageId: Int64,
                                 isRestricted: Bool) -> Observable<UpdateRestrictedMessageResponse> {
        var request = UpdateRestrictedMessageRequest()
        request.chatID = chatId
        request.messageID = messageId
        request.isRestricted = isRestricted
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    // 拉取MessageLink
    func pullMessageLink(
        token: String,
        previewID: String,
        needMessageIDs: [Int64],
        syncDataStrategy: Basic_V1_SyncDataStrategy
    ) -> Observable<(response: Im_V1_PullMessageLinkMessagesResponse, sdkCost: Int64)> {
        var request = Im_V1_PullMessageLinkMessagesRequest()
        request.token = token
        request.previewToken = previewID
        request.needMessageIds = needMessageIDs
        request.syncDataStrategy = syncDataStrategy
        let start = CACurrentMediaTime()
        return client.sendAsyncRequest(request, transform: { response -> (response: Im_V1_PullMessageLinkMessagesResponse, sdkCost: Int64) in
            let sdkCost = CACurrentMediaTime() - start
            return (response: response, sdkCost: Int64(sdkCost))
        }).subscribeOn(scheduler)
    }
}

extension RustMessageAPI {
    func set( request: inout RustPB.Im_V1_GetChatMessagesRequest, scene: FetchChatMessagesScene) {
        switch scene {
        case .firstScreen:
            request.scene = .firstScreen
        case .after(after: let position):
            request.scene = .nextPage
            request.position = position
        case .previous(before: let position):
            request.scene = .previousPage
            request.position = position
        case .specifiedPosition(let position):
            request.scene = .specifiedPosition
            request.position = position
        }
    }

    func handle(res: ContextResponse<RustPB.Im_V1_GetChatMessagesResponse>, localData: Bool, chatId: String) -> GetChatMessagesResult {
        let start = Date()
        let currentChatterId = self.currentChatterId
        let response = res.response
        let entity = response.entity
        var messages: [LarkModel.Message] = []
        let messagesMap = RustAggregatorTransformer.transformToMessageModel(fromEntity: entity, currentChatterId: currentChatterId)
        let quasiMessagesMap = RustAggregatorTransformer.transformToQuasiMessageMap(entity: entity)
        let ephemerialMsgMap = RustAggregatorTransformer.transformToEphemerialMessageModel(fromEntity: entity, currentChatterId: currentChatterId)
        var foldPostionRanges: [(Int32, Int32)] = []
        var foldIds: [Int64] = []
        for messageItem in response.messageItems {
            var message: LarkModel.Message?
            switch messageItem.itemType {
            case .normalMessage:
                message = messagesMap[messageItem.itemID]
            case .quasiMessage:
                message = quasiMessagesMap[messageItem.itemID]
            case .ephemeralMessage:
                message = ephemerialMsgMap[messageItem.itemID]
            case .messageFold:
                if let foldId = Int64(messageItem.itemID),
                   let foldDetail = entity.messageFoldDetails[foldId] {
                    foldIds.append(foldId)
                    var foldMessageEntity = entity
                    /// entity.messages可能没有FoldMessage，造成Message.transform.content不能更新
                    if foldMessageEntity.messages[foldDetail.message.id] == nil {
                        foldMessageEntity.messages[foldDetail.message.id] = foldDetail.message
                    }
                    let foldRootMessage = Message.transform(entity: foldMessageEntity, pb: foldDetail.message, currentChatterID: currentChatterId)
                    foldRootMessage.foldDetailInfo = foldDetail
                    if foldRootMessage.foldId != foldId {
                        RustMessageAPI.logger.error("fetchChatMessages foldRootMessage.foldId \(foldRootMessage.foldId) != messageItem.itemFoldID: \(foldId)")
                    }
                    let chatters = entity.chatChatters[chatId]?.chatters ?? entity.chatters
                    let foldUsers: [FoldUserInfo] = foldDetail.userCounts.compactMap { obj in
                        if let chatter = chatters["\(obj.userID)"] {
                            return FoldUserInfo(chatter: Chatter.transform(pb: chatter),
                                                count: obj.count)
                        }
                        RustMessageAPI.logger.error("foldUsers can not get chatter from entity.chatChatters userId: \(obj.userID)")
                        return nil
                    }
                    foldRootMessage.foldUsers = foldUsers
                    if let chatter = chatters["\(foldDetail.recallUserID)"] {
                        foldRootMessage.foldRecaller = Chatter.transform(pb: chatter)
                    }
                    foldPostionRanges.append((Int32(foldDetail.rootMessagePosition),
                                              Int32(foldDetail.lastMessagePosition)))
                    message = foldRootMessage
                }
            @unknown default:
                assert(false, "new value")
                message = nil
                break
            }
            if let message = message {
                messages.append(message)
            } else {
                RustMessageAPI.logger.error("fetchChatMessages MissMessage \(messageItem.itemID) \(messageItem.itemType.rawValue)")
            }
        }
        let messagePositions = messages.reduce("") { (result, msg) -> String in
            return result + " \(msg.position)"
        }
        let invalidPositions = response.invalidPositions.reduce("") { (result, position) -> String in
            return result + " \(position)"
        }
        let missPositions = response.missingPositions.reduce("") { (result, position) -> String in
            return result + " \(position)"
        }
        /// SDK 这个地方容易出问题 端上做个校验逻辑 已经给过fold信息的不再需要Message了, 需要移除
        messages.removeAll { message in
            if message.foldId > 0 && message.foldDetailInfo == nil && foldIds.contains(message.foldId) {
                RustMessageAPI.logger.error("SDK error to give message has fold \(message.id) isRoot: \(message.id == "\(message.foldId)")")
                return true
            }
            return false
        }
        RustMessageAPI.logger.info("chatTrace handleMessages",
                                   additionalData: ["chatId": "\(chatId)",
                                                    "positions": messagePositions,
                                                    "invalidPositions": invalidPositions,
                                                    "missPositions": missPositions,
                                                    "foldPositions": "\(foldPostionRanges)"])
        let parseCost = Int64(Date().timeIntervalSince(start) * 1000)
        let trackInfo = GetChatMessagesTrackInfo(contextId: res.contextID,
                                                 sdkCost: response.cost,
                                                 netCosts: response.netCosts,
                                                 parseCost: parseCost,
                                                 messagesSyncPipeFinished: response.messagesSyncPipeFinished)
        self.urlPreviewService.fetchMissingURLPreviews(messages: messages)
        return GetChatMessagesResult(messages: messages,
                                     invisiblePositions: response.invalidPositions,
                                     missedPositions: response.missingPositions,
                                     foldPositionRange: foldPostionRanges,
                                     localData: localData,
                                     trackInfo: trackInfo)
    }
}
