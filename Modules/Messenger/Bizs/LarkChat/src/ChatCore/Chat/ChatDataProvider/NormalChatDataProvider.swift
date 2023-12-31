//
//  NormalChatDataProvider.swift
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
import LKCommonsLogging
import LarkCore
import UIKit
import LarkMessageCore
import LarkTracing
import UniverseDesignToast
import LarkMessageBase

class NormalChatDataProvider: ChatDataProviderProtocol {
    private let logger = Logger.log(NormalChatDataProvider.self, category: "Business.Chat")

    let userResolver: UserResolver
    private let pushCenter: PushNotificationCenter
    lazy var messagesObservable: RxSwift.Observable<[LarkModel.Message]> = {
        let chatId = chatWrapper.chat.value.id
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
                var res: [Message] = self?.filterMessages(messages) ?? []
                return res
            })
    }()

    private let chatWrapper: ChatPushWrapper
    @ScopedInjectedLazy private var messageAPI: MessageAPI?

    private var chat: Chat {
        return self.chatWrapper.chat.value
    }

    let identify = "NormalChatDataProvider"
    func fetchMessages(position: Int32,
                       pullType: LarkSDKInterface.PullMessagesType,
                       redundancyCount: Int32,
                       count: Int32,
                       expectDisplayWeights: Int32?,
                       redundancyDisplayWeights: Int32?) -> RxSwift.Observable<LarkSDKInterface.GetChatMessagesResult> {
        var scene: FetchChatMessagesScene = FetchChatMessagesScene.previous(before: position)
        switch pullType {
        case .after:
            scene = FetchChatMessagesScene.after(after: position)
        default:
            break
        }

        return self.fetchMessages(scene: scene,
                                  redundancyCount: redundancyCount,
                                  count: count,
                                  expectDisplayWeights: expectDisplayWeights,
                                  redundancyDisplayWeights: redundancyDisplayWeights)
    }

    func fetchSpecifiedMessage(position: Int32,
                               redundancyCount: Int32,
                               count: Int32,
                               expectDisplayWeights: Int32?,
                               redundancyDisplayWeights: Int32?
    ) -> RxSwift.Observable<LarkSDKInterface.GetChatMessagesResult> {
        self.fetchMessages(scene: .specifiedPosition(position),
                           redundancyCount: ChatMessagesViewModel.redundancyCount,
                           count: ChatMessagesViewModel.requestCount,
                           expectDisplayWeights: expectDisplayWeights,
                           redundancyDisplayWeights: redundancyDisplayWeights)
    }

    func fetchMissedMessages(positions: [Int32]) -> RxSwift.Observable<[Message]> {
        self.logger.info("chatTrace fetchMissedMessages: \(self.chat.id) \(self.chat.isCrypto)")
        var channel = RustPB.Basic_V1_Channel()
        channel.id = self.chat.id
        channel.type = .chat
        return self.messageAPI?.fetchMessagesBy(positions: positions, channel: channel)
            .map({ (messages, _) -> [Message] in
                return messages
            }) ?? .error(UserScopeError.disposed)
    }

    func getMessageIdsByPosition(startPosition: Int32,
                                 count: Int32) -> Observable<Im_V1_GetMessageIdsByPositionResponse> {
        self.messageAPI?.getMessageIdsByPosition(chatId: self.chat.id, startPosition: startPosition, count: count) ?? .error(UserScopeError.disposed)
    }

    static func fetchFirstScreenMessages(
        chatId: String,
        positionStrategy: ChatMessagePositionStrategy?,
        userResolver: UserResolver,
        screenHeight: CGFloat,
        fetchChatData: Observable<(Chat, fetchChatCost: Int64, fetchChatterCost: Int64)>
    ) throws -> Observable<GetChatMessagesResult> {
        let fetchMessagePosition: FetchMessagePosition
        let messageAPI = try userResolver.resolve(type: MessageAPI.self)
        if let positionStrategy = positionStrategy {
            switch positionStrategy {
            case .position(let positon):
                fetchMessagePosition = FetchMessagePosition.position(positon)
            case .toLatestPositon:
                fetchMessagePosition = FetchMessagePosition.latestMessagePosition(chatOB: fetchChatData.map { $0.0 })
            }
        } else {
            fetchMessagePosition = FetchMessagePosition.position(nil)
        }
        switch fetchMessagePosition {
        case .position(let position):
            return Self.fetchFirstScreenMessages(
                chatId: chatId,
                specifiedPosition: position,
                messageAPI: messageAPI,
                screenHeight: screenHeight)
        case .latestMessagePosition(let chatOB):
            return chatOB.flatMap({ chat -> Observable<GetChatMessagesResult> in
                return Self.fetchFirstScreenMessages(
                    chatId: chatId,
                    specifiedPosition: chat.lastMessagePosition,
                    messageAPI: messageAPI,
                    screenHeight: screenHeight)
            })
        }
    }

    private static func fetchFirstScreenMessages(
        chatId: String,
        specifiedPosition: Int32?,
        messageAPI: MessageAPI,
        screenHeight: CGFloat
    ) -> Observable<GetChatMessagesResult> {
        LarkTracingUtil.startChildSpanByPName(spanName: LarkTracingUtil.firstScreenMessagesRender, parentName: LarkTracingUtil.enterChat)
        LarkTracingUtil.startChildSpanByPName(spanName: LarkTracingUtil.getChatMessages, parentName: LarkTracingUtil.firstScreenMessagesRender)
        let scene: FetchChatMessagesScene
        if let position = specifiedPosition {
            scene = .specifiedPosition(position)
        } else {
            scene = .firstScreen
        }
        return messageAPI.getChatMessages(chatId: chatId,
                                          scene: scene,
                                          redundancyCount: ChatMessagesViewModel.redundancyCount,
                                          count: ChatMessagesViewModel.requestCount,
                                          expectDisplayWeights: exceptWeight(height: screenHeight),
                                          redundancyDisplayWeights: exceptWeight(height: screenHeight / 3),
                                          needResponse: true,
                                          subscribChatEvent: true)
            .do(onSubscribed: {
            })
            .flatMap { (localResult) -> Observable<GetChatMessagesResult> in
                if let localResult = localResult {
                    return .just(localResult)
                }
                return messageAPI.fetchChatMessages(chatId: chatId,
                                                    scene: scene,
                                                    redundancyCount: ChatMessagesViewModel.redundancyCount,
                                                    count: ChatMessagesViewModel.requestCount,
                                                    expectDisplayWeights: exceptWeight(height: screenHeight),
                                                    redundancyDisplayWeights: exceptWeight(height: screenHeight / 3),
                                                    needResponse: true)
            }
    }

    required init(chatContext: ChatContext,
                  chatWrapper: ChatPushWrapper,
                  pushCenter: PushNotificationCenter) {
        self.userResolver = chatContext.userResolver
        self.chatWrapper = chatWrapper
        self.pushCenter = pushCenter
    }

    func filterMessages(_ messages: [Message]) -> [Message] {
        // 过滤消息：话题回复中的消息同步到群
        return messages.filter { $0.position >= -1 }
    }

    private func fetchMessages(
        scene: FetchChatMessagesScene,
        redundancyCount: Int32,
        count: Int32,
        expectDisplayWeights: Int32?,
        redundancyDisplayWeights: Int32?
    ) -> Observable<GetChatMessagesResult> {
        self.logForGetMessages(scene: scene, redundancyCount: redundancyCount, count: count, expectDisplayWeights: expectDisplayWeights)
        return self.messageAPI?.fetchChatMessages(chatId: self.chat.id,
                                                            scene: scene,
                                                            redundancyCount: redundancyCount,
                                                            count: count,
                                                            expectDisplayWeights: expectDisplayWeights,
                                                            redundancyDisplayWeights: redundancyDisplayWeights,
                                                            needResponse: true)
            .do(onError: { [weak self] (error) in
                self?.logger.error("chatTrace fetchMessages error", additionalData: ["chatId": self?.chat.id ?? "", "scene": "\(scene.description())"], error: error)
            }) ?? .error(UserScopeError.disposed)
    }

    private func logForGetMessages(scene: FetchChatMessagesScene, redundancyCount: Int32, count: Int32, expectDisplayWeights: Int32?) {
        self.logger.info("chatTrace fetchMessages",
                         additionalData: [
                            "chatId": self.chat.id,
                            "firstMessagePosition": "\(self.chat.firstMessagePostion)",
                            "bannerSetting.chatMessagePosition": "\(self.chat.bannerSetting?.chatMessagePosition)",
                            "lastMessagePosition": "\(self.chat.lastMessagePosition)",
                            "lastVisibleMessagePosition": "\(self.chat.lastVisibleMessagePosition)",
                            "scene": "\(scene.description())",
                            "count": "\(count)",
                            "redundancyCount": "\(redundancyCount)",
                            "expectDisplayWeights": "\(expectDisplayWeights ?? 0)"])
    }
}
