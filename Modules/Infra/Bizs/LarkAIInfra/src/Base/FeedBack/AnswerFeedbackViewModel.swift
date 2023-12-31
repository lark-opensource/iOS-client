//
//  AnswerFeedbackViewModel.swift
//  LarkAIInfra
//
//  Created by 李勇 on 2023/6/16.
//

import Foundation
import SnapKit
import RxSwift
import RxCocoa
import EditTextView
import EENavigator
import RustPB
import ServerPB
import LarkContainer
import LarkRustClient
import LKCommonsTracker
import LKCommonsLogging
import UniverseDesignIcon
import UniverseDesignButton

class AnswerFeedbackViewModel {
    static let logger = Logger.log(AnswerFeedbackViewModel.self, category: "Module.LarkAIInfra")

    private let rustClient: RustService?
    private let userResolver: UserResolver
    /// 这两个参数是点踩请求PutAILikeFeedbackRequest时，服务端返回的
    private let aiMessageId: String
    private let scenario: String
    /// InlineMode/ChatMode
    private let mode: MyAIAnswerFeedbackBody.Mode
    private let disposeBag = DisposeBag()
    /// 请求控频，避免服务端请求爆炸；不需要了，UDButton.showLoading会把isUserInteractionEnabled设置为fasle起到频控效果
    // private var currInRequest: Bool = false

    init(userResolver: UserResolver, aiMessageId: String, scenario: String, mode: MyAIAnswerFeedbackBody.Mode) {
        self.userResolver = userResolver
        self.rustClient = try? userResolver.resolve(type: RustService.self)
        self.aiMessageId = aiMessageId
        self.scenario = scenario
        self.mode = mode
    }

    /// 拉取原因
    func loadReasons(onSuccess: @escaping ((_ reasons: [AIFeedbackConfig.FeedbackReason]) -> Void)) {
        let reasons = AIFeedbackConfig(stringDic: try? self.userResolver.settings.setting(with: AIFeedbackConfig.key))?.reasons ?? []
        AnswerFeedbackViewController.logger.debug("my ai feedback send load \(reasons.count) reasons")
        // 这里需要延迟一点时间，让policyView.contentSize能更新为正确的值
        let delayTime: TimeInterval = 0.1
        DispatchQueue.main.asyncAfter(deadline: .now() + delayTime) { onSuccess(reasons) }
    }

    /// 发送反馈
    func sendFeedBack(reasonIds: [String], content: String, onSuccess: (() -> Void)?, onError: (() -> Void)?) {
        AnswerFeedbackViewModel.Feedback(aiMessageId: self.aiMessageId)

        // 发起赞踩请求
        var request = ServerPB_Ai_engine_FeedsbackRequest()
        if case .chatMode(let queryMessageID, let ansMessageID) = self.mode {
            request.queryMessageID = queryMessageID
            request.ansMessageID = ansMessageID
            request.mode = .chat
        } else if case .inlineMode(let queryMessageRawdata, let ansMessageRawdata) = self.mode {
            request.queryMessageRawdata = queryMessageRawdata
            request.ansMessageRawdata = ansMessageRawdata
            request.mode = .inline
        }
        request.aiMessageID = self.aiMessageId
        request.data.like = false
        request.data.reasonID = reasonIds
        request.data.extra = content
        request.scenario = self.scenario

        // 透传请求
        self.rustClient?.sendPassThroughAsyncRequest(request, serCommand: .larkAiFeedbackReasonSubmit).observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] _ in
            AnswerFeedbackViewModel.logger.info("my ai feedback send click success")
            onSuccess?()
        }, onError: { [weak self] error in
            AnswerFeedbackViewModel.logger.info("my ai feedback send click error, error: \(error)")
            onError?()
        }).disposed(by: self.disposeBag)
    }

    /// MyAI分会场，点击踩反馈，发送按钮，aiMessageId：AI那边的概念，实际和IM、CCM、VC等业务具体的资源一一绑定，IM业务就对应一个MessageId
    public static func Feedback(aiMessageId: String) {
        let params: [AnyHashable: Any] = ["click": "submit_feedback", "target": "none", "ai_message_id": aiMessageId]
        Tracker.post(TeaEvent("im_ai_msg_menu_click", params: params))
    }
}
