//
//  FeedMainViewModel+GuideService.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/12/22.
//

import Foundation
import LarkFeatureSwitch

public enum GuideKey: String {
    case feedAtGuide = "all_feed_mention_you" // At 某个人引导
    case feedAtAllGuide = "all_feed_mention_all" // At All引导
    case feedBadgeGuide = "all_badge_change_setting" // 免打扰feed上的badge引导
    case feedNaviBarDotGuide = "all_feed_navibar_avatar_badge" // 新注册用户红点
    case mobileTeamJoinKey = "mobile_ug_team_join_switch" // 身份切换引导
    case mobileOldSwitchV2Key = "mobile_switch_team_guidance_v2" // 旧版租户引导key
    case pcOldSwitchKey = "pc_multi_tenant"  // 旧版租户引导key PC
    case mobileMessengerThreeColumn = "mobile_messenger_three_column" // feed三栏引导
    case feedClearBadgeGuide = "im_msg_clear_unreadbadge" //feed第一次清除单个feed引导
    case feedBatchClearBadgeGuide = "mobile_messenger_dismissunreads_once" //一键清未读引导
}

/// 用户引导
extension FeedMainViewModel {
    /// 是否显示引导
    func needShowGuide(key: GuideKey) -> Bool {
        return dependency.needShowNewGuide(guideKey: key.rawValue)
    }

    /// 已经显示引导
    func didShowGuide(key: GuideKey) {
        dependency.didShowNewGuide(guideKey: key.rawValue)
    }

    /// 是否显示新用户头像红点引导(naviAvatarView Dot)
    var newRegisterGuideEnbale: Bool {
        var guideEnabled = true
        LarkFeatureSwitch.Feature.on(.feedGuide).apply(on: {}, off: { guideEnabled = false })
        return guideEnabled
    }

    /// 是否应该显示Feed汉堡菜单引导
    func feedThreeColumnsGuideEnabled() -> Bool {
        var guideEnabled = true
        LarkFeatureSwitch.Feature.on(.feedGuide).apply(on: {}, off: { guideEnabled = false })
        let needGuide = needShowGuide(key: .mobileMessengerThreeColumn)
        FeedContext.log.info("feedlog/threeColumns/guide. needShowThreeColumnGuide: \(needGuide), switchGuideEnable: \(guideEnabled)")
        return needGuide && guideEnabled
    }
}
