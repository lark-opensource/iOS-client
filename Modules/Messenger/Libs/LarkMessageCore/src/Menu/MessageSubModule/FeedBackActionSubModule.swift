//
//  FeedBackActionSubModule.swift
//  LarkMessageCore
//
//  Created by 李勇 on 2023/4/18.
//

import Foundation
import RustPB
import ServerPB
import LarkCore
import RxSwift
import RxCocoa
import LarkUIKit
import LarkAIInfra
import LarkOpenChat
import LKCommonsLogging
import LarkSDKInterface
import UniverseDesignIcon
import UniverseDesignToast
import LarkMessengerInterface

/// My AI回复，最后一轮的最后一条消息外，赞踩都收敛到消息菜单中
public final class LikeActionSubModule: MessageActionSubModule {
    private let disposeBag = DisposeBag()
    private static let logger = Logger.log(LikeActionSubModule.self, category: "Module.LarkMessageCore")

    /// 消息菜单操作的类型
    public override var type: MessageActionType { .like }

    public override class func canInitialize(context: MessageActionContext) -> Bool {
        return true
    }

    public override func canHandle(model: MessageActionMetaModel) -> Bool {
        // My AI的单聊 && My AI的回复
        guard model.chat.isP2PAi, model.message.fromChatter?.type == .ai else { return false }
        // 不在流式中
        guard model.message.streamStatus != .streamTransport, model.message.streamStatus != .streamPrepare else { return false }
        guard let myAIPageService = try? self.context.userResolver.resolve(type: MyAIPageService.self) else { return false }
        // 不是最后一轮的最后一条消息
        if !myAIPageService.chatMode, model.message.position == myAIPageService.aiRoundInfo.value.roundLastPosition { return false }
        if myAIPageService.chatMode, model.message.threadPosition == myAIPageService.aiRoundInfo.value.roundLastPosition { return false }
        return true
    }

    /// 一个SubModule可以构造一个消息按钮
    public override func createActionItem(model: MessageActionMetaModel) -> MessageActionItem? {
        let text = model.message.feedbackStatus == .like ? BundleI18n.LarkMessageCore.MyAI_IM_Unlike_Mobile_Button : BundleI18n.LarkMessageCore.MyAI_IM_Like_Hover
        let likeKey: UDIconType = model.message.feedbackStatus == .like ? .thumbsupFilled : .thumbsupOutlined
        let icon = UDIcon.getIconByKey(likeKey, iconColor: likeKey == .thumbsupFilled ? UIColor.ud.colorfulYellow : UIColor.ud.iconN1, size: CGSize(width: 22, height: 22))
        return MessageActionItem(text: text, icon: icon, trackExtraParams: ["click": "like", "target": "none"]) { [weak self] in
            guard let `self` = self, let myAIPageService = try? self.context.userResolver.resolve(type: MyAIPageService.self) else { return }
            IMTracker.Msg.Menu.Click.Like(
                model.chat,
                model.message,
                params: myAIPageService.chatMode ? ["app_name": myAIPageService.chatModeConfig.extra["app_name"] ?? "other"] : [:],
                myAIPageService.chatFromWhere
            )
            // 发起赞踩请求
            var request = Im_V1_CreateAILikeFeedbackRequest()
            request.messageID = model.message.id
            request.praise = true
            request.isDelete = model.message.feedbackStatus == .like
            // 透传请求 SDKRustService
            let sdkRustService = try? self.context.userResolver.resolve(type: SDKRustService.self)
            sdkRustService?.sendAsyncRequest(request).observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] _ in
                LikeActionSubModule.logger.info("my ai feedback like click success")
                guard let view = self?.context.targetVC?.view else { return }
                UDToast.showSuccess(with: request.isDelete ? BundleI18n.LarkMessageCore.MyAI_IM_LikeCanceled_Toast : BundleI18n.LarkMessageCore.MyAI_IM_LikeSubmitted_Toast, on: view)
            }, onError: { [weak self] error in
                LikeActionSubModule.logger.info("my ai feedback like click error, error: \(error)")
                guard let view = self?.context.targetVC?.view else { return }
                if let apiError = error.underlyingError as? APIError {
                    UDToast.showFailure(with: BundleI18n.LarkMessageCore.Lark_Legacy_NetworkOrServiceError, on: view, error: apiError)
                } else {
                    UDToast.showFailure(with: BundleI18n.LarkMessageCore.Lark_Legacy_NetworkOrServiceError, on: view, error: error)
                }
            }).disposed(by: self.disposeBag)
        }
    }
}

public final class DislikeActionSubModule: MessageActionSubModule {
    private let disposeBag = DisposeBag()
    private static let logger = Logger.log(DislikeActionSubModule.self, category: "Module.LarkMessageCore")

    /// 消息菜单操作的类型
    public override var type: MessageActionType { .dislike }

    public override class func canInitialize(context: MessageActionContext) -> Bool {
        return true
    }

    public override func canHandle(model: MessageActionMetaModel) -> Bool {
        // My AI的单聊 && My AI的回复
        guard model.chat.isP2PAi, model.message.fromChatter?.type == .ai else { return false }
        // 不在流式中
        guard model.message.streamStatus != .streamTransport, model.message.streamStatus != .streamPrepare else { return false }
        guard let myAIPageService = try? self.context.userResolver.resolve(type: MyAIPageService.self) else { return false }
        // 不是最后一轮的最后一条消息
        if !myAIPageService.chatMode, model.message.position == myAIPageService.aiRoundInfo.value.roundLastPosition { return false }
        if myAIPageService.chatMode, model.message.threadPosition == myAIPageService.aiRoundInfo.value.roundLastPosition { return false }
        return true
    }

    /// 一个SubModule可以构造一个消息按钮
    public override func createActionItem(model: MessageActionMetaModel) -> MessageActionItem? {
        let text = model.message.feedbackStatus == .dislike ? BundleI18n.LarkMessageCore.MyAI_IM_UndoDislike_Mobile_Button : BundleI18n.LarkMessageCore.MyAI_IM_Like_Dislike
        let dislikeKey: UDIconType = model.message.feedbackStatus == .dislike ? .thumbdownFilled : .thumbdownOutlined
        let icon = UDIcon.getIconByKey(dislikeKey, iconColor: dislikeKey == .thumbdownFilled ? UIColor.ud.iconN3 : UIColor.ud.iconN1, size: CGSize(width: 22, height: 22))
        return MessageActionItem(text: text, icon: icon, trackExtraParams: ["click": "dislike", "target": "none"]) { [weak self] in
            guard let `self` = self, let myAIPageService = try? self.context.userResolver.resolve(type: MyAIPageService.self) else { return }
            IMTracker.Msg.Menu.Click.Dislike(
                model.chat,
                model.message,
                params: myAIPageService.chatMode ? ["app_name": myAIPageService.chatModeConfig.extra["app_name"] ?? "other"] : [:],
                myAIPageService.chatFromWhere
            )
            // 发起赞踩请求
            var request = Im_V1_CreateAILikeFeedbackRequest()
            request.messageID = model.message.id
            request.praise = false
            request.isDelete = model.message.feedbackStatus == .dislike
            // 透传请求
            let sdkRustService = try? self.context.userResolver.resolve(type: SDKRustService.self)
            sdkRustService?.sendAsyncRequest(request).observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] (response: Im_V1_CreateAILikeFeedbackResponse) in
                DislikeActionSubModule.logger.info("my ai feedback dislike click success")
                // 如果是从 踩 -> 无赞，直接弹toast即可
                if request.isDelete {
                    if let view = self?.context.targetVC?.view { UDToast.showSuccess(with: BundleI18n.LarkMessageCore.MyAI_IM_LikeCanceled_Toast, on: view) }
                    return
                }
                // 如果是从 无赞 -> 踩，跳转到踩反馈界面
                guard let targetVC = self?.context.targetVC else { return }
                let response = self?.context.userResolver.navigator.response(
                    for: MyAIAnswerFeedbackBody(aiMessageId: response.aiMessageID, scenario: response.scene, mode: .chatMode(queryMessageID: "", ansMessageID: request.messageID))
                )
                guard let feedBackViewController = response?.resource as? UIViewController else { assertionFailure(); return }
                self?.context.userResolver.navigator.present(
                    feedBackViewController,
                    wrap: LkNavigationController.self,
                    from: targetVC,
                    prepare: { $0.transitioningDelegate = feedBackViewController as? UIViewControllerTransitioningDelegate; $0.modalPresentationStyle = .custom },
                    animated: true
                )
            }, onError: { [weak self] error in
                DislikeActionSubModule.logger.info("my ai feedback dislike click error, error: \(error)")
                guard let view = self?.context.targetVC?.view else { return }
                if let apiError = error.underlyingError as? APIError {
                    UDToast.showFailure(with: BundleI18n.LarkMessageCore.Lark_Legacy_NetworkOrServiceError, on: view, error: apiError)
                } else {
                    UDToast.showFailure(with: BundleI18n.LarkMessageCore.Lark_Legacy_NetworkOrServiceError, on: view, error: error)
                }
            }).disposed(by: self.disposeBag)
        }
    }
}
