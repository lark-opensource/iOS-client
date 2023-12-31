//
//  MyAIPageServiceImpl+Scene.swift
//  LarkAI
//
//  Created by 李勇 on 2023/10/13.
//

import Foundation
import ServerPB
import UniverseDesignToast
import RxSwift
import LarkSDKInterface
import LarkCore
import LarkModel

/// 场景相关逻辑放这里
public extension MyAIPageServiceImpl {
    func handleSceneSelectByApplink(_ applink: URL, chat: Chat, onChat: UIViewController) {
        MyAIPageServiceImpl.logger.info("my ai new scene by aplink begin")
        guard let query = applink.getQuery(), let scendIdString = query["scene_id"], let scendId = Int64(scendIdString) else {
            MyAIPageServiceImpl.logger.info("my ai new scene by aplink error: no scene id")
            return
        }
        /// 这个方法没有判断FG的原因：如果FG关闭，那么不应该收到带场景的卡片消息；如果推了，那么不能点击没有任何反应，用户会认为是个bug
        /* guard self.userResolver.fg.dynamicFeatureGatingValue(with: "lark.myai.mode.mvp") else {
         MyAIPageServiceImpl.logger.info("my ai add scene by aplink error: fg close")
            return
        } */

        IMTracker.Scene.Click.card(chat, params: ["session_id": self.aiRoundInfo.value.sessionID ?? "", "click": "scene_chat", "scene_chat_id": "[\(scendIdString)]"])
        IMTracker.Scene.Click.session(chat, params: ["session_id": self.aiRoundInfo.value.sessionID ?? "", "scene_trigger_type": "open_new_topic", "scene_id": "[\(scendIdString)]"])
        var request = ServerPB_Office_ai_AIChatNewTopicRequest()
        request.chatID = self.chatId
        if self.chatMode { request.aiChatModeID = self.chatModeConfig.aiChatModeId }
        // 场景需要添加sceneID、chatContext
        request.sceneID = scendId
        if self.chatMode { request.chatContext = self.chatModeConfig.getCurrentChatContext() }
        // 透传请求
        self.rustClient?.sendPassThroughAsyncRequest(request, serCommand: .larkOfficeAiImNewTopic).observeOn(MainScheduler.instance).subscribe(onNext: { _ in
            MyAIPageServiceImpl.logger.info("my ai new scene by aplink success")
        }, onError: { error in
            if let apiError = error.transformToAPIError().metaErrorStack.first(where: { $0 is APIError }) as? APIError {
                UDToast.showFailure(with: BundleI18n.LarkAI.Lark_Legacy_NetworkOrServiceError, on: onChat.view, error: apiError)
            } else {
                UDToast.showFailure(with: BundleI18n.LarkAI.Lark_Legacy_NetworkOrServiceError, on: onChat.view, error: error)
            }
            MyAIPageServiceImpl.logger.info("my ai new scene by aplink error: \(error)")
        }).disposed(by: self.disposeBag)
    }

    /// 使用场景ID创建新话题
    func newTopic(with sceneID: Int64) -> Observable<ServerPB_Office_ai_AIChatNewTopicResponse> {
        guard let myAIAPI = self.myAIAPI else { return .empty() }
        myAIMainChatConfig.onBoardInfoSubject.accept(.willDismiss)
        let resp = myAIAPI.newMyAITopic(chatID: self.chatId,
                                        aiChatModeID: self.chatMode ? self.chatModeConfig.aiChatModeId : nil,
                                        sceneID: sceneID,
                                        chatContext: self.chatMode ? self.chatModeConfig.getCurrentChatContext() : nil)
        /// onboard卡片进入willdismiss状态。mock新消息的loading样式
        resp.subscribe(onNext: { _ in
            Self.logger.info("my ai newTopic with sceneID(\(sceneID) success")
        }, onError: { [weak self] error in
            guard let info = self?.currentOnboardInfo else { return }
            self?.myAIMainChatConfig.onBoardInfoSubject.accept(.success(info, false))
            Self.logger.info("my ai newTopic with sceneID(\(sceneID) failed, error: \(error)")
        }).disposed(by: self.disposeBag)
        return resp
    }

    /// 唤起端上的Mock消息样式版onboard卡片
    func showOnboardCard(byUser: Bool, onError: ((Error) -> Void)?) {
        guard case .notShow = self.myAIMainChatConfig.onBoardInfoSubject.value else { return }
        if byUser {
            //用户手动触发的操作需要通知服务端将needOnboard标记状态置true
            self.myAIAPI?.putOnboard(chatID: self.chatId).subscribe(onNext: { _ in
                MyAIPageServiceImpl.logger.info("my ai put Onboard success")
            }, onError: { error in
                MyAIPageServiceImpl.logger.info("my ai put Onboard failed: \(error)")
            }).disposed(by: self.disposeBag)
        }
        self.myAIMainChatConfig.onBoardInfoSubject.accept(.loading)
        self.myAIAPI?.pullOnboardInfo(chatID: self.chatId).subscribe(onNext: { [weak self] resp in
            guard let self = self else { return }
            self.currentOnboardInfo = resp
            self.myAIMainChatConfig.onBoardInfoSubject.accept(.success(resp, byUser))
            MyAIPageServiceImpl.logger.info("my ai pull onboard info success, sceneCount: \(resp.scene.count)")
        }, onError: { [weak self] error in
            self?.myAIMainChatConfig.onBoardInfoSubject.accept(.notShow())
            onError?(error)
            MyAIPageServiceImpl.logger.info("my ai pull onboard info error: \(error)")
        }).disposed(by: self.disposeBag)
    }
}
