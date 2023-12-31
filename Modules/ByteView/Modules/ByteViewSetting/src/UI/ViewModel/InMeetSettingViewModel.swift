//
//  InMeetSettingViewModel.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/3/3.
//

import Foundation
import ByteViewTracker
import ByteViewNetwork
import LarkLocalizations
import ByteViewCommon

public protocol InMeetSettingHandler: AnyObject {
    func didChangeInMeetSetting(_ changeType: InMeetSettingChangeType)
}

public enum InMeetSettingChangeType {
    case hideSelf(Bool)
    case hideNonVideo(Bool)
    case hideReactionBubble(Bool)
    case hideMessageBubble(Bool)
}

public struct InMeetSettingContext {
    public let sessionId: String

    public var supportsHideSelf = false
    public var isHideSelfOn = false

    public var supportsHideNonVideo = false
    public var isHideNonVideoOn = false
    public var isHideNonVideoEnabled = false

    public var isE2EeMeeting = false
    // 通过点击 toast 跳转进入设置页面，用于埋点
    public var isFromToast = false

    public var isHiddenReactionBubble = false
    public var isHiddenMessageBubble = false

    public init(sessionId: String) {
        self.sessionId = sessionId
    }
}

final class InMeetSettingViewModel: GeneralSettingBaseViewModel<InMeetSettingContext> {
    private let handler: InMeetSettingHandler
    private let setting: MeetingSettingManager
    init(setting: MeetingSettingManager, context: InMeetSettingContext, handler: InMeetSettingHandler) {
        self.handler = handler
        self.setting = setting
        super.init(service: setting.service, context: context)
    }

    override func setup() {
        super.setup()
        self.pageId = .inMeetSetting
        self.title = I18n.View_G_Settings
        self.provider = InMeetSettingProvider(setting: setting)
        self.service.refreshVoiceprintStatus()
        self.setting.addInternalListener(self)
        self.setting.addComplexListener(self, for: .subtitlePhraseStatus)
    }

    override func trackPageAppear() {
        super.trackPageAppear()
        VCTracker.post(name: .vc_meeting_setting_view, params: ["setting_tab": "main"])
    }

    override func didBuildSmartMeetingSection(_ builder: SettingSectionBuilder) {
        // 会中设置不展示“智能会议”相关设置
    }

    override func didBuildReactionChatSection(_ builder: SettingSectionBuilder) {
        /// Reaction
        builder.section(header: SettingDisplayHeader(type: .titleHeader,
                                                     title: I18n.View_G_ReactionSettings_Subtitle))
            .switchCell(.reactionSetting, title: I18n.View_G_HideReactions_Desc, isOn: context.isHiddenReactionBubble) { [weak self] context in
                let isOn = context.isOn
                VCTracker.post(name: .vc_meeting_setting_click, params: [.click: "hide_others_reaction", "is_check": isOn, "setting_lab": "general"])
                self?.context.isHiddenReactionBubble = isOn
                self?.handler.didChangeInMeetSetting(.hideReactionBubble(isOn))
            }
            .gotoCell(.reactionDisplayMode, title: I18n.View_G_ReactionDisplay_Desc, accessoryText: service.reactionDisplayMode.title, if: provider.showsReactionDisplayMode, action: { [weak self] context in
                guard let self = self else { return }
                let viewModel = ReactionDisplayModeViewModel(service: context.service, context: self.sourceContext)
                context.push(SettingViewController(viewModel: viewModel))
            })
        /// Chat
        builder
            .section(header: SettingDisplayHeader(type: .titleHeader,
                                                  title: I18n.View_G_ChatSettings_Subtitle),
                     if: provider.showsChatTabSettingsSession)
            .switchCell(.chatSetting, title: I18n.View_G_HideChatBubbles_Desc, isOn: context.isHiddenMessageBubble, action: { [weak self] context in
                let isOn = context.isOn
                VCTracker.post(name: .vc_meeting_setting_click, params: [.click: "hide_all_chat_bubble", "is_check": isOn, "setting_lab": "general"])
                self?.context.isHiddenMessageBubble = isOn
                self?.handler.didChangeInMeetSetting(.hideMessageBubble(isOn))
            })
            .gotoCell(.chatSetting, title: I18n.View_MV_AutoTranslation_Feature, accessoryText: service.chatLanguageDisplay,
                      action: { [weak self] context in
                guard let self = self else { return }
                let viewModel = ChatLanguageViewModel(service: context.service, context: self.sourceContext)
                context.push(SettingViewController(viewModel: viewModel))
            })
    }

    override func didBuildVideoSection(_ builder: SettingSectionBuilder) {
        builder
            .switchCell(.hideSelfParticipant, title: I18n.View_G_HideMe,
                        isOn: context.isHideSelfOn,
                        if: context.supportsHideSelf, action: { [weak self] context in
                self?.context.isHideSelfOn = context.isOn
                self?.handler.didChangeInMeetSetting(.hideSelf(context.isOn))
            })
            .switchCell(.hideNonVideoParticipants, title: I18n.View_G_HideNonVideoParticipants,
                        isOn: context.isHideNonVideoOn, isEnabled: context.isHideNonVideoEnabled,
                        if: context.supportsHideNonVideo, action: { [weak self] context in
                self?.context.isHideNonVideoOn = context.isOn
                self?.handler.didChangeInMeetSetting(.hideNonVideo(context.isOn))
            })
    }

    override func trackUseCellularImproveAudioQuality(_ isOn: Bool) {
        VCTracker.post(name: .vc_meeting_setting_click, params: [
            .click: "cellular_improve_voice", "is_check": isOn, "from_source": context.isFromToast ? "toast" : "normal_setting"
        ])
    }

    override var supportsRotate: Bool {
        true
    }
}

extension InMeetSettingViewModel: MeetingInternalSettingListener, MeetingComplexSettingListener {
    func didChangeMyself(_ settings: MeetingSettingManager, value: Participant, oldValue: Participant?) {
        if oldValue?.settings.subtitleLanguage != value.settings.subtitleLanguage
            || oldValue?.settings.spokenLanguage != value.settings.spokenLanguage {
            reloadData()
        }
    }

    func didChangeComplexSetting(_ settings: MeetingSettingManager, key: MeetingComplexSettingKey, value: Any, oldValue: Any?) {
        reloadData()
    }
}
