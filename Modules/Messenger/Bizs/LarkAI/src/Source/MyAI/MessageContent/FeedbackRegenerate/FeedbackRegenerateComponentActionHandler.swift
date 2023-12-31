//
//  FeedbackRegenerateComponentActionHandler.swift
//  LarkAI
//
//  Created by 李勇 on 2023/6/16.
//

import UIKit
import LarkModel
import LarkCore
import LarkUIKit
import Foundation
import RustPB
import RxSwift
import ServerPB
import EENavigator
import LarkMessageBase
import LarkSDKInterface
import LarkContainer
import UniverseDesignToast
import LarkMessengerInterface
import LarkAIInfra

public protocol FeedbackRegenerateActionHanderContext: ViewModelContext {
    var myAIPageService: MyAIPageService? { get }
    var sdkRustService: SDKRustService? { get }
    var userResolver: UserResolver { get }
}

class FeedbackRegenerateComponentActionHandler<C: FeedbackRegenerateActionHanderContext>: ComponentActionHandler<C> {
    private let disposeBag = DisposeBag()
    /// 请求控频，避免服务端请求爆炸
    private var currInRequest: Bool = false

    public func didTapLike(chat: Chat, message: Message) {
        guard let myAIPageService = self.context.myAIPageService else { return }

        // 请求控频
        if self.currInRequest {
            MyAIPageServiceImpl.logger.info("my ai feedback like is in request")
            return
        }
        self.currInRequest = true

        IMTracker.Msg.Menu.Click.Like(
            chat,
            message,
            params: myAIPageService.chatMode ? ["app_name": myAIPageService.chatModeConfig.extra["app_name"] ?? "other"] : [:],
            myAIPageService.chatFromWhere
        )

        // 发起赞踩请求
        var request = Im_V1_CreateAILikeFeedbackRequest()
        request.messageID = message.id
        request.praise = true
        request.isDelete = message.feedbackStatus == .like
        // 透传请求
        self.context.sdkRustService?.sendAsyncRequest(request).observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] _ in
            MyAIPageServiceImpl.logger.info("my ai feedback like click success")
            self?.currInRequest = false
        }, onError: { [weak self] error in
            MyAIPageServiceImpl.logger.info("my ai feedback like click error, error: \(error)")
            self?.currInRequest = false
            guard let view = self?.context.targetVC?.view else { return }
            if let apiError = error.underlyingError as? APIError {
                UDToast.showFailure(with: BundleI18n.LarkAI.Lark_Legacy_NetworkOrServiceError, on: view, error: apiError)
            } else {
                UDToast.showFailure(with: BundleI18n.LarkAI.Lark_Legacy_NetworkOrServiceError, on: view, error: error)
            }
        }).disposed(by: self.disposeBag)
    }

    public func didTapDislike(chat: Chat, message: Message) {
        guard let myAIPageService = self.context.myAIPageService, let targetVC = self.context.targetVC else { return }

        // 请求控频
        if self.currInRequest {
            MyAIPageServiceImpl.logger.info("my ai feedback dislike is in request")
            return
        }
        self.currInRequest = true

        IMTracker.Msg.Menu.Click.Dislike(
            chat,
            message,
            params: myAIPageService.chatMode ? ["app_name": myAIPageService.chatModeConfig.extra["app_name"] ?? "other"] : [:],
            myAIPageService.chatFromWhere
        )

        // 发起赞踩请求
        var request = Im_V1_CreateAILikeFeedbackRequest()
        request.messageID = message.id
        request.praise = false
        request.isDelete = message.feedbackStatus == .dislike
        // 透传请求
        self.context.sdkRustService?.sendAsyncRequest(request).observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] (response: Im_V1_CreateAILikeFeedbackResponse) in
            MyAIPageServiceImpl.logger.info("my ai feedback dislike click success")
            self?.currInRequest = false

            // 如果是从 无/赞 -> 踩，跳转到踩反馈界面
            guard !request.isDelete else { return }
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
            MyAIPageServiceImpl.logger.info("my ai feedback dislike click error, error: \(error)")
            self?.currInRequest = false
            guard let view = self?.context.targetVC?.view else { return }
            if let apiError = error.underlyingError as? APIError {
                UDToast.showFailure(with: BundleI18n.LarkAI.Lark_Legacy_NetworkOrServiceError, on: view, error: apiError)
            } else {
                UDToast.showFailure(with: BundleI18n.LarkAI.Lark_Legacy_NetworkOrServiceError, on: view, error: error)
            }
        }).disposed(by: self.disposeBag)
    }

    /// 发起重新生成请求
    public func regenerateClick(chat: Chat, onSuccess: (() -> Void)?, onError: (() -> Void)?) {
        MyAIPageServiceImpl.logger.info("my ai regenerate click")
        guard let myAIPageService = self.context.myAIPageService else {
            MyAIPageServiceImpl.logger.info("my ai regenerate click error, service is none")
            return
        }

        IMTracker.Chat.Main.Click.regenerate(
            chat,
            params: myAIPageService.chatMode ? ["app_name": myAIPageService.chatModeConfig.extra["app_name"] ?? "other"] : [:],
            myAIPageService.chatFromWhere
        )

        let aiRoundInfo = myAIPageService.aiRoundInfo.value
        var request = ServerPB_Office_ai_AIChatReGenerateRequest()
        request.chatID = Int64(chat.id) ?? 0
        request.roundID = aiRoundInfo.roundId
        if myAIPageService.chatMode { request.aiChatModeID = myAIPageService.chatModeConfig.aiChatModeId }
        // 透传请求
        self.context.sdkRustService?.sendPassThroughAsyncRequest(request, serCommand: .larkOfficeAiImRegenerate).observeOn(MainScheduler.instance).subscribe(onNext: { _ in
            MyAIPageServiceImpl.logger.info("my ai regenerate click success")
            onSuccess?()
        }, onError: { [weak self] error in
            MyAIPageServiceImpl.logger.info("my ai regenerate click error, error: \(error)")
            onError?()
            guard let view = self?.context.targetVC?.view else { return }
            if let apiError = error.transformToAPIError().metaErrorStack.first(where: { $0 is APIError }) as? APIError {
                UDToast.showFailure(with: BundleI18n.LarkAI.Lark_Legacy_NetworkOrServiceError, on: view, error: apiError)
            } else {
                UDToast.showFailure(with: BundleI18n.LarkAI.Lark_Legacy_NetworkOrServiceError, on: view, error: error)
            }
        }).disposed(by: self.disposeBag)
    }
}
