//
//  ChatFeedCardDependency.swift
//  LarkFeedPlugin
//
//  Created by 夏汝震 on 2023/8/8.
//

import Foundation
import LarkMessengerInterface
import LarkAccountInterface
import LarkOpenFeed
import RustPB
import RxSwift
import LarkSDKInterface
import LarkContainer

protocol ChatFeedCardDependency {
    var accountType: PassportUserType { get }

    var isByteDancer: Bool { get }

    var currentTenantId: String { get }

    var iPadStatus: String? { get }

    func afterThatServerTime(time: Int64) -> Bool

    /// 被踢出群聊时，点击进入Chat，需要进行弹框拦截，同时移除该Feed
    func removeFeed(channel: Basic_V1_Channel,
                    feedPreviewPBType: Basic_V1_FeedCard.EntityType?) -> Observable<Void>

    /// 获取被踢出群的原因
    func getKickInfo(chatId: String) -> Observable<String>

    func changeMute(chatId: String, to state: Bool) -> Single<Void>
}

final class ChatFeedCardDependencyImpl: ChatFeedCardDependency {
    let userResolver: UserResolver

    let passportUserService: PassportUserService
    let serverNTPTimeService: ServerNTPTimeService
    let feedAPI: FeedAPI
    let chatAPI: ChatAPI
    let feedThreeBarService: FeedThreeBarService
    let disposeBag = DisposeBag()

    var accountType: PassportUserType {
        return passportUserService.user.type
    }

    var currentTenantId: String {
        return passportUserService.userTenant.tenantID
    }

    var isByteDancer: Bool {
        return passportUserService.userTenant.isByteDancer
    }

    var iPadStatus: String? {
        if let unfold = feedThreeBarService.padUnfoldStatus {
            return unfold ? "unfold" : "fold"
        }
        return nil
    }

    init(resolver: UserResolver) throws {
        self.userResolver = resolver
        self.passportUserService = try resolver.resolve(assert: PassportUserService.self)
        self.serverNTPTimeService = try resolver.resolve(assert: ServerNTPTimeService.self)
        self.feedAPI = try resolver.resolve(assert: FeedAPI.self)
        self.chatAPI = try resolver.resolve(assert: ChatAPI.self)
        self.feedThreeBarService = try resolver.resolve(assert: FeedThreeBarService.self)
    }

    func afterThatServerTime(time: Int64) -> Bool {
        return serverNTPTimeService.afterThatServerTime(time: time)
    }

    func removeFeed(channel: Basic_V1_Channel,
                    feedPreviewPBType: Basic_V1_FeedCard.EntityType?) -> Observable<Void> {
        return feedAPI.removeFeedCard(channel: channel, feedType: feedPreviewPBType)
    }

    func getKickInfo(chatId: String) -> Observable<String> {
        return chatAPI.getKickInfo(chatId: chatId)
    }

    func changeMute(chatId: String, to state: Bool) -> Single<Void> {
        chatAPI.updateChat(chatId: chatId, isRemind: state).map({ _ in
        }).asSingle()
    }
}
