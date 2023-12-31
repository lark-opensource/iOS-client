//
//  AIChatOnboardCardViewModel.swift
//  LarkChat
//
//  Created by Zigeng on 2023/11/6.
//

import Foundation
import UIKit
import LarkMessageCore
import LarkMessageBase
import AsyncComponent
import LarkModel
import ByteWebImage
import ServerPB
import LarkMessengerInterface
import RxSwift
import RxCocoa
import LarkAIInfra
import LarkUIKit
import UniverseDesignToast
import LKCommonsTracker
import Homeric
import LarkCore
import EEAtomic

struct OnboardScene {
    var sceneId: Int64
    var title: String
    var desc: String
    var imagePassThrough: ImagePassThrough
}

class AIChatOnboardCardCellViewModel: ChatCellViewModel {
    var _id = UUID().uuidString
    /// onboard卡片端上模拟的id
    /// 用处为埋点上报和清屏置顶的id匹配
    final override var id: String? {
        return identifier + _id
    }

    var title: String = ""
    var subTitle: String = ""
    var avatarKey: String = "" {
        didSet {
            if oldValue != avatarKey {
                self.calculateRenderer()
            }
        }
    }

    var scenes: [OnboardScene] = []
    var hasMoreScene: Bool = true

    var isWaitingNewTopic = false {
        didSet {
            if oldValue != isWaitingNewTopic {
                self.calculateRenderer()
            }
        }
    }

    /// 待上报埋点的sceneID
    @AtomicObject var pendingSceneIDs: [String] = []
    // 已上报过的sceneID
    var sendedSceneIDs = Set<String>()
    var debounceTimer: Timer?

    /// 埋点上报增加debounce统一上报，减少上报次数
    lazy var seceneWillDisplay: (String) -> Void = { [weak self] sceneID in
        /// 当前onboard 卡片已经上报过展示的scene进行去重
        guard let self = self, !sendedSceneIDs.contains(sceneID) else { return }
        // 收集待上报埋点
        pendingSceneIDs.append(sceneID)
        // 如果在0.5秒内有新的cell即将展示，计时器将被重置，上报操作将被推迟
        debounceTimer?.invalidate()
        // 重新启动计时器
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { [weak self] _ in
            self?.trackSceneCellShow()
        })
    }

    // 上报cell展示埋点
    func trackSceneCellShow() {
        Self.trackShowScene(sceneID: pendingSceneIDs, clientMessageID: id ?? "", sessionID: sessionID ?? "", chat: chat)
        pendingSceneIDs.removeAll()
    }

    lazy var allSceneButtonTapAction: () -> Void = { [weak self] in
        guard let self = self, let targetVC = self.context.pageAPI, let myAISceneService = try? self.context.userResolver.resolve(type: MyAISceneService.self) else { return }
        myAISceneService.openSceneList(from: targetVC, chat: chat, selected: { [weak self, weak targetVC] sceneId in
            guard let self = self, let targetVC = targetVC else { return }
            self.newTopicAction(sceneId, targetVC.view)
        })
        Self.trackSeeMore(clientMessageID: id ?? "", sessionID: sessionID ?? "", chat: chat)
    }

    lazy var newTopicAction: (Int64, UIView) -> Void = { [weak self] sceneID, view in
        guard let self = self, let myAIPageService = try? self.context.resolver.resolve(assert: MyAIPageService.self) else { return }
        myAIPageService.newTopic(with: sceneID).subscribe(onError: { [weak view] error in
            guard let view = view else { return }
            DispatchQueue.main.async {
                UDToast.showFailure(with: BundleI18n.LarkChat.Lark_Legacy_ErrorMessageTip, on: view, error: error)
            }
        }).disposed(by: self.disposeBag)
        Self.trackSelectScene(sceneID: String(sceneID), clientMessageID: id ?? "", sessionID: sessionID ?? "", chat: chat)
    }

    let chat: Chat
    var aiChatterID: String?
    var sessionID: String?
    lazy var avatarTapped = { [weak self] in
        guard let self = self, let aiChatterID = self.aiChatterID, let targetVC = self.context.pageAPI else { return }
        let body = PersonCardBody(chatterId: aiChatterID,
                                  chatId: chat.id,
                                  source: .chat)
        self.context.navigator.presentOrPush(
            body: body,
            wrap: LkNavigationController.self,
            from: targetVC,
            prepareForPresent: { vc in
                vc.modalPresentationStyle = .formSheet
            })
    }

    final override var identifier: String {
        return "myai_onboard_card-"
    }

    open override func willDisplay() {
        super.willDisplay()
    }

    init(context: ChatContext, info: MyAIOnboardInfo, chat: Chat) {
        self.chat = chat
        super.init(context: context, binder: AIChatModeOnboardCardComponentBinder(context: context))
        self.scenes = info.scene.map { .init(sceneId: $0.sceneID, title: $0.sceneName, desc: $0.description_p, imagePassThrough: ImagePassThrough.transform(passthrough: $0.scenePhoto)) }
        self.title = info.onboardText.title
        self.subTitle = info.onboardText.description_p
        if let infoService = try? context.resolver.resolve(assert: MyAIInfoService.self) {
            infoService.info.subscribe(onNext: { [weak self] myAiInfo in
                self?.avatarKey = myAiInfo.avatarKey
                self?.aiChatterID = myAiInfo.id
            }).disposed(by: self.disposeBag)
        }
        /// 初始化后sonboard卡片的sessionid固定下来（仅埋点用）
        if let pageService = try? context.resolver.resolve(assert: MyAIPageService.self) {
            sessionID = pageService.aiRoundInfo.value.sessionID
        }
        self.calculateRenderer()
    }
}

// 埋点
extension AIChatOnboardCardCellViewModel {
    static func trackShowScene(sceneID: [String], clientMessageID: String, sessionID: String, chat: Chat) {
        var params: [AnyHashable: Any] = [
            "scene_id": sceneID,
            "message_id": clientMessageID,
            "session_id": sessionID
        ]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent("public_ai_message_list_view", params: params))
    }

    static func trackSelectScene(sceneID: String, clientMessageID: String, sessionID: String, chat: Chat) {
        var params: [AnyHashable: Any] = [
            "click": "scene_chat",
            "scene_id": sceneID,
            "message_id": clientMessageID,
            "session_id": sessionID
        ]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent("public_ai_message_list_click", params: params))
    }

    static func trackSeeMore(clientMessageID: String, sessionID: String, chat: Chat) {
        var params: [AnyHashable: Any] = [
            "click": "see_more",
            "message_id": clientMessageID,
            "session_id": sessionID
        ]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent("public_ai_message_list_click", params: params))
    }
}

public final class AIChatModeOnboardCardComponentBinder: ComponentBinder<ChatContext> {
    private lazy var _component: AIChatOnboardCardComponent = .init(props: .init(), style: .init(), context: nil)
    private var props: AIChatOnboardCardComponent.Props = .init()

    public final override var component: ComponentWithContext<ChatContext> {
        return _component
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? AIChatOnboardCardCellViewModel else {
            assertionFailure()
            return
        }
        props.title = vm.title
        props.subTitle = vm.subTitle
        props.scenes = vm.scenes
        props.hasMoreScene = vm.hasMoreScene
        props.newTopicAction = vm.newTopicAction
        props.avatarKey = vm.avatarKey
        props.isWaitingNewTopic = vm.isWaitingNewTopic
        props.avatarTapped = vm.avatarTapped
        props.allSceneButtonTapAction = vm.allSceneButtonTapAction
        props.seceneWillDisplay = vm.seceneWillDisplay
        _component.props = props
    }

    public override func buildComponent(key: String? = nil, context: ChatContext? = nil) {
        let style = ASComponentStyle()
        style.paddingLeft = 12
        style.paddingRight = 12
        style.alignContent = .stretch
        style.justifyContent = .center
        _component = AIChatOnboardCardComponent(
            props: self.props,
            style: style,
            context: context
        )
    }
}
