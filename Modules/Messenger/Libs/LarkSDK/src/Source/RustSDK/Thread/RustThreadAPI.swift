//
//  RustThreadAPI.swift
//  LarkThread
//
//  Created by zc09v on 2019/1/31.
//

import Foundation
import UIKit
import RxSwift
import RustPB
import LarkModel
import LarkRustClient
import LKCommonsLogging
import LarkSDKInterface
import LarkAccountInterface

final class RustThreadAPI: LarkAPI, ThreadAPI {
    private let currentChatterId: String
    static let logger = Logger.log(RustThreadAPI.self, category: "LarkThread")
    private let urlPreviewService: MessageURLPreviewService

    init(client: SDKRustService, urlPreviewService: MessageURLPreviewService, currentChatterId: String, onScheduler: ImmediateSchedulerType? = nil) {
        self.urlPreviewService = urlPreviewService
        self.currentChatterId = currentChatterId
        super.init(client: client, onScheduler: onScheduler)
    }

    func update(threadId: String, isRemind: Bool) -> Observable<Void> {
        var request = RustPB.Im_V1_UpdateThreadRequest()
        request.threadID = threadId
        request.isRemind = isRemind
        return self.client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    func update(threadId: String, isFollow: Bool?, threadState: RustPB.Basic_V1_ThreadState?) -> Observable<Void> {
        var request = RustPB.Im_V1_UpdateThreadRequest()
        request.threadID = threadId

        if let isFollow = isFollow {
            request.isFollow = isFollow
        }
        if let state = threadState {
            request.threadState = state
        }
        return self.client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    func updateThreadsMeRead(channel: RustPB.Basic_V1_Channel, threadIds: [String], readPosition: Int32, readPositionBadgeCount: Int32) {
        var request = RustPB.Im_V1_UpdateThreadsMeReadRequest()
        request.channel = channel
        request.threadIds = threadIds
        request.readPosition = readPosition
        request.readPositionBadgeCount = readPositionBadgeCount
        var disposeBag: DisposeBag = DisposeBag()
        self.client.sendAsyncRequest(request).subscribeOn(scheduler).subscribe(onError: { (error) in
            RustThreadAPI.logger.error("updateThreadsMeRead报错: ", error: error)
            disposeBag = DisposeBag()
        }).disposed(by: disposeBag)
    }

    func updateThreadMessagesMeRead(channel: RustPB.Basic_V1_Channel, threadId: String, messageIds: [String], maxPositionInThread: Int32, maxPositionBadgeCountInThread: Int32) {
        var request = RustPB.Im_V1_UpdateMessagesMeReadRequest()
        request.threadID = threadId
        request.channel = channel
        request.messageIds = messageIds
        request.maxPositionBadgeCount = 0
        request.maxPosition = 0
        request.threadMaxPosition = maxPositionInThread
        request.threadMaxPositionBadgeCount = maxPositionBadgeCountInThread
        var disposeBag: DisposeBag = DisposeBag()
        self.client.sendAsyncRequest(request).subscribeOn(scheduler).subscribe(onError: { (error) in
            RustThreadAPI.logger.error("updateThreadMessagesMeRead报错: ", error: error)
            disposeBag = DisposeBag()
        }).disposed(by: disposeBag)
    }

    func updateTopicsMeRead(readPairs: [RustPB.Im_V1_UpdateTopicsMeReadRequest.ReadPair]) {
        var request = RustPB.Im_V1_UpdateTopicsMeReadRequest()
        request.readPairs = readPairs
        var disposeBag: DisposeBag = DisposeBag()
        self.client.sendAsyncRequest(request, transform: { (res: ContextResponse<RustPB.Im_V1_UpdateTopicsMeReadResponse>) -> Void in
            RustThreadAPI.logger.info("UpdateTopicsMeReadRequest response: \(res.contextID) \(readPairs)")
        }).subscribeOn(scheduler).subscribe(onError: { (error) in
            RustThreadAPI.logger.error("UpdateTopicsMeReadRequest报错: ", error: error)
            disposeBag = DisposeBag()
        }).disposed(by: disposeBag)
    }

    func fetchThreads(_ threadIds: [String],
                      strategy: RustPB.Basic_V1_SyncDataStrategy,
                      forNormalChatMessage: Bool
    ) -> Observable<(threadMessages: [ThreadMessage], trackInfo: ThreadRequestTrackInfo)> {
        let reqeustStart = CACurrentMediaTime()
        var request = RustPB.Im_V1_MGetThreadsRequest()
        request.threadIds = threadIds
        request.strategy = strategy
        request.forNormalChatMessage = forNormalChatMessage
        let currentChatterId = self.currentChatterId
        return client.sendAsyncRequest(request) { (res: ContextResponse<RustPB.Im_V1_MGetThreadsResponse>) -> ([ThreadMessage], ThreadRequestTrackInfo) in
            let praseStart = CACurrentMediaTime()
            let reqeustCost = praseStart - reqeustStart
            let response = res.response

            let threads = transformToThreadMessage(fromEntity: response.entity, currentChatterId: currentChatterId)
            let threadMessages = threadIds.compactMap({ (threadId) -> ThreadMessage? in
                return threads[threadId]
            })
            let trackInfo = ThreadRequestTrackInfo(
                contextId: res.contextID,
                parseCost: CACurrentMediaTime() - praseStart,
                requestCost: reqeustCost
            )
            return (threadMessages, trackInfo)
        }.do(onNext: { [weak self] threadMessages, _ in
            let messages = threadMessages.flatMap({ [$0.rootMessage] + $0.replyMessages + $0.latestAtMessages })
            self?.urlPreviewService.fetchMissingURLPreviews(messages: messages)
        }).subscribeOn(scheduler)
    }

    func transformEntityToThreadMessage(
        fromEntity entity: RustPB.Basic_V1_Entity
    ) -> [String: ThreadMessage] {
        return transformToThreadMessage(
            fromEntity: entity,
            currentChatterId: self.currentChatterId
        )
    }

    func fetchFilteredThreads(
        channelID: String,
        filterID: String,
        extendFilterID: [String],
        scene: RustPB.Basic_V1_ChannelDataScene,
        cursor: String?,
        count: Int32,
        preloadCount: Int32
    ) -> Observable<([ThreadMessage], String, String)> {
        var request = RustPB.Im_V1_GetFilteredThreadsRequest()
        request.channelID = channelID
        request.filterID = filterID
        request.scene = scene
        if let cursor = cursor {
            request.cursor = cursor
        }
        var extendData = RustPB.Im_V1_GetFilteredThreadsRequest.ExtendData()
        extendData.extendFilterIds = extendFilterID
        request.extendData = extendData
        request.count = count
        request.preloadCount = preloadCount

        return client.sendAsyncRequest(request, transform: { (res: RustPB.Im_V1_GetFilteredThreadsResponse) -> ([ThreadMessage], String, String) in
            let threadMaps = transformToThreadMessage(fromEntity: res.entity, currentChatterId: self.currentChatterId)
            var threads = [ThreadMessage]()
            res.threadItems.forEach({ (threadItem) in
                if var thread = threadMaps[threadItem.itemID] {
                    // 设置当前thread是通过哪个filterId拉取到的
                    thread.filterId = threadItem.filterID
                    threads.append(thread)
                }
            })

            return (threads, res.prevCursor, res.prevFilterID)
        }).do(onNext: { [weak self] threadMessages, _, _ in
            let messages = threadMessages.flatMap({ [$0.rootMessage] + $0.replyMessages + $0.latestAtMessages })
            self?.urlPreviewService.fetchMissingURLPreviews(messages: messages)
        }).subscribeOn(scheduler)
    }

    func fetchRecommendThread(
        scene: RustPB.Im_V1_GetRecommendationsByUserRequest.RecommendationsScene,
        count: Int32,
        preloadCount: Int32,
        cursor: String?
    ) -> Observable<GetRecommendItemResult> {
        let requestStart = CACurrentMediaTime()

        var request = RustPB.Im_V1_GetRecommendationsByUserRequest()
        request.scene = scene
        if let cursor = cursor {
            request.cursor = cursor
        }
        request.count = count
        request.preloadCount = preloadCount
        return client.sendAsyncRequest(
            request,
            transform: { (res: ContextResponse<RustPB.Im_V1_GetRecommendationsByUserResponse>) -> GetRecommendItemResult in
                let response = res.response
                let parseStart = CACurrentMediaTime()
                let reqeustCost = parseStart - requestStart

                let threadMaps = transformToThreadMessage(fromEntity: response.entity, currentChatterId: self.currentChatterId)
                var recommenItems = [ThreadRecommendItem]()
                response.recommendationItems.forEach({ (threadItem) in
                    switch threadItem.recommendationType {
                    case .thread, .quasiThread:
                        if var threadMessage = threadMaps[threadItem.itemID] {
                            threadMessage.impressionID = threadItem.impressionID
                            let recommondItem = ThreadRecommendItem(threadMessage: threadMessage, type: .topic)
                            recommenItems.append(recommondItem)
                        }
                    case .groups:
                        let recommendTopicGroups = ThreadRecommendedGroupItem.transform(recommendedGroups: threadItem.topicGroups)

                        let recommondItem = ThreadRecommendItem(
                            recommendGroup: ThreadRecommendGroup(
                                recommendGroups: recommendTopicGroups,
                                hasMoreRecommendedTopicGroups: threadItem.hasMoreRecommendedTopicGroups_p
                            ),
                            type: .groups
                        )
                        recommenItems.append(recommondItem)
                    case .unknownRecommendationType:
                        break
                    @unknown default:
                        assert(false, "new value")
                        break
                    }
                })

                let parseCost = CACurrentMediaTime() - parseStart
                let trackInfo = ThreadRequestTrackInfo(contextId: res.contextID, parseCost: parseCost, requestCost: reqeustCost)

                return GetRecommendItemResult(
                    recommendItems: recommenItems,
                    nextCursor: response.nextCursor,
                    isRefreshed: response.refreshed,
                    trackInfo: trackInfo
                )
            }).do(onNext: { [weak self] result in
                let messages = result.recommendItems.compactMap({ $0.threadMessage }).flatMap({ [$0.rootMessage] + $0.replyMessages + $0.latestAtMessages })
                self?.urlPreviewService.fetchMissingURLPreviews(messages: messages)
            }).subscribeOn(scheduler)
    }

    func getThreads(
        channel: RustPB.Basic_V1_Channel,
        scene: GetDataScene,
        redundancyCount: Int32,
        count: Int32,
        useIncompleteLocalData: Bool,
        needReplyPrompt: Bool) -> Observable<GetThreadsResult> {
        let requestStart = CACurrentMediaTime()
        var request = RustPB.Im_V1_GetChannelThreadsRequest()
        request.channel = channel
        self.set(request: &request, scene: scene)
        request.redundancyCount = redundancyCount
        request.count = count
        if useIncompleteLocalData {
            request.strategy = .returnLocalData
        } else {
            request.strategy = .ignoreLocalData
        }
        request.needReplyPrompt = needReplyPrompt
        return client.sendAsyncRequest(request, transform: { (res: ContextResponse<RustPB.Im_V1_GetChannelThreadsResponse>) -> GetThreadsResult in
            if useIncompleteLocalData {
                //本地数据不完整,且一条消息都没有返回
                if !res.response.dataComplete && res.response.threadItems.isEmpty {
                    return self.getEmptyThreadsResult(contextID: res.contextID, requestStart: requestStart)
                }
                return self.handle(res: res, localData: true, requestStart: requestStart)
            } else {
                if res.response.dataComplete {
                    return self.handle(res: res, localData: true, requestStart: requestStart)
                }
                return self.getEmptyThreadsResult(contextID: res.contextID, requestStart: requestStart)
            }
        }).do { [weak self] result in
            let messages = result.threadMessages.flatMap({ [$0.rootMessage] + $0.replyMessages + $0.latestAtMessages }) + result.newAtReplyMessages
            self?.urlPreviewService.fetchMissingURLPreviews(messages: messages)
        }
    }

    private func getEmptyThreadsResult(contextID: String, requestStart: Double) -> GetThreadsResult {
        let trackInfo = ThreadRequestTrackInfo(
            contextId: contextID,
            parseCost: 0,
            requestCost: CACurrentMediaTime() - requestStart
        )
        return GetThreadsResult(
            threadMessages: [ThreadMessage](),
            invisiblePositions: [Int32](),
            missedPositions: [Int32](),
            newReplyCount: 0,
            newAtReplyMessages: [],
            newAtReplyCount: 0,
            localData: false,
            needFetchRemote: true,
            trackInfo: trackInfo
        )
    }

    func fetchThreads(
        channel: RustPB.Basic_V1_Channel,
        scene: GetDataScene,
        redundancyCount: Int32,
        count: Int32,
        needReplyPrompt: Bool) -> Observable<GetThreadsResult> {
        var request = RustPB.Im_V1_GetChannelThreadsRequest()
        request.channel = channel
        self.set(request: &request, scene: scene)
        request.redundancyCount = redundancyCount
        request.count = count
        request.strategy = .syncServerData
        request.needReplyPrompt = needReplyPrompt
        let requestStart = CACurrentMediaTime()
        return client.sendAsyncRequest(request, transform: { (res: ContextResponse<RustPB.Im_V1_GetChannelThreadsResponse>) -> GetThreadsResult in
            return self.handle(res: res, localData: false, requestStart: requestStart)
        }).do(onNext: { [weak self] result in
            let messages = result.threadMessages.flatMap({ [$0.rootMessage] + $0.replyMessages + $0.latestAtMessages }) + result.newAtReplyMessages
            self?.urlPreviewService.fetchMissingURLPreviews(messages: messages)
        }).subscribeOn(scheduler)
    }

    func putReadMyThreads(groupId: String) -> Observable<Void> {
        var request = Im_V1_ReadMyThreadsRequest()
        request.groupID = groupId
        return client.sendAsyncRequest(request).map({ _ in }).subscribeOn(scheduler)
    }

    func fetchThreadsBy(positions: [Int32], channel: RustPB.Basic_V1_Channel) -> Observable<([ThreadMessage], invisiblePositions: [Int32])> {
        var request = RustPB.Im_V1_GetThreadsByPositionsRequest()
        request.channel = channel
        request.positions = positions
        return client.sendAsyncRequest(request) { (res: RustPB.Im_V1_GetThreadsByPositionsResponse) -> ([ThreadMessage], invisiblePositions: [Int32]) in
            let currentChatterId = self.currentChatterId
            let entity = res.entity
            let threadMessages = Array(
                transformToThreadMessage(
                    fromEntity: entity,
                    currentChatterId: currentChatterId
                ).values
            )
            return (threadMessages, invisiblePositions: res.invalidPositions)
        }.do(onNext: { [weak self] threadMessages, _ in
            let messages = threadMessages.flatMap({ [$0.rootMessage] + $0.replyMessages + $0.latestAtMessages })
            self?.urlPreviewService.fetchMissingURLPreviews(messages: messages)
        }).subscribeOn(scheduler)
    }

    func getThreadMessages(
        threadId: String,
        isReplyInThread: Bool,
        scene: GetDataScene,
        redundancyCount: Int32,
        count: Int32,
        useIncompleteLocalData: Bool) -> Observable<GetThreadMessagesResult?> {
        var request = RustPB.Im_V1_GetThreadMessagesV2Request()
        request.threadID = threadId
        self.set(request: &request, scene: scene)
        request.redundancyCount = redundancyCount
        request.count = count
        if useIncompleteLocalData {
            request.strategy = .returnLocalData
        } else {
            /// isReplyInhread优化一下策略
            request.strategy = isReplyInThread ? .syncServerData : .ignoreLocalData
        }
        let start = CACurrentMediaTime()
        return client.sendAsyncRequest(request) { (res: RustPB.Im_V1_GetThreadMessagesV2Response) -> GetThreadMessagesResult? in
            let sdkCost = CACurrentMediaTime() - start
            if useIncompleteLocalData {
                //本地数据不完整,且一条消息都没有返回
                if !res.dataComplete && res.messageItems.isEmpty {
                    return nil
                }
                return self.handle(response: res, threadId: threadId, localData: true, sdkCost: sdkCost)
            } else {
                return res.dataComplete ? self.handle(response: res, threadId: threadId, localData: true, sdkCost: sdkCost) : nil
            }
        }.do { [weak self] result in
            guard let messages = result?.messages else { return }
            self?.urlPreviewService.fetchMissingURLPreviews(messages: messages)
        }
    }

    func fetchThreadMessages(
        threadId: String,
        scene: GetDataScene,
        redundancyCount: Int32,
        count: Int32) -> Observable<GetThreadMessagesResult> {
        var request = RustPB.Im_V1_GetThreadMessagesV2Request()
        request.threadID = threadId
        self.set(request: &request, scene: scene)
        request.redundancyCount = redundancyCount
        request.count = count
        request.strategy = .syncServerData
        let start = CACurrentMediaTime()
        return client.sendAsyncRequest(request, transform: { (res: RustPB.Im_V1_GetThreadMessagesV2Response) -> GetThreadMessagesResult in
            let sdkCost = CACurrentMediaTime() - start
            return self.handle(response: res, threadId: threadId, localData: false, sdkCost: sdkCost)
        }).do(onNext: { [weak self] result in
            self?.urlPreviewService.fetchMissingURLPreviews(messages: result.messages)
        }).subscribeOn(scheduler)
    }

    func fetchThreadMessagesBy(positions: [Int32], threadID: String) -> Observable<([LarkModel.Message], invisiblePositions: [Int32])> {
        var request = RustPB.Im_V1_GetThreadMessagesByPositionsRequest()
        request.positions = positions
        request.threadID = threadID
        return client.sendAsyncRequest(request) { (res: RustPB.Im_V1_GetThreadMessagesByPositionsResponse) -> ([LarkModel.Message], invisiblePositions: [Int32]) in
            let currentChatterId = self.currentChatterId
            let entity = res.entity
            let messages = RustAggregatorTransformer.transformToMessageModels(fromEntity: entity, currentChatterId: currentChatterId).sorted(by: { (msg1, msg2) -> Bool in
                return msg1.threadPosition < msg2.threadPosition
            })
            return (messages, invisiblePositions: res.invalidPositions)
        }.do(onNext: { [weak self] messages, _ in
            self?.urlPreviewService.fetchMissingURLPreviews(messages: messages)
        }).subscribeOn(scheduler)
    }

    func shareThreadTopic(threadId: String, chatId: String, toChatIds: [String]) -> Observable<Void> {
        var request = RustPB.Im_V1_SendShareThreadRequest()
        request.threadID = threadId
        request.channelID = chatId
        request.chatIds = toChatIds
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    func shareThreadTopicWithResp(threadId: String, chatId: String, toChatIds: [String]) -> Observable<[String: String]> {
        var request = RustPB.Im_V1_SendShareThreadRequest()
        request.threadID = threadId
        request.channelID = chatId
        request.chatIds = toChatIds
        return client.sendAsyncRequest(request) { (res: RustPB.Im_V1_SendShareThreadResponse) -> ([String: String]) in
            return res.messageIds
        }.subscribeOn(scheduler)
    }

    func subscribeThreadTab(isSubscribe: Bool) -> Observable<Void> {
        var request = RustPB.Im_V1_SubscribeThreadTabRequest()
        request.subscribe = isSubscribe
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    func fetchRecommendedTopicGroups(
        scene: RustPB.Im_V1_GetRecommendedTopicGroupsRequest.RecommendedGroupScene,
        count: Int32,
        cursor: String?
    ) -> Observable<([ThreadRecommendedGroupItem], String)> {
        var request = RustPB.Im_V1_GetRecommendedTopicGroupsRequest()
        request.scene = scene
        request.count = count
        if let cursor = cursor {
            request.cursor = cursor
        }
        return client.sendAsyncRequest(request) { (res: RustPB.Im_V1_GetRecommendedTopicGroupsResponse) -> ([ThreadRecommendedGroupItem], String) in
            let groups = ThreadRecommendedGroupItem.transform(recommendedGroups: res.items)
            return (groups, res.nextCursor)
        }.subscribeOn(scheduler)
    }

    // MARK: - 创建小组
    func createTopicGroup(
        name: String,
        desc: String,
        userIds: [String],
        isPublic: Bool
    ) -> Observable<Chat> {
        var request = RustPB.Im_V1_CreateTopicGroupRequest()
        request.chatterIds = userIds
        request.groupName = name
        request.groupDesc = desc
        request.isPublic = isPublic

        return client.sendAsyncRequest(request) { (res: RustPB.Im_V1_CreateTopicGroupResponse) -> LarkModel.Chat in
            if let chat = RustAggregatorTransformer.transformToChatsMap(fromEntity: res.entity)[res.groupID] {
                return chat
            } else {
                throw APIError(type: .entityIncompleteData(message: "CreateChatResponse has no chat"))
            }
        }.subscribeOn(scheduler)
    }

    func addMembers(topicGroupID: String, memberIDs: [String], isDefaultFavorite: Bool) -> Observable<Void> {
        var request = RustPB.Im_V1_AddTopicGroupMemberRequest()
        request.topicGroupID = topicGroupID
        request.memberIds = memberIDs
        request.isDefaultFavorite = isDefaultFavorite
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    func getThreadAnonymousInfo() -> Observable<RustPB.Im_V1_GetAnonymousInfoResponse> {
        let request = RustPB.Im_V1_GetAnonymousInfoRequest()
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

}

fileprivate extension RustThreadAPI {
    func set( request: inout RustPB.Im_V1_GetChannelThreadsRequest, scene: GetDataScene) {
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

    func set(request: inout RustPB.Im_V1_GetThreadMessagesV2Request, scene: GetDataScene) {
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

    func handle(res: ContextResponse<RustPB.Im_V1_GetChannelThreadsResponse>, localData: Bool, requestStart: Double) -> GetThreadsResult {
        let start = CACurrentMediaTime()
        let requestCost = start - requestStart
        let response = res.response

        let currentChatterId = self.currentChatterId
        let threadMessageMap = transformToThreadMessage(fromEntity: response.entity, currentChatterId: currentChatterId)
        var threadMessages: [ThreadMessage] = []
        for threadItem in response.threadItems {
            let threadMessage: ThreadMessage?
            switch threadItem.itemType {
            case .normalData:
                threadMessage = threadMessageMap[threadItem.itemID]
            case .quasiData:
                threadMessage = threadMessageMap[threadItem.itemID]
            @unknown default:
                assert(false, "new value")
                threadMessage = nil
            }
            if let threadMessage = threadMessage {
                threadMessages.append(threadMessage)
            } else {
                RustThreadAPI.logger.error("getThreads missThread \(threadItem.itemID) \(threadItem.itemType.rawValue)")
            }
        }

        // 获取有几条@我的消息，按照时间增序排序，最后为最新的
        var newAtReplyMessages: [Message] = []
        response.newAtReplyIds.forEach { (id) in
            do {
                let message = try Message.transform(entity: response.entity, id: id, currentChatterID: self.currentChatterId)
                newAtReplyMessages.append(message)
            } catch {
                RustThreadAPI.logger.error("getThreads miss newAtReplyId \(id)")
            }
        }

        let trackInfo = ThreadRequestTrackInfo(
            contextId: res.contextID,
            parseCost: CACurrentMediaTime() - start,
            requestCost: requestCost
        )
        return GetThreadsResult(
            threadMessages: threadMessages,
            invisiblePositions: response.invalidPositions,
            missedPositions: response.missingPositions,
            newReplyCount: response.newReplyCount,
            newAtReplyMessages: newAtReplyMessages,
            newAtReplyCount: response.newAtReplyCount,
            localData: localData,
            trackInfo: trackInfo
        )
    }

    func handle(response: RustPB.Im_V1_GetThreadMessagesV2Response, threadId: String, localData: Bool, sdkCost: Double) -> GetThreadMessagesResult {
        let start = CACurrentMediaTime()
        let currentChatterId = self.currentChatterId
        let entity = response.entity
        var messages: [LarkModel.Message] = []
        let messagesMap = RustAggregatorTransformer.transformToMessageModel(fromEntity: entity, currentChatterId: currentChatterId)
        let quasiMessagesMap = RustAggregatorTransformer.transformToQuasiMessageMap(entity: entity)
        for messageItem in response.messageItems {
            let message: LarkModel.Message?
            switch messageItem.itemType {
            case .normalData:
                message = messagesMap[messageItem.itemID]
            case .quasiData:
                message = quasiMessagesMap[messageItem.itemID]
            @unknown default:
                message = nil
                break
            }

            if message?.fromChatter == nil {
                RustThreadAPI.logger.error("message chatter is nil \(threadId) \(messageItem.itemID) \(messageItem.itemType.rawValue)")
            }

            if let message = message {
                messages.append(message)
            } else {
                RustThreadAPI.logger.error("getThreadMessages missMessage \(threadId) \(messageItem.itemID) \(messageItem.itemType.rawValue)")
            }
        }
        // 返回追踪数据
        let trackInfo = ThreadRequestTrackInfo(
            contextId: "",
            parseCost: CACurrentMediaTime() - start,
            requestCost: sdkCost
        )

        return GetThreadMessagesResult(
            messages: messages,
            invisiblePositions: response.invalidPositions,
            missedPositions: response.missingPositions,
            localData: localData,
            sdkCost: sdkCost,
            trackInfo: trackInfo
        )
    }
}
// MARK: 发帖页
extension RustThreadAPI {
    func getTopicGroupsForPost(cursor: String, count: Int) -> Observable<([TopicGroupWithChat], String)> {
        var request = RustPB.Im_V1_GetTopicGroupsToPostRequest()
        if !cursor.isEmpty {
            request.cursor = cursor
        }
        request.count = Int32(count)
        return client.sendAsyncRequest(request, transform: { (res: RustPB.Im_V1_GetTopicGroupsToPostResponse) -> ([TopicGroupWithChat], String) in
            var topicGroupWithChats: [TopicGroupWithChat] = []
            guard let results = res.results else { return ([], res.nextCursor) }
            switch results {
            case let .itemList(list):
                list.items.forEach { (item) in
                    if let chat = res.entity.chats[item.itemID],
                    let topicGroup = res.entity.topicGroups[item.itemID] {
                        let chatModel = LarkModel.Chat.transform(entity: res.entity, pb: chat)
                        let topicGroupModel = TopicGroup.transform(pb: topicGroup)
                        topicGroupWithChats.append(TopicGroupWithChat(topicGroup: topicGroupModel, chat: chatModel))
                    }
                }
            @unknown default:
                assert(false, "new value")
                break
            }

            return (topicGroupWithChats, res.nextCursor)
        })
    }

    func getTopicGroup(topicGroupIDs: [String], forceRemote: Bool) -> Observable<[String: TopicGroup]> {
        var request = RustPB.Im_V1_GetTopicGroupsRequest()
        request.groupIds = topicGroupIDs
        request.syncData = forceRemote
        return client.sendAsyncRequest(request, transform: { (res: RustPB.Im_V1_GetTopicGroupsResponse) -> [String: TopicGroup] in
            return res.entity.topicGroups.mapValues({ (topicGroup) -> TopicGroup in
                return TopicGroup.transform(pb: topicGroup)
            })
        })
    }

    func fetchUnreadAtMessages(quaries: GetUnreadAtMessagesRequestQuary, ignoreBadged: Bool, needResponse: Bool) -> Observable<[ThreadMessage]> {
        var request = RustPB.Im_V1_GetUnreadAtMessagesRequest()
        request.ignoreBadged = ignoreBadged
        request.queries = [quaries]
        request.needResponse = needResponse
        let currentChatterId = self.currentChatterId
        return client.sendAsyncRequest(request, transform: { (res: RustPB.Im_V1_GetUnreadAtMessagesResponse) -> [ThreadMessage] in
            let threadsDic = transformToThreadMessage(fromEntity: res.entity, currentChatterId: currentChatterId)
            let threads = res.orderedMessageIds.compactMap { id -> ThreadMessage? in
                threadsDic[id]
            }
            return threads
        }).do(onNext: { [weak self] threadMessages in
            let messages = threadMessages.flatMap({ [$0.rootMessage] + $0.replyMessages + $0.latestAtMessages })
            self?.urlPreviewService.fetchMissingURLPreviews(messages: messages)
        }).subscribeOn(scheduler)
    }

    func fetchChatAndTopicGroup(chatID: String, forceRemote: Bool, syncUnsubscribeGroups: Bool) ->
        Observable<(ChatAndTopicGroupsResult?)> {
        let requestStart = CACurrentMediaTime()

        var request = RustPB.Im_V1_GetTopicGroupsRequest()
        request.groupIds = [chatID]
        request.syncData = forceRemote
        request.needSyncUnsubscribeGroups = syncUnsubscribeGroups
        return client.sendAsyncRequest(
            request,
            transform: { (res: ContextResponse<RustPB.Im_V1_GetTopicGroupsResponse>) ->
                ChatAndTopicGroupsResult? in
                let response = res.response
                let praseStart = CACurrentMediaTime()
                let reqeustCost = praseStart - requestStart

                var topicGroupModel: TopicGroup?
                if let topicGroup = response.entity.topicGroups[chatID] {
                    topicGroupModel = TopicGroup.transform(pb: topicGroup)
                }

                guard let chat = response.entity.chats[chatID] else {
                    RustThreadAPI.logger.error("chat is nil \(chatID)")
                    return nil
                }
                // 需要解析groupOptionInfo，得到是否有新群公告未读
                let chatModel = LarkModel.Chat.transform(
                    entity: response.entity,
                    chatOptionInfo: response.groupOptionInfo[chatID],
                    pb: chat
                )

                let trackInfo = ThreadRequestTrackInfo(
                    contextId: res.contextID,
                    parseCost: CACurrentMediaTime() - praseStart,
                    requestCost: reqeustCost
                )

                return (chatModel, topicGroupModel, trackInfo)
            })
    }
}
// MARK: 不感兴趣
extension RustThreadAPI {
    func dislikeTopicGroup(topicGroupID: String) -> Observable<Void> {
        var request = RustPB.Im_V1_UninterestTopicGroupForUserRequest()
        request.topicGroupIds = [topicGroupID]
        return client.sendAsyncRequest(request)
    }

    func dislikeTopic(threadID: String) -> Observable<Void> {
        var request = RustPB.Im_V1_UninterestTopicForUserRequest()
        request.threadIds = [threadID]
        return client.sendAsyncRequest(request)
    }

    func dislikeUser(userID: String) -> Observable<Void> {
        var request = RustPB.Im_V1_UninterestUserForUserRequest()
        request.userIds = [userID]
        return client.sendAsyncRequest(request)
    }
}

func transformToThreadMessage(
    fromEntity entity: RustPB.Basic_V1_Entity,
    currentChatterId: String
) -> [String: ThreadMessage] {
    var threadMessageMap: [String: ThreadMessage] = [:]
    for (key, _) in entity.threads {
        do {
            threadMessageMap[key] = try ThreadMessage.transform(
                entity: entity,
                id: key,
                currentChatterID: currentChatterId
            )
        } catch {
            RustThreadAPI.logger.error("transformToThreadMessage error: \(error)")
        }
    }
    for (key, _) in entity.quasiThreads {
        do {
            threadMessageMap[key] = try ThreadMessage.transformQuasi(
                entity: entity,
                id: key,
                currentChatterID: currentChatterId
            )
        } catch {
            RustThreadAPI.logger.error("transformToThreadMessage error: \(error)")
        }
    }

    return threadMessageMap
}
