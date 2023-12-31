//
//  ReactionMenuActionHandler.swift
//  Pods
//
//  Created by liuwanlin on 2019/3/12.
//

import UIKit
import Foundation
import Homeric
import LKCommonsLogging
import RxSwift
import LarkModel
import LarkUIKit
import UniverseDesignToast
import EENavigator
import LarkContainer
import LarkMessengerInterface
import LarkMessageBase
import LKCommonsTracker
import LarkSDKInterface
import AppReciableSDK
import LarkCore
import LarkEmotion
import LarkFloatPicker

public final class ReactionMenuActionHandler {

    private var reactionAPI: ReactionAPI?
    private let currentChatterId: String
    private let scene: ContextScene
    private weak var targetVC: UIViewController?
    private let disposeBag = DisposeBag()

    static let logger = Logger.log(ReactionMenuActionHandler.self, category: "ReactionMenuActionHandler")

    // MARK: - Life Cycle
    public init(currentChatterId: String,
                scene: ContextScene,
                reactionAPI: ReactionAPI?,
                targetVC: UIViewController) {
        self.currentChatterId = currentChatterId
        self.scene = scene
        self.targetVC = targetVC
        self.reactionAPI = reactionAPI
    }

    /// 接口参数固化静态化,将字典封装一层
    func handle(message: Message,
                chat: Chat,
                reactionKey: String,
                reactionSource: ReactionActionSource,
                isSkintonePanel: Bool? = nil,
                skintoneEmojiSelectWay: SelectedWay? = nil,
                time: TimeInterval) {
        let params: [String: Any] = [
            MessageMenuInfoKey.skintoneEmojiSelectWay: skintoneEmojiSelectWay,
            MessageMenuInfoKey.isSkintonePanel: isSkintonePanel,
            MessageMenuInfoKey.reactionKey: reactionKey,
            MessageMenuInfoKey.reactionSource: reactionSource,
            MessageMenuInfoKey.time: time,
            MessageMenuInfoKey.scene: "im"
        ]
        self.handle(message: message,
                    chat: chat,
                    params: params)
    }

    // MARK: - public methods
    public func handle(message: Message, chat: Chat, params: [String: Any]) {
        guard let type = params[MessageMenuInfoKey.reactionKey] as? String,
            let source = params[MessageMenuInfoKey.reactionSource] as? ReactionActionSource,
            let time = params[MessageMenuInfoKey.time] as? TimeInterval else {
            return
        }

        ReactionMenuActionHandler.logger.info("call reactionAPI \(message.id) \(type)")
        let isCancel = message.reactions.contains(where: { (reaction) -> Bool in
            if reaction.type != type {
                return false
            } else if chat.anonymousId.isEmpty {
                return reaction.chatterIds.contains(currentChatterId)
            } else {
                return reaction.chatterIds.contains(chat.anonymousId)
            }
        })
        if isCancel {
            reactionAPI?.deleteISendReaction(messageId: message.id, reactionType: type)
                .observeOn(MainScheduler.instance)
                .subscribe(onError: { [weak self] (error) in
                    self?.handleReactionError(error)
                }).disposed(by: disposeBag)
        } else {
            let reciableKey = AppReciableSDK.shared.start(biz: .Messenger, scene: .Chat, event: .showReaction, page: "ChatViewController")
            let beforeSend = CACurrentMediaTime()
            self.trackReaction(message: message, chat: chat, type: type, source: source, time: time)
            reactionAPI?.sendReaction(messageId: message.id, reactionType: type)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { (_) in
                    //发送成功埋点
                    let sdk_cost = CACurrentMediaTime() - beforeSend
                    let extra = Extra(
                        isNeedNet: true,
                        latencyDetail: [
                            "sdk_cost": Int(sdk_cost * 1000)
                        ],
                        metric: nil,
                        category: [
                            "message_type": "\(message.type)",
                            "chat_type": "\(chat.type)",
                            "is_metting": chat.isMeeting
                        ],
                        extra: [
                            "context_id": ""
                        ]
                    )
                    AppReciableSDK.shared.end(key: reciableKey, extra: extra)
                }, onError: { [weak self] (error) in
                    self?.handleReactionError(error)
                    //失败埋点
                    AppReciableSDK.shared.error(params: ErrorParams(
                        biz: .Messenger,
                        scene: .Chat,
                        event: .showReaction,
                        errorType: .SDK,
                        errorLevel: .Exception,
                        errorCode: (error as NSError).code,
                        userAction: nil,
                        page: "ChatViewController",
                        errorMessage: (error as NSError).description,
                        extra: Extra(
                            isNeedNet: true,
                            category: [
                                "message_type": "\(message.type)",
                                "chat_type": "\(chat.type)",
                                "is_metting": chat.isMeeting
                            ],
                            extra: [
                                "context_id": ""
                            ]
                        )))
                }).disposed(by: disposeBag)
            reactionAPI?.updateRecentlyUsedReaction(reactionType: type).subscribe().disposed(by: disposeBag)
        }
        if message.type == .hongbao || message.type == .commercializedHongbao {
            Tracker.post(TeaEvent(Homeric.MOBILE_HONGBAO_REACTION))
        }
        var isSkintonePanel = false
        var scene: String = "unknown"
        var skintoneEmojiSelectWay: SelectedWay?
        if let enable = params[MessageMenuInfoKey.isSkintonePanel] as? Bool {
            isSkintonePanel = enable
        }
        if let value = params[MessageMenuInfoKey.scene] as? String {
            scene = value
        }
        if let value = params[MessageMenuInfoKey.skintoneEmojiSelectWay] as? SelectedWay {
            skintoneEmojiSelectWay = value
        }
        switch source {
        /// 所有reaction面板点击
        case .ReactionPanel(_):
            PublicTracker.Reaction.Click(type, scene: scene, tab: .all, isSkintonePanel: isSkintonePanel, skintoneEmojiSelectWay: skintoneEmojiSelectWay, chatId: nil)
        /// 最常使用reaction面板点击
        case .ReactionBar:
            PublicTracker.Reaction.Click(type, scene: scene, tab: .mru, isSkintonePanel: isSkintonePanel, skintoneEmojiSelectWay: skintoneEmojiSelectWay, chatId: nil)
            IMTracker.Msg.Menu.Click.ReactionClick(chat, message, params[MessageMenuInfoKey.chatFromWhere] as? String)
        case .ReactionView:
            break
        }
    }

    private func handleReactionError(_ error: Error) {
        guard let targetVC = self.targetVC else {
            return
        }
        if let error = error.underlyingError as? APIError {
            switch error.type {
            case .noSecretChatPermission(let message):
                UDToast.showFailure(with: message, on: targetVC.view, error: error)
            default:
                break
            }
        }
        Self.logger.error(error.localizedDescription)
    }

    // MARK: - tracker
    private func trackReaction(message: Message, chat: Chat, type: String, source: ReactionActionSource, time: TimeInterval) {
        var tab = "unknown"
        switch source {
        case .ReactionView:
            // 默认表情
            tab = "all"
        case .ReactionBar:
            // 最常使用
            tab = "commonly_used"
        case .ReactionPanel(_):
            // 默认表情
            tab = "all"
        }

        ReactionTracker.trackReaction(message: message, chat: chat, scene: scene, type: type, tab: tab, time: time)
    }
}
