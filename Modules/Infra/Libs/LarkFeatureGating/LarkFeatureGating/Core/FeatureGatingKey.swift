//
//  FeatureGatingKey.swift
//  FeatureGating
//
//  Created by 李勇 on 2019/9/5.
//

import Foundation

/// 在FeatureGatingKey中定义的key会默认加入到cache中，方便开发进行debug
public enum FeatureGatingKey: String, CaseIterable {
    case secretChat = "secretchat.main"
    case byteViewEncryptedCall = "byteview.call.encrypted.ios"
    case byteViewAsrSubtitle = "byteview.asr.subtitle"
    case byteViewMeetingRecord = "byteview.meeting.ios.recording"
    case byteViewPushKit = "byteview.pushkit.ios"
    case byteViewCallKit = "byteview.callkit.ios"
    case byteViewLiveLegal = "byteview.meeting.ios.live_legal"
    case byteviewLive = "byteview.meeting.ios.live_meeting"
    case byteViewSubtitleRecordingHint = "byteview.callmeeting.ios.subtitle_recordinghint"
    case meeting = "calendar.meeting.iOS"
    case inviteFriends = "add.contacts.invite"
    case privacy = "setting.privacy"
    case redPacket = "hongbao.enable"
    case forward = "foward.quickswitcher.v118"
    case multiTenant = "lark.multitenant"
    case pinBadgeEnable = "pin.badge.enable"
    case rangeCopyEnable = "copy_ios"
    case isEnableOncall = "oncall.enable"
    case audioToTextEnable = "audio.convert.to.text"
    case createGroup = "create.group.public"
    case slide = "search.space.type.filter.slide"
    case mindnote = "search.space.type.filter.mindnote"
    case appcenterCardShare = "appcenter.cardshare"
    case autoTranslation = "auto.translation"
    case unregister = "lark.user.unregister"
    case searchFile = "search.file"

    /// filter topics in feed. ture: show filter topics button
    case filterTopicsEnable = "create.group.thread"
    /// threadChat reverse FG. true: use reverse.
    case reverseEnable = "group.topiclist.sort.reverse.v2"
    /// for external tenant
    case sortNormalEnable = "group.topiclist.sort.normal"
    /// topic group participant mode FG. true: open participant mode
    case topicGroupParticipantEnable = "group.role.obeserver"
    /// create topic group entry in thread Tab.
    case threadTabCreateGroupEnable = "group.tab.create.group"
    /// show tips when at others.
    case groupMentionTipsEnable = "group.mention.new.tips"
    /// 匿名发帖
    case groupAnonymous = "group.anonymous.enable"

    /// 设置小程序引擎网络代理是否走Rust SDK
    case microappNetworkRust = "microapp.network.rust"
    /// 小程序启动start_page支持Tab页面
    case microappLaunchTabStartPage = "microapp.launch.tab_startpage"
    /// 设置小程序引擎跨平台授权是否启用
    case microappAuthorizationCrossdevice = "microapp.authorization.crossdevice"
    /// 设置小程序引擎拍照是否使用LarkCamera
    case microappUICamera = "microapp.ui.camera"
    // 是否打开小程序包预下载
    case microappPushPreload = "microapp.preload"
    /// 是否启用小程序流式分段录音
    case microappAPIAudioStreamingRecord = "microapp.api.audio_streaming_record"
    /// 小程序filePicker是否支持系统文件选择器
    case microappAPIFilePickerSystem = "microapp.api.filepicker.system"
    /// 小程序chooseContact是否支持回显
    case microappAPIChooseContactDisplayback = "microapp.api.choosecontact.displayback"
    /// 小程序返回小程序场景值
    case microappSceneBackFromApp = "microapp.scene.back.from.app"
    /// 小程序是否允许播放加密音频
    case microappAudioEncrypt = "microapp.audio.encrypt"
    /// 小程序引擎网络请求cookie key去重
    case microAppRequestCookieKeyDeduplication = "microapp.api.request_cookie_deduplication"

    /// 邮件Tab开关
    case mailTabSearch = "lark.mail.mobile.search"
    case mailTabCustomLabel = "lark.mail.mobile.custom_labels"
    case mailContactSearch = "lark.mail.mobile.contact.search"
    case mailTabcountColor = "larkmail.cli.tabcount.gray"
    /// Email push mail navigator
    case mailNotificationNavigator = "larkmail.cli.notification.navigator"
    /// Email client
    case mailClient = "larkmail.cli.mailclient"
    case mailOnboardNewUser = "larkmail.cli.client.onboarding"
    case mailAlertIcon = "larkmail.cli.alerttabicon"
    case attachmentPreviewDrive = "lark.mail.attachment.preview.drive"
    case shortcutSupportDoc = "shortcut.support_doc"
    /// 是否可以冲聊天中跳入邮件
    case enterMailFromChat = "larkmail.cli.forwardmessage.navigator"
    case mailChatSetting = "larkmail.cli.maillinglist.setting"
    /// 勿扰模式
    case doNotDisrurbEnable = "lark.dnd"
    /// 置顶展开交互
    case shortcutDragExpend = "shortcut.drag_expend"
    /// 邀请企业成员
    case inviteMemberEnable = "invite.member.enable"
    case inviteMemberEmailEnable = "invite.member.email.enable"
    case inviteMemberNonAdminNonDirectionalInviteEnable = "invite.member.non_admin.non_directional.invite.enable"
    case inviteMemberChannelsPageEnable = "invite.member.channels.page.enable"
    case inviteMemberChannelsPageQRcodeEnable = "invite.member.channels.page.qrcode.enable"
    case inviteMemberChannelsPageLinkEnable = "invite.member.channels.page.link.enable"
    case inviteMemberChannelsPageFromGuideEnable = "invite.member.channels.page.from.guide.enable"
    case inviteMemberAccessInfo = "suite.admin.create_user.targeted_invitation"
    case keyboardNewStyleEnable = "lark.keyboard.newstyle"
    /// 是否启动简易键盘
    case simpleKeyboardEnable = "lark.keyboard.simple"
    case feedDetectScrollViewEnable = "feed.detect.srcollview.enable"
    case usecConfigCentersdk = "feature.gating.configcentersdk"
    // 小程序API
    case microappApiGetDeviceId = "microapp.api.deviceid"
    // 外部搜索
    case externalSearch = "search.external.content"
    /// 是否打开应用通知能力
    case applicationNofitication = "lark.app.notification"
    /// 群分享历史
    case groupShareHistory = "group.share.history"
    /// 能否邀请国外用户，只对飞书用户有用
    case inviteAbroadphone = "invite.abroadphone.enable"
    /// VSCode Log
    case microappIDELoggeer = "microapp.ide.logger"
    /// calendar RSVP card
    case wikiSearchEnable = "wiki.search.enable"
    // 搜索页面是否在网络失败的时候展示toast
    case larkSearchToastOff = "lark.search.toastoff"
    /// 是否使用新的密聊控制逻辑
    case newSecretControlRule = "lark.client.secretchat_priviledge_control.migrate"

    case modifiersFirst = "modifiers.first"
    /// 服务台群侧边栏小程序入口
    case chatSidebarMiniProgram = "lark.helpdesk.chat.sidebar.mini_program"
    // NSE 埋点开关
    case notificationServiceDotting = "notification.service.dotting.enable"
    /// 是否支持离线登出
    case logoutOffline = "lark.logout.offline"
    /// 应用机制是否上传信息(location, wifi)到开放平台
    case appStrategyTerminalinfo = "appstrategy.terminalinfo"
    /// 极速打卡优化位定位
    case openplatformTerminalinfoLocationOptimization = "openplatform.terminalinfo.location.optimization"
    case openplatformTerminalinfoLocationOptimizationv2 = "openplatform.terminalinfo.location.optimizationv2"
    case voipDisableRingingtocalling = "voip.disable.ringingtocalling"
    /// applink 开启兼容页面
    case applinkCompatibilityVersion = "applink.compatibility.version"
    /// 全球呼叫SOS开关
    case sosCallInChat = "lark.call.sos"
    /// 应用中心编辑页入口
    case appcenterCommonSet = "lark.appcenter.common.set"
    /// applink 启用openId唤起会话
    case applinkChatOpen = "applink.chat.open"
    /// h5sdk 屏蔽鉴权
    case h5sdkDisableVerify = "lark.h5api.verify"
    /// 群组高级搜索
    case advanceSearchGroup = "advance.search.group"
    /// 新的Pin列表
    case newPinList = "group_pin_new"
    /// 内部群添加外部成员限制
    case groupAddExternalLimit = "add.external.group.member.limit"
    /// 工作台是否启用rust网络
    case appcenterUseRust = "appcenter.network.userust"
    /// 自动会话盒子
    case autoChatbox = "lark.autochatbox"
    /// 小程序是否启用动态域名
    case microappDomainDynamic = "microapp.domain.dynamic"
    // allpin页面是否可跳转大搜
    case allPinSearch = "lark.pin.search"
    /// 添加好友统一入口
    case inviteUnionEnable = "invite.union.enable"
    /// 外部联系人邀请入口
    case inviteExternalEnable = "invite.external.enable"
    /// 全员有奖是否开启
    case inviteExternalAwardEnable = "invite.external.award.enable"
    /// 成员有奖邀请是否开启
    case inviteMemberAwardEnable = "invite.member.award.enable"
    /// 用户活跃度激励是否开启
    case activityAwardEnable = "activity.award.enable"
    /// 自定义导航栏
    case navigationCustomize = "lark.all.navigation.customize"
    /// oom触顶监控是否打开（影响性能）
    case oomDetector = "lark.oom.detector.open"
    /// space性能上报到slardar，用做渠道区分
    case spacePerformanceDetector = "spacekit.performance.detector.open"
    /// pin 机器人通知设置
    case pinBotConfig = "pin.bot.config"
    /// App 自定义分享
    case customSharePanelEnable = "invite.share.panel.enable"
    /// thread 开启管理员功能
    case threadAdminEnabled = "group.admin.content.manage"

    /// 自定义导航栏 - allPintab
    case allPinTabEnable = "pin.single.tab"

    /// 群Pin列表是否放开allpin入口
    case allPinInGroupPin = "allpin_in_group_pin"

    /// 没有链接Call时是否关闭pushKit
    case pushKitEnableWithoutCallKit = "pushkit.enable.without.callkit"

    /// 是否使用SetPushTokenRequest接口
    case enableSetPushToken = "enable.set.push.token"

    /// 是否使用deviceLoginId
    case pushUseDeviceId = "lark.push.use.device_id"

    /// 小程序使用新的进场动画页面
    case microappLoadingAnimation = "microapp.loading.animation"
    /// enable ner (Named-entity recognition)
    /// 开启实体识别
    case abbreviationEnabled = "chat.abbreviation.mobile.enable"
    /// 实体词整句查询
    case abbreviationQueryEnabled = "abbreviation.chat.menu.enable"
    /// 飞书是否打开PushKit
    case pushKitEnable = "lark.pushkit.enable"
    /// 小程序使用V2版本的更新策略
    case microappPushV2 = "microapp.update.v2"
    /// 小程序openScheme使用白名单来自getMeta
    case microappOpenSchemeV2 = "microapp.openschema.whitelist"
    /// 小程序checkSession是否使用过期时间逻辑
    case microappLoginExpireTime = "microapp.login.expiretime"
    /// 小程序关于页面版本更新提示
    case gadgetAboutVersionUpdateTip = "gadget.about.version.update.tip"
    /// 小程序vscode真机调试
    case gadgetDevtoolVSCDebug = "gadget.devtool.vsc.debug"
    /// 动态化初始化
    case dynamicInit = "lark_dynamic_init"
    /// 动态化URL拦截
    case dynamicURLInterceptor = "lark_dynamic_url_interceptor"
    /// 视频会议Tab
    case videoConferenceTab = "byteview.meeting.ios.tab"
    /// 视频会议工作台
    case videoConferenceSpace = "byteview.meeting.ios.meeting_space"

    case calIsInviteByGmail = "calendar.invite.gmail"
    /// 主导航自定义（3.15+）
    case navigationCustomizeV2 = "lark.all.navigation.customize.v2"
    /// 组织权限
    case microappOrgAuthScope = "microapp.userauthscope"
    /// Space Wiki全屏目录树封面
    case wikiTreeCoverEnaled = "spacekit.mobile.wiki_tree_home_optimization"
    /// Space Wiki目录树左滑onboarding
    case wikitreeLeftSwipeOnboardingEnable = "spacekit.wiki_mobile_tree_onboarding"
    /// DocsSDK启动优化修改开关
    case spaceKitLaunchOptimize = "spacekit.docsdk_launch_optimize"
    /// 临时消息卡片是否上屏
    case messageCardEphemeral = "messagecard.ephemeral.visible"
    /// Advanced Forward
    case advancedForward = "lark.overseas.forward"
    /// + gadget entrance enable
    case keyboardGadgetEnable = "lark.app.plus"
    /// reportAnalytics API enable
    case microappApiReportAnalytics = "microapp.api.report_analytics"
    /// DocsSDK 对外分享开关
    case spaceKitShareLinkEntrance = "spacekit.mobile.share_link_edit_entrance"
    /// new onboarding 视频引导是否横屏播放
    case guideVideoLandscapeEnable = "guide.video.landscape.enable"
    /// doc icon 支持自定义url
    case docCustomAvatarEnable = "lark_feature_doc_icon_custom"
    /// 翻译设置新版本总开关
    case translateSettingsV2Enable = "translate.settings.v2.enable"
    /// 自动翻译设置网页入口开关
    case translateSettingsV2WebEnable = "translate.settings.v2.auto_translate.web.enable"
    /// 自动翻译设置 Mail 入口开关
    case translateSettingsMailEnable = "larkmail.cli.autotranslation"
    /// 全员开放修改姓名入口
    case larkAllChangeName = "lark.all.change.name"
    /// 新通知设置界面入口
    case notificationClassify = "notification.classify"
    /// 加入或创建团队侧边栏入口 替换 lark.onboarding.team_conversion
    case passportTeamConversion = "lark.passport.team.conversion"
    /// 成员邀请是否启用微信分享
    case inviteMemberWechatShareEnable = "invite.member.third.share.wx.enable"
    /// 成员邀请是否启用微信分享
    case inviteExternalWechatShareEnable = "invite.external.third.share.wx.enable"
    /// 切换租户是否禁用fast switch 3.22.0 版本使用
    case passportDisableFastSwitch = "lark.passport.disable_fast_switch"
    /// 切换租户是否启用fast switch 3.23.0 版本及以上使用
    case passportFastSwitch = "lark.passport.fast_switch"
    /// NSE 日志开关
    case notificationServiceLog = "notification.service.log.enable"
    /// 消息卡片转发 - 消息卡片是否支持转发
    case messageCardForward = "messagecard.forward.enable"
    /// 消息卡片转发 - 消息卡片是否支持多选
    case messageCardSupportMutilSelect = "messagecard.support.mutilselect"
    /// 视频会议横幅
    case byteviewMeetingBanner = "byteview.meeting.ios.meetingbanner"
    /// lite 版本是否显示 appCenter
    case larkLiteAppcenterEnable = "lark.lite.appcenter.enable"
    /// 开放平台短链服务
    case shortAppLinkEnable = "lark.applink.shortlink"
    /// 是否开启 Lark Z 轴功能 (Yelowstone 是 Z 轴功能的项目代号)
    case larkYellowstoneEnable = "lark.yellowstone.enable"
    /// 分享口令功能
    case shareTokenEnable = "lark.share.kouling"
    /// 引导-升级团队Banner
    case upgradeTeamVCBannerEnable = "banner.ug.ad.coldscene"
    /// lite版是否支持自定义分享面板
    case larkLiteSharePanelEnable = "lite.invite.share.panel.enable"
    /// 隐私设置中 ”通过设置添加我“
    case larkPrivacySettingAddfriends = "lark.messenger.setting.privacy.addfriends"
    /// 隐私设置中 ”通过设置添加我“
    case larkPrivacySettingAddfriendsByMail = "lark.messenger.setting.privacy.mail.addfriends"
    /// 邀请团队码页面复制按钮是否显示
    case memberInviteTeamCodeCopyEnable = "invite.member.teamcode.copy.enable"
    /// 图片消息长按菜单是否显示翻译入口
    case imageMessageTranslateEnable = "translate.image.chat.menu.enable"
    /// message相关场景中的图片在查看器中是否支持翻译
    case imageViewerInMessageScenesTranslateEnable = "translate.message.image.viewer.enable"
    /// 其他场景(收藏、头像等)中的图片在查看器中是否支持翻译
    case imageViewerInOtherScenesTranslateEnable = "translate.other.image.viewer.enable"
    /// H5应用是否开启 monitorReport API
    case gadgetWebAppApiMonitorReport = "gadget.web_app.api.monitor_report"
    /// 是否将侧边栏迁移至会话设置页面
    case sideBarToChatSetting = "lark.sidebar_to_chatsetting"
    /// 是否切换新版工作台
    case workPlaceNewVersion = "lark.appcenter.new_version"
    /// 是否展示Widget
    case workPlaceWigetDisplacy = "lark.appcenter.widget.display"
    /// 是否开启iPad 工作台Tab
    case ipadWorkPlaceTab = "lark.ipad.appcenter.tab"
    /// iPad是否支持打开小程序
    case ipadMicroApp = "lark.ipad.microapp"
    /// 新建群组、拉人入群等场景支持部门下的全选操作
    case groupSupportSelectAll = "lark.group.support.select.all"
    /// 加急时选择所有未读用户
    case buzzUnreadCheckbox = "lark.messenger.buzz.unread.checkbox"
    /// UG 身份切换提示需求
    case ugGuideTeamSwitch = "ug.guide.teamswitch"
    /// UG 外部联系人优化排序分组
    case ugContactExternalGroup = "contact.external.alphabetic.group"
    /// 智能补全开关
    case smartComposeEnable = "suite.ai.smart_compose.mobile.enabled"
    /// 是否开启Chat中UI降频策略
    case chatUIReduceFrequency = "lark.chat.ui.reduce.frequency"
    /// 水印重构支持多scene
    case waterMarkRefactor = "lark.ios.watermarkrefactor"
    /// 工作台widget是否支持展开
    case widgetCanExpand = "lark.appcenter.widget.expand"
    /// 网页翻译
    case webTranslateEnable = "translate.webpage.enable"
    /// 翻译反馈
    case translateFeedBack = "message.translation.feedback"
    /// IM卡片和添加外部协作者Ask owner FG
    case askOwnerAlertEnabled = "spacekit.moblie.ask_owner_alert"
    /// 联系人优化 UI/入口调整
    case contactOptForUI = "lark.client.contact.opt.ui"
    /// 引导流程优化客户端FG
    case onboardingFlowOpt = "lark.client.onboarding.opt"
    /// 新引导接入FG-VC
    case enableNewGuideSwitchVC = "lark.newguide.switch.vc"
    /// 新引导接入FG-IM
    case enableNewGuideSwitchIM = "lark.newguide.switch.im"
    /// 小组降噪优化
    case groupFeedOptimize = "group.feed.optimize"
    /// 是否开始小程序引擎 JSRuntime 优化：修复特定情况下的消息丢失,MEEGO-864772
    case gadgetFixJsruntimeDelegateLifecycle = "gadget.jscontext.delegate.lifecycle.fix"
    /// 是否启用标准H5分享内容抓取逻辑
    case enableH5StandardMetaInfo = "gadget.h5.standard_meta_info"
    /// 话题群是否使用新版复制
    case groupMobileCopyOptimize = "group.mobile.copy.optimize"
    /// 客户端兜底使用新Emoji & Reaction顺序
    case clientChatEmojiOrder = "client_chat_emoji_order"
    /// 客户端输入框Emoji使用新面板
    case clientChatInputEmojiUpdate = "client_chat_input_emoji_update"
    /// 新版profile
    case newProfile = "messenger.profile.new_structure_5.0"
    /// 新版profile勋章
    case newProfileMedal = "messenger.profile.badge"
    /// 使用新的图片编辑器
    case useNewImageEditor = "messenger.image.ve.editor"
    /// 新版profile备注功能
    case newProfileAlias = "messenger.profile.more_alias"
    /// 特别关注
    case specialRemind = "im.contact.favorite"
    case team = "lark.feed.new_team"
    /// 锁屏
    case appLockSettingEnable = "applock.enable"
    /// 通知声音
    case notificationSound = "core.ios_setting.sound"
    /// 新版群投票
    case newGroupVote = "im.chat.vote"
    /// 消息卡片支持翻译
    case messageCardTranslate = "messagecard.translate.support"
    /// 消息卡片支持翻译
    case messageCardForceTranslate = "messagecard.translate.force_enable_translate"
    /// 是否支持群成员字母排序
    case imChatMemberList = "im.chat.member_list"
    /// 默认是否为首字母排序
    case memberListDefaultAlphabetical = "im.chat.member_list_default_alphabetical"
    /// 企业百科支持高亮
    case lingoHighlightOnKeyboard = "lingo.imeditor.recall"
}
