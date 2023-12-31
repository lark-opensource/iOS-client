//
//  OPAppTabRepresentable.swift
//  LarkOPInterface
//
//  Created by ByteDance on 2023/10/17.
//

import Foundation
import LarkTab
import RxRelay
import LarkContainer
import LKCommonsLogging
import LarkSetting

public class OPAppTabRepresentable: TabRepresentable, UserResolverWrapper {
    public lazy var userResolver: UserResolver = Container.shared.getCurrentUserResolver()
    
    static let logger = Logger.log(OPAppTabRepresentable.self)
    
    public var tab: Tab
    /// 红点数据源
    private var _badge = BehaviorRelay<LarkTab.BadgeType>(value: .none)
    /// 红点是否可见数据源，可见
    private var _badgeOutsideVisable = BehaviorRelay<Bool>(value: true)
    /// 红点样式数据源，红色badge类型
    private var _badgeStyle = BehaviorRelay<BadgeRemindStyle>(value: .strong)
    /// 红点数据版本
    private var _badgeVersion = BehaviorRelay<String?>(value: nil)
    // badge data source
    public var badge: BehaviorRelay<LarkTab.BadgeType>? {
        return self._badge
    }
    public var badgeStyle: BehaviorRelay<BadgeRemindStyle>? {
        return _badgeStyle
    }
    public var badgeOutsideVisiable: BehaviorRelay<Bool>? {
        return _badgeOutsideVisable
    }
    public var badgeVersion: BehaviorRelay<String?>? {
        return _badgeVersion
    }
    
    private var badgeObsever: OPBadge.BadgePushObserver?
    
    private var badgeService: OPBadge.OPBadgeService?
    
    public init(
        tab: Tab
    ) {
        self.tab = tab
        do {
            try observeBadge()
        } catch {
            Self.logger.error("[OPBadge] observeBadge throws error, cannot get dependencies", error: error)
        }
    }
    
    deinit {
        Self.logger.info("[OPBadge] OPAppTabRepresentable deinit")
    }
    
    /// 监听Badge变化
    private func observeBadge() throws {
        guard let appId = tab.extra[NavigationKeys.appid] as? String else {
            Self.logger.error("[OPBadge] tab extra data has no appId")
            self._badge.accept(.none)
            self._badgeVersion.accept(nil)
            return
        }
        let badgeAPI = try userResolver.resolve(assert: OPBadgeAPI.self)
        let featureGatingService = try userResolver.resolve(assert: FeatureGatingService.self)
        let pushCenter = try userResolver.resolve(assert: PushNotificationCenter.self)
        
        let enableGadgetAppBadge = featureGatingService.staticFeatureGatingValue(
            with: OPBadgeFeatureKey.enableGadgetAppBadge.key
        )
        let enableMainTabOpenplatformAppBadge = featureGatingService.staticFeatureGatingValue(
            with: OPBadgeFeatureKey.enableMainTabOpenplatformAppBadge.key
        )
        guard enableGadgetAppBadge, enableMainTabOpenplatformAppBadge else {
            Self.logger.info("[OPBadge] observe badge, but fg: gadget.open_app.badge is not enable")
            self._badge.accept(.none)
            self._badgeVersion.accept(nil)
            return
        }
        var appAbility: OPBadge.AppAbility = .unknown
        /// 租户添加的应用：通过 tab.appType 判断
        /// 用户 pin 到导航栏的应用: appType 是 .appTypeOpenApp, 这种类型可能还包含用户手动添加的开放平台网页链接，因此用 tab.bizType 判断
        if tab.appType == .gadget || tab.bizType == .MINI_APP {
            appAbility = .MiniApp
        } else if tab.appType == .webapp || tab.bizType == .WEB_APP {
            appAbility = .H5
        } else {
            appAbility = .unknown
        }
        guard let featureType = appAbility.toAppFeatureType() else {
            Self.logger.error("[OPBadge] observe badge, but feature type not satisfied", additionalData: [
                "appId": appId,
                "appType": tab.appType.rawValue,
                "bizType": "\(tab.bizType.rawValue)",
                "appAbility": "\(appAbility.rawValue)"
            ])
            self._badge.accept(.none)
            self._badgeVersion.accept(nil)
            return
        }
        
        let enableNewAppTabBadge = featureGatingService.staticFeatureGatingValue(
            with: OPBadgeFeatureKey.newOpenAppTabBadge.key
        )
        Self.logger.info("[OPBadge] start observe badge", additionalData: [
            "appId": appId,
            "appType": tab.appType.rawValue,
            "appAbility": "\(appAbility.rawValue)",
            "enableNewAppTabBadge": "\(enableNewAppTabBadge)"
        ])
        
        if enableNewAppTabBadge {
            /// 新的 badge 数据流程，从 rust 获取 badge 数据
            let badgeNodeCallback: ((
                _ badgeNode: OPBadgeRustAlias.OpenAppBadgeNode) -> Void
            ) = { [weak self] (badgeNode) in
                guard let self = self else {
                    Self.logger.error("[OPBadge] observe badge, but OPAppTabRepresentable released")
                    return
                }
                
                if badgeNode.needShow {
                    Self.logger.info("[OPBadge] Tab update badge", additionalData: [
                        "appId": badgeNode.appID,
                        "needShow": "\(badgeNode.needShow)",
                        "badgeNum": "\(badgeNode.badgeNum)",
                        "version": "\(badgeNode.version)",
                        "feature": "\(badgeNode.feature)",
                        "updateTime": "\(badgeNode.updateTime)"
                    ])
                    self._badge.accept(.number(Int(badgeNode.badgeNum)))
                    self._badgeVersion.accept(badgeNode.version)
                } else {
                    Self.logger.info("[OPBadge] Tab hide badge", additionalData: [
                        "appId": badgeNode.appID,
                        "needShow": "\(badgeNode.needShow)",
                        "badgeNum": "\(badgeNode.badgeNum)",
                        "version": "\(badgeNode.version)",
                        "feature": "\(badgeNode.feature)",
                        "updateTime": "\(badgeNode.updateTime)"
                    ])
                    self._badge.accept(.none)
                    self._badgeVersion.accept(badgeNode.version)
                }
            }
            
            self.badgeService = OPBadge.OPBadgeService(
                pushCenter: pushCenter,
                badgeAPI: badgeAPI,
                appId: appId,
                featureType: featureType,
                badgeNodeCallback: badgeNodeCallback
            )
        } else {
            /// 旧的 badge 数据流程，从工作台通知获取 badge 数据
            let badgeNumCallback: ((
                _ badgeNum: Int,
                _ needShow: Bool) -> Void
            ) = { [weak self] (badgeNum, needShow) in
                guard let self = self else {
                    Self.logger.error("[OPBadge] observe badge, but OPAppTabRepresentable released")
                    return
                }
                
                if needShow {
                    Self.logger.info("[OPBadge] Tab update badge", additionalData: [
                        "appId": appId,
                        "appAbility": "\(appAbility.description)",
                        "badgeNum": "\(badgeNum)"
                    ])
                    self._badge.accept(.number(badgeNum))
                } else {
                    Self.logger.info("[OPBadge] Tab hide badge", additionalData: [
                        "appId": appId,
                        "appAbility": "\(appAbility.description)",
                        "badgeNum": "\(badgeNum)"
                    ])
                    self._badge.accept(.none)
                }
            }
            self.badgeObsever = OPBadge.BadgePushObserver(
                appId: appId,
                type: appAbility,
                badgeNumCallback: badgeNumCallback
            )
        }
    }
}
