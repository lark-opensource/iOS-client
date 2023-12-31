//
//  OpenPlatformOuterServiceImpl.swift
//  LarkOpenPlatform
//
//  Created by baojianjun on 2023/5/15.
//

import Foundation
import LKCommonsLogging
import LarkNavigation
import LarkContainer
import EENavigator
import LarkUIKit
import LarkTab
import RxSwift

import OPFoundation
import LarkOPInterface
import LarkMessengerInterface
import LarkSDKInterface

final class OpenPlatformOuterServiceImpl: OpenPlatformOuterService {
    private lazy var disposeBag: DisposeBag = { DisposeBag() }()
    private let resolver: UserResolver
    private static let logger = Logger.oplog(OpenPlatformOuterServiceImpl.self, category: "OpenPlatform")
    
    init(resolver: UserResolver) {
        self.resolver = resolver
    }
    
    func enterChat(chatId: String?, showBadge: Bool, window: UIWindow?) {
        guard let chatId = chatId else {
            Self.logger.error("[EMAProtocolImpl]: can not open chat with empty chatId")
            return
        }
        guard let from = OPNavigatorHelper.topmostNav(window: window) else {
            Self.logger.error("[EMAProtocolImpl]: can not open profile without from vc")
            assertionFailure("[EMAProtocolImpl]: nil topmost vc")
            return
        }
        var body = ChatControllerByIdBody(chatId: chatId)
        body.showNormalBack = !showBadge
        let context: [String: Any] = [
            FeedSelection.contextKey: FeedSelection(feedId: chatId, selectionType: .skipSame)
        ]
        resolver.navigator.showAfterSwitchIfNeeded(tab: Tab.feed.url, body: body, context: context, wrap: LkNavigationController.self, from: from)
    }
    
    func enterProfile(userId: String?, window: UIWindow?) {
        guard let chatterId = userId else {
            Self.logger.error("[EMAProtocolImpl]: can not open profile with empty userid")
            return
        }
        guard let from = OPNavigatorHelper.topmostNav(window: window) else {
            Self.logger.error("[EMAProtocolImpl]: can not open profile \(chatterId) without from vc")
            assertionFailure("[EMAProtocolImpl]: nil topmost vc")
            return
        }
        let body = PersonCardBody(chatterId: chatterId)
        resolver.navigator.presentOrPush(body: body,
                                       wrap: LkNavigationController.self,
                                       from: from,
                                       prepareForPresent: { (vc) in
            vc.modalPresentationStyle = .formSheet
        })
    }
    
    func enterBot(botId: String?, window: UIWindow?) {
        guard let chatService = try? resolver.resolve(assert: ChatService.self) else {
            Self.logger.error("[EMAProtocolImpl]: can not open bot chat without chat service")
            return }
        guard let bid = botId else {
            Self.logger.error("[EMAProtocolImpl]: can not open bot chat with empty botid")
            return
        }
        guard let from = OPNavigatorHelper.topmostNav(window: window) else {
            Self.logger.error("[EMAProtocolImpl]: can not open bot chat \(bid) without from vc")
            assertionFailure("[EMAProtocolImpl]: nil topmost vc")
            return
        }
        chatService.createP2PChat(userId: bid, isCrypto: false, chatSource: nil).observeOn(MainScheduler.instance).subscribe(onNext: { (chat) in
            let body = ChatControllerByChatBody(chat: chat)
            let context: [String: Any] = [
                FeedSelection.contextKey: FeedSelection(feedId: chat.id, selectionType: .skipSame)
            ]
            self.resolver.navigator.showAfterSwitchIfNeeded(tab: Tab.feed.url, body: body, context: context, wrap: LkNavigationController.self, from: from)
        }).disposed(by: self.disposeBag)
    }
}
