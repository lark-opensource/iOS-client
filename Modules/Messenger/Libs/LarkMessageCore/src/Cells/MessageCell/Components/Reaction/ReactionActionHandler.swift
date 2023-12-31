//
//  ReactionActionHandler.swift
//  LarkMessageCore
//
//  Created by Ping on 2023/1/28.
//

import UIKit
import Foundation
import RxSwift
import Homeric
import LarkCore
import LarkModel
import LarkUIKit
import LarkMessageBase
import LKCommonsTracker
import LarkSDKInterface
import UniverseDesignToast
import LarkMessengerInterface

class ReactionActionHandler<C: ReactionViewModelContext>: ComponentActionHandler<C> {
    private let disposeBag = DisposeBag()

    public func reactionDidTapped(chat: Chat, message: Message, reaction: Reaction, tapType: ReactionActionType) {
        switch tapType {
        case .icon: tapIcon(chat: chat, message: message, type: reaction.type)
        case .more: tapMore(messageID: message.id, type: reaction.type)
        case .name(let chatterId): tapChatter(chat: chat, message: message, chatterId)
        }
    }

    func tapIcon(chat: Chat, message: Message, type: String) {
        let isCancel = message.reactions.contains(where: { (reaction) -> Bool in
            if reaction.type != type {
                return false
            } else if chat.anonymousId.isEmpty {
                return reaction.chatterIds.contains(context.currentChatterId)
            } else {
                return reaction.chatterIds.contains(chat.anonymousId)
            }
        })
        let messageId = message.id
        if isCancel {
            context.reactionAPI?.deleteISendReaction(messageId: message.id, reactionType: type)
                .observeOn(MainScheduler.instance)
                .subscribe(onError: { [weak self] (error) in
                    self?.handleReactionError(messageId: messageId, reactionType: type, error: error)
                }).disposed(by: disposeBag)
            IMTracker.Chat.Main.Click.Msg.Reaction(chat, message, context.trackParams[PageContext.TrackKey.sceneKey] as? String, effect: "remove", type: type)
        } else {
            ReactionTracker.trackReaction(message: message, chat: chat, scene: context.scene, type: type, tab: "all", time: 0)
            context.reactionAPI?.sendReaction(messageId: message.id, reactionType: type)
                .observeOn(MainScheduler.instance)
                .subscribe(onError: { [weak self] (error) in
                    self?.handleReactionError(messageId: messageId, reactionType: type, error: error)
                }).disposed(by: disposeBag)
            context.reactionAPI?.updateRecentlyUsedReaction(reactionType: type).subscribe().disposed(by: disposeBag)
            IMTracker.Chat.Main.Click.Msg.Reaction(chat, message, context.trackParams[PageContext.TrackKey.sceneKey] as? String, effect: "add", type: type)
        }
        if message.type == .hongbao || message.type == .commercializedHongbao {
            Tracker.post(TeaEvent(Homeric.MOBILE_HONGBAO_REACTION))
        }
    }

    func tapChatter(chat: Chat, message: Message, _ chatterId: String) {
        let body = PersonCardBody(chatterId: chatterId,
                                  chatId: message.channel.id,
                                  source: .chat)

        if Display.phone {
            context.navigator(type: .push, body: body, params: nil)
        } else {
            context.navigator(
                type: .present,
                body: body,
                params: NavigatorParams(wrap: LkNavigationController.self, prepare: { vc in
                    vc.modalPresentationStyle = .formSheet
                }))
        }
        IMTracker.Chat.Main.Click.Msg.Reaction(chat, message, context.trackParams[PageContext.TrackKey.sceneKey] as? String, effect: "profile", type: "none")
    }

    func tapMore(messageID: String, type: String) {
        let body = ReactionDetailBody(messageId: messageID, type: type)
        context.navigator(
            type: .present,
            body: body,
            params: NavigatorParams(
                wrap: LkNavigationController.self,
                prepare: { (controller) in
                    controller.modalPresentationStyle = .overCurrentContext
                    controller.modalTransitionStyle = .crossDissolve
                    controller.view.backgroundColor = UIColor.clear
                },
                animated: false)
        )
    }

    private func handleReactionError(messageId: String, reactionType: String, error: Error) {
        if let error = error.underlyingError as? APIError, let window = self.context.targetVC?.view.window {
            switch error.type {
            case .noSecretChatPermission(let message):
                UDToast.showFailure(with: message, on: window, error: error)
            default:
                break
            }
        }
        ReactionViewModelLogger.logger.error("reaction: handleReactionError messageId = \(messageId), reactionType = \(reactionType), error = \(error)")
    }
}

class ThreadPostForwardReactionActionHandler<C: ReactionViewModelContext>: ReactionActionHandler<C> {
    override func tapIcon(chat: Chat, message: Message, type: String) {}

    override func tapMore(messageID: String, type: String) {}
}

final class MergeForwardReactionActionHandler<C: ReactionViewModelContext>: ThreadPostForwardReactionActionHandler<C> {
    override func tapChatter(chat: Chat, message: Message, _ chatterId: String) {
    }
}
