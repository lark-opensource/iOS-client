//
//  WebinarSettingViewModel.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/5/15.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork
import ByteViewUI
import UniverseDesignToast

public struct WebinarSettingContext {
    let jsonString: String?
    let speakerCanInviteOthers: Bool
    let speakerCanSeeOtherSpeakers: Bool
    let audienceCanInviteOthers: Bool
    let audienceCanSeeOtherSpeakers: Bool

    public init(jsonString: String?, speakerCanInviteOthers: Bool, speakerCanSeeOtherSpeakers: Bool, audienceCanInviteOthers: Bool, audienceCanSeeOtherSpeakers: Bool) {
        self.jsonString = jsonString
        self.speakerCanInviteOthers = speakerCanInviteOthers
        self.speakerCanSeeOtherSpeakers = speakerCanSeeOtherSpeakers
        self.audienceCanInviteOthers = audienceCanInviteOthers
        self.audienceCanSeeOtherSpeakers = audienceCanSeeOtherSpeakers
    }
}

final class WebinarSettingViewModel: SettingViewModel<WebinarSettingContext> {
    private let ref = CalendarSettingsRef()
    private var settings: CalendarSettings {
        get { ref.settings }
        set { ref.settings = newValue }
    }

    override func setup() {
        super.setup()
        supportedCellTypes.formUnion([.calendarCheckmarkCell, .calendarSettingGotoCell])
        var defaultSettings = CalendarSettings()
        if let s = context.jsonString, let setting = try? CalendarSettings(jsonString: s) {
            defaultSettings = setting
        } else {
            httpClient.getResponse(GetCalendarDefaultVCSettingsRequest()) { [weak self] r in
                guard let self = self, case .success(let resp) = r else { return }
                var settings = resp.calendarVcSetting
                settings.speakerCanInviteOthers = self.settings.speakerCanInviteOthers
                settings.speakerCanSeeOtherSpeakers = self.settings.speakerCanSeeOtherSpeakers
                settings.audienceCanInviteOthers = self.settings.audienceCanInviteOthers
                settings.audienceCanSeeOtherSpeakers = self.settings.audienceCanSeeOtherSpeakers
                self.settings = settings
                self.reloadData()
            }
        }
        defaultSettings.speakerCanInviteOthers = context.speakerCanInviteOthers
        defaultSettings.speakerCanSeeOtherSpeakers = context.speakerCanSeeOtherSpeakers
        defaultSettings.audienceCanInviteOthers = context.audienceCanInviteOthers
        defaultSettings.audienceCanSeeOtherSpeakers = context.audienceCanSeeOtherSpeakers
        self.settings = defaultSettings
    }

    override func buildSections(builder: SettingSectionBuilder) {
        super.buildSections(builder: builder)
        builder
            .section()
            .switchCell(.rehearsalMode,
                        title: I18n.View_G_RehearsalMode_Tick,
                        subtitle: I18n.View_G_RehearsalModeExplain,
                        cellStyle: .blankPaper,
                        isOn: settings.rehearsalMode,
                        action: { [weak self] context in
                self?.settings.rehearsalMode = context.isOn
            })

        builder
            .section(header: SettingDisplayHeader(type: .titleHeader,
                                                  title: I18n.View_MV_JoinMeetingWho_GreyText,
                                                  titleTextStyle: .r_14_22))
            .checkmark(.securityLevelPublic, title: I18n.View_M_JoiningPermissionsAnyone, cellStyle: .blankPaper, isOn: settings.vcSecuritySetting == .public, action: { [weak self] _ in
                self?.settings.vcSecuritySetting = .public
                self?.reloadData()
            })
            .checkmark(.securityLevelTenant, title: I18n.View_G_UserFromOrgOnly, cellStyle: .blankPaper,
                      isOn: settings.vcSecuritySetting == .sameTenant, action: { [weak self] _ in
                self?.settings.vcSecuritySetting = .sameTenant
                self?.reloadData()
            })
            .checkmark(.securityLevelCalendar, title: I18n.View_M_OnlyEventGuestsCanJoin, cellStyle: .blankPaper, isOn: settings.vcSecuritySetting == .onlyCalendarGuest, action: { [weak self] _ in
                self?.settings.vcSecuritySetting = .onlyCalendarGuest
                self?.reloadData()
            })

        builder
            .section()
            .switchCell(.allowPanelistStartMeeting,
                        title: I18n.View_G_AllowPanelistToStart,
                        cellStyle: .blankPaper,
                        isOn: settings.canJoinMeetingBeforeOwnerJoined, action: { [weak self] context in
                self?.settings.canJoinMeetingBeforeOwnerJoined = context.isOn
            })
            .switchCell(.calendarMeetingAutoRecord,
                        title: I18n.View_G_RecordMeetingAutomatically,
                        cellStyle: .blankPaper,
                        isOn: settings.autoRecord, action: { [weak self] context in
                self?.settings.autoRecord = context.isOn
            })

        builder
            .section()
            .gotoCell(.panelistPermission, title: I18n.View_G_PanelistPermissions, cellStyle: .blankPaper, action: { [weak self] context in
                guard let self = self else { return }
                let vm = WebinarPanelistSettingViewModel(service: self.service, context: self.context, ref: self.ref)
                context.push(CalendarBaseSettingVC(viewModel: vm))
            })
            .gotoCell(.attendeePermission, title: I18n.View_G_AttendeePermissions, cellStyle: .blankPaper, action: { [weak self] context in
                guard let self = self else { return }
                let vm = WebinarAttendeeSettingViewModel(service: self.service, context: self.context, ref: self.ref)
                context.push(CalendarBaseSettingVC(viewModel: vm))
            })

        builder
            .section()
            .gotoCell(.webinarAdvancedSetting, title: I18n.View_G_SAAdvancedSettings, cellStyle: .blankPaper, action: { [weak self] context in
                guard let self = self else { return }
                let vm = WebinarAdvancedSettingViewModel(service: self.service, context: self.context, ref: self.ref)
                context.push(CalendarBaseSettingVC(viewModel: vm))
            })
    }

    func save() -> Result<CalendarSettings, WebinarSettingError> {
        if settings.backupHostUids.count > 10 {
            return .failure(.hostCount)
        } else if settings.interpretationSetting.interpreterSettings.contains(where: { !$0.isPreSetFull }) {
            return .failure(.interpreterNotFull)
        }
        return .success(settings)
    }
}

private final class CalendarSettingsRef {
    @RwAtomic var settings = CalendarSettings()
}

private class WebinarSubsettingViewModel: SettingViewModel<WebinarSettingContext> {
    private let ref: CalendarSettingsRef
    var settings: CalendarSettings {
        get { ref.settings }
        set { ref.settings = newValue }
    }

    fileprivate init(service: UserSettingManager, context: WebinarSettingContext, ref: CalendarSettingsRef) {
        self.ref = ref
        super.init(service: service, context: context)
    }
}

private final class WebinarPanelistSettingViewModel: WebinarSubsettingViewModel {
    override func setup() {
        super.setup()
        self.title = I18n.View_G_PanelistPermissions
    }

    override func buildSections(builder: SettingSectionBuilder) {
        super.buildSections(builder: builder)

        builder.section()
            .switchCell(.speakerCanInviteOthers,
                        title: I18n.View_G_InviteGuestPermit,
                        cellStyle: .blankPaper,
                        isOn: settings.speakerCanInviteOthers, action: { [weak self] context in
                self?.settings.speakerCanInviteOthers = context.isOn
                if !context.isOn {
                    self?.settings.audienceCanInviteOthers = false
                }
            })
            .switchCell(.speakerCanSeeOtherSpeakers,
                        title: I18n.View_G_ViewListPermit,
                        cellStyle: .blankPaper,
                        isOn: settings.speakerCanSeeOtherSpeakers, action: { [weak self] context in
                self?.settings.speakerCanSeeOtherSpeakers = context.isOn
                if !context.isOn {
                    self?.settings.audienceCanSeeOtherSpeakers = false
                }
            })

            .section()
            .switchCell(.onlyHostCanShare,
                        title: I18n.View_G_OnlyHostCanShare,
                        cellStyle: .blankPaper,
                        isOn: settings.onlyHostCanShare, action: { [weak self] context in
                self?.settings.onlyHostCanShare = context.isOn
            })
            .switchCell(.onlyPresenterCanAnnotate,
                        title: I18n.View_G_OnlyPresenterCanAnnotate,
                        cellStyle: .blankPaper,
                        isOn: settings.onlyPresenterCanAnnotate, action: { [weak self] context in
                self?.settings.onlyPresenterCanAnnotate = context.isOn
            })

            .section()
            .switchCell(.muteOnEntry,
                        title: I18n.View_G_SAMuteOnEntry,
                        cellStyle: .blankPaper,
                        isOn: settings.muteMicrophoneWhenJoin, action: { [weak self] context in
                self?.settings.muteMicrophoneWhenJoin = context.isOn
            })
            .switchCell(.allowPartiUnmute,
                        title: I18n.View_G_AllowUnmuteOneself,
                        cellStyle: .blankPaper,
                        isOn: !settings.isPartiUnmuteForbidden, action: { [weak self] context in
                self?.settings.isPartiUnmuteForbidden = !context.isOn
            })

            .section()
            .switchCell(.allowSendMessage,
                        title: I18n.View_G_InMeetingChat,
                        cellStyle: .blankPaper,
                        isOn: settings.panelistPermission.allowSendMessage, action: { [weak self] context in
                self?.settings.panelistPermission.allowSendMessage = context.isOn
            })
            .switchCell(.allowSendReaction,
                        title: I18n.View_G_SendEmoji_Tick,
                        cellStyle: .blankPaper,
                        isOn: settings.panelistPermission.allowSendReaction, action: { [weak self] context in
                self?.settings.panelistPermission.allowSendReaction = context.isOn
            })

            .section()
            .switchCell(.allowVirtualBackground,
                        title: I18n.View_G_UseVirtualBack_Tick,
                        cellStyle: .blankPaper,
                        isOn: settings.panelistPermission.allowVirtualBackground, action: { [weak self] context in
                self?.settings.panelistPermission.allowVirtualBackground = context.isOn
            })
            .switchCell(.allowVirtualAvatar,
                        title: I18n.View_G_UseAvatar_Tick,
                        cellStyle: .blankPaper,
                        isOn: settings.panelistPermission.allowVirtualAvatar, action: { [weak self] context in
                self?.settings.panelistPermission.allowVirtualAvatar = context.isOn
            })

            .section()
            .switchCell(.allowPartiChangeName,
                        title: I18n.View_G_ChangeMeetingName,
                        cellStyle: .blankPaper,
                        isOn: !settings.isPartiChangeNameForbidden, action: { [weak self] context in
                self?.settings.isPartiChangeNameForbidden = !context.isOn
            })
    }
}

private final class WebinarAttendeeSettingViewModel: WebinarSubsettingViewModel {
    override func setup() {
        super.setup()
        self.title = I18n.View_G_AttendeePermissions
    }

    override func buildSections(builder: SettingSectionBuilder) {
        super.buildSections(builder: builder)

        builder.section()
            .switchCell(.audienceCanInviteOthers,
                        title: I18n.View_G_InviteGuestPermit,
                        cellStyle: .blankPaper,
                        isOn: settings.audienceCanInviteOthers, action: { [weak self] context in
                self?.settings.audienceCanInviteOthers = context.isOn
                if context.isOn {
                    self?.settings.speakerCanInviteOthers = true
                }
            })
            .switchCell(.audienceCanSeeOtherSpeakers,
                        title: I18n.View_G_ViewListPermit,
                        cellStyle: .blankPaper,
                        isOn: settings.audienceCanSeeOtherSpeakers, action: { [weak self] context in
                self?.settings.audienceCanSeeOtherSpeakers = context.isOn
                if context.isOn {
                    self?.settings.speakerCanSeeOtherSpeakers = true
                }
            })

            .section()
            .switchCell(.allowAttendeeSendMessage,
                        title: I18n.View_G_InMeetingChat,
                        cellStyle: .blankPaper,
                        isOn: !settings.isAudienceImForbidden, action: { [weak self] context in
                self?.settings.isAudienceImForbidden = !context.isOn
            })
            .switchCell(.allowAttendeeSendReaction,
                        title: I18n.View_G_SendEmoji_Tick,
                        cellStyle: .blankPaper,
                        isOn: !settings.isAudienceReactionForbidden, action: { [weak self] context in
                self?.settings.isAudienceReactionForbidden = !context.isOn
            })
    }
}

private final class WebinarAdvancedSettingViewModel: WebinarSubsettingViewModel {
    private var backupHostInfos: [ParticipantUserInfo] = []

    override func setup() {
        super.setup()
        self.observedSettingChanges = [.suiteQuota]
        self.supportedCellTypes.formUnion([.addInterpreterCell, .editInterpreterCell, .calendarBackupHostCell, .settingCell, .calendarHeaderCell, .emptyPaddingCell])
        self.title = I18n.View_G_SAAdvancedSettings
        service.refreshSuiteQuota(force: true)
        service.refreshVideoChatConfig(force: true)
        if !self.settings.backupHostUids.isEmpty {
            let backupHostUids = settings.backupHostUids
            let pids = backupHostUids.map { ByteviewUser(id: $0, type: .larkUser) }
            httpClient.participantService.participantInfo(pids: pids, meetingId: nil) { [weak self] infos in
                guard self?.settings.backupHostUids == backupHostUids else { return }
                self?.backupHostInfos = infos
                Util.runInMainThread {
                    self?.reloadData()
                }
            }
        }
    }

    override func buildSections(builder: SettingSectionBuilder) {
        super.buildSections(builder: builder)

        // 添加主持人
        let hostUids = settings.backupHostUids.map { ByteviewUser(id: $0, type: .larkUser) }
        builder
            .section()
            .row(.addHost, reuseIdentifier: .calendarHeaderCell, title: I18n.View_G_AlternativeHosts_Subtitle, subtitle: I18n.View_G_AssignHostRule, cellStyle: .blankPaper)
        for userInfo in backupHostInfos {
            builder.calendarBackupHostCell(userInfo: userInfo) { [weak self] userId in
                self?.removeHost(userId)
            }
        }
        if !hostUids.isEmpty {
            builder.row(.paddingCell, reuseIdentifier: .emptyPaddingCell, title: "")
        }
        builder.row(.addHost, reuseIdentifier: .addInterpreterCell, title: I18n.View_G_AddHosts, cellStyle: .blankPaper, action: { [weak self] _ in self?.addHost() })

        // 添加传译
        builder.section()
            .row(.addInterpreterHeader, reuseIdentifier: .calendarHeaderCell, title: I18n.View_G_Interpretation, subtitle: I18n.View_G_InterpretersAutoPanelists, cellStyle: .blankPaper)
        for (index, interpreter) in settings.interpretationSetting.interpreterSettings.enumerated() {
            let channel = InterpretationChannelInfo(index: index, interpreter: interpreter)
            builder
                .editInterpreterCell(channel: channel, delegate: self)
        }

        builder.row(.addInterpreter, reuseIdentifier: .addInterpreterCell, title: I18n.View_G_AddInterpreter, cellStyle: .blankPaper,
                 isEnabled: service.suiteQuota().interpretation, action: { [weak self] _ in self?.addInterpreter() })
    }

    private func addHost() {
        guard settings.backupHostUids.count < 10 else {
            UDToast.showTips(with: I18n.View_G_AddTenHostsMax, on: hostViewController?.view ?? UIView())
            return
        }
        let participantService = httpClient.participantService
        let vc = CalendarHostSettingsVC(service: service, selectedIds: settings.backupHostUids) { [weak self] ids in
            self?.settings.backupHostUids = ids
            let pids = ids.map { ByteviewUser(id: $0, type: .larkUser) }
            participantService.participantInfo(pids: pids, meetingId: nil) { [weak self] infos in
                guard let self = self, self.settings.backupHostUids == ids else { return }
                self.backupHostInfos = infos
                Util.runInMainThread {
                    self.reloadData()
                }
            }
        }
        hostViewController?.presentDynamicModal(vc, config: DynamicModalConfig(presentationStyle: .formSheet, needNavigation: true))
    }

    private func removeHost(_ uid: String) {
        backupHostInfos.removeAll { $0.id == uid }
        settings.backupHostUids.removeAll {  $0 == uid }
        reloadData()
    }

    private func addInterpreter() {
        guard service.suiteQuota().interpretation else {
            showToast(I18n.View_G_UpgradePlanToUseFeature)
            return
        }
        guard settings.interpretationSetting.interpreterSettings.count < AddInterpreterCell.maxChannelInfosCount else {
            showToast(I18n.View_G_InterpretersCapacityReached)
            return
        }
        var setting: InterpreterSetting = InterpreterSetting()
        // "* 1000" => 防止快速点击"添加"导致interpreterSetTime一致
        setting.interpreterSetTime = Int64(Date().timeIntervalSince1970 * 1000)
        let interpreterSettings = settings.interpretationSetting.interpreterSettings
        let index = interpreterSettings.count
        let interpreter = SetInterpreter(user: .emptyUser, interpreterSetting: setting, isDeleteInterpreter: false)
        let channel = InterpretationChannelInfo(index: index, interpreter: interpreter)

        let selectedIds = selectedInterpreters.map { $0.user.id }.filter { !$0.isEmpty }
        let vc = CalendarInterpreterSettingsVC(service: service, selectedIds: selectedIds) { [weak self] id in
            guard let self = self else { return }
            self.settings.interpretationSetting.interpreterSettings.append(interpreter)
            self.didModifyInterperter(channel, action: { $0.user = ByteviewUser(id: id, type: .larkUser) })
            Util.runInMainThread {
                self.reloadData()
                self.delegate?.scrollToRow(for: .addInterpreter, at: .bottom, animated: true)
            }
        }
        self.hostViewController?.presentDynamicModal(vc, config: DynamicModalConfig(presentationStyle: .formSheet, needNavigation: true))
    }
}

extension WebinarAdvancedSettingViewModel: EditInterpreterCellDelegate {
    var selectedInterpreters: [ByteViewNetwork.SetInterpreter] {
        settings.interpretationSetting.interpreterSettings
    }

    var supportedInterpretationLanguage: [ByteViewNetwork.InterpreterSetting.LanguageType] {
        service.videoChatConfig.meetingSupportInterpretationLanguage
    }

    func canEditInterpreter(_ channel: InterpretationChannelInfo) -> Bool {
        true
    }

    func didRemoveInterpreter(_ channel: InterpretationChannelInfo) {
        self.settings.interpretationSetting.interpreterSettings.removeAll {
            $0.interpreterSetting?.interpreterSetTime == channel.interpreterSetting?.interpreterSetTime
        }
        self.reloadData()
    }

    func didModifyInterperter(_ channel: InterpretationChannelInfo, action: (inout SetInterpreter) -> Void) {
        if let index = self.settings.interpretationSetting.interpreterSettings.firstIndex(where: {
            $0.interpreterSetting?.interpreterSetTime == channel.interpreterSetting?.interpreterSetTime
        }) {
            action(&self.settings.interpretationSetting.interpreterSettings[index])
        }
        self.reloadData()
    }
}
