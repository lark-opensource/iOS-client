//
//  ChatContainerGuideManager.swift
//  LarkChat
//
//  Created by 赵家琛 on 2021/7/28.
//

import UIKit
import Foundation
import LarkCore
import LarkModel
import LarkMessengerInterface
import LarkGuide
import LarkMessageBase
import LarkMessageCore
import LarkGuideUI
import LarkContainer
import LarkSDKInterface
import RxSwift
import RustPB
import LarkOpenChat
import UGReachSDK
import UGSpotlight
import EENavigator
import LKCommonsTracker
import LarkFeatureGating
import LKCommonsLogging

enum ChatContainerGuideType {
    case pinSide
    case pinSummary
}

final class ChatContainerGuideManager: UserResolverWrapper {
    let userResolver: UserResolver
    static let logger = Logger.log(ChatContainerGuideManager.self, category: "Module.IM.Message")
    @ScopedInjectedLazy private var newGuideManager: NewGuideService?
    @ScopedInjectedLazy private var guideService: ChatTabsGuideService?
    @ScopedInjectedLazy private var userGeneralSettings: UserGeneralSettings?
    private lazy var chatTabAddUGLinkConfig: ChatTabAddUGLinkConfig? = {
        return userGeneralSettings?.chatTabAddUGLinkConfig
    }()
    @ScopedInjectedLazy var reachService: UGReachSDKService?
    private let customReachPointId: String = "RP_SPOTLIGHT_CLICK_CHAT_TAB"
    private let addReachPointId: String = "RP_SPOTLIGHT_ADD_CHAT_TAB"
    private let chatTabScenarioId: String = "SCENE_CHAT_TAB"
    private var customReachPoint: SpotlightReachPoint?
    private var addReachPoint: SpotlightReachPoint?
    private lazy var enableChatTabOnboarding: Bool = {
        return userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: FeatureGatingKey.enableChatTabOnboarding))
    }()
    /// 查看自定义Tab引导id
    private var customTabGuideTabId: Int64?

    private weak var chatContainerVC: ChatContainerViewController?
    //提示气泡
    fileprivate var hintBubbleView: EasyhintBubbleView?
    private let chatId: String
    private var shouldShowAddTabGuide: Bool = false

    init(chatContainerVC: ChatContainerViewController, chatId: String) {
        self.chatContainerVC = chatContainerVC
        self.userResolver = chatContainerVC.userResolver
        self.chatId = chatId
        self.shouldShowAddTabGuide = guideService?.currentShowGuideChatIds.contains(chatId) ?? false

    }

    private func setupCustomReachPoint() {
        if !enableChatTabOnboarding { return }
        let bizContextProvider = UGAsyncBizContextProvider(
            scenarioId: chatTabScenarioId) { [weak self] () -> Observable<[String: String]> in
                guard let self = self else { return .just([:]) }
                return .just(["CHAT_ID": self.chatId])
        }
        self.customReachPoint = reachService?.obtainReachPoint(
            reachPointId: customReachPointId,
            bizContextProvider: bizContextProvider
        )
        self.customReachPoint?.datasource = self
    }

    private func setupAddReachPoint() {
        if !enableChatTabOnboarding { return }
        let bizContextProvider = UGAsyncBizContextProvider(
            scenarioId: chatTabScenarioId) { [weak self] () -> Observable<[String: String]> in
                guard let self = self else { return .just([:]) }
                return .just(["CHAT_ID": self.chatId])
        }
        self.addReachPoint = reachService?.obtainReachPoint(
            reachPointId: addReachPointId,
            bizContextProvider: bizContextProvider
        )
        self.addReachPoint?.datasource = self
        self.addReachPoint?.singleDelegate = self
    }

    deinit {
        print("NewChat: ChatContainerGuideManager deinit")
        self.reachService?.recycleReachPoint(reachPointId: addReachPointId, reachPointType: SpotlightReachPoint.reachPointType)
        self.reachService?.recycleReachPoint(reachPointId: customReachPointId, reachPointType: SpotlightReachPoint.reachPointType)
    }

    func checkShowGuideIfNeeded(_ guideType: ChatContainerGuideType) {
        switch guideType {
        case .pinSide:
            checkShowPinSideGuideIfNeeded()
        case .pinSummary:
            checkShowPinSummaryGuideIfNeeded()
        }
    }

    private var viewDidAppeared = false
    func viewDidAppear() {
        if viewDidAppeared { return }
        viewDidAppeared = true
        if !checkShowTabGuideAlready { return }
        tryExposeChatTabGuide()
    }

    /// tab 展示出来，判断是否需要去展示引导
    private var checkShowTabGuideAlready: Bool = false
    func checkShowTabGuide(_ customTabId: Int64?) {
        if checkShowTabGuideAlready { return }
        checkShowTabGuideAlready = true
        customTabGuideTabId = customTabId
        if !viewDidAppeared { return }
        tryExposeChatTabGuide()
    }

    private func tryExposeChatTabGuide() {
        setupCustomReachPoint()
        setupAddReachPoint()
        if customTabGuideTabId != nil {
            Self.logger.info("ChatContainerGuideManager tryExpose custom tab RP \(self.chatId)")
            self.reachService?.tryExpose(by: chatTabScenarioId, specifiedReachPointIds: [customReachPointId])
        } else if shouldShowAddTabGuide {
            Self.logger.info("ChatContainerGuideManager tryExpose add tab RP \(self.chatId)")
            self.reachService?.tryExpose(by: chatTabScenarioId, specifiedReachPointIds: [addReachPointId])
        }
    }

    func removeHintBubbleView() {
        self.hintBubbleView?.removeFromSuperview()
        self.hintBubbleView = nil
    }
}

extension ChatContainerGuideManager {
    private func checkShowPinSideGuideIfNeeded() {
        guard chatViewIsReady() else {
            return
        }
        defer {
            ChatTracker.trackPinSidebarGuideShow()
        }
        guard let rightButton = self.chatContainerVC?.naviBar.getRightItem(type: .moreItem)?.view else { return }

        let viewPinGuideKey = "all_view_pin"
        newGuideManager?.showBubbleGuideIfNeeded(
            guideKey: viewPinGuideKey,
            bubbleType: .single(SingleBubbleConfig(
                delegate: nil,
                bubbleConfig: BubbleItemConfig(
                    guideAnchor: TargetAnchor(
                        targetSourceType: .targetView(rightButton),
                        arrowDirection: .up,
                        targetRectType: .rectangle
                    ),
                    textConfig: TextInfoConfig(detail: BundleI18n.LarkChat.Lark_Pin_PinSideBarGuideTips)
                )
            )),
            customWindow: rightButton.window,
            dismissHandler: nil
        )
    }

    private func checkShowPinSummaryGuideIfNeeded() {
        guard chatViewIsReady() else {
            return
        }
        guard let targetView = self.chatContainerVC?.pinSummaryView?.getGuideTargetView() else {
            return
        }
        newGuideManager?.showBubbleGuideIfNeeded(
            guideKey: "im.chat.pinned.msg",
            bubbleType: .single(SingleBubbleConfig(
                delegate: nil,
                bubbleConfig: BubbleItemConfig(
                    guideAnchor: TargetAnchor(
                        targetSourceType: .targetView(targetView),
                        arrowDirection: .up,
                        targetRectType: .rectangle
                    ),
                    textConfig: TextInfoConfig(detail: BundleI18n.LarkChat.Lark_IM_NewPinOnboard_Text)
                )
            )),
            dismissHandler: nil
        )
    }

    private func chatViewIsReady() -> Bool {
        guard (self.chatContainerVC?.isViewLoaded ?? false) && self.chatContainerVC?.view.window != nil else {
            return false
        }
        return true
    }
}

extension ChatContainerGuideManager: SpotlightReachPointDataSource, UGSingleSpotlightDelegate {
    func onShow(spotlightReachPoint: SpotlightReachPoint, spotlightData: UGSpotlightData, isMult: Bool) -> SpotlightBizProvider? {
        guard chatViewIsReady(), self.chatContainerVC?.displayTabs ?? false else { return nil }

        if spotlightReachPoint === self.customReachPoint {
            Self.logger.info("ChatContainerGuideManager onShow custom tab RP \(self.chatId)")
            if let customTabGuideTabId = self.customTabGuideTabId {
                return ceateCustomProvider(customTabGuideTabId: customTabGuideTabId)
            }
            return nil
        }
        if spotlightReachPoint === self.addReachPoint {
            Self.logger.info("ChatContainerGuideManager onShow add tab RP \(self.chatId)")
            return ceateAddProvider()
        }
        return nil
    }

    private func ceateAddProvider() -> SpotlightBizProvider? {
        guard let chatContainerVC = self.chatContainerVC else { return nil }
        Tracker.post(TeaEvent("im_chat_tab_add_onboard_view",
                              bizSceneModels: [IMTracker.Transform.chat(chatContainerVC.chat.value)]))
        var anchorView: UIView?
        let addButton = chatContainerVC.chatTabsView.addButton
        let manageButton = chatContainerVC.chatTabsView.manageButton
        if !addButton.isHidden {
            anchorView = addButton
        } else if !manageButton.isHidden {
            anchorView = manageButton
        }
        guard let anchoview = anchorView else { return nil }
        let coordinateView = chatContainerVC.view.window ?? chatContainerVC.view
        var rect = anchoview.convert(anchoview.bounds, to: coordinateView)
        let provider = SpotlightBizProvider(
            hostProvider: {
                return chatContainerVC
            }, targetSourceTypes: {
                return [.targetRect(CGRect(x: rect.origin.x, y: rect.origin.y - 12, width: rect.size.width, height: rect.size.height))]
            }
        )
        return provider
    }

    private func ceateCustomProvider(customTabGuideTabId: Int64) -> SpotlightBizProvider? {
        guard let chatContainerVC = self.chatContainerVC else { return nil }
        Tracker.post(TeaEvent("im_chat_tab_click_onboard_view",
                              bizSceneModels: [IMTracker.Transform.chat(chatContainerVC.chat.value)]))
        let anchorView: UIView
        if let itemView = chatContainerVC.chatTabsView.getTabItemView(customTabGuideTabId) {
            anchorView = itemView
        } else {
            anchorView = chatContainerVC.chatTabsView.manageButton
        }
        let coordinateView = chatContainerVC.view.window ?? chatContainerVC.view
        var rect = anchorView.convert(anchorView.bounds, to: coordinateView)
        let provider = SpotlightBizProvider(
            hostProvider: {
                return chatContainerVC
            }, targetSourceTypes: {
                return [.targetRect(CGRect(x: rect.origin.x, y: rect.origin.y - 12, width: rect.size.width, height: rect.size.height))]
            }
        )
        return provider
    }

    public func didClickLeftButton(bubbleConfig: BubbleItemConfig) {
        guard let chatContainerVC = self.chatContainerVC, let chatTabAddUGLinkConfig else { return }
        Tracker.post(TeaEvent("im_chat_tab_add_onboard_click",
                              params: ["click": "learn_more",
                                       "target": "none"],
                              bizSceneModels: [IMTracker.Transform.chat(chatContainerVC.chat.value)]))
        self.addReachPoint?.closeSpotlight(hostProvider: chatContainerVC)
        self.reachService?.recycleReachPoint(reachPointId: addReachPointId, reachPointType: SpotlightReachPoint.reachPointType)
        if let url = URL(string: chatTabAddUGLinkConfig.zhLink) {
            navigator.push(url, from: chatContainerVC)
            return
        }
        if let url = URL(string: chatTabAddUGLinkConfig.enLink) {
            navigator.push(url, from: chatContainerVC)
            return
        }
        if let url = URL(string: chatTabAddUGLinkConfig.jaLink) {
            navigator.push(url, from: chatContainerVC)
            return
        }
    }

    public func didClickRightButton(bubbleConfig: BubbleItemConfig) {
        guard let chatContainerVC = self.chatContainerVC else { return }
        Tracker.post(TeaEvent("im_chat_tab_add_onboard_click",
                              params: ["click": "OK",
                                       "target": "none"],
                              bizSceneModels: [IMTracker.Transform.chat(chatContainerVC.chat.value)]))
        self.addReachPoint?.closeSpotlight(hostProvider: chatContainerVC)
        self.reachService?.recycleReachPoint(reachPointId: addReachPointId, reachPointType: SpotlightReachPoint.reachPointType)
    }
}
