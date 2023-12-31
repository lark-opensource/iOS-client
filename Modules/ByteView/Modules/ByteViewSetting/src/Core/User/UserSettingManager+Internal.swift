//
//  UserSettingManager+Internal.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/4/11.
//

import Foundation
import ByteViewCommon

extension UserSettingManager {

    // 控制会中发言，默认为true
    var isChatPermissionEnabled: Bool {
        fg("vc.chat.chat_permission")
    }

    var isDisplayHDModeEnabled: Bool {
        fg("byteview.meeting.hdvideo") && multiResolutionConfig.isHighEndDevice
    }

    var isSubtitleEnabled: Bool {
        adminSettings.enableSubtitle && fg("byteview.asr.subtitle")
    }

    var isSubtitleTranslationEnabled: Bool {
        fg("byteview.vc.subtitle.translation")
    }

    var feedbackConfig: FeedbackConfig {
        settings(for: .vc_feedback_issue_type_config, defaultValue: .default)
    }

    var myAiOnboardingConfig: MyAiOnboardingConfig {
        settings(for: .myai_onboarding_config, defaultValue: .default)
    }

    /// AI 品牌名
    var aiBrandNameConfig: [String: String]? {
        settings(for: .my_ai_brand_name) as? [String: String]
    }

    var isAutoRecordEnabled: Bool {
        fg("admin.vc.setting.auto.record")
    }

    var isVirtualBgEnabled: Bool {
        adminSettings.enableMeetingBackground
    }

    var isAnimojiEnabled: Bool {
        adminSettings.enableVirtualAvatar && fg("byteview.meeting.ios.animoji")
    }

    /// 语音识别设置
    var isVoiceprintRecognitionEnabled: Bool {
        adminSettings.enableVoiceprint && fg("byteview.vc.ios.voiceprint")
    }

    var chatLanguageDisplay: String {
        let setting = self.translateLanguageSetting
        if setting.isAutoTranslationOn, let lang = setting.availableLanguages.first(where: { $0.key == setting.targetLanguage }) {
            return lang.name
        } else {
            return I18n.View_G_NoTranslation_DropMenu
        }
    }

    var isPiPEnabled: Bool {
        fg("byteview.meeting.ios.pip")
    }

    /// 在纪要文档中生成智能会议纪要
    var isMeetingNotesEnabled: Bool {
        fg("byteview.meeting.meetingnotes")
    }

    /// 在会议中使用 AI 对话
    var isChatWithAiEnabled: Bool {
        fg("byteview.vc.my_ai_chat")
    }
}
