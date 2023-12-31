//
//  FeatureGating.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/05/21.
//

import Foundation
import LarkFeatureGating
import LarkSetting
import LarkContainer

extension Feed {
    public struct Feature {
        public let userResolver: UserResolver
        public init(_ userResolver: UserResolver) {
            self.userResolver = userResolver
        }

        // 频繁使用fg & 懒得写在业务初始化地方的，可以放这提前初始化
        static func feedInit(userResolver: UserResolver) {
            FeedContext.log.info("feedlog/feature/feedInit")
            Feed.Feature.urgentEnabled = Feature._getUrgentEnabled(userResolver: userResolver)
            Feed.Feature.labelEnabled = Feature._getLabelEnabled(userResolver: userResolver)
            Feed.Feature.teamChatPrivacy = Feature._getTeamChatPrivacy(userResolver: userResolver)
        }

        // 对一致性有要求的fg，可以放在这里
        static func beforeSwitchAccount() {
            FeedContext.log.info("feedlog/feature/beforeSwitchAccount")
            // Feature._addMuteGroupEnable = nil
        }

        static func getStaticFgValueWithLog(_ fgKey: String,
                                            userResolver: UserResolver) -> Bool {
            let enable = userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: fgKey))
            FeedContext.log.info("feedlog/feature/fg/static. \(fgKey): \(enable)")
            return enable
        }

        func getStaticFgValueWithLog(_ fgKey: String) -> Bool {
            let enable = Self.getStaticFgValueWithLog(fgKey, userResolver: userResolver)
            FeedContext.log.info("feedlog/feature/fg/static. \(fgKey): \(enable)")
            return enable
        }

        func getDynamicFgValueWithLog(_ fgKey: String) -> Bool {
            let enable = userResolver.fg.dynamicFeatureGatingValue(with: .init(stringLiteral: fgKey))
            FeedContext.log.info("feedlog/feature/fg/dynamic. \(fgKey): \(enable)")
            return enable
        }
    }
}

// MARK: 产品需求FG - 灰度中
public extension Feed.Feature {
    // 基础模式
    var isBasicModeEnabe: Bool { getStaticFgValueWithLog("mobile.core.basic_mode") }

    // 团队群组权限
    static var teamChatPrivacy: Bool = false
    private static func _getTeamChatPrivacy(userResolver: UserResolver) -> Bool {
        getStaticFgValueWithLog("lark.feed.team_chat_privacy", userResolver: userResolver)
    }

    // 会话快捷操作设置优化
    var feedActionSettingEnable: Bool {
        return getStaticFgValueWithLog("lark.im.feed.card.quick_swipe_setting")
    }
}

// MARK: 产品需求FG
public extension Feed.Feature {
    // Feed 支持展示快捷按钮
    var feedButtonEnable: Bool { getStaticFgValueWithLog("lark.im.feed.feed_button") }

    var groupPopOverForPad: Bool {
        return getStaticFgValueWithLog("core.ipad.popover_feed_folder")
    }
}

// MARK: 产品需求FG - 待删除
public extension Feed.Feature {
    // TODO: 待删除相关代码，以下三个fg都已经全量1个月，待删除
    // 增加免打扰分组
    var addMuteGroupEnable: Bool { true }

    // 分组设置
    var groupSettingEnable: Bool { true }

    // 分组设置优化
    var groupSettingOptEnable: Bool { true }

    // 清未读引导功能开关
    var isClearBadgeGuideEnable: Bool { return getStaticFgValueWithLog("lark.core.mobile.clearunreboard") }

    // 屏蔽机器人推送功能开关
    var isChatForbiddenEnable: Bool { getStaticFgValueWithLog("messager.bot.p2p_chat_mute") }
}

// MARK: 技术需求FG - 灰度中
public extension Feed.Feature {
    // 打印比较全的log来跟踪一些数据同步问题，开启之后，打印的日志量会比较大，谨慎开启
    var isTracklog: Bool { getStaticFgValueWithLog("lark.feed.tracklog") }

    // 是否启用feeds的增量排序能力
    var partialSortEnabled: Bool { getStaticFgValueWithLog("lark.feed.main.sortopt.enable") }
}

// MARK: 技术需求FG - 待删除
public extension Feed.Feature {
    static var userScopeFG: Bool {
        let v = FeatureGatingManager.shared.featureGatingValue(with: "ios.container.scope.user.feed") // Global
        return v
    }

    // 是否禁用diff刷新UI
    var isForbidiff: Bool { getStaticFgValueWithLog("lark.feed.forbidiff") }
}
