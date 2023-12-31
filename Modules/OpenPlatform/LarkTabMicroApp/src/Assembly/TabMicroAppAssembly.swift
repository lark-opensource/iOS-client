//
//  TabMicroAppAssembly.swift
//  LarkTabMicroApp
//
//  Created by tujinqiu on 2019/12/19.
//

import Swinject
import EENavigator
import LarkUIKit
import AnimatedTabBar
import LarkNavigation
import EEMicroAppSDK
import BootManager
import LarkTab
import RxRelay
import SnapKit
import LKCommonsLogging
import LarkFeatureGating
import LarkAssembler
import LarkRustClient
import LarkOPInterface
import LarkSetting
import LarkContainer

public final class TabMicroAppAssembly: LarkAssemblyInterface {

    public init() {}

    public func registRouter(container: Container) {
        Navigator.shared.registerRoute.match({ (url) -> Bool in
            return url.absoluteString.hasPrefix(Tab.gadgetPrefix)
        }).factory(TabMicroAppHandler.init(resolver:))
        
    }

    public func registMatcherTabRegistry(container: Container) {
        (Tab.gadgetPrefix, { (queryItems: [URLQueryItem]?) -> TabRepresentable in
            let key = queryItems?.first { $0.name == "key" }?.value ?? ""
            let badgeAPI = try? container.resolve(assert: OPBadgeAPI.self)
            let featureGatingService = try? container.resolve(assert: FeatureGatingService.self)
            let pushCenter = try? container.resolve(assert: PushNotificationCenter.self)

            return MicroAppTab(
                tab: Tab.gadget(key: key),
                badgeAPI: badgeAPI,
                pushCenter: pushCenter,
                featureGatingService: featureGatingService
            )
        })
    }
    
    /// 注册消息推送
    public func registRustPushHandlerInUserSpace(container: Container) {
        (Command.pushOpenAppBadgeNodes, OPBadgePushHandler.init(resolver:))
    }
}

private class MicroAppTab: TabRepresentable {
    private let appTab: Tab
    private let tabExta: GadgetTabExtra
    private var badgeAPI: OPBadgeAPI?
    private var pushCenter: PushNotificationCenter?
    private var featureGatingService: FeatureGatingService?
    /// 红点数字样式以及配置
    private let log = Logger.oplog(MicroAppTab.self, category: "MicroAppTab")
    private var _badge = BehaviorRelay<LarkTab.BadgeType>(value: .none)
    private var _badgeOutsideVisable = BehaviorRelay<Bool>(value: true)
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
    
    // badge data source
    init (
        tab: Tab,
        badgeAPI: OPBadgeAPI?,
        pushCenter: PushNotificationCenter?,
        featureGatingService: FeatureGatingService?
    ) {
        self.appTab = tab
        self.tabExta = GadgetTabExtra(dict: tab.extra)
        self.badgeAPI = badgeAPI
        self.pushCenter = pushCenter
        self.featureGatingService = featureGatingService
        observeBadge()
    }

    var tab: Tab {
        return self.appTab
    }
    /// 监听Badge变化
    private func observeBadge() {
        if let appId = tab.appid {
            var appAbility: OPBadge.AppAbility = .unknown
            switch tab.appType {
            case .gadget:
                appAbility = .MiniApp
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
            self.log.info("observe badge, appId: \(appId), appAbility: \(appAbility.rawValue), enableNewAppTabBadge: \(enableNewAppTabBadge), enableGadgetAppBadge: \(enableGadgetAppBadge), hasBadgeAPI: \(badgeAPI != nil), hasPushCenter: \(pushCenter != nil)")
            
            if enableNewAppTabBadge,
               let feature = featureType,
               let badgeAPI = badgeAPI,
               let pushCenter = pushCenter
            {
                let badgeNodeCallback: ((
                    _ badgeNode: OPBadgeRustAlias.OpenAppBadgeNode) -> Void
                ) = { [weak self] (badgeNode) in
                    guard let self = self else {
                        return
                    }
                    
                    guard enableGadgetAppBadge else {
                        self.log.info("receive badge update but GadgetAppBadge fg not enable, appId: \(badgeNode.appID), feature: \(badgeNode.feature)")
                        self._badge.accept(.none)
                        self._badgeVersion.accept(nil)
                        return
                    }
                    
                    if badgeNode.needShow {
                        self.log.info("Tab update badge, appId: \(badgeNode.appID), needShow: \(badgeNode.needShow), badgeNum: \(badgeNode.badgeNum), version: \(badgeNode.version), feature: \(badgeNode.feature), updateTime: \(badgeNode.updateTime)")
                        self._badge.accept(.number(Int(badgeNode.badgeNum)))
                        self._badgeVersion.accept(badgeNode.version)
                    } else {
                        self.log.info("Tab hide badge, appId: \(badgeNode.appID), needShow: \(badgeNode.needShow), badgeNum: \(badgeNode.badgeNum), version: \(badgeNode.version), feature: \(badgeNode.feature), updateTime: \(badgeNode.updateTime)")
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
            
            self.badgeObsever = OPBadge.BadgePushObserver(
                appId: appId,
                type: appAbility,
                badgeNumCallback: { [weak self] (badgeNum, needShow) in
                    guard let self = self else {
                        return
                    }
                    guard LarkFeatureGating.shared.getFeatureBoolValue(for: OPBadge.isEnableGadgetAppBadge) else {
                        self.log.info("received badge update bug GadgetAppBadge fg not enable")
                        self._badge.accept(.none)
                        self._badgeVersion.accept(nil)
                        return
                    }
                    if needShow {
                        self.log.info("Tab App \(appId) type \(appAbility.description) update badge \(badgeNum)")
                        self._badge.accept(.number(badgeNum))
                    } else {
                        self.log.info("Tab App \(appId) type \(appAbility.description) hide badge")
                        self._badge.accept(.none)
                    }
                })
        } else {
            self.log.info("tab has no appId")
        }
    }
}
