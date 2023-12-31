//
//  GuideKey.swift
//  ByteView
//
//  Created by kiri on 2021/8/26.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

enum GuideKey: String {
    // https://bytedance.feishu.cn/docs/doccnMHA5dBTn8bdJ1jHth5dybg#
    // 第一次使用带后退能力的 Magic share 功能，从文档中点击了子链接 "点击返回上一个内容"
    case followNavBack = "mobile_vc_magic_share_back"
    // 被共享者，跟随状态，"点击或滚动文档可以自由浏览哦"
    case followerFreeBrowse = "mobile_magic_share_free_browse"
    // 被共享者，自由浏览，"点击跟随主讲人浏览内容"
    case followerFollowPresenter = "mobile_magic_share_to_presenter"

    // 沉浸态点击展开工具栏
    case followExpandToolbar = "mobile_magic_share_expand_toolbar"
    // 沉浸态隐藏工具栏toast
    case toolbarAutoHide = "mobile_vc_click_anytoolbar"
    // 关闭自动隐藏工具栏,首次竟然横屏模式引导
    case toolbarAccessHide = "mobile_vc_hide_access_toolbar"

    // 共享屏幕横屏
    case landscapeSharescreen = "mobile_vc_landscape_sharescreen"

    /// MS场景首次进入沉浸模式，OnBoarding提示“点击「共享指示区」可唤起工具栏”
    /// 沉浸态退出引导： 引导用户完成一次，点击 Bar 并退出沉浸态后，引导气泡消失
    case followExapndToolbarSharingBar = "mobile_magic_share_expand_toolbar_sharingbar"

    /// MS场景首次不跟随且在沉浸态，OnBoaring提示“当前您处于「自由浏览」。点击共享人头像可「跟随浏览」。”
    /// MS沉浸态下未跟随引导： 点击指示区域时，或者点击空白处，或进行其他操作时，引导气泡消失
    case followClickAvatarToFollow = "mobile_magic_share_click_avatar_to_follow"

    case subtitlesHistory = "all_vc_subtitles_history"
    case live = "all_vc_meet_live"
    case reaction = "mobile_vc_chatandreaction"
    case tabList = "vc_tab_recentmeetings_onboarding"

    /// 倒计时入口引导
    case countDown = "all_vc_countdown_more"
    /// 倒计时面板收起至状态栏后，可点击状态栏的tag，重新展开面板
    case countDownUnfold = "all_vc_countdown_meetingbar"

    // 引导-打开历史字幕指引
    case subtitleSetting = "all_vc_subtitles_setting"
    case shrinkerGuideKey = "mobile_vc_magic_share_hide_video"
    case liveLayoutSetting = "all_vc_live_layout_setting"

    // 在非共享人首次使用标注功能时，提示标注行为会协同到所有人的屏幕上
    case followerStartAnnoate = "vc_follower_start_annotate"

    // lab effect onboarding
    case labEffectGuidekEY = "mobile_vc_beautyandfilterandanimoji"

    case hostSecurityGuideKey = "vc_pc_host_security"

    case interactionFloatingPanel = "mobile_vc_reaction_lefthide"

    /// iPad 收起视频流按钮指引
    case thumbnailFold = "all_vc_thumbnail_fold"

    /// Pad 支持切换视图类型
    case padChangeSceneMode = "pad_vc_changelayout"

    /// Pad 自定义视频顺序
    case customOrder = "all_vc_customize_video_order"

    /// Pad 重置视频顺序
    case resetOrder = "all_vc_reset_order"

    /// webinar 观众首次入会，提示可以举手发言
    case webinarAttendee = "vc_webinar_audience"

    /// 投屏转妙享，设备首次被允许自由浏览时
    case enabledNewMagicShare = "vc_newmagicshare_free_mobile"

    /// 投屏转妙享，设备首次进入自由浏览时
    case enteredNewMagicShare = "vc_newmagicshare_follow_mobile"

    /// 会议纪要上线引导，入会时检查并显示
    case notesOnboarding = "all_vc_note"
    /// iPad 面试空间
    case interviewSpace = "vc_interview_space"

    /// My AI 的 Onboarding
    case myAIOnboarding = "global_my_ai_init_guide"

    /// 引导用户长按发送连击表情
    case reactionPressOnboarding = "all_vc_reactionpress"
    case micLocation = "all_vc_mictoolbar"
}
