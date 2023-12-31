//
//  ShareScreenToFollowTracks.swift
//  ByteView
//
//  Created by liurundong.henry on 2022/10/11.
//

import Foundation
import ByteViewTracker
import ByteViewNetwork

// MARK: - 投屏转妙享
// 埋点文档 https://bytedance.feishu.cn/sheets/shtcnbtgQSWEI9ssV1Bhipu8ate?sheet=KFuJbb

enum ClickFreeToBrowseButtonSwitchReason: String {
    case barIcon = "bar_icon" // 点击被共享 bar上的自由浏览icon
    case doubleClick = "double_click" // 双击进入自由浏览
}

enum ClickBackToShareScreenButtonSwitchReason: String {
    case barIcon = "bar_icon" // 被共享人点击被共享 bar上的回到共享屏幕icon
    case changeTag = "change_tag" // 主共享人切换tag 导致跟随
    case closeAuthority = "close_authority" // 主共享人收回自由浏览权限 导致跟随"
}

final class ShareScreenToFollowTracks {

    /// 展示“自由浏览”按钮
    /// - Parameter fileId: 文档ID
    static func trackViewFreeToBrowseButton(with fileId: String?) {
        VCTracker.post(name: .vc_share_screen_to_ms_view,
                       params: ["view": "free_to_browse_icon",
                                "file_id": fileId ?? ""])
    }

    static func trackClickFreeToBrowseButton(with switchReason: ClickFreeToBrowseButtonSwitchReason) {
        VCTracker.post(name: .vc_share_screen_to_ms_click,
                       params: [.click: "free_to_browse_file",
                                "switch_reason": switchReason.rawValue])
    }

    static func trackClickBackToShareScreenButton(with switchReason: ClickBackToShareScreenButtonSwitchReason) {
        VCTracker.post(name: .vc_share_screen_to_ms_click,
                       params: [.click: "back_to_screen",
                                "switch_reason": switchReason.rawValue])
    }

    static func trackClickCopyFileLinkButton() {
        VCTracker.post(name: .vc_share_screen_to_ms_click,
                       params: [.click: "copy_file_link"])
    }

    static func trackClickReloadButton() {
        VCTracker.post(name: .vc_share_screen_to_ms_click,
                       params: [.click: "reload"])
    }

    static func trackClickBackToLastFileButton() {
        VCTracker.post(name: .vc_share_screen_to_ms_click,
                       params: [.click: "backward"])
    }

    static func trackInitDocument() {
        VCTracker.post(name: .vc_screen_to_file_dev,
                       params: ["is_success": true,
                                "is_file_load_success": true,
                                "total_duration": 0])
    }

}

// MARK: - Onboarding
// 埋点文档 https://bytedance.feishu.cn/sheets/shtcnbtgQSWEI9ssV1Bhipu8ate?sheet=tZKXpJ

enum ShareScreenToFollowOnboardingType: String {
    /// 妙享模式已开启，点击即可进入自由浏览
    case viewOnMyOwn = "viewer_view_on_my_own"
    /// 你目前正在自由浏览，点击即可回到屏幕共享
    case backToScreen = "viewer_back_to_screen"
}

enum ShareScreenToFollowOnboardingClickType: String {
    /// 点击“我知道了”
    case check = "check"
    /// 直接进入自由浏览
    case viewOnMyOwn = "view_on_my_own"
    /// 直接回到共享屏幕
    case backToScreen = "back_to_screen"
}

extension ShareScreenToFollowTracks {

    /// 投屏转妙享 Onboarding 展现时上报
    static func trackShowOnboarding(with onboardingType: ShareScreenToFollowOnboardingType) {
        VCTracker.post(name: .vc_sharescreen_to_magicshare_onboarding_view,
                       params: ["onboarding_type": onboardingType])
    }

    /// 用户点击投屏转妙享 Onboarding 中的“我知道了”时上报
    static func trackClickOnboarding(with onboardingType: ShareScreenToFollowOnboardingType, clickType: ShareScreenToFollowOnboardingClickType) {
        VCTracker.post(name: .vc_sharescreen_to_magicshare_onboarding_click,
                       params: ["onboarding_type": onboardingType,
                                "click": clickType])
    }

}
