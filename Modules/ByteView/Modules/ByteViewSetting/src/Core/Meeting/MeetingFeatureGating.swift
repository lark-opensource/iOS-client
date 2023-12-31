//
//  MeetingFeatureGating.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/4/14.
//

import Foundation
import ByteViewCommon

final class MeetingFeatureGating {
    private let setting: UserSettingManager
    private let logger: Logger
    init(_ setting: UserSettingManager, logger: Logger) {
        self.setting = setting
        self.logger = logger
    }

    private func fg(_ key: String) -> Bool {
        setting.fg(key, logger: logger)
    }

    private func dynamicFeatureGatingValue(_ key: String) -> Bool {
        setting.dynamicFeatureGatingValue(key, logger: logger)
    }

    lazy var isAudioRecordEnabledForSubtitle = fg("byteview.callmeeting.ios.subtitle_recordinghint")

    /// 开启后，字幕去掉“说话语言”的相关设置及弹窗
    lazy var subtitleDeleteSpokenLanguage = fg("byteview.callmeeting.ios.subtitle_delete_spoken_language")

    lazy var isSubtitleEnabled = fg("byteview.asr.subtitle")

    lazy var isSubtitleTranslationEnabled = fg("byteview.vc.subtitle.translation")

    lazy var isLiveEnabled = fg("byteview.meeting.ios.live_meeting")

    /// 打开的时候有企业直播功能，关闭的时候没有企业直播功能，默认关闭
    lazy var isEnterpriseLiveEnabled = fg("byteview.live.enterpriselive")

    lazy var isSubtitleIconOut = fg("byteview.callmeeting.ios.subtitle_icon")

    lazy var isDialpadEnabled = fg("byteview.meeting.dialpad")

    /// FG开启 首位开启字幕有弹窗；FG关闭 首位开启字幕者无弹窗，所有参会人的说话语言不会被修改
    lazy var isSpokenLanguageSettingsEnabled = fg("byteview.callmeeting.ios.subtitle.spokenlangsetting")

    // MARK: - network
    /// 弱网提示
    lazy var isWeakNetworkEnabled = fg("byteview.meeting.weaknetworkdetectandtips")

    /// 远端ICE提示根据Network unknown进行判断
    lazy var isRemoteNetworkUnknown = fg("byteview.meeting.remotenetworkquality_unknown")

    /// 多端协同
    lazy var isJoinRoomTogetherEnabled = fg("byteview.meeting.ios.room_join_together")

    /// 一键邀请电话入会
    lazy var isPstnQuickCallEnable = fg("byteview.meeting.pstnquickcall")

    /// 是否接入主端提供的个人状态控件
    lazy var isNewStatusEnabled = dynamicFeatureGatingValue("core.status.onleave")

    // MARK: - sip
    lazy var isSipInviteEnabled = fg("byteview.meeting.ios.invitesip")

    lazy var isPhoneServiceEnable = fg("byteview.vc.pstn.phoneservice")

    ///是否支持节能模式
    lazy var isEcoModeEnabled = fg("byteview.meeting.eco_mode")

    /// 是否开启温度降级
    lazy var isThermalDegradeEnabled = fg("byteview.meeting.thermal_downgrade")

    /// 是否在 MagicShare 页面开启自动隐藏工具栏
    lazy var isMSHideToolbarEnabled = fg("byteview.meeting.ios.ms.hide_controlbar")

    /// 当UI和RTC麦克风/摄像头状态不一致时是否自动mute
    lazy var isAutoMuteWhenConflictEnabled = fg("byteview.meeting.ios.mute_when_diff")

    /// 是否允许SIP信息复制到剪贴板
    lazy var isH323CopyInvitationEnabled = fg("byteview.meeting.copyh323invitation")

    lazy var isMeetingRecordEnabled = fg("byteview.meeting.ios.recording")

    /// 别名展示设置
    lazy var isShowAnotherNameEnabled = fg("lark.chatter.name_with_another_name_p2")

    // MARK: - 特效
    lazy var isFilterEnabled = fg("byteview.meeting.ios.filter")
    lazy var isRetuschierenEnabled = fg("byteview.meeting.ios.touchup")
    lazy var isAnimojiEnabled = fg("byteview.meeting.ios.animoji")

    ///  虚拟背景是否可以用coreml、cvpixelbuffer
    lazy var isVirtualBgCoremlEnabled = fg("byteview.meeting.ios.background_coreml_enable")
    lazy var isVirtualBgCvpixelbufferEnabled = fg("byteview.meeting.cvpixelbuffer")

    /// 语音识别设置
    lazy var isVoiceprintRecognitionEnabled = fg("byteview.vc.ios.voiceprint")

    /// 是否在设置页面中显示高级调试功能
    lazy var isAdvancedDebugOptionsEnabled = fg("byteview.meeting.advanced.debugopts")

    /// 是否开启RTC证书注入
    lazy var isRtcSslEnabled = fg("byteview.callmeeting.client.rtc.enable_ssl_pinning")

    /// 是否限制RTC带宽
    lazy var isLimitRTCBandwidth = fg("byteview.vc.limitbandwith")

    lazy var isCallMeEnabled = Display.phone && fg("byteview.vc.pstn.call_me")

    /// 是否开启带宽管控
    lazy var isNetTrafficControlEnabled = setting.settings(for: .fine_scheduling)["lark.vc.net.traffic_control"] != nil

    /// 是否展示关联标签
    lazy var isRelationTagEnabled = fg("lark.suite_admin.orm.b2b.relation_tag_for_office_apps")

    /// 是否使用IM chat
    lazy var isUseImChatEnabled = fg("vc.chat.client.new_imchat")

    /// 日程会议是否使用IM chat
    lazy var isCalUseImChatEnabled = fg("vc.chat.client.cal_new_imchat")

    lazy var isHDModeEnabled = fg("byteview.meeting.hdvideo")

    /// 电话服务是否精细化管理
    lazy var isRefinementManagement = fg("byteview.vc.pstn.refinement_management")

    /// 是否支持长按空格取消静音功能
    lazy var isKeyboardMuteEnabled = fg("byteview.meeting.ios.unmutebyspace")

    /// 控制会中发言
    lazy var isChatPermissionEnabled = fg("vc.chat.chat_permission")

    lazy var isOnewayRelationshipEnabled = fg("lark.client.contact.opt")

    /// 是否展示清晰度标签
    lazy var canShowRtcDefinition = fg("byteview.meeting.definitionlabel")

    /// 若附近Room（超声波检测）已在会中，是否入会自动静音自己
    lazy var isAutoMuteWhenRoomInMeetingEnabled = fg("byteview.meeting.mob.automute")

    lazy var isLiveLegalEnabled = fg("byteview.meeting.ios.live_legal")

    /// 主动入会不启用 callkit
    lazy var isCallKitOutgoingDisable = fg("byteview.meeting.callkit_outgoing_disable")

    lazy var isMagicShareNewDocsEnabled = fg("byteview.callmeeting.ios.magic_share_new_docs")

    lazy var isMagicShareNewBitableEnabled = fg("byteview.meeting.ios.magic_share_bitable")

    // MARK: - 会中妙享
    /// MagicShare中DocX的灰度
    /// 灰度内，灰度范围内能发起 DocX 的共享和看共享
    /// 灰度外，支持在共享面板上搜索到 DocX 文档，但是不支持发起，同时隐藏新建 DocX 的入口
    lazy var isMSDocXEnabled = fg("byteview.meeting.ios.magic_share_docx")
    /// MagicShare中新建DocX选项后是否显示beta标签
    lazy var isMSCreateNewDocXBetaShow = fg("byteview.meeting.ios.magic_share_docx_beta")
    /// 妙享中ccmDocX和ccmWikiDocX类型是否支持横屏
    lazy var isMSDocXHorizontalEnabled = fg("ccm_docx_mobile.screen_view_horizental")
    /// 妙享中ccmMindnote和ccmWikiMindnote类型是否支持横屏
    lazy var isMSMindnoteHorizontalEnabled = fg("ccm_mindnote_mobile.screen_view_horizental")
    /// MS回到上次位置优化（使用CCM的位置应用能力，VC控制位置的记录与应用）
    lazy var isMSBackToLastLocationEnabled = fg("byteview.callmeeting.ios.back_to_last_location")
    /// 妙享场景CPU上报（供CCM降级）
    lazy var isMagicShareCpuUpdateEnabled = fg("lark.core.cpu.manager.power.optimize")
    /// 用途描述：在MS场景下复用同一个webview，去掉在切换文档时重新加载模板的性能消耗
    /// 命中时表现：复用同一个webview
    /// 未命中时表现：走旧的逻辑，会先创建新webview再释放旧的
    lazy var isMagicShareWebViewReuseEnabled = fg("ccm.docs.ms_webview_reuse_enable_ios")
    /// 会中妙享v7.9新增的降级策略开关
    lazy var isMagicShareDowngradeEnabled = fg("ccm.mobile.magic_share_downgrade_enabled")

    // MARK: - 会议纪要
    /// 会议纪要总开关
    lazy var isMeetingNotesEnabled = fg("byteview.meeting.meetingnotes")
    /// Notes 文档增加 My AI 引导的 FG
    lazy var isNotesMyAIGuideEnabled = fg("byteview.vc.minutes.ai_summary_on")

    lazy var isDecorateEnabled = fg("byteview.meeting.ios.background_decorate")
    /// myAI是否可用
    lazy var isMyAIChatEnabled = fg("byteview.vc.my_ai_chat")
    /// 采集编码帧率联动
    lazy var isEncodeLinkageEnabled = fg("byteview.callmeeting.client.rtc.fps_linkage")
    /// My AI 总 FG
    lazy var isMyAIAllEnabled = fg("lark.my_ai.main_switch")

    /// 画中画开关
    lazy var isPiPEnabled = fg("byteview.meeting.ios.pip")
    /// 画中画 SampleBuffer 渲染开关
    lazy var isPiPSampleBufferRenderEnabled = fg("byteview.meeting.ios.pip.render")
    /// 预览页替代入会功能
    lazy var isSwitchDeviceInMeetingEnabled = fg("byteview.meeting.switch_device_in_meeting")

    /// 会中专属表情
    lazy var isExclusiveReactionEnabled = fg("byteview.meeting.vc_reaction")

    /// 最小化悬浮窗, 画中画时是否停止订阅共享屏幕视频流
    lazy var miniWindowShareDisabled = fg("byteview.meeting.mobile.miniwindow_share")

    /// 会议标注白板保存功能
    lazy var isWhiteboardSaveEnabled = fg("byteview.whiteboard.save")
}
