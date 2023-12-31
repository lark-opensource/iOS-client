//
//  InMeetSecurityViewModel.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/4/28.
//

import Foundation
import ByteViewCommon
import ByteViewTracker
import ByteViewNetwork
import ByteViewUI
import UniverseDesignTheme
import UniverseDesignColor

public protocol InMeetSecurityListener: AnyObject {
    func didChangeParticipantNum(_ participantNum: Int)
}

public protocol InMeetSecurityContext {
    var fromSource: InMeetSecurityFromSource { get }
    var participantNum: Int { get }
    var isMySharingScreen: Bool { get }

    func addListener(_ listener: InMeetSecurityListener)
}

public enum InMeetSecurityFromSource: String {
    case tips
    case toolbar
    case participant
}

final class InMeetSecurityViewModel: SettingViewModel<InMeetSecurityContext> {
    private typealias SecurityLevel = VideoChatSettings.SecuritySetting.SecurityLevel

    private let setting: MeetingSettingManager
    private var videoChatSettings: VideoChatSettings { setting.videoChatSettings }
    private var manageCapabilities: VideoChatSettings.ManageCapabilities { setting.manageCapabilities }
    private var securitySetting: VideoChatSettings.SecuritySetting { videoChatSettings.securitySetting }
    /// 会议维度的智能会议设置
    private var intelligentMeetingSetting: IntelligentMeetingSetting { videoChatSettings.intelligentMeetingSetting }
    var fromSource: InMeetSecurityFromSource { context.fromSource }
    @RwAtomic private var showsSuggest: Bool = false
    @RwAtomic private var participantNum: Int = 1
    private lazy var securityRequestor = InMeetSecurityRequestor(setting: setting)

    init(setting: MeetingSettingManager, context: InMeetSecurityContext) {
        self.setting = setting
        super.init(service: setting.service, context: context)
    }

    override func setup() {
        super.setup()
        self.title = fromSource.title
        self.supportedCellTypes.insert(.upgradableSwitchCell)
        self.participantNum = context.participantNum
        updateShowsSuggest(shouldReloadData: false)
        securityRequestor.delegate = self
        setting.addInternalListener(self)
        setting.addListener(self, for: .hasCohostAuthority)
        context.addListener(self)
    }

    override func trackPageAppear() {
        super.trackPageAppear()
        VCTracker.post(name: .vc_meeting_hostpanel_view, params: [.from_source: fromSource.trackName])
    }

    override var supportsRotate: Bool { true }

    // nolint: long_function
    override func buildSections(builder: SettingSectionBuilder) {
        let isLocked = securitySetting.isLocked

        builder.section(footer: SettingDisplayFooter(type: .descriptionFooter,
                                                     description: I18n.View_MV_OnlyHostInviteCanJoin))
            .switchCell(.lockMeeting, title: I18n.View_MV_LockMeeting,
                        isOn: isLocked) { [weak self] context in
                guard let self = self else { return }
                self.trackClickSwitch("lock_meeting", isOn: context.isOn, extraParams: ["is_wait_lobby_open": self.securitySetting.isOpenLobby])
                self.setting.updateLockMeeting(context.isOn)
            }

        var selectedLevel = securitySetting.securityLevel
        var eventSelected = securitySetting.specialGroupType.contains(.calendarGuestList)
        if isLocked, let last = videoChatSettings.lastSecuritySetting {
            self.securityRequestor.updateSecuritySetting(last)
            selectedLevel = last.securityLevel
            eventSelected = last.specialGroupType.contains(.calendarGuestList)
        } else {
            self.securityRequestor.updateSecuritySetting(securitySetting)
        }
        var securityUserDescs: [String] = []
        if selectedLevel == .contactsAndGroup {
            if eventSelected {
                securityUserDescs.append(I18n.View_G_EventGuests)
            }
            securityUserDescs.append(contentsOf: self.securityRequestor.names)
        }

        builder
            .section(header: SettingDisplayHeader(type: .titleHeader,
                                                  title: I18n.View_MV_JoinMeetingWho_GreyText + (isLocked ? I18n.View_MV_JoinMeetingWho_GreyTextExplain : "")))
            .checkbox(.securityLevelPublic, title: I18n.View_MV_JoiningPermissionsAnyone,
                      isOn: selectedLevel == .public, isEnabled: !isLocked) { [weak self] _ in
                self?.trackClickSecurityLevel(.public)
                self?.setting.updateSecurityLevel(.public)
            }.checkbox(.securityLevelTenant, title: I18n.View_G_UserFromOrgOnly,
                       isOn: selectedLevel == .tenant, isEnabled: !isLocked) { [weak self] _ in
                self?.trackClickSecurityLevel(.tenant)
                self?.setting.updateSecurityLevel(.tenant)
            }.checkbox(.securityLevelContactsAndGroup, title: I18n.View_G_OnlySelectUserCanJoin,
                       subtitle: securityUserDescs.isEmpty ? nil : securityUserDescs.joined(separator: I18n.View_G_EnumerationComma),
                       isOn: selectedLevel == .contactsAndGroup, isEnabled: !isLocked, showsRightView: true,
                       data: ["subtitleLines": 3]) { [weak self] context in
                guard let self = self else { return }
                self.trackClickSecurityLevel(.contactsAndGroup)
                context.push(InMeetSecurityPickerViewController(setting: self.setting))
            }

        builder
            .section(footer: SettingDisplayFooter(type: .descriptionFooter,
                                                  description: I18n.View_MV_PlaceInLobby_ExplainNote))
            .row(.lobbyOnEntry, reuseIdentifier: .upgradableSwitchCell, title: I18n.View_MV_OpenLobby_Switch,
                 isOn: self.securitySetting.isOpenLobby, isEnabled: manageCapabilities.vcLobby && setting.suiteQuota.waitingRoom,
                 data: ["shouldUpgrade": !self.setting.suiteQuota.waitingRoom]) { [weak self] context in
                guard let self = self else { return }
                let isOn = context.isOn
                if self.setting.suiteQuota.waitingRoom {
                    VCTracker.post(name: .vc_meeting_page_onthecall, params: [
                        .action_name: "lobby_entry", .from_source: "control_bar",
                        .extend_value: ["action_enabled": isOn ? 1 : 0, "join_permission": self.securitySetting.securityLevel.trackName] as [String: Any]])
                    self.trackClickSwitch("lobby_entry", isOn: isOn, extraParams: ["host_tab": "join_permission"])
                    var setting = self.securitySetting
                    setting.isOpenLobby = isOn
                    self.setting.updateHostManage(.setSecurityLevel, update: { $0.securitySetting = setting })
                } else {
                    VCTracker.post(name: .common_pricing_popup_view,
                                   params: ["function_type": "vc_waiting_room_function", "is_presetting_panel": "host_panel"])
                    var popoverConfig: DynamicModalPopoverConfig?
                    if let view = context.anchorView {
                        popoverConfig = DynamicModalPopoverConfig(sourceView: view, sourceRect: view.bounds.offsetBy(dx: 0, dy: -4),
                                                                  backgroundColor: .clear,
                                                                  permittedArrowDirections: [.up])
                    }
                    let regularConfig = DynamicModalConfig(presentationStyle: .popover, popoverConfig: popoverConfig, backgroundColor: .clear)
                    context.from?.presentDynamicModal(UpgradePremiumViewController(),
                                                      regularConfig: regularConfig,
                                                      compactConfig: .init(presentationStyle: .pan))
                    context.reloadRow()
                }
            }

        let isWebinar = self.setting.isWebinarMeeting
        builder
            .section(header: isWebinar ? nil : SettingDisplayHeader(type: .titleHeader,
                                                                    title: I18n.View_G_SpeakingPermissions))
            .switchCell(.muteOnEntry, title: I18n.View_G_SAMuteOnEntry, showsSuggest: showsSuggest, isSuggestOn: true,
                        isOn: videoChatSettings.isMuteOnEntry) { [weak self] context in
                let isOn = context.isOn
                self?.trackClickSwitch("mute_on_entry", isOn: isOn, hasOld: true, oldExtraParams: ["action_enabled": isOn ? 1 : 0])
                self?.setting.updateHostManage(.muteOnEntry, update: { $0.isMuteOnEntry = isOn }) { result in
                    if self != nil, case .success = result {
                        context.showToast(isOn ? I18n.View_M_MutedOnEntryHost : I18n.View_M_UnmutedOnEntryHost)
                    }
                }
            }.switchCell(.allowPartiUnmute, title: I18n.View_G_UnmuteThemselves, showsSuggest: showsSuggest, isSuggestOn: false,
                         isOn: videoChatSettings.allowPartiUnmute,
                         isEnabled: manageCapabilities.forceMuteMicrophone, if: !isWebinar) { [weak self] context in
                self?.trackClickSwitch("participants_unmute_permission", isOn: context.isOn, hasOld: true, oldExtraParams: [.from_source: "control_bar"])
                self?.setting.updateHostManage(.allowPartiUnmute, update: { $0.allowPartiUnmute = context.isOn })
            }

        builder
            .section(header: SettingDisplayHeader(type: .titleHeader,
                                                  title: I18n.View_M_SharingPermissions),
                     if: fromSource.showsSharingSection)
            .switchCell(.onlyHostCanShare, title: I18n.View_G_OnlyHostCanShare, showsSuggest: showsSuggest, isSuggestOn: true,
                        isOn: videoChatSettings.onlyHostCanShare, isEnabled: manageCapabilities.sharePermission) { [weak self] context in
                self?.trackClickSwitch("share_permission", isOn: context.isOn, hasOld: true)
                self?.setting.updateHostManage(.setOnlyHostCanShare, update: { $0.onlyHostCanShare = context.isOn })
            }.switchCell(.onlyHostCanReplaceShare, title: I18n.View_G_OnlyHostCanTakeover, isOn: videoChatSettings.onlyHostCanReplaceShare,
                         isEnabled: manageCapabilities.forceGetSharePermission && !videoChatSettings.onlyHostCanShare) { [weak self] context in
                self?.trackClickSwitch("host_reshare_permission", isOn: context.isOn, hasOld: true)
                self?.setting.updateHostManage(.setOnlyHostCanReplaceShare, update: { $0.onlyHostCanReplaceShare = context.isOn })
            }.switchCell(.onlyPresenterCanAnnotate,
                         title: isWebinar ? I18n.View_G_OnlyPresenterCanAnnotate : I18n.View_G_OnlySharerAnnotateEdit,
                         showsSuggest: showsSuggest, isSuggestOn: true, isOn: videoChatSettings.onlyPresenterCanAnnotate,
                         isEnabled: manageCapabilities.onlyPresenterCanAnnotate) { [weak self] context in
                guard let self = self else { return }
                self.trackClickSwitch("host_mark_permission", isOn: context.isOn, hasOld: true,
                                      oldExtraParams: [.action_name: "annotation_permission", "is_sharer": self.context.isMySharingScreen ? 1 : 0])
                self.setting.updateHostManage(.setOnlyPresenterCanAnnotate, update: { $0.onlyPresenterCanAnnotate = context.isOn })
            }

        let isGenerateAISummaryInMinutesEnabled = videoChatSettings.intelligentMeetingSetting.generateMeetingSummaryInMinutes.isValid
        let isGenerateAISummaryInDocsEnabled = videoChatSettings.intelligentMeetingSetting.generateMeetingSummaryInDocs.isValid
        let isChatWithAIInMeetingEnabled = videoChatSettings.intelligentMeetingSetting.chatWithAiInMeeting.isValid
        let isSmartMeetingSectionDisplayEnabled = (isGenerateAISummaryInMinutesEnabled || isGenerateAISummaryInDocsEnabled || isChatWithAIInMeetingEnabled) && !isWebinar
        builder
            .section(header: SettingDisplayHeader(type: .titleHeader,
                                                  title: I18n.View_G_PermissionSmartMeeting_Subtitle),
                     if: isSmartMeetingSectionDisplayEnabled)
            .switchCell(.generateAiSummaryInMinutes,
                        title: I18n.View_G_UseAINotesInMinutes_Desc,
                        isOn: videoChatSettings.intelligentMeetingSetting.generateMeetingSummaryInMinutes.isOn,
                        if: isGenerateAISummaryInMinutesEnabled,
                        action: { [weak self] context in
                guard let self = self else { return }
                var setting = self.intelligentMeetingSetting
                setting.generateMeetingSummaryInMinutes = context.isOn ? .featureStatusOn : .featureStatusOff
                self.setting.updateHostManage(.intelligentMeetingSetting, update: { $0.intelligentMeetingSetting = setting })
            })
            .switchCell(.generateAiSummaryInNotes,
                        title: I18n.View_G_UseAINotesInDocs_Desc,
                        isOn: videoChatSettings.intelligentMeetingSetting.generateMeetingSummaryInDocs.isOn,
                        if: isGenerateAISummaryInDocsEnabled,
                        action: { [weak self] context in
                guard let self = self else { return }
                var setting = self.intelligentMeetingSetting
                setting.generateMeetingSummaryInDocs = context.isOn ? .featureStatusOn : .featureStatusOff
                self.setting.updateHostManage(.intelligentMeetingSetting, update: { $0.intelligentMeetingSetting = setting })
            })
            .switchCell(.chatWithAiInMeet,
                        title: I18n.View_G_UseAIDuringMeetings_Desc,
                        isOn: videoChatSettings.intelligentMeetingSetting.chatWithAiInMeeting.isOn,
                        if: isChatWithAIInMeetingEnabled,
                        action: { [weak self] context in
                guard let self = self else { return }
                var setting = self.intelligentMeetingSetting
                setting.chatWithAiInMeeting = context.isOn ? .featureStatusOn : .featureStatusOff
                self.setting.updateHostManage(.intelligentMeetingSetting, update: { $0.intelligentMeetingSetting = setting })
            })

        var notesPermission = videoChatSettings.notePermission
        let onlyHostCanCreate = notesPermission.createPermission == .onlyHost
        let createEditNotesEnabled = setting.isMeetingNotesEnabled && !isWebinar && !setting.isInterviewMeeting

        builder
            .section(header: SettingDisplayHeader(type: .titleHeader,
                                                  title: I18n.View_G_MeetingNotesCreation_Subtitle), if: createEditNotesEnabled)
            .checkbox(.noteCanCreate, title: I18n.View_G_AllCanCreateNotes_Desc, isOn: !onlyHostCanCreate) { [weak self] _ in
                VCTracker.post(name: .vc_meeting_hostpanel_click, params: [.click: "audience_can_create_notes"])
                notesPermission.createPermission = .all
                self?.setting.updateHostManage(.notePermission, update: { $0.notesPermission = notesPermission })
            }
            .checkbox(.noteCanEditByHost, title: I18n.View_G_HostCanCreateNotes_Desc, isOn: onlyHostCanCreate) { [weak self] _ in
                VCTracker.post(name: .vc_meeting_hostpanel_click, params: [.click: "only_host_can_create_notes"])
                notesPermission.createPermission = .onlyHost
                self?.setting.updateHostManage(.notePermission, update: { $0.notesPermission = notesPermission })
            }
        let onlyHostCanEdit = notesPermission.editpermission == .onlyHost

        builder
            .section(header: SettingDisplayHeader(type: .titleHeader,
                                                  title: I18n.View_G_MeetingNotesEditing_Subtitle), if: createEditNotesEnabled)
            .checkbox(.noteCanEdit, title: I18n.View_G_AllCanEditNotes_Desc, isOn: !onlyHostCanEdit) { [weak self] _ in
                VCTracker.post(name: .vc_meeting_hostpanel_click, params: [.click: "audience_can_edit_notes"])
                notesPermission.editpermission = .all
                self?.setting.updateHostManage(.notePermission, update: { $0.notesPermission = notesPermission })
            }
            .checkbox(.noteCanEditByHost, title: I18n.View_G_HostCanEditNotes_Desc, isOn: onlyHostCanEdit) { [weak self] _ in
                VCTracker.post(name: .vc_meeting_hostpanel_click, params: [.click: "only_host_can_edit_notes"])
                notesPermission.editpermission = .onlyHost
                self?.setting.updateHostManage(.notePermission, update: { $0.notesPermission = notesPermission })
            }

        let isChatSwitchEnabled = videoChatSettings.panelistPermission.messageButtonStatus == .default
        builder
            .section(header: SettingDisplayHeader(type: .titleHeader,
                                                  title: isWebinar ? I18n.View_G_PanelistsCan : I18n.View_VM_ParticipantPermissions))
            .switchCell(.allowPartiUnmute, title: I18n.View_G_PanelistsCanUnmute, showsSuggest: showsSuggest, isSuggestOn: false,
                        isOn: videoChatSettings.allowPartiUnmute,
                        isEnabled: manageCapabilities.forceMuteMicrophone, if: isWebinar) { [weak self] context in
                VCTracker.post(name: .vc_meeting_hostpanel_click, params: [
                    .click: "panelist_self_unmute", "is_check": context.isOn, "from_source": self?.fromSource.trackName])
                self?.trackClickSwitch("participants_unmute_permission", isOn: context.isOn, hasOld: true, oldExtraParams: [.from_source: "control_bar"])
                self?.setting.updateHostManage(.allowPartiUnmute, update: { $0.allowPartiUnmute = context.isOn })
            }.switchCell(.allowSendMessage, title: I18n.View_G_InMeetingChat, isOn: videoChatSettings.panelistPermission.allowSendMessage && isChatSwitchEnabled,
                         if: setting.fg.isChatPermissionEnabled || isWebinar) { [weak self] context in
                if isChatSwitchEnabled {
                    self?.setting.updatePanelistPermission({ $0.allowSendMessage = context.isOn })
                    self?.trackClickSwitch("send_message_permission", isOn: context.isOn)
                } else {
                    self?.showToast(I18n.View_G_NoFeatureForGroupMeeting)
                    context.reloadRow()
                }
            }.switchCell(.allowSendReaction, title: I18n.View_G_SendEmoji_Tick,
                         isOn: videoChatSettings.panelistPermission.allowSendReaction) { [weak self] context in
                self?.trackClickSwitch("send_reaction_permission", isOn: context.isOn)
                self?.setting.updatePanelistPermission({ $0.allowSendReaction = context.isOn })
            }.switchCell(.allowPartiChangeName, title: isWebinar ? I18n.View_G_PanelistsCanRename : I18n.View_G_ChangeMeetingName,
                         isOn: !videoChatSettings.isPartiChangeNameForbidden) { [weak self] context in
                if isWebinar {
                    VCTracker.post(name: .vc_meeting_hostpanel_click, params: [
                        .click: "panelist_change_name", "is_check": context.isOn, "from_source": self?.fromSource.trackName])
                }
                self?.trackClickSwitch("allow_participant_rename", isOn: context.isOn)
                self?.setting.updateHostManage(.setForbidPartiChangeName, update: { $0.isPartiChangeNameForbidden = !context.isOn })
            }.switchCell(.allowRequestRecord, title: I18n.View_G_RequestToRecord,
                         isOn: videoChatSettings.panelistPermission.allowRequestRecord, if: !setting.isE2EeMeeting) { [weak self] context in
                self?.trackClickSwitch("request_record", isOn: context.isOn)
                self?.setting.updatePanelistPermission({ $0.allowRequestRecord = context.isOn })
            }

        builder
            .section(header: SettingDisplayHeader(type: .titleHeader,
                                                  title: I18n.View_G_AttendeesCan),
                     if: isWebinar)
            .switchCell(.allowAttendeeSendMessage, title: I18n.View_G_InMeetingChat,
                        isOn: videoChatSettings.attendeePermission.allowSendMessage) { [weak self] context in
                self?.trackClickSwitch("send_message_permission", isOn: context.isOn)
                self?.setting.updateAttendeePermission({ $0.allowSendMessage = context.isOn })
            }.switchCell(.allowAttendeeSendReaction, title: I18n.View_G_SendEmoji_Tick,
                         isOn: videoChatSettings.attendeePermission.allowSendReaction) { [weak self] context in
                self?.trackClickSwitch("send_reaction_permission", isOn: context.isOn)
                self?.setting.updateAttendeePermission({ $0.allowSendReaction = context.isOn })
            }
    }

    private func trackClickSecurityLevel(_ level: SecurityLevel) {
        let fromLevel = self.securitySetting.securityLevel
        let isLocked = self.securitySetting.isLocked
        VCTracker.post(name: .vc_meeting_hostpanel_click, params: [
            .click: "join_permission", .from_source: self.fromSource.trackName, .option: level.trackName,
            "is_meeting_locked": isLocked, "host_tab": "join_permission"])
        VCTracker.post(name: .vc_meeting_page_onthecall, params: [
            .action_name: "join_permission", "from_permission": fromLevel.trackName, "after_permission": level.trackName])
    }

    private func trackClickSwitch(_ action: String, isOn: Bool, hasOld: Bool = false, extraParams: TrackParams = [:], oldExtraParams: TrackParams = [:]) {
        var params: TrackParams = [.click: action, .from_source: self.fromSource.trackName, "is_check": isOn,
                                   "is_meeting_locked": self.securitySetting.isLocked, "host_tab": "advanced_options"]
        params.updateParams(extraParams.rawValue)
        VCTracker.post(name: .vc_meeting_hostpanel_click, params: params)
        if hasOld {
            var oldParams: TrackParams = [.action_name: action, .from_source: "host_panel", .extend_value: ["action_enabled": isOn ? "1" : "0"]]
            oldParams.updateParams(oldExtraParams.rawValue)
            VCTracker.post(name: .vc_meeting_page_onthecall, params: oldParams)
        }
    }

    private func updateShowsSuggest(shouldReloadData: Bool = true) {
        // 参会人数低于会管阈值不展示"建议提示"
        // 讨论组不展示tag
        let showsSuggest = self.participantNum >= self.setting.suggestManageThreshold && !self.setting.isInBreakoutRoom
        if self.showsSuggest != showsSuggest {
            self.showsSuggest = showsSuggest
            if shouldReloadData {
                self.reloadData()
            }
        }
    }

    private func dismissHostVC() {
        if let vc = hostViewController, let nav = vc.navigationController, nav.viewControllers.count > 1,
           let index = nav.viewControllers.firstIndex(of: vc), index > 0 {
            let last = nav.viewControllers[index - 1]
            nav.popToViewController(last, animated: true)
        } else {
            self.hostViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
        }
    }
}

extension InMeetSecurityViewModel: MeetingInternalSettingListener {
    func didChangeSuiteQuota(_ settings: MeetingSettingManager, value: GetSuiteQuotaResponse, oldValue: GetSuiteQuotaResponse?) {
        reloadData()
    }

    func didChangeVideoChatSettings(_ settings: MeetingSettingManager, value: VideoChatSettings, oldValue: VideoChatSettings?) {
        reloadData()
    }

    func didChangeMyself(_ settings: MeetingSettingManager, value: Participant, oldValue: Participant?) {
        reloadData()
    }

    func didChangeSuggestThreshold(_ settings: MeetingSettingManager, value: Int) {
        updateShowsSuggest()
    }
}

extension InMeetSecurityViewModel: MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        if key == .hasCohostAuthority, !isOn {
            Util.runInMainThread {
                self.dismissHostVC()
            }
        }
    }
}

extension InMeetSecurityViewModel: InMeetSecurityListener {
    func didChangeParticipantNum(_ participantNum: Int) {
        self.participantNum = participantNum
        updateShowsSuggest()
    }
}

extension InMeetSecurityViewModel: InMeetSecurityRequestorDelegate {
    func didUpdateSecurityUsers(for setting: VideoChatSettings.SecuritySetting) {
        reloadData()
    }
}

extension VideoChatSettings.SecuritySetting.SecurityLevel {
    var trackName: String {
        switch self {
        case .public:
            return "anyone"
        case .onlyHost:
            return "host_invited"
        case .contactsAndGroup:
            return "selected"
        case .tenant:
            return "organizer_company"
        default:
            return ""
        }
    }
}

private extension SettingSectionBuilder {
    @discardableResult
    func switchCell(_ item: SettingDisplayItem, title: String, showsSuggest: Bool, isSuggestOn: Bool, subtitle: String? = nil, isOn: Bool,
                    isEnabled: Bool = true, data: [String: Any] = [:],
                    if condition: @autoclosure () -> Bool = true,
                    action: ((SettingRowActionContext) -> Void)? = nil) -> Self {
        if showsSuggest, isSuggestOn != isOn {
            return row(SettingDisplayRow(
                item: item, cellType: .switchCell, title: title, subtitle: subtitle,
                isOn: isOn, isEnabled: isEnabled, showsRightView: true,
                attributedTitle: { SuggestTitleBuilder.attributedTitle(for: title, isSuggestOn: isSuggestOn) },
                data: data, action: action
            ), if: condition())
        } else {
            return row(SettingDisplayRow(
                item: item, cellType: .switchCell, title: title, subtitle: subtitle,
                isOn: isOn, isEnabled: isEnabled, showsRightView: true,
                attributedTitle: nil,
                data: data, action: action
            ), if: condition())
        }
    }
}

private struct SuggestTitleBuilder {
    static func attributedTitle(for title: String, isSuggestOn: Bool) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: title, config: .body)
        let nameAttachment = suggestAttachment(for: isSuggestOn ? I18n.View_G_RecTurnedOn : I18n.View_G_RecTurnedOff)
        attributedString.append(NSAttributedString(string: " ", config: .body))
        attributedString.append(NSAttributedString(attachment: nameAttachment))
        return attributedString
    }

    private static func suggestAttachment(for text: String) -> NSTextAttachment {
        let key = SuggestAttachmentKey(text)
        if let attachment = Self.suggestCache[key] {
            return attachment
        }

        let label = PaddingLabel()
        label.textInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)
        label.textColor = UIColor.ud.udtokenTagTextSBlue
        label.backgroundColor = UIColor.ud.udtokenTagBgBlue
        label.layer.cornerRadius = 4.0
        label.clipsToBounds = true
        label.attributedText = NSAttributedString(string: text, config: .assist)
        label.sizeToFit()
        label.frame = label.frame.insetBy(dx: -4, dy: 0)

        let imageSize = label.frame.size
        let render = UIGraphicsImageRenderer(bounds: .init(origin: .zero, size: imageSize))
        let image = render.image { context in
            label.layer.render(in: context.cgContext)
        }

        let nameLabelFont = UIFont.systemFont(ofSize: 16, weight: .regular)
        let imageOffset = (nameLabelFont.capHeight - imageSize.height) / 2
        let attachment = NSTextAttachment()
        attachment.image = image
        attachment.bounds = CGRect(origin: CGPoint(x: 0, y: imageOffset), size: imageSize)
        Self.suggestCache[key] = attachment
        return attachment
    }

    private static var suggestCache: [SuggestAttachmentKey: NSTextAttachment] = [:]

    private struct SuggestAttachmentKey: Hashable {
        let text: String
        let theme: Int

        init(_ text: String) {
            self.text = text
            if #available(iOS 13.0, *) {
                self.theme = UDThemeManager.getRealUserInterfaceStyle().rawValue
            } else {
                self.theme = 0
            }
        }
    }
}

private extension InMeetSecurityFromSource {
    var trackName: String {
        switch self {
        case .toolbar, .tips:
            return "tool_bar"
        case .participant:
            return "user_list"
        }
    }

    var title: String {
        switch self {
        case .toolbar, .tips:
            return I18n.View_G_Security_MeetingBigTab
        case .participant:
            return I18n.View_G_Settings
        }
    }

    var showsSharingSection: Bool {
        switch self {
        case .toolbar, .tips:
            return true
        case .participant:
            return false
        }
    }
}
