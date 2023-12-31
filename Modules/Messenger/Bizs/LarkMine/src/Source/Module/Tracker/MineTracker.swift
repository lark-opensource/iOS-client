//
//  MineTracker.swift
//  LarkMine 
//
//  Created by 姚启灏 on 2018/7/4.
//

import Foundation
import Homeric
import LarkModel
import LKCommonsTracker
import RustPB

enum TranslateEffectType: Int {
    case withOriginal = 1
    case onlyTranslation = 2
}

enum TranslateSettingPositionType: String {
    case guide              // 自动翻译的引导卡片
    case global_setting     // 全局翻译设置
    case web_guide          // 网页翻译中的引导
}

enum TranslateSettingObjectType: String {
    case general            // 总开关
    case message            // 消息自动翻译开关
    case doc                // 文档正文自动翻译开关
    case comment            // 文档评论自动翻译开关
    case web                // 网页自动翻译开关
    case email              // 邮件自动翻译开关
    case moments            // 公司圈自动翻译开关
    case unknow
}

enum TranslateGeneralStatusType: String {
    case general_open       //此时总开关是开的
    case general_close      //此时总开关是关的
}

enum TranslateActionStatus: String {
    case open
    case close
}

final class MineTracker {
    static var category: String {
        return "Me"
    }

    /// 在设置页面中，选择了接收全部新消息通知
    static func trackSettingNotificationAllNewMessage() {
        Tracker.post(TeaEvent(Homeric.SETTING_NOTIFICATION_ALL_NEW_MESSAGE))
    }

    /// 在设置页面中，选择了不接受新消息通知
    static func trackSettingNotificationNothing() {
        Tracker.post(TeaEvent(Homeric.SETTING_NOTIFICATION_NOTHING))
    }

    /// 在设置页面中，选择了只接收部分新消息通知，New: V2
    static func trackSettingNotificationSpecificMessage(setting: String) {
        Tracker.post(TeaEvent(Homeric.SETTING_NOTIFICATION_SPECIFIC_MESSAGE, params: [
            "message_kind": setting
        ]))
    }

    /// 在选择了只接收部分新消息通知后，点击进入了编辑页
    static func trackSettingNotificationSpecificMessageEdit() {
        Tracker.post(TeaEvent(Homeric.SETTING_NOTIFICATION_SPECIFIC_MESSAGE_EDIT))
    }

    /// 在选择了只接收部分新消息通知的基础上，勾选了接收@消息并确定
    static func trackSettingNotificationSpecificMessageMentionChoose() {
        Tracker.post(TeaEvent(Homeric.SETTING_NOTIFICATION_SPECIFIC_MESSAGE_MENTION_CHOOSE))
    }

    /// 在选择了只接收部分新消息通知的基础上，取消勾选了接收@消息并确定
    static func trackSettingNotificationSpecificMessageMentionCancel() {
        Tracker.post(TeaEvent(Homeric.SETTING_NOTIFICATION_SPECIFIC_MESSAGE_MENTION_CANCEL))
    }

    /// 在设置页点击pc端登录手机端关闭通知的按钮
    static func trackSettingPcLoginMuteMobileNotification(status: Bool) {
        Tracker.post(TeaEvent(Homeric.SETTING_PC_LOGIN_MUTE_MOBILE_NOTIFICATION, params: [
            "open_or_close": status ? "y" : "n"
            ])
        )
    }

    /// 在设置页pc端登录手机端关闭通知的选项中，点击了@消息的开关按钮
    static func trackSettingPcLoginMuteMobileNotificationMention(status: Bool) {
        Tracker.post(TeaEvent(Homeric.SETTING_PC_LOGIN_MUTE_MOBILE_NOTIFICATION_MENTION, params: [
            "open_or_close": status ? "y" : "n"
            ])
        )
    }

    static func trackTabMe() {
        Tracker.post(TeaEvent(Homeric.ME_VIEW, category: category))
    }

    static func trackCleanCache() {
        Tracker.post(TeaEvent(Homeric.CLEAN_CACHE, category: "Setting"))
    }

    static func trackPersonalStatusEdit(type: Chatter.DescriptionType) {
        var status_icon = "default"
        switch type {
        case .onLeave:
            status_icon = "leave"
        case .onBusiness:
            status_icon = "ooo"
        case .onDefault:
            status_icon = "default"
        case .onMeeting:
            status_icon = "meeting"
        @unknown default:
            assert(false, "new value")
            break
        }

        Tracker.post(TeaEvent(Homeric.PROFILE_STATUS_EDIT, category: category, params: [
            "status_icon": status_icon
            ])
        )
    }

    static func trackDeleteWorkDay() {
        Tracker.post(TeaEvent(Homeric.DELETE_ONLEAVE_STATUS))
    }

    static func trackIs24HourTime(_ is24HourTime: Bool) {
        Tracker.post(TeaEvent(Homeric.CAL_TIMEFORMAT, params: ["action_type": is24HourTime ? "on" : "off"]))
    }

    /// 点击勿扰模式的入口
    static func trackDndClick() {
        Tracker.post(TeaEvent(Homeric.DND_CLICK))
    }

    /// 打开勿扰模式 单位分钟
    static func trackDndOpen(time: Int) {
        Tracker.post(TeaEvent(Homeric.DND_OPEN, params: ["time": time]))
    }

    /// 手动结束勿扰模式 单位分钟
    static func trackDndClose(remaintime: Int) {
        Tracker.post(TeaEvent(Homeric.DND_CLOSE, params: ["remaintime": remaintime]))
    }

    /// 修改勿扰模式的时间 单位分钟
    static func trackDndAdjust(time: Int) {
        Tracker.post(TeaEvent(Homeric.DND_ADJUST, params: ["time": time]))
    }

    /// 修改自动识别语音
    static func trackAutoAudioToText(enable: Bool) {
        Tracker.post(TeaEvent(Homeric.SET_AUDIO_TO_TEXT, params: ["action": enable ? "open" : "close"]))
    }

    /// 侧边栏点击姓名区域进入个人信息页面
    static func trackEditProfile(click: String, clickField: String, extraParams: [String: String] = [:]) {
        var params: [String: String] = [:]
        params["click"] = click.isEmpty ? "avatar_area" : click
        params["target"] = "setting_personal_information_view"
        params["click_field"] = clickField
        params += extraParams
        Tracker.post(TeaEvent(Homeric.SETTING_MAIN_CLICK, params: params))
    }

    /// 个人信息界面点击姓名行
    static func trackEditNameEntrance(isPermission: Bool) {
        Tracker.post(TeaEvent(Homeric.EDIT_NAME_ENTRANCE, params: ["is_permission": isPermission ? "yes" : "no"]))
    }

    /// 个人信息页面别名展示
    static func trackAnotherNameEntranceView(hasShown: Bool) {
        var hasShownStr = hasShown ? "true" : "false"
        Tracker.post(TeaEvent(Homeric.SETTING_PERSONAL_INFORMATION_VIEW, params: ["is_nickname_field_shown": hasShownStr]))
    }

    /// 个人信息界面点击别名行
    static func trackEditAnotherNameEntrance(isPermission: Bool) {
        var params: [String: String] = [:]
        params["click"] = "nickname"
        params["target"] = isPermission ? "setting_nickname_edit_view" : "none"
        Tracker.post(TeaEvent(Homeric.SETTING_PERSONAL_INFORMATION_CLICK, params: params))
    }

    /// 编辑别名页面展示
    static func trackEditAnotherNameView() {
        Tracker.post(TeaEvent(Homeric.SETTING_NICKNAME_EDIT_VIEW))
    }

    /// 编辑别名点击
    static func trackEditAnotherNameClick(click: String, target: String, nickNameLength: Int, nickNameChanged: Bool) {
        var params: [String: Any] = [:]
        params["click"] = click
        params["target"] = target
        params["nickname_length"] = nickNameLength
        params["is_nickname_changed"] = nickNameChanged ? "true" : "false"
        Tracker.post(TeaEvent(Homeric.SETTING_NICKNAME_EDIT_CLICK, params: params))
    }

    /// 用户点击隐私设置
    static func trackEnterPrivacySetting() {
        Tracker.post(TeaEvent(Homeric.VISITED_PRIVACY_SETTING, params: ["origination": "directly_from_system_settings"]))
    }
    // MARK: - Translate
    /// 翻译-修改翻译语言（在全局设置中）- language语言名称缩写
    static func trackTranslateLanguageSetting(language: String) {
        Tracker.post(TeaEvent(Homeric.TRANSLATE_LANGUAGE_SETTING, params: ["language": language]))
    }

    /// 翻译-修改翻译显示效果（在全局设置中）
    static func trackTranslateEffectSetting(action: TranslateEffectType) {
        Tracker.post(TeaEvent(Homeric.TRANSLATE_EFFECT_SETTING, params: ["action": action.rawValue]))
    }

    /// 翻译-设置特殊语言的翻译效果 - defaultGlobal：用户此时全局的显示效果设置, language语言名称缩写
    static func trackTranslateEffectSpecialSetting(defaultGlobal: TranslateEffectType, language: String, action: TranslateEffectType) {
        Tracker.post(TeaEvent(Homeric.TRANSLATE_EFFECT_SPECIAL_SETTING, params: ["default": defaultGlobal.rawValue, "language": language, "action": action.rawValue]))
    }

    /// 翻译-自动翻译设置（全局总开关修改、子内容开关修改都算，但单独修改各语种的自动翻译开关不算在此埋点内）
    static func trackAutoTranslateSetting(
        action: TranslateActionStatus,
        position: TranslateSettingPositionType,
        object: TranslateSettingObjectType,
        general: TranslateGeneralStatusType? = nil
    ) {
        var params = ["action": action.rawValue, "position": position.rawValue, "object": object.rawValue] as [String: Any]
        if let general = general {
            params["general"] = general.rawValue
        }
        Tracker.post(TeaEvent(Homeric.AUTOTRANSLATE_SETTING, params: params))
    }

    static func trackVCAutoTranslateSetting(isOn: Bool) {
        let params = [
            "click": "vc_chat_translate",
            "location": "lark_setting",
            "setting_tab": "chat",
            "target": "none",
            "is_check": isOn ? "true" : "false"
          ]
        Tracker.post(TeaEvent("vc_meeting_setting_click", params: params))
    }

    /// 翻译-自动翻译开关的特殊设置 - language语言名称缩写
    static func trackAutoTranslateSpecialSetting(object: TranslateSettingObjectType, language: String, action: TranslateActionStatus, defaultValueStatus: TranslateActionStatus) {
        Tracker.post(TeaEvent(
            Homeric.AUTOTRANSLATE_SPECIAL_SETTING,
            params: [
                "object": object.rawValue,
                "language": language,
                "action": action.rawValue,
                "default": defaultValueStatus.rawValue
            ]
        ))
    }

    /// 翻译-自动翻译网页开关
    static func trackWebAutoTranslateSetting(action: TranslateActionStatus, position: TranslateSettingPositionType) {
        Tracker.post(TeaEvent(Homeric.WEB_AUTO_TRANSLATE_SETTING, params: ["action": action.rawValue, "position": position.rawValue]))
    }

    /// 隐私设置 用户进入设置后，点击隐私设置tab
    static func trackSettingPrivacytabClick() {
        Tracker.post(TeaEvent(Homeric.SETTING_PRIVACYTAB_CLICK, params: [:]))
    }

    /// 隐私设置 用户点击“通过以下方式找到我”
    static func trackSettingPrivacytabClick(type: String, enable: Bool) {
        Tracker.post(TeaEvent(Homeric.SETTING_PRIVACY_FINDME_CLICK, params: ["type": type,
                                                                             "enable": enable]))
    }

    /// 隐私设置 用户点击“通过妙记方式找到我”
    static func trackSettingPrivacytabMinutesClick(enable: Bool) {
        Tracker.post(TeaEvent(Homeric.SETTING_DETAIL_CLICK, params: ["click": "minutes_add_friends",
                                                                     "is_on": enable]))
    }

    /// 隐私设置 用户点击“谁能跟我单聊”
    static func trackSettingWhoCanChatWithMe(type: String) {
        Tracker.post(TeaEvent(Homeric.SETTING_PRIVACY_CHAT, params: ["type": type]))
    }

    /// 隐私设置 删除屏蔽名单中的用户
    static func trackSettingPrivacyBlockDelete() {
        Tracker.post(TeaEvent(Homeric.SETTING_PRIVACY_BLOCK_DELETE, params: [:]))
    }

    /// 隐私搜索设置页内点击'查看区别'查看帮助中心文档
    static func trackPrivacyViewDifferenceClick() {
        Tracker.post(TeaEvent(Homeric.PRIVACY_VIEW_DIFFERENCE_CLICK, params: [:]))
    }

    /// 关于飞书 进入“关于飞书”页面
    static func trackSettingAboutFeishuEnter() {
        Tracker.post(TeaEvent(Homeric.SETTING_ABOUT_FEISHU_ENTER))
    }

    /// 关于飞书 点击“检查更新”条目
    static func trackSettingAboutLatestversion() {
        Tracker.post(TeaEvent(Homeric.SETTING_ABOUT_LATESTVERSION))
    }

    /// 关于飞书 点击“更新日志”条目
    static func trackSettingAboutUpdatelog() {
        Tracker.post(TeaEvent(Homeric.SETTING_ABOUT_UPDATELOG))
    }

    /// 关于飞书 点击“特色功能介绍”条目
    static func trackSettingAboutFetures() {
        Tracker.post(TeaEvent(Homeric.SETTING_ABOUT_FEATURES))
    }

    /// 关于飞书 点击“最佳实践”条目
    static func trackSettingAboutBestpract() {
        Tracker.post(TeaEvent(Homeric.SETTING_ABOUT_BESTPRACT))
    }

    /// 关于飞书 点击“用户协议”条目
    static func trackSettingAboutUseragree() {
        Tracker.post(TeaEvent(Homeric.SETTING_ABOUT_USERAGREE))
    }

    /// 关于飞书 点击“隐私政策”条目
    static func trackSettingAboutPrivacypolicy() {
        Tracker.post(TeaEvent(Homeric.SETTING_ABOUT_PRIVACYPOLICY))
    }

    /// 关于飞书 点击“第三方SDK列表”条目
    static func trackSettingAboutSDKList() {
        Tracker.post(TeaEvent(Homeric.SETTING_ABOUT_SDK_LIST))
    }

    /// 关于飞书 点击“安全白皮书”条目
    static func trackSettingAboutWhitePaper() {
        Tracker.post(TeaEvent(Homeric.SETTING_ABOUT_WHITE_PAPER))
    }

    /// 关于飞书 点击“应用权限说明”条目
    static func trackSettingAboutAppPermission() {
        Tracker.post(TeaEvent(Homeric.SETTING_ABOUT_APP_PERMISSION))
    }

    /// 收否支持会话左右侧布局
    static func trackChatAvatarLayout(leftLayout: Bool) {
        Tracker.post(TeaEvent(Homeric.SETTING_DETAIL_CLICK, params: [
            "click": leftLayout ? "msg_left_align" : "msg_leftright_align",
            "target": "none"
        ]))
    }

    /// 隐私页 对方查看手机是否通知我
    static func trackSettingPrivacyNotifyClick(isOn: Bool) {
        Tracker.post(TeaEvent(Homeric.SETTING_DETAIL_CLICK, params: [
            "click": "notify_me_when_checking_my_tel_number",
            "target": "none",
            "is_on": isOn ? "true" : "false"
        ]))
    }

    /// 展示个人信息页
    static func trackPersonalInfoViewShow(params: [String: String]) {
        Tracker.post(TeaEvent(Homeric.SETTING_PERSONAL_INFORMATION_VIEW, params: params))
    }

    /// 点击个人信息页内容
    static func trackPersonalInfoViewClick(params: [String: String]) {
        Tracker.post(TeaEvent(Homeric.SETTING_PERSONAL_INFORMATION_CLICK, params: params))
    }

    // MARK: 勋章相关埋点
    /// 是否有勋章入口「我的勋章」按钮
    static func trackIsMedalWallEntryShown(_ isMedalWallEntryShown: Bool) {
        Tracker.post(TeaEvent(Homeric.SETTING_MAIN_PERSONAL_LINK_VIEW,
                              params: [
                                "is_medal_wall_entry_shown": isMedalWallEntryShown ? "true" : "false"
                              ]))
    }

    /// 是否点击了勋章链接
    static func trackIsMedalOptionClicked() {
        Tracker.post(TeaEvent(Homeric.SETTING_MAIN_PERSONAL_LINK_CLICK,
                              params: [
                                "click": "my_medal",
                                "target": "profile_avatar_medal_wall_view"
                              ]))
    }

    /// 点击网络诊断
    static func trackSettingNetworkCheckClick() {
        Tracker.post(TeaEvent(Homeric.SETTING_DETAIL_CLICK, params: [
            "click": "general_network_check",
            "target": "public_network_check_view"
        ]))
    }

    /// 显示诊断结果
    static func trackNetworkCheckView(trackerParams: [String: String]) {
        Tracker.post(TeaEvent(Homeric.PUBLIC_NETWORK_CHECK_VIEW,
                              params: trackerParams))
    }

    /// 显示诊断结果
    static func trackNetworkCheckPageShowView(trackerParams: [String: String]) {
        Tracker.post(TeaEvent("public_network_check_page_show_view",
                              params: trackerParams))
    }

    //重新诊断
    static func trackNetworkReCheck() {
        var trackerParams: [String: String] = ["click": "re_check", "target": "public_network_check_view"]
        Tracker.post(TeaEvent(Homeric.PUBLIC_NETWORK_CHECK_CLICK,
                              params: trackerParams))
    }

    //保存日志
    static func trackNetworkSaveLog() {
        var trackerParams: [String: String] = ["click": "save", "target": "none"]
        Tracker.post(TeaEvent(Homeric.PUBLIC_NETWORK_CHECK_CLICK,
                              params: trackerParams))
    }

    // 在「通知设置页」点击「通知诊断」
    static func trackClickNotificationDiagnosis() {
        Tracker.post(TeaEvent(Homeric.SETTING_DETAIL_CLICK, params: [
            "click": "notification_issue_test",
            "target": "none"
        ]))
    }

    // 在「通知诊断页」点击「联系客服」
    static func trackClickContactService() {
        Tracker.post(TeaEvent(Homeric.SETTING_DETAIL_CLICK, params: [
            "click": "contact_service",
            "target": "none"
        ]))
    }

    /// 更改铃声
    static func customizeRingtone() {
        Tracker.post(TeaEvent("setting_detail_click", params: ["click": "meeting_ring"]))
    }
}
