//
//  ByteViewTabAssembly.swift
//  Lark
//
//  Created by kiri on 2021/8/22.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import Swinject
import BootManager
import EENavigator
import LarkTab
import LarkContainer
import ByteViewCommon
import ByteViewNetwork
import ByteViewTracker
import ByteViewInterface
import LarkAppLinkSDK
import ByteViewTab
import RxSwift
import RxRelay
import LarkNavigation
import LarkUIKit
import AnimatedTabBar
import LarkAssembler
import LarkNavigator
import RunloopTools
import ByteView

final class TabAssembly: LarkAssemblyInterface {

    func registContainer(container: Container) {
        let user = container.inObjectScope(.vcUser)
        //这个地方目前没有直接取Config、Account是因为时机可能比这连个东西初始化早
        user.register(TabBadgeService.self) {
            TabService.shared.createBadgeService(userId: $0.userID, httpClient: try $0.resolve(assert: HttpClient.self))
        }

        user.register(TabGuideService.self) { r in
            #if LarkMod
            ByteViewTabGuideServiceImpl(resolver: r)
            #else
            DefaultTabGuideServiceImpl()
            #endif
        }

        user.register(TabRouteDependency.self) {
            TabRouteDependencyImpl(resolver: $0)
        }

        user.register(TabDependency.self) {
            try TabDependencyImpl(userResolver: $0)
        }
    }

    func registRouter(container: Container) {
        Navigator.shared.registerRoute.plain(Tab.byteview.urlString).priority(.high).factory(ByteViewTabHandler.init(resolver:))
        Navigator.shared.registerRoute.type(MeetingTabBody.self).factory(MeetingTabHandler.init(resolver:))
    }

    func registLaunch(container: Container) {
        NewBootManager.register(TabSetupTask.self)
    }

    func registTabRegistry(container: Container) {
        (Tab.byteview, { (_: [URLQueryItem]?) -> TabRepresentable in
            VideoConferenceTab()
        })
    }

    func registLarkAppLink(container: Container) {
        LarkAppLinkSDK.registerHandler(path: MeetingTabBody.path, handler: { (applink: AppLink) in
            OpenByteViewTabLinkHandler().handle(appLink: applink)
        })
    }
}

final class VideoConferenceTab: TabRepresentable {
    var tab: Tab {
        Tab.byteview
    }

    private var _badge = BehaviorRelay<LarkTab.BadgeType>(value: .none)
    private var _badgeOutsideVisable = BehaviorRelay<Bool>(value: false)
    private var _badgeStyle = BehaviorRelay<BadgeRemindStyle>(value: .strong)

    // badge
    var badge: BehaviorRelay<LarkTab.BadgeType>? {
        _badge
    }

    var badgeStyle: BehaviorRelay<BadgeRemindStyle>? {
        // 红色数字、灰色数字 目前都是这个Style
        _badgeStyle
    }

    var badgeOutsideVisiable: BehaviorRelay<Bool>? {
        _badgeOutsideVisable
    }

    // 更新 badge 数量
    func updateBadge(_ badge: LarkTab.BadgeType) {
        _badge.accept(badge)

        switch badge {
        case .number, .image: _badgeStyle.accept(.strong)
        case .dot: _badgeStyle.accept(.weak)
        default: break
        }
        if case .number(let number) = badge, number > 0 {
            _badgeOutsideVisable.accept(true)
        } else {
            _badgeOutsideVisable.accept(false)
        }
    }
}

private class ByteViewTabHandler: UserRouterHandler {
    func handle(req: EENavigator.Request, res: Response) throws {
        let dependency = try userResolver.resolve(assert: TabDependency.self)
        MeetingFrontier.preload(for: "MeetingTab", account: try userResolver.resolve(assert: AccountInfo.self))
        res.end(resource: TabService.shared.createTabViewController(dependency: dependency))
    }
}

#if LarkMod
extension ByteViewBaseTabViewController: LarkMainViewController {

    public var larkNavigationBarHeight: CGFloat {
        naviHeight
    }

    public func changeLarkNavigationBarPresentation(show: Bool?, animated: Bool) {
        changeNaviBarPresentation(show: show, animated: animated)
    }

    public func reloadLarkNavigationBar() {
        reloadNaviBar()
    }

    public var isLarkNaviBarShown: Bool {
        isNaviBarShown
    }

    public var larkTabBarHeight: CGFloat? {
        animatedTabBarController?.tabbarHeight
    }
}

extension ByteViewBaseTabViewController: TabRootViewController {

    public var tab: Tab {
        Tab.byteview
    }

    public var controller: UIViewController {
        self
    }
}

extension ByteViewBaseTabViewController: TabbarItemTapProtocol {

    public func onTabbarItemDoubleTap() {
        handleTabbarItemDoubleTap()
    }

    public func onTabbarItemTap(_ isSameTab: Bool) {
        if isNewTabEnabled {
            var isReminded: Bool = false
            if let vcTab = TabRegistry.resolve(tab), let badge = vcTab.badge?.value,
               case .number(let number) = badge, number > 0 {
                isReminded = true
            }
            VCTracker.post(name: .vc_meeting_lark_detail, params: [
                .action_name: "tab_click", "is_reminded": isReminded
            ])
        } else {
            VCTracker.post(name: .vc_lark_tab, params: [.action_name: "bottom"])
        }
        handleTabbarItemTap(isSameTab)
    }
}

extension ByteViewBaseTabViewController: LarkNaviBarProtocol, LarkNaviBarAbility {

    public func larkNaviBar(userDefinedButtonOf type: LarkNaviButtonType) -> UIButton? {
        switch type {
        case .search:
            return naviBarSearchButton
        case .first:
            return naviBarButton
        default:
            return nil
        }
    }

    public func onButtonTapped(on button: UIButton, with type: LarkNaviButtonType) {
        switch type {
        case .search:
            self.didTapSearchButton()
        default:
            break
        }
    }

    public func larkNavibarBgColor() -> UIColor? {
        larkNavibarBgColor
    }

    public func onTitleViewTapped() {}
}

extension ByteViewBaseTabViewController: TabBarEventViewController {
    public func tabBarController(_ tabBarController: AnimatedTabBarController,
                                 willSwitch tab: Tab,
                                 to newTab: Tab) {
        willSwitchToTabBar()
    }

    public func tabBarController(_ tabBarController: AnimatedTabBarController,
                                 didSwitch tab: Tab,
                                 to newTab: Tab) {
        didSwitchToTabBar()
        clearTabBadgeUnreadCount()
    }

    public func tabBarController(_ tabBarController: AnimatedTabBarController,
                                 willSwitchOut tab: Tab,
                                 to newTab: Tab) {
        willSwitchOutTabBar()

    }

    public func tabBarController(_ tabBarController: AnimatedTabBarController,
                                 didSwitchOut tab: Tab,
                                 to newTab: Tab) {
        didSwitchOutTabBar()
        clearTabBadgeUnreadCount()
    }
}

#else
extension ByteViewBaseTabViewController: LarkMainViewController {

    public var larkNavigationBarHeight: CGFloat {
        0
    }

    public var larkTabBarHeight: CGFloat? {
        nil
    }

    public func changeLarkNavigationBarPresentation(show: Bool?, animated: Bool) {
    }

    public func reloadLarkNavigationBar() {
    }

    public var isLarkNaviBarShown: Bool {
        true
    }
}
#endif

private final class MeetingTabHandler: UserTypedRouterHandler {
    func handle(_ body: MeetingTabBody, req: EENavigator.Request, res: Response) {
        switch (body.action, body.source) {
        case (.detail, .chat), (_, .callkit), (.opentab, .onboarding):
            /// 冷启动的时需要保证跳转操作在tabBarViewController正常加载之后
            RunloopDispatcher.shared.addTask(priority: .medium) {
                self.userResolver.navigator.switchTab(Tab.byteview.url, from: req.from, animated: true) { _ in
                    if body.action == .detail, let meetingID = body.meetingID {
                        let isFromBot = body.source == .chat
                        TabService.shared.openMeetingID.onNext((meetingID, isFromBot))
                    }
                }
            }
            res.end(resource: EmptyResource())
        default:
            res.end(resource: nil)
        }
    }
}

private final class OpenByteViewTabLinkHandler {
    private static let logger = Logger.getLogger("AppLink")

    func handle(appLink: AppLink) {
        guard let from = appLink.context?.from() else {
            Self.logger.error("applink.context.from is nil")
            return
        }
        let queryParameters = appLink.url.queryParameters
        Self.logger.info("handle applink queryParameters = \(queryParameters)")

        let source = queryParameters["source"]
        let action = queryParameters["action"]
        let meetingID = queryParameters["meetingId"]

        guard let s = source, let sourceParam = MeetingTabBody.Source(rawValue: s),
              let a = action, let actionParam = MeetingTabBody.Action(rawValue: a) else {
            Self.logger.error("handle applink error by unsupported param: source = \(String(describing: source)), action = \(String(describing: action)), id = \(String(describing: meetingID))")
            return
        }

        let body = MeetingTabBody(source: sourceParam, action: actionParam, meetingID: meetingID)
        Navigator.currentUserNavigator.push(body: body, from: from)
    }
}
