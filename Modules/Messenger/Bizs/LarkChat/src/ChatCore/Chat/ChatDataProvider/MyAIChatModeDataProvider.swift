//
//  MyAIChatModeDataProvider.swift
//  LarkChat
//
//  Created by ByteDance on 2023/10/16.
//

import Foundation
import LarkMessengerInterface
import RxSwift
import LarkSDKInterface
import LarkContainer
import LarkModel
import RustPB
import ServerPB
import LKCommonsLogging
import LarkCore
import UIKit
import LarkMessageCore
import UniverseDesignToast
import EENavigator
import LarkMessageBase

class MyAIChatModeDataProvider: ChatDataProviderProtocol {

    private static let logger = Logger.log(MyAIChatModeDataProvider.self, category: "Business.Chat")

    private let chatId: String
    private let pushCenter: PushNotificationCenter
    let userResolver: UserResolver
    lazy var messagesObservable: RxSwift.Observable<[LarkModel.Message]> = {
        let chatId = self.chatId
        return pushCenter.observable(for: PushChannelMessages.self)
            .map({ (push) -> [Message] in
                return push.messages.filter({ (msg) -> Bool in
                    return msg.channel.id == chatId
                })
            })
            .filter({ (msgs) -> Bool in
                return !msgs.isEmpty
            })
            .map({ [weak self] messages -> [Message] in
                // 分会场只展示当前分会场的消息，这里不能用thread.id过滤，因为进分会场时可能没有thread
                let aiChatModeMessages = messages.filter { $0.aiChatModeID == self?.myAIPageService?.chatModeConfig.aiChatModeId }
                let res: [Message] = Self.transThreadDataToChatData(messages: aiChatModeMessages.map({ $0.copy() }))
                return res
            })
    }()

    lazy var myAIPageService: MyAIPageService? = {
        let myAIPageService = try? userResolver.resolve(type: MyAIPageService.self)
        assert(myAIPageService != nil, "myAIPageService must not be nil")
        return myAIPageService
    }()
    private var threadMessage: ThreadMessage? {
        return myAIPageService?.chatModeThreadMessage
    }
    private var thread: RustPB.Basic_V1_Thread? {
        return threadMessage?.thread
    }
    @ScopedInjectedLazy private var threadAPI: ThreadAPI?

    let identify = "MyAIChatModeDataProvider"
    func fetchMessages(position: Int32,
                       pullType: LarkSDKInterface.PullMessagesType,
                       redundancyCount: Int32,
                       count: Int32,
                       expectDisplayWeights: Int32?,
                       redundancyDisplayWeights: Int32?) -> RxSwift.Observable<LarkSDKInterface.GetChatMessagesResult> {
        var scene: GetDataScene = .previous(before: position + 1)
        switch pullType {
        case .after:
            scene = .after(after: position - 1)
        default:
            break
        }
        return self.fetchMessagesForMyAI(scene: scene, redundancyCount: 0, count: 30)
    }

    func fetchSpecifiedMessage(position: Int32,
                               redundancyCount: Int32,
                               count: Int32,
                               expectDisplayWeights: Int32?,
                               redundancyDisplayWeights: Int32?
    ) -> RxSwift.Observable<LarkSDKInterface.GetChatMessagesResult> {
        return self.fetchMessagesForMyAI(scene: .specifiedPosition(position),
                                         redundancyCount: redundancyCount,
                                         count: count)
    }

    func fetchMissedMessages(positions: [Int32]) -> Observable<[Message]> {
        guard let thread = self.thread,
              let threadAPI = self.threadAPI else { return .error(UserScopeError.disposed) }
        MyAIChatModeDataProvider.logger.info("chatTrace fetchMissedMessageForMyAIChatMode: \(self.chatId) \(thread.id)")
        return threadAPI.fetchThreadMessagesBy(positions: positions, threadID: thread.id)
            .map({ [weak self] (messages, _) -> [Message] in
                guard let self = self else { return [] }
                var messages = messages
                if messages.first?.threadPosition == 0,
                    let threadMessage = self.threadMessage,
                       !threadMessage.thread.isMock,
                   threadMessage.rootMessage.id == threadMessage.thread.rootMessageID { //防止rootMessage是Mock的 的时候出现badcase，兜个底
                    messages.insert(threadMessage.rootMessage, at: 0)
                }
                return Self.transThreadDataToChatData(messages: messages)
            })
    }

    func getMessageIdsByPosition(startPosition: Int32,
                                 count: Int32) -> Observable<Im_V1_GetMessageIdsByPositionResponse> {
        fatalError("Not implemented")
    }

    static func fetchFirstScreenMessages(
        chatId: String,
        positionStrategy: ChatMessagePositionStrategy?,
        userResolver: UserResolver,
        screenHeight: CGFloat,
        fetchChatData: Observable<(Chat, fetchChatCost: Int64, fetchChatterCost: Int64)>
    ) throws -> Observable<GetChatMessagesResult> {
        let myAIChatModeConfig = try userResolver.resolve(type: MyAIPageService.self).chatModeConfig
        let aiChatModeId = myAIChatModeConfig.aiChatModeId
        let chatContext: RustPB.Basic_V1_ChatContext = myAIChatModeConfig.getCurrentChatContext()
        let chatIdInt = Int64(chatId) ?? 0
        let threadAPI = try userResolver.resolve(type: ThreadAPI.self)
        let myAiAPI = try userResolver.resolve(type: MyAIAPI.self)
        var specifiedPosition: Int32?
        if let positionStrategy = positionStrategy {
            switch positionStrategy {
            case .position(let positon):
                specifiedPosition = positon
            case .toLatestPositon:
                break
            }
        }

        return myAiAPI.getThreadByAIChatModeID(aiChatModeID: aiChatModeId, chatID: chatIdInt, chatContext: chatContext)
            .flatMap({ [weak userResolver] (response) -> Observable<GetThreadMessagesResult> in
                // 如果rootMessage没有，则会transform失败
                let threadMessages = threadAPI.transformEntityToThreadMessage(fromEntity: response.entity)
                //response一定会有threadID和对应的thread，但不一定有threadMessage，若没有则需要端上mock一个
                //（thread可能是sdk mock的。预期 当且仅当thread是sdk mock的时，会没有threadMessage）
                if let threadMessage = threadMessages[response.threadID] {
                    (try? userResolver?.resolve(type: MyAIPageService.self))?.chatModeThreadMessage = threadMessage
                    // 获取分会场绑定的Scene信息，此分支表示thread是创建好的，但是旧版本升级上来时sceneInfo先是空的，后续通过PushThreads更新sceneName，更新导航title
                    var scene = ServerPB_Office_ai_MyAIScene(); scene.sceneName = threadMessage.thread.sceneInfo.sceneName
                    (try? userResolver?.resolve(type: MyAIPageService.self))?.chatModeScene.accept(scene)
                    MyAIChatModeDataProvider.logger.info("my ai navgation bar get thread info for thread message, scene name: \(scene.sceneName)")
                } else if let thread = response.entity.threads[response.threadID] {
                    var mockThreadMessage = ThreadMessage(
                        thread: thread,
                        rootMessage: Message.transform(pb: Message.PBModel())
                    )
                    (try? userResolver?.resolve(type: MyAIPageService.self))?.chatModeThreadMessage = mockThreadMessage
                    // 获取分会场绑定的Scene信息，这里的sceneName应该是空的，这个分支表示thread是SDK Mock的，后续通过PushThreads更新sceneName，更新导航title
                    var scene = ServerPB_Office_ai_MyAIScene(); scene.sceneName = thread.sceneInfo.sceneName
                    (try? userResolver?.resolve(type: MyAIPageService.self))?.chatModeScene.accept(scene)
                    MyAIChatModeDataProvider.logger.info("my ai navgation bar get thread info for thread, scene name: \(scene.sceneName)")
                } else {
                    //预期永远也不会走这个分支
                    assertionFailure("no thread")
                    if let mainSceneWindow = userResolver?.navigator.mainSceneWindow {
                        UDToast.showFailure(with: BundleI18n.LarkChat.Lark_Legacy_ErrorMessageTip, on: mainSceneWindow)
                    }
                }
                return Self.fetchFirstScreenMessagesForMyAIChatMode(threadId: response.threadID,
                                                                    specifiedPosition: specifiedPosition,
                                                                    threadAPI: threadAPI)
            }).map({ [weak userResolver] (result) -> GetChatMessagesResult in
                return Self.transThreadDataToChatData(result: result,
                                                      threadMessage: (try? userResolver?.resolve(type: MyAIPageService.self))?.chatModeThreadMessage)
            })
    }

    static func fetchFirstScreenMessagesForMyAIChatMode(
        threadId: String,
        specifiedPosition: Int32?,
        threadAPI: ThreadAPI
    ) -> Observable<GetThreadMessagesResult> {
        let scene: GetDataScene
        if let position = specifiedPosition {
            scene = .specifiedPosition(position)
        } else {
            scene = .firstScreen
        }
        let firstScreenDataOb: Observable<GetThreadMessagesResult>
        firstScreenDataOb = threadAPI.getThreadMessages(
            threadId: threadId,
            isReplyInThread: true,
            scene: scene,
            redundancyCount: ChatMessagesViewModel.redundancyCount,
            count: ChatMessagesViewModel.requestCount,
            useIncompleteLocalData: true
        ).flatMap({ (localResult) -> Observable<GetThreadMessagesResult> in
            if let localResult = localResult {
                return .just(localResult)
            } else {
                return threadAPI.fetchThreadMessages(
                    threadId: threadId,
                    scene: scene,
                    redundancyCount: ChatMessagesViewModel.redundancyCount,
                    count: ChatMessagesViewModel.requestCount
                    )
            }
        })
        return firstScreenDataOb
    }

    required init(chatContext: ChatContext,
                  chatWrapper: ChatPushWrapper,
                  pushCenter: PushNotificationCenter) {
        self.userResolver = chatContext.userResolver
        self.chatId = chatWrapper.chat.value.id
        self.pushCenter = pushCenter
    }

    private func fetchMessagesForMyAI(
        scene: GetDataScene,
        redundancyCount: Int32,
        count: Int32
    ) -> Observable<GetChatMessagesResult> {
        self.logForGetMessages(scene: scene, redundancyCount: redundancyCount, count: count)
        return self.threadAPI?.fetchThreadMessages(
            threadId: self.threadMessage?.id ?? "",
            scene: scene,
            redundancyCount: redundancyCount,
            count: count
        ).map({ [weak self] result -> GetChatMessagesResult in
            return Self.transThreadDataToChatData(result: result, threadMessage: self?.threadMessage)
        }).do(onError: { [weak self] (error) in
            MyAIChatModeDataProvider.logger
                        .error("chatTrace my ai chatMode fetchMessages error",
                               additionalData: ["threadId": self?.threadMessage?.id ?? "",
                                            "scene": "\(scene)"],
                               error: error)
            }) ?? .error(UserScopeError.disposed)
    }

    private func logForGetMessages(scene: GetDataScene, redundancyCount: Int32, count: Int32) {
        MyAIChatModeDataProvider.logger.info("chatTrace fetchMessagesForMyAIChatMode",
                         additionalData: [
                            "chatId": self.chatId,
                            "aiChatModeId": "\(self.myAIPageService?.chatModeConfig.aiChatModeId)",
                            "lastMessagePosition": "\(self.thread?.lastMessagePosition)",
                            "lastVisibleMessagePosition": "\(self.thread?.lastVisibleMessagePosition)",
                            "scene": "\(scene.description())",
                            "count": "\(count)",
                            "redundancyCount": "\(redundancyCount)"])
    }

    static private func transThreadDataToChatData(result: GetThreadMessagesResult, threadMessage: ThreadMessage?) -> GetChatMessagesResult {
        let trackInfo = GetChatMessagesTrackInfo(contextId: result.trackInfo.contextId,
                                                 sdkCost: Int64(result.sdkCost * 1000),
                                                 netCosts: [],
                                                 parseCost: Int64(result.trackInfo.parseCost * 1000),
                                                 messagesSyncPipeFinished: [:])
        var messages = result.messages
        if let threadMessage = threadMessage,
           !threadMessage.thread.isMock,
           threadMessage.rootMessage.id == threadMessage.thread.rootMessageID, //防止rootMessage是Mock的 的时候出现badcase，兜个底
           (result.messages.first?.threadPosition == 0) || (threadMessage.thread.replyCount == 0) {
            messages.insert(threadMessage.rootMessage, at: 0)
        }
        let newMessages = Self.transThreadDataToChatData(messages: messages)
        return GetChatMessagesResult(messages: newMessages,
                                     invisiblePositions: result.invisiblePositions,
                                     missedPositions: result.missedPositions,
                                     foldPositionRange: [],
                                     localData: result.localData,
                                     trackInfo: trackInfo)
    }

    static private func transThreadDataToChatData(messages: [Message]) -> [Message] {
        let res = messages.map { msg in
            let newMsg = msg
            // 目前只有Push会有问题，loadMore等都是新创建的Message实例
            if newMsg.threadMessageType == .threadRootMessage {
                newMsg.position = -1
            } else {
                newMsg.position = newMsg.threadPosition
            }
            newMsg.rootMessage = nil
            newMsg.rootId = ""
            newMsg.parentMessage = nil
            newMsg.parentId = ""
            newMsg.threadMessageType = .unknownThreadMessage
            newMsg.badgeCount = newMsg.threadBadgeCount
            return newMsg
        }
        return res
    }
}
