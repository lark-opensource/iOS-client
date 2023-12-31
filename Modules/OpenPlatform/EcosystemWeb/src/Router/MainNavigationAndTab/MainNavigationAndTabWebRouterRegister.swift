//
//  MainNavigationAndTabWebRouterRegister.swift
//  EcosystemWeb
//
//  Created by 新竹路车神 on 2021/6/28.
//

import EENavigator
import LarkFeatureGating
import LarkOPInterface
import LarkTab
import LKCommonsLogging
import Swinject
import RxRelay
import WebBrowser
import LarkSetting
import LarkContainer

//code from lilun，未改动任何一行逻辑，只换了位置
/// 符合飞书Tab系统的网页视图控制器Tab对象
final class MainNavigationAndTabWebBrowserTab: TabRepresentable {
    var tab: Tab {
        appTab
    }
    private let appTab: Tab
    private let logger = Logger.ecosystemWebLog(MainNavigationAndTabWebBrowserTab.self, category: "MainNavigationAndTabWebBrowserTab")
    private var badgeAPI: OPBadgeAPI?
    private var pushCenter: PushNotificationCenter?
    private var featureGatingService: FeatureGatingService?

    /// 红点数据源
    private var _badge = BehaviorRelay<LarkTab.BadgeType>(value: .none)
    /// 红点是否可见数据源，可见
    private var _badgeOutsideVisable = BehaviorRelay<Bool>(value: true)
    /// 红点样式数据源，红色badge类型
    private var _badgeStyle = BehaviorRelay<BadgeRemindStyle>(value: .strong)
    /// 红点数据版本
    private var _badgeVersion = BehaviorRelay<String?>(value: nil)
    // badge data source
    var badge: BehaviorRelay<LarkTab.BadgeType>? {
        return self._badge
    }
    var badgeStyle: BehaviorRelay<BadgeRemindStyle>? {
        return _badgeStyle
    }
    var badgeOutsideVisiable: BehaviorRelay<Bool>? {
        return _badgeOutsideVisable
    }
    public var badgeVersion: BehaviorRelay<String?>? {
        return _badgeVersion
    }
    private var badgeObsever: OPBadge.BadgePushObserver?
    
    private var badgeService: OPBadge.OPBadgeService?
    
    init(
        tab: Tab,
        badgeAPI: OPBadgeAPI?,
        pushCenter: PushNotificationCenter?,
        featureGatingService: FeatureGatingService?
    ) {
        logger.info("WebBrowserTab init, url: \(tab.url), appid: \(tab.appid)")
        appTab = tab
        self.badgeAPI = badgeAPI
        self.pushCenter = pushCenter
        self.featureGatingService = featureGatingService
        observeBadge()
    }
    /// 监听Badge变化
    private func observeBadge() {
        if let appId = tab.appid {
            var appAbility: OPBadge.AppAbility = .unknown
            switch tab.appType {
            case .webapp:
                appAbility = .H5
            default:
                appAbility = .unknown
            }
            let enableNewAppTabBadge = featureGatingService?.staticFeatureGatingValue(
                with: OPBadgeFeatureKey.newOpenAppTabBadge.key
            ) ?? false
            let enableGadgetAppBadge = featureGatingService?.staticFeatureGatingValue(
                with: OPBadgeFeatureKey.enableGadgetAppBadge.key
            ) ?? false
            let featureType = appAbility.toAppFeatureType()
            self.logger.info("observe badge, appId: \(appId), appAbility: \(appAbility.rawValue), enableNewAppTabBadge: \(enableNewAppTabBadge), enableGadgetAppBadge: \(enableGadgetAppBadge), hasBadgeAPI: \(badgeAPI != nil), hasPushCenter: \(pushCenter != nil)")
            
            if enableNewAppTabBadge,
               let feature = featureType,
               let badgeAPI = badgeAPI,
               let pushCenter = pushCenter {
                let badgeNodeCallback: ((
                    _ badgeNode: OPBadgeRustAlias.OpenAppBadgeNode) -> Void
                ) = { [weak self] (badgeNode) in
                    guard let self = self else {
                        return
                    }
                    
                    guard enableGadgetAppBadge else {
                        self.logger.info("receive badge update data, but GadgetAppBadge fg not enable, appId: \(badgeNode.appID), feature: \(badgeNode.feature)")
                        self._badge.accept(.none)
                        return
                    }
                    
                    if badgeNode.needShow {
                        self.logger.info("Tab update badge, appId: \(badgeNode.appID), needShow: \(badgeNode.needShow), badgeNum: \(badgeNode.badgeNum), version: \(badgeNode.version), feature: \(badgeNode.feature), updateTime: \(badgeNode.updateTime)")
                        self._badge.accept(.number(Int(badgeNode.badgeNum)))
                        self._badgeVersion.accept(badgeNode.version)
                    } else {
                        self.logger.info("Tab hide badge, appId: \(badgeNode.appID), needShow: \(badgeNode.needShow), badgeNum: \(badgeNode.badgeNum), version: \(badgeNode.version), feature: \(badgeNode.feature), updateTime: \(badgeNode.updateTime)")
                        self._badge.accept(.none)
                        self._badgeVersion.accept(badgeNode.version)
                    }
                }
                self.badgeService = OPBadge.OPBadgeService(
                    pushCenter: pushCenter,
                    badgeAPI: badgeAPI,
                    appId: appId,
                    featureType: feature,
                    badgeNodeCallback: badgeNodeCallback
                )
                return
            }
            badgeObsever = OPBadge.BadgePushObserver(
                appId: appId,
                type: appAbility,
                badgeNumCallback: { [weak self] (badgeNum, needShow) in
                    guard let self = self else {
                        return
                    }
                    /// Badge的fg是否开启，预计3.45版本之后移除fg控制
                    //未修改任何逻辑
                    guard LarkFeatureGating.shared.getFeatureBoolValue(for: OPBadge.isEnableGadgetAppBadge) else {// user:global
                        self.logger.info("received badge update bug GadgetAppBadge fg not enable")
                        self._badge.accept(.none)
                        return
                    }
                    if needShow {
                        self.logger.info("[NavigationTabBadge] Tab App \(appId) type \(appAbility.description) update badge \(badgeNum)")
                        self._badge.accept(.number(badgeNum))
                    } else {
                        self.logger.info("[NavigationTabBadge] Tab App \(appId) type \(appAbility.description) hide badge")
                        self._badge.accept(.none)
                    }
                })
        } else {
            self.logger.info("tab has no appId")
        }
    }
}
