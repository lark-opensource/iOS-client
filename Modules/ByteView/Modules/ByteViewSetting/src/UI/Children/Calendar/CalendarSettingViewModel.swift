//
//  CalendarSettingViewModel.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/3/5.
//

import Foundation
import ByteViewCommon
import ByteViewTracker
import ByteViewNetwork
import UniverseDesignToast
import ByteViewUI

public struct CalendarSettingContext {
    public let type: CalendarSettingType
    public var createSubmitHandler: ((Result<ApplyMeetingNOResponse, Error>) -> Void)?
    public var editSubmitHandler: ((Result<Void, Error>) -> Void)?

    public init(type: CalendarSettingType) {
        self.type = type
    }
}

public enum CalendarSettingType: Equatable {
    /// 创建日历时，第一次进入视频会议设置页进行编辑的状态
    case start
    /// 创建日历时，进入视频会议设置页编辑并保存后，再次进入进行编辑的状态
    /// - parameter vcSettingId: 设置ID，用于GetCalendarPreVCSettingsRequest
    case preEdit(String)
    /// 日历创建后，进入视频会议设置页进行编辑的状态
    /// - parameter uniqueId: 日程的uniqueId，用于GetCalendarSettingsRequest/SetCalendarSettingsRequest
    /// - parameter calendarInstanceIdentifier: 日程的identifier，用于SetCalendarSettingsRequest
    case edit(String, CalendarInstanceIdentifier)
}

protocol CalendarSettingViewModelDelegate: SettingViewModelDelegate {
    func scrollToFirstInterpreter()
}

final class CalendarSettingViewModel: SettingViewModel<CalendarSettingContext> {
    @RwAtomic
    private(set) var settings = CalendarSettings()
    @RwAtomic
    private(set) var isSettingLoaded = false
    @RwAtomic
    private(set) var isSaveButtonEnabled = false
    private var uniqueId: String = ""
    private var backupHostInfos: [ParticipantUserInfo] = []

    @RwAtomic
    private var hostNames: String = ""

    override func setup() {
        self.pageId = .calendarSetting
        self.title = I18n.View_M_VideoMeetingSettings
        self.observedSettingChanges = [.adminSettings, .suiteQuota]
        self.supportedCellTypes.formUnion([.upgradableSwitchCell, .addInterpreterCell, .editInterpreterCell,
                                           .calendarBackupHostCell, .settingCell, .calendarCheckmarkCell,
                                           .calendarHeaderCell, .emptyPaddingCell])
        service.refreshSuiteQuota(force: true)
        service.refreshAdminSettings(force: true)
        service.refreshVideoChatConfig(force: true)
        switch context.type {
        case .start:
            httpClient.getResponse(GetCalendarDefaultVCSettingsRequest()) { [weak self] r in
                var settings: CalendarSettings?
                if case .success(let response) = r {
                    settings = response.calendarVcSetting
                    settings?.isOrganizer = true // 创建者即组织者
                }
                self?.onLoadSetting(settings)
            }
        case .preEdit(let settingId):
            let request = GetCalendarPreVCSettingsRequest(vcSettingID: settingId)
            httpClient.getResponse(request) { [weak self] r in
                var settings: CalendarSettings?
                if case .success(let response) = r {
                    settings = response.calendarVcSetting
                    settings?.isOrganizer = true // 创建者即组织者
                }
                self?.onLoadSetting(settings)
            }
        case .edit(let uniqueId, let instance):
            self.uniqueId = uniqueId
            let request = GetCalendarSettingsRequest(uniqueID: uniqueId, calendarInstanceIdentifier: instance)
            httpClient.getResponse(request) { [weak self] r in
                var settings: CalendarSettings?
                if case .success(let response) = r {
                    settings = response.settings
                }
                self?.onLoadSetting(settings)
            }
        }
    }

    func submit(completion: ((Result<Void, Error>) -> Void)?) {
        settings.interpretationSetting.interpreterSettings.removeAll(where: { !$0.isPreSetFull })
        switch context.type {
        case .start, .preEdit:
            let request = ApplyMeetingNORequest(settings: settings)
            httpClient.getResponse(request) { [weak self] r in
                Util.runInMainThread {
                    if case .success = r {
                        self?.trackSubmitSuccess()
                    }
                    self?.context.createSubmitHandler?(r)
                    completion?(r.map({ _ in Void() }))
                }
            }
        case .edit(let uniqueId, let instance):
            let request = SetCalendarSettingsRequest(uniqueID: uniqueId, settings: settings, calendarInstanceIdentifier: instance)
            httpClient.send(request) { [weak self] r in
                Util.runInMainThread {
                    if case .success = r {
                        self?.trackSubmitSuccess()
                    }
                    self?.context.editSubmitHandler?(r)
                    completion?(r)
                }
            }
        }
    }

    // nolint: long_function
    override func buildSections(builder: SettingSectionBuilder) {
        updateVideoChatConfigIfNeeded()
        let uniqueId = self.uniqueId
        let location = self.context.type == .start ? "create_cal" : "cal_detail"
        builder
            .section(header: SettingDisplayHeader(type: .titleHeader,
                                                  title: I18n.View_MV_JoinMeetingWho_GreyText,
                                                  titleTextStyle: .r_14_22))
            .checkmark(.securityLevelPublic, title: I18n.View_M_JoiningPermissionsAnyone,
                       cellStyle: .blankPaper,
                       isOn: settings.vcSecuritySetting == .public,
                       action: { [weak self] _ in
                self?.updatePermission(.public)
            })
            .checkmark(.securityLevelTenant, title: I18n.View_G_UserFromOrgOnly,
                       cellStyle: .blankPaper,
                       isOn: settings.vcSecuritySetting == .sameTenant,
                       action: { [weak self] _ in
                self?.updatePermission(.sameTenant)
            })
            .checkmark(.securityLevelCalendar, title: I18n.View_M_OnlyEventGuestsCanJoin,
                       cellStyle: .blankPaper,
                       isOn: settings.vcSecuritySetting == .onlyCalendarGuest,
                       action: { [weak self] _ in
                self?.updatePermission(.onlyCalendarGuest)
            })

            .section()
            .row(.lobbyOnEntry, reuseIdentifier: .upgradableSwitchCell, title: I18n.View_MV_OpenLobby_Switch, subtitle: I18n.View_MV_PlaceInLobby_ExplainNote, cellStyle: .blankPaper,
                 isOn: settings.putNoPermissionUserInLobby, isEnabled: service.suiteQuota().waitingRoom,
                 action: { [weak self] context in
                guard let self = self else { return }
                if self.service.suiteQuota().waitingRoom {
                    VCTracker.post(name: .vc_pre_setting_page, params: [
                        "unique_id": uniqueId, .env_id: "", .action_name: "click_enable_pre_waitingroom",
                        "action_status": context.isOn ? "1" : "0",
                        .location: location
                    ])
                    VCTracker.post(name: .vc_meeting_pre_setting_click,
                                   params: [.click: "enable_pre_waitingroom", "is_clicked": context.isOn, .location: location])
                    self.updateSetting({ $0.putNoPermissionUserInLobby = context.isOn })
                } else {
                    VCTracker.post(name: .common_pricing_popup_view,
                                   params: ["function_type": "vc_waiting_room_function", "is_presetting_panel": "presetting"])
                    if let view = context.anchorView {
                        let popoverConfig = DynamicModalPopoverConfig(sourceView: view,
                                                                      sourceRect: view.bounds.offsetBy(dx: 0, dy: -4),
                                                                      backgroundColor: .clear,
                                                                      permittedArrowDirections: [.up])
                        let regularConfig = DynamicModalConfig(presentationStyle: .popover,
                                                               popoverConfig: popoverConfig,
                                                               backgroundColor: .clear)
                        context.from?.presentDynamicModal(UpgradePremiumViewController(),
                                                          regularConfig: regularConfig,
                                                          compactConfig: .init(presentationStyle: .pan))
                    }
                    context.reloadRow()
                }
            })

            .switchCell(.allowPanelistStartMeeting, title: I18n.View_G_AllowParticipantToStart,
                        cellStyle: .blankPaper,
                        isOn: settings.canJoinMeetingBeforeOwnerJoined,
                        action: { [weak self] context in
                VCTracker.post(name: .vc_pre_setting_page, params: [
                    "unique_id": uniqueId, .env_id: "", .action_name: "click_permit_join_before_owner",
                    "action_status": context.isOn ? "1" : "0",
                    .location: location
                ])
                VCTracker.post(name: .vc_meeting_pre_setting_click,
                               params: [.click: "permit_join_before_owner", "is_clicked": context.isOn, .location: location])
                self?.updateSetting({ $0.canJoinMeetingBeforeOwnerJoined = context.isOn })
            })

        builder
            .section(header: SettingDisplayHeader(type: .titleHeader,
                                                  title: I18n.View_G_SpeakingPermissions,
                                                  titleTextStyle: .r_14_22))
            .switchCell(.muteOnEntry, title: I18n.View_G_SAMuteOnEntry,
                        cellStyle: .blankPaper,
                        isOn: settings.muteMicrophoneWhenJoin,
                        action: { [weak self] context in
                VCTracker.post(name: .vc_pre_setting_page, params: [
                    "unique_id": uniqueId, .env_id: "", .action_name: "click_auto_mute",
                    "action_status": context.isOn ? "1" : "0",
                    .location: location
                ])
                VCTracker.post(name: .vc_meeting_pre_setting_click,
                               params: [.click: "auto_mute", "is_clicked": context.isOn, .location: location])
                self?.updateSetting({ $0.muteMicrophoneWhenJoin = context.isOn })
            })
            .switchCell(.allowPartiUnmute, title: I18n.View_G_UnmuteThemselves,
                        cellStyle: .blankPaper,
                        isOn: !settings.isPartiUnmuteForbidden,
                        action: { [weak self] context in
                VCTracker.post(name: .vc_meeting_pre_setting_click,
                               params: [.click: "permit_self_opening_mic", "is_clicked": context.isOn, .location: location])
                self?.updateSetting({ $0.isPartiUnmuteForbidden = !context.isOn })
            })

        builder
            .section(header: SettingDisplayHeader(type: .titleHeader,
                                                  title: I18n.View_M_SharingPermissions,
                                                  titleTextStyle: .r_14_22))
            .switchCell(.onlyHostCanShare, title: I18n.View_G_OnlyHostCanShare,
                        cellStyle: .blankPaper,
                        isOn: settings.onlyHostCanShare,
            action: { [weak self] context in
                VCTracker.post(name: .vc_meeting_pre_setting_click,
                               params: [.click: "only_host_can_share", "is_clicked": context.isOn, .location: location])
                self?.updateSetting({ $0.onlyHostCanShare = context.isOn })
            })
            .switchCell(.onlyPresenterCanAnnotate,
                        title: I18n.View_G_OnlySharerAnnotateEdit,
                        cellStyle: .blankPaper,
                        isOn: settings.onlyPresenterCanAnnotate,
            action: { [weak self] context in
                VCTracker.post(name: .vc_meeting_pre_setting_click,
                               params: [.click: "only_presenter_can_mark", "is_clicked": context.isOn, .location: location])
                self?.updateSetting({ $0.onlyPresenterCanAnnotate = context.isOn })
            })

        builder
            .section(header: SettingDisplayHeader(type: .titleHeader,
                                                  title: I18n.View_VM_ParticipantPermissions,
                                                  titleTextStyle: .r_14_22))
            .switchCell(.allowSendMessage,
                        title: I18n.View_G_InMeetingChat,
                        cellStyle: .blankPaper,
                        isOn: settings.panelistPermission.allowSendMessage, if: service.isChatPermissionEnabled,
                        action: { [weak self] context in
                self?.updateSetting({ $0.panelistPermission.allowSendMessage = context.isOn })
            })
            .switchCell(.allowSendReaction,
                        title: I18n.View_G_SendEmoji_Tick,
                        cellStyle: .blankPaper,
                        isOn: settings.panelistPermission.allowSendReaction,
                        action: { [weak self] context in
                self?.updateSetting({ $0.panelistPermission.allowSendReaction = context.isOn })
            })
            .switchCell(.allowPartiChangeName,
                        title: I18n.View_G_ChangeMeetingName,
                        cellStyle: .blankPaper,
                        isOn: !settings.isPartiChangeNameForbidden,
                        action: { [weak self] context in
                VCTracker.post(name: .vc_meeting_pre_setting_click,
                               params: [.click: "permit_rename", "is_clicked": context.isOn, .location: location])
                self?.updateSetting({ $0.isPartiChangeNameForbidden = !context.isOn })
            })
            .switchCell(.allowRequestRecord,
                        title: I18n.View_G_RequestToRecord,
                        cellStyle: .blankPaper,
                        isOn: settings.panelistPermission.allowRequestRecord,
                        action: { [weak self] context in
                VCTracker.post(name: .vc_meeting_pre_setting_click,
                               params: [.click: "request_record", "is_clicked": context.isOn, .location: location])
                self?.updateSetting({ $0.panelistPermission.allowRequestRecord = context.isOn })
            })
            .switchCell(.allowVirtualBackground,
                        title: I18n.View_G_UseVirtualBack_Tick,
                        cellStyle: .blankPaper,
                        isOn: settings.panelistPermission.allowVirtualBackground, if: service.isVirtualBgEnabled,
                        action: { [weak self] context in
                self?.updateSetting({ $0.panelistPermission.allowVirtualBackground = context.isOn })
            })
            .switchCell(.allowVirtualAvatar,
                        title: I18n.View_G_UseAvatar_Tick,
                        cellStyle: .blankPaper,
                        isOn: settings.panelistPermission.allowVirtualAvatar, if: service.isAnimojiEnabled,
                        action: { [weak self] context in
                self?.updateSetting({ $0.panelistPermission.allowVirtualAvatar = context.isOn })
            })

            .section(if: service.adminSettings.enableRecord && service.fg("byteview.meeting.ios.auto_record"))
            .switchCell(.calendarMeetingAutoRecord,
                        title: I18n.View_G_RecordMeetingAutomatically,
                        cellStyle: .blankPaper,
                        isOn: settings.autoRecord,
                        action: { [weak self] context in
                VCTracker.post(name: .vc_pre_setting_page, params: [
                    "unique_id": uniqueId, .env_id: "", .action_name: "click_auto_record",
                    "action_status": context.isOn ? "1" : "0",
                    .location: location
                ])
                VCTracker.post(name: .vc_meeting_pre_setting_click,
                               params: [.click: "auto_record", "is_clicked": context.isOn, .location: location])
                self?.updateSetting({ $0.autoRecord = context.isOn })
            })

        let isGenerateAISummaryInMinutesEnabled = settings.intelligentMeetingSetting.generateMeetingSummaryInMinutes.isValid
        let isGenerateAISummaryInDocsEnabled = isGenerateAISummaryInMinutesEnabled && service.isMeetingNotesEnabled
        let isChatWithAIInMeetingEnabled = service.isChatWithAiEnabled
        let isSmartMeetingSectionDisplayEnabled = service.adminSettings.enableRecordAiSummary && (isGenerateAISummaryInMinutesEnabled || isGenerateAISummaryInDocsEnabled || isChatWithAIInMeetingEnabled)
        builder
            .section(header: SettingDisplayHeader(type: .titleAndRedirectDescriptionHeader,
                                                  title: I18n.View_G_SmartMeeting_Tab,
                                                  description: I18n.View_G_AIMinutesNewAgain_Desc,
                                                  serviceTerms: service.myAiOnboardingConfig.serviceTerms),
                     if: isSmartMeetingSectionDisplayEnabled)
            .switchCell(.generateAiSummaryInMinutes,
                        title: I18n.View_G_UseAINotesInMinutes_Desc,
                        isOn: settings.intelligentMeetingSetting.generateMeetingSummaryInMinutes.isOn,
                        if: isGenerateAISummaryInMinutesEnabled,
                        action: { [weak self] context in
                self?.updateSetting({ $0.intelligentMeetingSetting.generateMeetingSummaryInMinutes = context.isOn ? .on : .off })
            })
            .switchCell(.generateAiSummaryInNotes,
                        title: I18n.View_G_UseAINotesInDocs_Desc,
                        isOn: settings.intelligentMeetingSetting.generateMeetingSummaryInDocs.isOn,
                        if: isGenerateAISummaryInDocsEnabled,
                        action: { [weak self] context in
                self?.updateSetting({ $0.intelligentMeetingSetting.generateMeetingSummaryInDocs = context.isOn ? .on : .off })
            })
            .switchCell(.chatWithAiInMeet,
                        title: I18n.View_G_UseAIDuringMeetings_Desc,
                        isOn: settings.intelligentMeetingSetting.chatWithAiInMeeting.isOn,
                        if: isChatWithAIInMeetingEnabled,
                        action: { [weak self] context in
                self?.updateSetting({ $0.intelligentMeetingSetting.chatWithAiInMeeting = context.isOn ? .on : .off })
            })

        // 添加主持人
        let hostUids = settings.backupHostUids.map { ByteviewUser(id: $0, type: .larkUser) }
        builder
            .section()
            .row(.addHostHeader, reuseIdentifier: .calendarHeaderCell, title: I18n.View_G_AlternativeHosts_Subtitle, subtitle: I18n.View_G_AssignHostRule, cellStyle: .blankPaper)
        for userInfo in backupHostInfos {
            builder.calendarBackupHostCell(userInfo: userInfo) { [weak self] userId in
                self?.removeHost(userId)
            }
        }
        if !hostUids.isEmpty {
            builder.row(.paddingCell, reuseIdentifier: .emptyPaddingCell, title: "")
        }
        builder.row(.addHost, reuseIdentifier: .addInterpreterCell, title: I18n.View_G_AddHosts,
                    cellStyle: .blankPaper, action: { [weak self] _ in self?.addHost() })


        // 传译
        builder.section()
            .row(.addInterpreterHeader, reuseIdentifier: .calendarHeaderCell, title: I18n.View_G_Interpretation, cellStyle: .blankPaper)

        for (index, interpreter) in settings.interpretationSetting.interpreterSettings.enumerated() {
            let channel = InterpretationChannelInfo(index: index, interpreter: interpreter)
            builder
                .editInterpreterCell(channel: channel, delegate: self)
        }
        builder.row(.addInterpreter, reuseIdentifier: .addInterpreterCell, title: I18n.View_G_AddInterpreter,
                    cellStyle: .blankPaper,
                    data: ["showInfo": !service.suiteQuota().interpretation], action: { [weak self] _ in self?.addInterpreter() })

        let saveHostEnabled = hostUids.count <= 10
        let saveInterpreterEnabled = settings.interpretationSetting.interpreterSettings.allSatisfy { $0.isPreSetFull }
        isSaveButtonEnabled = saveHostEnabled && saveInterpreterEnabled
    }

    private func onLoadSetting(_ settings: CalendarSettings?) {
        isSettingLoaded = true
        if let settings = settings {
            self.settings = settings
        }
        if let backupHostUids = settings?.backupHostUids, !backupHostUids.isEmpty {
            let pids = backupHostUids.map { ByteviewUser(id: $0, type: .larkUser) }
            httpClient.participantService.participantInfo(pids: pids, meetingId: nil) { [weak self] infos in
                guard self?.settings.backupHostUids == backupHostUids else { return }
                self?.backupHostInfos = infos
                Util.runInMainThread {
                    self?.reloadData()
                }
            }
        } else {
            reloadData()
        }
    }

    private func updatePermission(_ permission: CalendarSettings.SecuritySetting) {
        let trackText = permission.trackText
        let location = context.type == .start ? "create_cal" : "cal_detail"
        VCTracker.post(name: .vc_pre_setting_page, params: [
            "unique_id": uniqueId, .env_id: "",
            .action_name: "change_permission", "action_status": trackText,
            .location: location
        ])
        VCTracker.post(name: .vc_meeting_pre_setting_click, params: [
            .click: "change_permission", "is_clicked": trackText, .location: location
        ])
        updateSetting({ $0.vcSecuritySetting = permission })
    }

    private func updateSetting(_ action: (inout CalendarSettings) -> Void) {
        var settings = self.settings
        action(&settings)
        self.settings = settings
        self.reloadData()
    }

    private func updateVideoChatConfigIfNeeded() {
        if settings.isOrganizer, service.suiteQuota().interpretation {
            service.refreshVideoChatConfig(force: false)
        }
    }

    private func addHost() {
        guard settings.isOrganizer else {
            showToast(I18n.View_G_OrganizerCanAssign)
            return
        }
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
        self.hostViewController?.presentDynamicModal(vc, config: DynamicModalConfig(presentationStyle: .formSheet, needNavigation: true))
    }

    private func removeHost(_ uid: String) {
        backupHostInfos.removeAll { $0.id == uid }
        updateSetting {
            $0.backupHostUids.removeAll { $0 == uid }
        }
    }

    private func addInterpreter() {
        guard settings.isOrganizer else {
            showToast(I18n.View_G_OnlySetInterpreter)
            return
        }
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

    private func trackSubmitSuccess() {
        let permission = settings.vcSecuritySetting.trackText
        VCTracker.post(name: .vc_pre_setting_page, params: [
            "unique_id": uniqueId,
            .env_id: "",
            .action_name: "click_back",
            "is_auto_mute_clicked": settings.muteMicrophoneWhenJoin ? 1 : 0,
            "permission": permission,
            "is_prewaitingroom_enabled": settings.putNoPermissionUserInLobby ? 1 : 0,
            "is_join_before_owner_clicked": settings.canJoinMeetingBeforeOwnerJoined ? 1 : 0,
            "is_auto_record_clicked": settings.autoRecord ? 1 : 0,
            .location: context.type == .start ? "create_cal" : "cal_detail"
        ])
        // 确定返回后上报所有设置
        VCTracker.post(name: .vc_meeting_pre_setting_click, params: [
            .click: "confirm",
            .target: "cal_event_detail_view",
            "is_change_permission": permission,
            "is_enable_pre_waitingroom": settings.putNoPermissionUserInLobby,
            "is_permit_join_before_owner": settings.canJoinMeetingBeforeOwnerJoined,
            "is_auto_mute": settings.muteMicrophoneWhenJoin,
            "is_auto_record": settings.autoRecord,
            "is_permit_self_opening_mic": !settings.isPartiUnmuteForbidden,
            "is_only_host_can_share": settings.onlyHostCanShare,
            "is_only_presenter_can_mark": settings.onlyPresenterCanAnnotate,
            "is_permit_rename": !settings.isPartiChangeNameForbidden,
            "is_set_host": !settings.backupHostUids.isEmpty,
            "is_set_interpreter": !settings.interpretationSetting.interpreterSettings.isEmpty,
            "send_message_permission": settings.panelistPermission.allowSendMessage,
            "send_reaction_permission": settings.panelistPermission.allowSendReaction,
            "host_list": settings.backupHostUids.map { EncryptoIdKit.encryptoId($0) },
            .location: context.type == .start ? "create_cal" : "cal_detail"
        ])
    }

    override func didChangeUserSetting(_ setting: UserSettingManager, _ data: UserSettingChange) {
        guard isSettingLoaded else { return }
        super.didChangeUserSetting(setting, data)
    }
}

extension CalendarSettingViewModel: EditInterpreterCellDelegate {
    var selectedInterpreters: [ByteViewNetwork.SetInterpreter] {
        self.settings.interpretationSetting.interpreterSettings
    }

    var supportedInterpretationLanguage: [ByteViewNetwork.InterpreterSetting.LanguageType] {
        self.service.videoChatConfig.meetingSupportInterpretationLanguage
    }

    func canEditInterpreter(_ channel: InterpretationChannelInfo) -> Bool {
        guard settings.isOrganizer else {
            showToast(I18n.View_G_OnlySetInterpreter)
            return false
        }
        return true
    }

    func didRemoveInterpreter(_ channel: InterpretationChannelInfo) {
        self.updateSetting { settings in
            settings.interpretationSetting.interpreterSettings.removeAll {
                $0.interpreterSetting?.interpreterSetTime == channel.interpreterSetting?.interpreterSetTime
            }
        }
    }

    func didModifyInterperter(_ channel: InterpretationChannelInfo, action: (inout SetInterpreter) -> Void) {
        if let index = self.settings.interpretationSetting.interpreterSettings.firstIndex(where: {
            $0.interpreterSetting?.interpreterSetTime == channel.interpreterSetting?.interpreterSetTime
        }) {
            self.updateSetting {
                action(&$0.interpretationSetting.interpreterSettings[index])
            }
        }
    }
}

private extension CalendarSettings.SecuritySetting {
    var trackText: String {
        switch self {
        case .public:
            return "anyone"
        case .sameTenant:
            return "organizer_company"
        case .onlyCalendarGuest:
            return "event_guest"
        }
    }
}

extension SetInterpreter {
    var isPreSetFull: Bool {
        if self.user.id.isEmpty {
            return false
        }
        guard let setting = self.interpreterSetting else {
            return false
        }
        return !setting.firstLanguage.languageType.isEmpty && !setting.secondLanguage.languageType.isEmpty
    }
}

extension ByteviewUser {
    static let emptyUser = ByteviewUser(id: "", type: .larkUser)
}
