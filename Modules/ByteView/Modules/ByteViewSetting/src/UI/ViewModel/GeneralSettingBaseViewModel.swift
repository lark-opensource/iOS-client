//
//  GeneralSettingBaseViewModel.swift
//  ByteViewSetting
//
//  Created by wulv on 2023/3/20.
//

import Foundation
import ByteViewCommon
import UniverseDesignToast
import ByteViewUI
import ByteViewTracker
import ByteViewNetwork

enum SettingSourceContext {
    case generalSetting
    case inMeetSetting

    var supportsRotate: Bool {
        self == .inMeetSetting
    }
}

class GeneralSettingBaseViewModel<Context>: SettingViewModel<Context> {
    lazy var provider: GeneralSettingProvider = GeneralSettingProvider(service: service)

    var sourceContext: SettingSourceContext { self.pageId == .inMeetSetting ? .inMeetSetting : .generalSetting }

    override func setup() {
        super.setup()
        self.observedSettingChanges = [.micSpeakerDisabled, .viewDeviceSetting, .viewUserSetting, .useCellularImproveAudioQuality, .myVoiceprintStatus, .autoHideToolStatusBar, .meetingHDVideo, .pip, .ultrawave, .translateLanguageSetting, .displayFPS, .displayCodec, .needAdjustAnnotate, .userjoinAudioOutputSetting, .reactionDisplayMode]
    }

    // nolint: long_function
    final override func buildSections(builder: SettingSectionBuilder) {
        /// 音频
        let joinAudioType = service.userjoinAudioOutputSetting
        builder
            .section(header: SettingDisplayHeader(type: .titleHeader,
                                                  title: I18n.View_G_Audio))
            .switchCell(.micSpeakerDisabled, title: I18n.View_G_NoMicSpeaker,
                        subtitle: I18n.View_G_EnterMeetingNoMicSpeaker,
                        isOn: provider.isMicSpeakerDisabled,
                        action: { [weak self] context in
                let location = self?.pageId == .inMeetSetting ? "meeting_setting" : "preview"
                VCTracker.post(name: .vc_meeting_setting_click, params: [
                    .click: "ban_mic_speaker", "is_check": context.isOn, .location: location
                ])
                context.service.isMicSpeakerDisabled = context.isOn
            })
            .switchCell(.defaultMicrophoneOn, title: I18n.View_G_DefaultUnmute_Desc,
                        isOn: provider.micCameraSetting.isMicrophoneEnabled,
                        isEnabled: !provider.isMicSpeakerDisabled,
                        action: { [weak self] context in
                VCTracker.post(name: self?.pageId == .inMeetSetting ? .vc_meeting_setting_click : .setting_meeting_click,
                               params: [.click: "mic_on_when_join", "is_check": context.isOn])
                let oldSetting = context.service.micCameraSetting
                context.service.micCameraSetting = MicCameraSetting(isMicrophoneEnabled: context.isOn, isCameraEnabled: oldSetting.isCameraEnabled)
            })
            .longGotoCell(.audioOutputDevice, title: I18n.View_G_DefaultAudioUse_Subtitle,
                      subtitle: I18n.View_G_DefaultAudioUse_Desc,
                      accessoryText: joinAudioType.text,
                      if: Display.phone && provider.showsUserjoinAudioOutputSetting,
                      action: { context in
                let vm = JoinAudioOutputSettingViewModel(service: context.service, context: self.sourceContext)
                context.push(SettingViewController(viewModel: vm))
            })

        builder
            .section(header: SettingDisplayHeader(type: .titleHeader,
                                                  title: I18n.View_G_Video))
            .switchCell(.defaultCameraOn, title: I18n.View_G_DefaultCameraOn_Desc,
                        isOn: provider.micCameraSetting.isCameraEnabled,
                        action: { [weak self] context in
                VCTracker.post(name: self?.pageId == .inMeetSetting ? .vc_meeting_setting_click : .setting_meeting_click,
                               params: [.click: "cam_on_when_join", "is_check": context.isOn])
                let oldSetting = context.service.micCameraSetting
                context.service.micCameraSetting = MicCameraSetting(isMicrophoneEnabled: oldSetting.isMicrophoneEnabled, isCameraEnabled: context.isOn)
            })
            .switchCell(.mirrorVideo, title: I18n.View_G_VideoMirroring,
                        isOn: provider.isVideoMirroed,
                        isEnabled: provider.enableVideoMirror,
                        if: provider.showsVideoSetting,
                        action: { context in
                VCTracker.post(name: .vc_meeting_video_setting, params: [
                    .from_source: "vc_main_settings", .action_name: "click_mirror", "action_enable": context.isOn ? 1 : 0
                ])
                VCTracker.post(name: .vc_meeting_setting_click, params: [
                    .click: "is_mirror", "is_check": context.isOn, "setting_tab": "setting"
                ])
                context.service.updateViewUserSetting({ $0.isMirror = context.isOn })
            })
            .switchCell(.highResolution, title: I18n.View_G_HDQuality, subtitle: I18n.View_G_HDQualityCost,
                        isOn: service.isHDModeEnabled, if: provider.showsHDMode && provider.showsVideoSetting,
                        action: { [weak self] context in
                VCTracker.post(name: .vc_meeting_setting_click, params: [
                    .click: "is_high_resolution", "is_check": context.isOn, "is_meeting": self?.pageId == .inMeetSetting
                ])
                context.service.isHDModeEnabled = context.isOn
            })
            .switchCell(.centerStage, title: I18n.View_G_CenterStage, subtitle: I18n.View_G_OnlyFrontCamera,
                        isOn: service.centerStage.hasOpened, if: service.centerStage.canUse && provider.showsVideoSetting,
                        action: { context in
                VCTracker.post(name: .vc_meeting_setting_click, params: [.click: "center_stage", "is_check": context.isOn])
                if context.isOn {
                    context.service.centerStage.start()
                } else {
                    context.service.centerStage.stop()
                }
            })
            .switchCell(.pip, title: I18n.View_MV_ShowFloatOutApp, subtitle: I18n.View_MV_EnablePIPSystem,
                        isOn: service.isPIPPreferred, if: PIPCapability.isMultiTaskingCameraAccessEnabled && provider.showsPiPOption,
                        action: { context in
                VCTracker.post(name: .vc_meeting_setting_click, params: [
                    .click: "enable_picture_in_picture", "is_check": context.isOn, "non_pc_type": Display.pad ? "ios_pad" : "ios_mobile"
                ])
                context.service.isPIPPreferred = context.isOn
            })
        didBuildVideoSection(builder)

        builder
            .section(header: SettingDisplayHeader(type: .titleHeader,
                                                  title: I18n.View_G_DataMode_NoColon),
                     if: provider.showEcoMode)
            .checkmark(.dataModeStandard,
                       title: I18n.View_G_DataMode_Standard_NoColon,
                       subtitle: I18n.View_G_AllowNormalQualityVideo_Tooltip,
                       isOn: provider.dataMode == .standardMode,
                       action: { [weak self] _ in
                guard self?.provider.dataMode != .standardMode else { return }
                VCTracker.post(name: .vc_meeting_setting_click, params: [
                    .click: "energy_and_performance_data_mode", .option: "normal"
                ])
                self?.provider.updateDataMode(.standardMode)
                self?.reloadData()
            })
            .checkmark(.dataModeEco,
                       title: I18n.View_G_DataMode_PowerSaving_NoColon,
                       subtitle: I18n.View_G_Setting_LowPowerMode_Tip,
                       isOn: provider.dataMode == .ecoMode,
                       action: { [weak self] _ in
                guard self?.provider.dataMode != .ecoMode else { return }
                VCTracker.post(name: .vc_meeting_setting_click, params: [
                    .click: "energy_and_performance_data_mode", .option: "lower_quality"
                ])
                self?.provider.updateDataMode(.ecoMode)
                self?.reloadData()
            })
            .checkmark(.dataModeVoice,
                       title: I18n.View_G_DataMode_AudioOnly_NoColon,
                       subtitle: I18n.View_G_AudioModeExplain,
                       isOn: provider.dataMode == .voiceMode,
                       action: { [weak self] _ in
                guard self?.provider.dataMode != .voiceMode else { return }
                VCTracker.post(name: .vc_meeting_setting_click, params: [
                    .click: "energy_and_performance_data_mode", .option: "audio_sharing_only"
                ])
                self?.provider.updateDataMode(.voiceMode)
                self?.reloadData()
            })


        let isAutoRecordEnabled = service.isAutoRecordEnabled
        let recordCompliancePopup = service.viewUserSetting.meetingAdvanced.recording.recordCompliancePopup
        let recordComplianceVoicePrompt = service.viewUserSetting.meetingAdvanced.recording.recordComplianceVoicePrompt

        /// 会前录制
        builder
            .section(header: SettingDisplayHeader(type: .titleHeader,
                                                  title: I18n.View_G_Recording_Title),
                     if: provider.showsRecordSection)
            .switchCell(.groupMeetingAutoRecord,
                        title: I18n.View_G_AutomaticMeetingRecording_PersonalSettingTitle,
                        subtitle: I18n.View_G_AutomaticMeetingRecording_PersonalSettingTitleExplain,
                        isOn: service.viewUserSetting.meetingAdvanced.recording.groupMeetingAutoRecord,
                        if: isAutoRecordEnabled, action: { context in
                VCTracker.post(name: .setting_meeting_click, params: [.click: "auto_meeting_record", "is_check": context.isOn])
                context.service.updateViewUserSetting { $0.groupMeetingAutoRecord = context.isOn }
            })
            .switchCell(.singleMeetingAutoRecord,
                        title: I18n.View_G_AudioVideoAutomaticRecording_PersonalSettingTitle,
                        subtitle: I18n.View_G_AudioVideoAutomaticRecording_PersonalSettingTitleExplain,
                        isOn: service.viewUserSetting.meetingAdvanced.recording.singleMeetingAutoRecord,
                        if: isAutoRecordEnabled, action: { context in
                VCTracker.post(name: .setting_meeting_click, params: [.click: "auto_call_record", "is_check": context.isOn])
                context.service.updateViewUserSetting { $0.singleMeetingAutoRecord = context.isOn }
            })
            .switchCell(.recordCompliancePopup,
                        title: I18n.View_G_ReceivePopUpRemindBoth,
                        isOn: recordCompliancePopup.optionalValue,
                        isEnabled: recordCompliancePopup.displayStatus == .normal, showsDisabledButton: true,
                        if: recordCompliancePopup.displayStatus != .hidden, action: { context in
                VCTracker.post(name: .setting_detail_click, params: [.click: "accept_record_remind", "is_on": context.isOn])
                if context.row.isEnabled {
                    context.service.updateViewUserSetting { $0.recordCompliancePopup = context.isOn }
                } else {
                    // recordCompliancePopupStatus为disable的状态，需要置灰并且点击需要弹窗提示。
                    ByteViewDialog.Builder()
                        .id(.closeRecordingReminder)
                        .title(I18n.View_G_MeetRecordRemindBox)
                        .message(I18n.View_G_OrgOnRecordRemindContact)
                        .rightTitle(I18n.View_G_OkButton)
                        .show()
                }
            })
            .switchCell(.recordComplianceVoicePrompt, title: I18n.View_G_AlsoPlayAudioRemind,
                        isOn: recordComplianceVoicePrompt.optionalValue,
                        isEnabled: recordComplianceVoicePrompt.displayStatus == .normal,
                        if: recordCompliancePopup.optionalValue && recordComplianceVoicePrompt.displayStatus != .hidden,
                        action: { context in
                VCTracker.post(name: .setting_detail_click, params: [.click: "play_voice_remind", "is_on": context.isOn])
                context.service.updateViewUserSetting { $0.recordComplianceVoicePrompt = context.isOn }
            })
            .gotoCell(.recordLayoutType, title: I18n.View_G_DefaultRecordLayoutTitle,
                      accessoryText: service.viewUserSetting.meetingAdvanced.recording.recordLayoutType.title,
                      action: { context in
                context.push(RecordLayoutSettingViewController(service: context.service))
            })
            .switchCell(.hideCamMutedParticipantInRecording, title: I18n.View_G_RecordHideNonVideo,
                        subtitle: I18n.View_G_RecordHideNonVideoExplain,
                        isOn: service.viewUserSetting.meetingAdvanced.recording.hideCamMutedParticipant,
                        action: { context in
                context.service.updateViewUserSetting { $0.hideCamMutedParticipant = context.isOn }
            })

        /// 智能会议
        didBuildSmartMeetingSection(builder)

        /// 字幕
        builder
            .section(header: SettingDisplayHeader(type: .titleHeader,
                                                  title: I18n.View_M_Subtitles),
                     if: provider.showsSubtitleSection)
            .switchCell(.turnOnSubtitleWhenJoin, title: I18n.View_G_TurningOnSubtitlesJoinMeeting,
                        isOn: service.viewUserSetting.meetingAdvanced.subtitle.turnOnSubtitleWhenJoin,
                        if: provider.showsTurnOnSubtitleWhenJoin,
                        action: { context in
                VCTracker.post(name: .vc_meeting_page_setting, params: [
                    .from_source: "lark_setting", .action_name: "subtitle",
                    .extend_value: ["action_enabled": context.isOn ? "1" : "0"]
                ])
                VCTracker.post(name: .setting_meeting_click, params: [.click: "join_subtitle", "is_check": context.isOn])
                context.service.updateViewUserSetting { $0.turnOnSubtitleWhenJoin = context.isOn }
            })
            .gotoCell(.spokenLanguage, title: I18n.View_G_SpokenLanguage, accessoryText: provider.subtitle.spokenLanguage?.desc,
                      if: provider.showsSpokenLanguage, action: { [weak self] context in
                guard let self = self else { return }
                let subtitleContext = SubtitleLanguageContext(supportsRotate: self.supportsRotate, languageType: .spokenLanguage)
                let vm = SubtitleLanguageViewModel(service: context.service, context: subtitleContext)
                context.push(SettingViewController(viewModel: vm))
            })
            .gotoCell(.subtitleLanguage, title: I18n.View_MV_TranslationLanguageInto,
                      accessoryText: self.provider.subtitle.subtitleLanguage.desc,
                      isEnabled: provider.subtitle.isSubtitleTranslationEnabled,
                      action: { [weak self] context in
                guard let self = self else { return }
                let subtitleContext = SubtitleLanguageContext(supportsRotate: self.supportsRotate, languageType: .subtitleLanguage)
                let vm = SubtitleLanguageViewModel(service: context.service, context: subtitleContext)
                context.push(SettingViewController(viewModel: vm))
            })
            .switchCell(.subtitlePhrase, title: I18n.View_G_SmartAnnotation_Tick, subtitle: I18n.View_G_ExplainSmartAnnotation,
                        isOn: provider.subtitle.isSubtitlePhraseOn, isEnabled: provider.subtitle.isSubtitlePhraseEnabled,
                        showsDisabledButton: true, if: provider.showsSubtitlePhrase, action: { [weak self] context in
                self?.provider.subtitle.updateSubtitlePhrase(isOn: context.isOn, context: context)
            })


        didBuildReactionChatSection(builder)

        /// 通用
        builder
            .section(header: SettingDisplayHeader(type: .titleHeader,
                                                  title: I18n.View_G_GeneralText))
            .switchCell(.calendarMeetingStartNotify, title: I18n.View_M_MeetingNotificationNew,
                        isOn: service.viewUserSetting.meetingGeneral.calendarMeetingStartNotify,
                        if: provider.showsCalendarMeetingStartNotify,
                        action: { context in
                VCTracker.post(name: .vc_meeting_page_setting, params: [
                    .from_source: "lark_setting", .action_name: "calendar_remind",
                    .extend_value: ["action_enabled": context.isOn ? "1" : "0"]
                ])
                VCTracker.post(name: .setting_meeting_click, params: [.click: "start_remind", "is_check": context.isOn])
                context.service.updateViewUserSetting { $0.calendarMeetingStartNotify = context.isOn }
            })
            .switchCell(.playEnterExitChimes, title: I18n.View_M_PlayChimes,
                        isOn: service.viewUserSetting.meetingGeneral.playEnterExitChimes,
                        action: { [weak self] context in
                VCTracker.post(name: .vc_meeting_page_setting, params: [
                    .from_source: "lark_setting", .action_name: "attendee_remind",
                    .extend_value: ["action_enabled": context.isOn ? "1" : "0"]
                ])
                VCTracker.post(name: .setting_meeting_click, params: [.click: "join_out_tone", "is_check": context.isOn])
                self?.provider.updatePlayEnterExitChimes(context.isOn)
            })
            .gotoCell(.missedCallReminder, title: I18n.View_MV_UnanswerMeetingNotice,
                      accessoryText: service.viewUserSetting.meetingAdvanced.missedCallReminder.reminder == .bot ? I18n.View_MV_UnanswerMeetingBotNote : I18n.View_MV_Unanswer_MenuRedDot,
                      action: { context in
                VCTracker.post(name: .setting_meeting_click, params: [
                    .click: "missed_call_alert", .target: TrackEventName.setting_meeting_missed_call_view
                ])
                context.push(MissedCallReminderSettingViewController(service: context.service))
            })
            .switchCell(.keyboardMute, title: I18n.View_G_SpacebarMute_FollowSettingTitle,
                        isOn: service.isKeyboardMuteEnabled, if: provider.showsKeyboardMute,
                        action: { context in
                VCTracker.post(name: .vc_meeting_setting_click, params: [
                    .click: "space_open_mic", "is_check": context.isOn, "setting_tab": "voice"
                ])
                context.service.isKeyboardMuteEnabled = context.isOn
            })
            .switchCell(.enableSelfAsActiveSpeaker,
                        title: I18n.View_G_MyselfasActiveSpeaker_Desc,
                        isOn: service.viewUserSetting.meetingGeneral.enableSelfAsActiveSpeaker,
                        action: { [weak self] context in
                VCTracker.post(name: .vc_meeting_setting_click, params: [.click: "see_myself_active_speaker", "is_check": context.isOn])
                self?.provider.updateEnableSelfAsActiveSpeaker(context.isOn)
            })
            .switchCell(.autoHideToolbar, title: I18n.View_G_AutoHideToolbar,
                        subtitle: I18n.View_G_AutoHideToolbarExplain,
                        isOn: service.autoHideToolStatusBar, action: { context in
                VCTracker.post(name: .vc_meeting_setting_click, params: [.click: "auto_hide_toolbar", "is_check": context.isOn])
                context.service.autoHideToolStatusBar = context.isOn
            })
            .switchCell(.dataModeVoice, title: I18n.View_G_AudioMode, subtitle: I18n.View_G_AudioModeExplain,
                        isOn: provider.dataMode == .voiceMode, if: provider.showsVoiceMode && !provider.showEcoMode, action: { [weak self] context in
                VCTracker.post(name: .vc_meeting_setting_click, params: [
                    .click: "energy_and_performance_data_mode", .option: context.isOn ? "audio_sharing_only" : "normal"
                ])
                self?.provider.updateDataMode(context.isOn ? .voiceMode : .standardMode)
                self?.reloadData()
            })
            .switchCell(.ultrasonicConnection, title: I18n.View_G_UseUltrasonicToConnectOrShare_Desc,
                        subtitle: I18n.View_G_UseUltrasonicToConnectOrShare_Tooltip(deviceType: UIDevice.current.name),
                        isOn: service.isUltrawaveEnabled, autoJump: autoJumpCell == .ultrasonicConnection, if: !provider.isE2EeMeeting,
                        action: { context in
                VCTracker.post(name: .vc_meeting_setting_click, params: [
                    .click: "use_ultrasonic", "is_check": context.isOn, "setting_tab": "general"
                ])
                context.service.isUltrawaveEnabled = context.isOn
            })
            .switchCell(.useCellularImproveAudioQuality, title: I18n.View_MV_CellularForAudio, subtitle: I18n.View_MV_SwitchToCellular,
                        isOn: service.useCellularImproveAudioQuality, if: Display.phone,
                        action: { [weak self] context in
                self?.trackUseCellularImproveAudioQuality(context.isOn)
                context.service.useCellularImproveAudioQuality = context.isOn
            })
            .switchCell(.adjustAnnotate, title: I18n.View_G_AutocorrectAnnotation, subtitle: I18n.View_G_AutoCorrectNote, isOn: service.needAdjustAnnotate, action: { context in
                context.service.needAdjustAnnotate = context.isOn
            })

        /// 声纹识别
        let isVoiceEnrolled = service.myVoiceprintStatus == .enrolled
        builder
            .section(if: service.isVoiceprintRecognitionEnabled && !provider.isE2EeMeeting)
            .switchCell(.enableVoiceprintRecognition, title: I18n.View_G_VoiceprintRecognition,
                        subtitle: I18n.View_G_VoiceprintRecognitionExplain,
                        isOn: service.viewUserSetting.audio.enableVoiceprintRecognition,
                        action: { [weak self] context in
                if context.isOn {
                    self?.handleVoiceprintOn(context)
                } else {
                    self?.handleVoiceprintOff(context)
                }
            })
            .gotoCell(.myVoiceprint, title: I18n.View_G_MyVoiceprint,
                      subtitle: isVoiceEnrolled ? I18n.View_G_YesVoiceprint : I18n.View_G_NoVoiceprintWillCollect,
                      accessoryText: isVoiceEnrolled ? I18n.View_ClearVoiceprint : nil,
                      isEnabled: service.myVoiceprintStatus != .none,
                      if: service.viewUserSetting.audio.enableVoiceprintRecognition,
                      action: { [weak self] context in
                self?.handleClearVoiceprint(context)
            })

            .section(if: provider.showsAdvancedDebugSection)
            .switchCell(.displayFPS, title: I18n.View_G_DisplayVideoResolution,
                        isOn: service.displayFPS, action: { context in
                context.service.displayFPS = context.isOn
            })
            .switchCell(.displayCodec, title: I18n.View_G_DisplayCodecInfo,
                        isOn: service.displayCodec, action: { context in
                context.service.displayCodec = context.isOn
            })

            .section(if: !service.isPrivateKA)
            .gotoCell(.feedback, title: I18n.View_G_SliderMenuFeedback, action: { [weak self] context in
                guard let self = self else { return }
                let viewModel = FeedbackViewModel(service: context.service, context: self.sourceContext)
                context.push(SettingViewController(viewModel: viewModel))
            })
    }

    /// 智能会议（纪要+AI）
    func didBuildSmartMeetingSection(_ builder: SettingSectionBuilder) {
        let isGenerateAISummaryInMinutesEnabled = service.viewUserSetting.meetingAdvanced.intelligentMeetingSetting.generateMeetingSummaryInMinutes.isValid
        let isGenerateAISummaryInDocsEnabled = isGenerateAISummaryInMinutesEnabled && service.isMeetingNotesEnabled
        let isChatWithAIInMeetingEnabled = service.isChatWithAiEnabled
        let isSmartMeetingSectionDisplayEnabled = provider.showsSmartNotesSection && (isGenerateAISummaryInMinutesEnabled || isGenerateAISummaryInDocsEnabled || isChatWithAIInMeetingEnabled)
        builder
            .section(header: SettingDisplayHeader(type: .titleHeader,
                                                  title: I18n.View_G_SmartMeeting_Tab),
                     footer: SettingDisplayFooter(type: .redirectDescriptionFooter,
                                                  description: I18n.View_G_AIMinutesNewAgain_Desc,
                                                  serviceTerms: provider.myAiOnboardingServiceTerms),
                     if: isSmartMeetingSectionDisplayEnabled)
            .switchCell(.generateAiSummaryInMinutes,
                        title: I18n.View_G_UseAINotesInMinutes_Desc,
                        isOn: service.viewUserSetting.meetingAdvanced.intelligentMeetingSetting.generateMeetingSummaryInMinutes.isOn,
                        if: isGenerateAISummaryInMinutesEnabled,
                        action: { context in
                context.service.updateViewUserSetting { $0.generateMeetingSummaryInMinutes = context.isOn ? .featureStatusOn : .featureStatusOff }
            })
            .switchCell(.generateAiSummaryInNotes,
                        title: I18n.View_G_UseAINotesInDocs_Desc,
                        isOn: service.viewUserSetting.meetingAdvanced.intelligentMeetingSetting.generateMeetingSummaryInDocs.isOn,
                        if: isGenerateAISummaryInDocsEnabled,
                        action: { context in
                context.service.updateViewUserSetting { $0.generateMeetingSummaryInDocs = context.isOn ? .featureStatusOn : .featureStatusOff }
            })
            .switchCell(.chatWithAiInMeet,
                        title: I18n.View_G_UseAIDuringMeetings_Desc,
                        isOn: service.viewUserSetting.meetingAdvanced.intelligentMeetingSetting.chatWithAiInMeeting.isOn,
                        if: isChatWithAIInMeetingEnabled,
                        action: { context in
                context.service.updateViewUserSetting { $0.chatWithAiInMeeting = context.isOn ? .featureStatusOn : .featureStatusOff }
            })
    }

    func didBuildReactionChatSection(_ builder: SettingSectionBuilder) {
        // Reaction
        builder
            .section(header: SettingDisplayHeader(type: .titleHeader,
                                                  title: I18n.View_G_ReactionSettings_Subtitle))
            .gotoCell(.reactionDisplayMode, title: I18n.View_G_ReactionDisplay_Desc, accessoryText: service.reactionDisplayMode.title, if: provider.showsReactionDisplayMode, action: { [weak self] context in
                guard let self = self else { return }
                let viewModel = ReactionDisplayModeViewModel(service: context.service, context: self.sourceContext)
                context.push(SettingViewController(viewModel: viewModel))
            })

        // Chat
        builder
            .section(header: SettingDisplayHeader(type: .titleHeader,
                                                  title: I18n.View_G_ChatTab_MoreSettings),
                     if: provider.showsChatTabSettingsSession)
            .gotoCell(.chatSetting, title: I18n.View_MV_AutoTranslation_Feature, accessoryText: service.chatLanguageDisplay,
                      action: { [weak self] context in
                guard let self = self else { return }
                let viewModel = ChatLanguageViewModel(service: context.service, context: self.sourceContext)
                context.push(SettingViewController(viewModel: viewModel))
            })
    }

    func didBuildVideoSection(_ builder: SettingSectionBuilder) {}

    func handleVoiceprintOn(_ context: SettingRowActionContext) {
        let linkText = LinkTextParser.parsedLinkText(from: I18n.View_G_NotePrivacyExplain)
        let urls = provider.privateStatementURL
        ByteViewDialog.Builder()
            .id(.voiceprint)
            .title(I18n.View_VM_NotificationDefault)
            .linkText(linkText, alignment: .center, handler: { _, _ in
                guard urls.count > 0, let urlString = urls.first, !urlString.isEmpty, let url = URL(string: urlString) else {
                    return
                }
                context.reloadRow()
                ByteViewDialogManager.shared.dismiss(ids: [.voiceprint])
                context.push(url: url)
            })
            .leftTitle(I18n.View_G_CancelButton)
            .leftHandler({ _ in
                context.reloadRow()
            })
            .rightTitle(I18n.View_G_AgreeEnable)
            .rightHandler({ _ in
                context.service.updateViewUserSetting { $0.canOpenVoidprintRecognition = true }
                context.service.refreshVoiceprintStatus()
                VCTracker.post(name: .vc_meeting_setting_click, params: [
                    .click: "voiceprint", "is_check": true, "target": "none"
                ])
            })
            .needAutoDismiss(false)
            .show()
    }

    func handleVoiceprintOff(_ context: SettingRowActionContext) {
        ByteViewDialog.Builder()
            .colorTheme(.redLight)
            .message(I18n.View_G_ConfirmVoiceprintOffExplain)
            .leftTitle(I18n.View_G_CancelButton)
            .leftHandler({ _ in
                context.reloadRow()
            })
            .rightTitle(I18n.View_G_TurnOffButton)
            .rightHandler({ _ in
                context.service.updateViewUserSetting { $0.canOpenVoidprintRecognition = false }
                VCTracker.post(name: .vc_meeting_setting_click, params: [
                    .click: "voiceprint", "is_check": false, "target": "none"
                ])
            })
            .needAutoDismiss(false)
            .show()
    }

    func handleClearVoiceprint(_ context: SettingRowActionContext) {
        let from = context.from
        let service = context.service
        ByteViewDialog.Builder()
            .colorTheme(.followSystem)
            .message(I18n.View_G_ConfirmVoiceprintClear)
            .leftTitle(I18n.View_G_CancelButton)
            .rightTitle(I18n.View_G_ConfirmButton)
            .rightHandler({ [weak from, weak service] _ in
                guard let from = from, let service = service else { return }
                let toast = UDToast.showLoading(with: I18n.View_VM_Loading, on: from.view, disableUserInteraction: false)
                service.clearVoiceprint { [weak from] result in
                    toast.remove()
                    if let from = from, case .failure(let error) = result {
                        let errorMsg = error.localizedDescription
                        if !errorMsg.isEmpty {
                            UDToast.showTips(with: errorMsg, on: from.view)
                        }
                    }
                }
            })
            .needAutoDismiss(false)
            .show()
    }

    func trackUseCellularImproveAudioQuality(_ isOn: Bool) {
        VCTracker.post(name: .setting_meeting_click, params: [
            .click: "cellular_improve_voice", "is_check": isOn
        ])
    }
}

/// 通用设置在无会中会议时的provider
class GeneralSettingProvider {
    let service: UserSettingManager
    var subtitle: GeneralSubtitleProvider
    init(service: UserSettingManager, subtitle: GeneralSubtitleProvider? = nil) {
        self.service = service
        if let subtitle = subtitle {
            self.subtitle = subtitle
        } else {
            self.subtitle = GeneralSubtitleProvider(service: service)
        }
    }

    var isMicSpeakerDisabled: Bool { service.isMicSpeakerDisabled }

    var micCameraSetting: MicCameraSetting { service.micCameraSetting }

    var showsVideoSetting: Bool { true }
    var enableVideoMirror: Bool { true }
    var isVideoMirroed: Bool { service.viewDeviceSetting.video.mirror }
    var showsHDMode: Bool { service.isDisplayHDModeEnabled }

    var showsRecordSection: Bool { service.adminSettings.enableRecord }
    var showsSubtitleSection: Bool { service.isSubtitleEnabled && service.suiteQuota().subtitle }
    var showsSmartNotesSection: Bool { service.adminSettings.enableRecordAiSummary }
    var showsChatTabSettingsSession: Bool { true }
    var showsTurnOnSubtitleWhenJoin: Bool { true }
    var showsSpokenLanguage: Bool { false }
    var showsSubtitlePhrase: Bool { false }
    var showsReactionDisplayMode: Bool { service.floatReactionConfig.isEnabled }

    var showsPiPOption: Bool { service.isPiPEnabled }

    var showsUserjoinAudioOutputSetting: Bool { true }

    var showsKeyboardMute: Bool { false }
    var showsCalendarMeetingStartNotify: Bool { true }

    var showsVoiceMode: Bool { false }

    var showEcoMode: Bool { false }

    var dataMode: DataMode { .standardMode }

    var isE2EeMeeting: Bool { false }

    var privateStatementURL: [String] { service.domain(for: .vcPrivacySoundUrl) }

    var myAiOnboardingServiceTerms: String { service.myAiOnboardingConfig.serviceTerms }
    var showsAdvancedDebugSection: Bool { false }

    func updatePlayEnterExitChimes(_ isOn: Bool) {
        service.updateViewUserSetting { $0.playEnterExitChimes = isOn }
    }

    func updateEnableSelfAsActiveSpeaker(_ isOn: Bool) {
        service.updateViewUserSetting { $0.enableSelfAsActiveSpeaker = isOn }
    }

    func updateDataMode(_ dataMode: DataMode) {}
}

/// 通用设置在有会中会议时的provider
class InMeetGeneralSettingProvider: GeneralSettingProvider {
    let setting: MeetingSettingManager
    init(setting: MeetingSettingManager) {
        self.setting = setting
        super.init(service: setting.service, subtitle: InMeetSubtitleProvider(setting: setting))
    }

    override var enableVideoMirror: Bool { setting.isFrontCameraEnabled }
    override var showsHDMode: Bool { setting.fg.isHDModeEnabled && setting.multiResolutionConfig.isHighEndDevice}
    override var showsSubtitleSection: Bool { setting.showsSubtitleSetting }
    override var showsUserjoinAudioOutputSetting: Bool { false }

    override func updatePlayEnterExitChimes(_ isOn: Bool) {
        super.updatePlayEnterExitChimes(isOn)
        setting.updateParticipantSettings { $0.participantSettings.playEnterExitChimes = isOn }
    }
}

/// 会中设置的provider
class InMeetSettingProvider: InMeetGeneralSettingProvider {
    override var showsVideoSetting: Bool { !setting.isWebinarAttendee }
    override var showsSubtitleSection: Bool { !setting.isInBreakoutRoom && setting.showsSubtitleSetting && !setting.isE2EeMeeting }
    override var showsChatTabSettingsSession: Bool { !setting.isE2EeMeeting }
    override var showsTurnOnSubtitleWhenJoin: Bool { false }
    override var showsSpokenLanguage: Bool { !setting.fg.subtitleDeleteSpokenLanguage && !subtitle.spokenLanguageKey.isEmpty }
    override var showsRecordSection: Bool { false }
    override var showsKeyboardMute: Bool { setting.supportsKeyboardMute }
    override var showsSubtitlePhrase: Bool {
        switch setting.subtitlePhraseStatus {
        case .unknown, .unavailable:
            return false
        case .disabled, .on, .off:
            return true
        }
    }

    override var showsCalendarMeetingStartNotify: Bool { false }
    override var showsVoiceMode: Bool { true }
    override var showsAdvancedDebugSection: Bool { setting.isAdvancedDebugOptionsEnabled }

    override var showEcoMode: Bool { setting.isEcoModeEnabled }
    override var dataMode: DataMode { setting.dataMode }

    override var isE2EeMeeting: Bool { setting.isE2EeMeeting }

    override func updateDataMode(_ dataMode: DataMode) {
        setting.updateSettings { $0.dataMode = dataMode }
    }
}
