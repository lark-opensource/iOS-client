//
//  ParticipantsViewModel.swift
//  ByteView
//
//  Created by LUNNER on 2019/1/9.
//

import Foundation
import RxSwift
import ByteViewCommon
import ByteViewNetwork
import ByteViewUI
import ByteViewSetting

// parameters: ParticipantId, isLarkGuest
typealias JumpToUserProfile = ((ParticipantId, Bool) -> Void)

enum ParticipantsListState: Equatable {
    case none, lock
    case overlay(members: Int)

    var toastText: String? {
        switch self {
        case .none: return nil
        case .lock: return I18n.View_MV_MeetingLocked_Toast
        case .overlay(let members): return I18n.View_M_LimitReachedMaxMemberBraces(members)
        }
    }
}

final class ParticipantsViewModel: InMeetMeetingProvider {
    static let logger = Logger.ui
    let disposeBag = DisposeBag()
    let resolver: InMeetViewModelResolver
    let meeting: InMeetMeeting
    let statusReactionViewModel: InMeetStatusReactionViewModel?
    @RwAtomic var inMeetIds: [String] = []
    @RwAtomic var attendeeIds: [String] = []
    var duplicatedIds: Set<String> { Set(Dictionary(grouping: inMeetIds + attendeeIds, by: { $0 }).filter { $0.value.count > 1 }.map { $0.key }) }
    var currentUserId: String { meeting.userId }

    var meetingRole: ParticipantMeetingRole { meeting.myself.meetingRole }
    var magicShareDocument: MagicShareDocument? { meeting.shareData.shareContentScene.magicShareDocument }
    var canInvite: Bool { meeting.setting.canInvite }
    /// 收到参会人变更时，inMeetingInfo 为空
    @RwAtomic var updateParticipantsAfterMeetingInfoChanged = false

    var suggestionConfig: SuggestionConfig {
        meeting.setting.suggestionConfig
    }

    // --- 状态表情 ---
    var hasParticipantHandUp: Bool {
        numberOfHandsUp > 0
    }
    var handsUpDescription: String {
        I18n.View_G_NumberRaisedHand(numberOfHandsUp)
    }
    private var numberOfHandsUp: Int {
        self.statusReactionViewModel?.count ?? 0
    }

    private var participantsConfig: ParticipantsConfig {
        meeting.setting.participantsConfig
    }
    /// 参会人列表数据源（main thread only）
    private(set) var participantDataSource: [ParticipantsSectionModel] = []
    @RwAtomic private(set) var participantSectionModels: [ParticipantsSectionModel] = []
    lazy var participantReloadTrigger = StrategyTrigger<Void>(with: .milliseconds(participantsConfig.allTabReladMilliseconds), id: "participantReload") { [weak self] _ in
        guard let self = self else { return }
        let newDataSource = self.participantSectionModels
        DispatchQueue.main.async {
            // 更新数据源
            self.participantDataSource = newDataSource
            self.listerners.forEach { $0.participantDataSourceDidChange(self.participantDataSource) }
        }
    }
    lazy var didChangeParticipantsTrigger = StrategyTrigger<ParticipantsChangeModel>(with: .milliseconds(participantsConfig.participantConsumeMillisecond), id: "participantChange") { [weak self] changeModel in
        self?.participantsToInviteInMeetCellModels(changeModel)
    }
    lazy var didChangeLobbysTrigger = StrategyTrigger<[LobbyParticipant]>(with: .milliseconds(participantsConfig.lobbyConsumeMillisecond), id: "lobbyChange") { [weak self] lobbyParticipants in
        var lobbys: [LobbyParticipant] = []
        var attendeeLobbys: [LobbyParticipant] = []
        lobbyParticipants.forEach {
            if $0.participantMeetingRole == .webinarAttendee {
                attendeeLobbys.append($0)
            } else {
                lobbys.append($0)
            }
        }
        self?.lobbyParticipantsToLobbyCellModels(lobbys)
        self?.attendeeLobbyParticipantsToLobbyCellModels(attendeeLobbys)
    }

    /// 等候section数据源
    var lobbySectionModel: ParticipantsSectionModel? {
        participantSectionModels.first(where: { $0.itemType == .lobby })
    }
    /// 邀请section数据源（V5.16+ 除了 ringing 状态，还可能有 idle 状态）
    var invitedSectionModel: ParticipantsSectionModel? {
        participantSectionModels.first(where: { $0.itemType == .invite })
    }
    /// 邀请列表中的呼叫反馈参会人（缓存一份，空间换时间）
    @RwAtomic private(set) var feedbackCellModels: [InvitedParticipantCellModel] = []
    /// 会中section数据源
    var inMeetSectionModel: ParticipantsSectionModel? {
        participantSectionModels.first(where: { $0.itemType == .inMeet })
    }

    /// 建议列表/拒绝列表下发数据
    @RwAtomic private var suggestedChanged: InMeetingSuggestedParticipantsChanged?
    /// 「已拒绝日程的参会人」数据
    @RwAtomic var calendarRejectParticpants: [Participant] = []
    /// 初始拒绝列表人数
    @RwAtomic var calendarRejectDefaultCount: Int64 = 0
    /// 建议列表数据源（main thread only）
    var suggestionDataSource: [SuggestionParticipantCellModel] = []
    @RwAtomic var suggestionCellModels: [SuggestionParticipantCellModel] = []
    /// webinar 建议参会数据源
    var werbinarSuggestSectionModel: ParticipantsSectionModel? {
        participantSectionModels.first(where: { $0.itemType == .suggest })
    }

    /// 建议列表是否多选态
    var suggestionIsMultiple: Bool = false {
        didSet {
            if suggestionIsMultiple != oldValue {
                changeSuggestionMultiple(suggestionIsMultiple)
            }
        }
    }
    /// 批量邀请冷却期
    var inviteCooling: Bool = false

    /// 观众列表数据源（main thread only）
    var attendeeDataSource: [ParticipantsSectionModel] = []
    @RwAtomic var attendeeSectionModels: [ParticipantsSectionModel] = []
    lazy var attendeeReloadTrigger = StrategyTrigger<Void>(with: .milliseconds(participantsConfig.allTabReladMilliseconds), id: "attendeeReload") { [weak self] _ in
        guard let self = self else { return }
        let newDataSource = self.attendeeSectionModels
        DispatchQueue.main.async {
            // 更新数据源
            self.attendeeDataSource = newDataSource
            self.listerners.forEach { $0.attendeeDataSourceDidChange(self.attendeeDataSource) }
        }
    }
    lazy var didChangeAttendeesTrigger = StrategyTrigger<[Participant]>(with: .milliseconds(participantsConfig.attendeeConsumeMillisecond), id: "attendeeChange") { [weak self] attendees in
        self?.participantsToAttendeeCellModels(attendees)
    }
    @RwAtomic var attendeeCollapsedTypes: Set<ParticipantState> = []
    func updateAttendeeCollapsedTypes(_ types: Set<ParticipantState>) {
        if self.attendeeCollapsedTypes != types {
            self.attendeeCollapsedTypes = types
            updateAttendeeDataSourceCollapsedStyle(attendeeSectionModels)
            attendeeReloadTrigger.excute(())
        }
    }
    /// 观众列表人数
    @RwAtomic var attendeeNum: Int64 = 0

    /// 搜索列表数据源
    @RwAtomic private(set) var searchDataSource: [SearchParticipantCellModel] = []

    var canUnMuteAll: Bool {
        // maxSoftRtcNormalMode即千人会议中的x定义
        meeting.participant.currentRoom.count <= meeting.setting.maxSoftRtcNormalMode
    }

    /// 举手状态表情个数
    var reactionHandsUpCount: Int {
        if let vm = statusReactionViewModel, vm.showHandsUpStatus {
            return vm.count
        }
        return 0
    }
    /// webinar 观众举手状态表情个数
    var reactionHandsUpAttendeeCount: Int {
        if isWebinar, let vm = statusReactionViewModel, vm.showHandsUpStatus {
            return vm.attendeeCount
        }
        return 0
    }

    weak var manipulatorActionSheet: ActionSheetController?

    let breakoutRoom: BreakoutRoomManager?
    private var breakoutRoomData: BreakoutRoomData?
    private(set) var participantListState: ParticipantsListState = .none
    private lazy var logDescription = metadataDescription(of: self)
    private var isUpgraded = false

    /// 上次展开邀请action sheet时，对应的参会人ID
    var lastPIDForShowingInvite: String?

    /// 用于参会人搜索
    private let searchQueue = DispatchQueue(label: "com.lark.meeting.participantSearch", qos: .userInitiated)

    /// 呼叫反馈
    @RwAtomic private(set) var invitedFeedbackParticipants: [String: Participant] = [:] // key 为 ringingIdentifier
    /// 用于呼叫反馈展示计时
    @RwAtomic private var invitedFeedbackTimes: [String: TimeInterval] = [:] // key 为 ringingIdentifier

    let actionService: ParticipantActionService

    /// notify data source changed
    let listerners = Listeners<ParticipantsViewModelListener>()
    func addListener(_ listener: ParticipantsViewModelListener, fireImmediately: Bool = true) {
        listerners.addListener(listener)
        if !fireImmediately { return }

        DispatchQueue.main.async {
            if !self.participantDataSource.isEmpty {
                listener.participantDataSourceDidChange(self.participantDataSource)
            }
            if !self.suggestionDataSource.isEmpty {
                listener.suggestionDataSourceDidChange(self.suggestionDataSource)
            }
            if !self.attendeeDataSource.isEmpty {
                listener.attendeeDataSourceDidChange(self.attendeeDataSource)
            }
        }
        if attendeeNum != 0 {
            listener.attendeeNumDidChange(attendeeNum)
        }
        if !calendarRejectParticpants.isEmpty || calendarRejectDefaultCount != 0 {
            listener.calendarRejectParticipantsDidChange(calendarRejectParticpants, initialCount: calendarRejectDefaultCount)
        }
        if !searchDataSource.isEmpty {
            listener.searchDataSourceDidChange(searchDataSource)
        }
        listener.muteAllAuthorityChange()
        if let breakoutRoomData = breakoutRoomData {
            listener.breakoutRoomDataDidChange(breakoutRoomData)
        }
        if participantListState != .none {
            listener.participantsListStateDidChange(participantListState)
        }
        listener.settingFeatureEnabled(meeting.setting.showsHostControl)
    }

    init(resolver: InMeetViewModelResolver) {
        self.resolver = resolver
        self.meeting = resolver.meeting
        self.breakoutRoom = resolver.resolve()
        self.statusReactionViewModel = resolver.resolve(InMeetStatusReactionViewModel.self)
        self.actionService = ParticipantActionService(meeting: meeting, context: resolver.viewContext)
        self.breakoutRoom?.addObserver(self)
        if let lobby = resolver.resolve(InMeetLobbyViewModel.self) {
            if !lobby.participants.isEmpty {
                didChangeLobbyParticipants(lobby.participants)
            }
            lobby.addObserver(self)
        }
        meeting.addMyselfListener(self)
        meeting.data.addListener(self)
        meeting.shareData.addListener(self)
        meeting.participant.addListener(self)
        meeting.setting.addListener(self, for: [.canCancelInvite, .showsHostControl, .isHostControlEnabled, .isHostEnabled, .showsAskHostForHelp, .hasCohostAuthority])

        updateCancelAllInvitedButton()
        updateSettingFeature()
        updateMeetingRole()
        updateBreakoutRoomData()
        statusReactionViewModel?.addObserver(self)
        meeting.participant.pullSuggestionTrigger.excute(())
        Self.logger.info("init \(logDescription)")
    }

    deinit {
        Self.logger.info("deinit \(logDescription)")
    }

    // MARK: - Participant: Invite + InMeet

    /// [Participant] to [InMeetParticipantCellModel] + [InvitedParticipantCellModel]
    private func participantsToInviteInMeetCellModels(_ changeModel: ParticipantsChangeModel) {
        // 更新多设备信息
        let oldInMeetIds = inMeetIds
        inMeetIds = changeModel.onTheCalls.map { $0.user.id }
        // 构建cellModel
        if changeModel.isEmpty {
            feedbackCellModels = []
            updateCellModelsIfNeeded(inMeetCellModels: [], invitedCellModels: [])
        } else {
            let duplicatedParticipantIds = duplicatedIds
            let hasCohostAuthority = meeting.setting.hasCohostAuthority
            let hostEnabled = meeting.setting.isHostEnabled
            let meetingSubType = meeting.subType
            let roleStrategy = meeting.data.roleStrategy
            var inMeetCellModels: [InMeetParticipantCellModel] = []
            var invitedCellModels: [InvitedParticipantCellModel] = []
            var invitedFeedbackCellModels: [InvitedParticipantCellModel] = []
            let updateIsHost: (inout Participant, MeetingRoleStrategy) -> Void = { p, roleStrategy in
                let role = p.role
                p.isHost = p.isHost && !p.isLarkGuest && roleStrategy.participantCanBecomeHost(role: role)
            }
            for p in changeModel.callings {
                var participant = p
                updateIsHost(&participant, roleStrategy)
                let inviteCellModel = createInvitedCellModel(participant, hasCohostAuthority: hasCohostAuthority, meetingSubType: meetingSubType)
                invitedCellModels.append(inviteCellModel)
            }
            for p in changeModel.feedbacks {
                var participant = p
                updateIsHost(&participant, roleStrategy)
                let inviteCellModel = createInvitedCellModel(participant, hasCohostAuthority: hasCohostAuthority, meetingSubType: meetingSubType)
                invitedCellModels.append(inviteCellModel)
                invitedFeedbackCellModels.append(inviteCellModel)
            }
            for p in changeModel.onTheCalls {
                var participant = p
                updateIsHost(&participant, roleStrategy)
                let inMeetCellModel = createInMeetCellModel(participant, duplicatedParticipantIds: duplicatedParticipantIds, hasCohostAuthority: hasCohostAuthority, hostEnabled: hostEnabled)
                inMeetCellModels.append(inMeetCellModel)
            }
            // 更新呼叫反馈
            feedbackCellModels = invitedFeedbackCellModels
            // 排序
            inMeetCellModels = sortInMeetParticipantCellModels(inMeetCellModels)
            invitedCellModels = sortInvitedParticipantCellModels(invitedCellModels)
            // 更新数据源
            updateCellModelsIfNeeded(inMeetCellModels: inMeetCellModels, invitedCellModels: invitedCellModels)
        }
        // 更新观众多设备信息
        if oldInMeetIds != inMeetIds {
            updateAttendeeDeviceImgChanged()
        }
    }

    ///  sorted [InMeetParticipantCellModel]
    private func sortInMeetParticipantCellModels(_ cellModels: [InMeetParticipantCellModel]) -> [InMeetParticipantCellModel] {
        // rust在拆分participants时去除了排序逻辑，端上自行排序
        return ParticipantsSortTool.partitionAndSort(cellModels, currentUser: meeting.account)
    }

    /// sorted [InvitedParticipantCellModel]
    private func sortInvitedParticipantCellModels(_ cellModels: [InvitedParticipantCellModel]) -> [InvitedParticipantCellModel] {
        // rust在拆分participants时去除了排序逻辑，端上自行排序
        return ParticipantsSortTool.partitionAndSort(cellModels, currentUser: meeting.account)
    }

    /// insert [InMeetParticipantCellModel] & [InvitedParticipantCellModel] in data source
    private func updateCellModelsIfNeeded(inMeetCellModels: [InMeetParticipantCellModel], invitedCellModels: [InvitedParticipantCellModel]) {
        // 构造section
        let newInMeetSection = createInMeetSection(inMeetCellModels)
        let newInvitedSection = createInvitedSection(invitedCellModels)
        // 按需更新
        updateParticipantsSectionsIfNeeded(newInMeetSection: newInMeetSection, newInvitedSection: newInvitedSection)
    }

    private func createInMeetSection(_ inMeetCellModels: [InMeetParticipantCellModel]) -> ParticipantsSectionModel {
        let header = I18n.View_MV_InMeetingWithNumber(inMeetCellModels.count)
        let newInMeetSection = ParticipantsSectionModel(header: header, itemType: .inMeet, items: inMeetCellModels)
        return newInMeetSection
    }

    private func createInvitedSection(_ invitedCellModels: [InvitedParticipantCellModel]) -> ParticipantsSectionModel? {
        var newInvitedSection: ParticipantsSectionModel?
        if !invitedCellModels.isEmpty {
            // 计数时剔除呼叫反馈
            let ringingCount = invitedCellModels.count - feedbackCellModels.count
            let header = I18n.View_MV_CallingWithNumber(ringingCount)
            let showButton = meeting.setting.canCancelInvite && ringingCount > 1
            let actionName = showButton ? I18n.View_MV_CancelAll_BlueButton : ""
            newInvitedSection = ParticipantsSectionModel(header: header, actionName: actionName, itemType: .invite, items: invitedCellModels)
        }
        return newInvitedSection
    }

    private func updateParticipantsSectionsIfNeeded(newInMeetSection: ParticipantsSectionModel?, newInvitedSection: ParticipantsSectionModel?) {
        if invitedSectionModel == newInvitedSection, inMeetSectionModel == newInMeetSection {
            Self.logger.debug("participant dataSource no need update inviting or inMeeting")
            return
        } else if invitedSectionModel == newInvitedSection {
            // 邀请人员相同，仅更新会中
            Self.logger.debug("participant dataSource update inMeet count: \(newInMeetSection?.items.count)")
            updateParticipantDataSouce(lobbySection: lobbySectionModel, invitedSection: invitedSectionModel, inMeetSection: newInMeetSection, webinarSuggestSection: werbinarSuggestSectionModel)
        } else if inMeetSectionModel == newInMeetSection {
            // 会中人员相同，仅更新邀请
            Self.logger.debug("participant dataSource update invite count: \(newInvitedSection?.items.count)")
            updateParticipantDataSouce(lobbySection: lobbySectionModel, invitedSection: newInvitedSection, inMeetSection: inMeetSectionModel, webinarSuggestSection: werbinarSuggestSectionModel)
        } else {
            // 会中和邀请都要更新
            Self.logger.debug("participant dataSource update invite count: \(newInvitedSection?.items.count), inMeet count: \(newInMeetSection?.items.count)")
            updateParticipantDataSouce(lobbySection: lobbySectionModel, invitedSection: newInvitedSection, inMeetSection: newInMeetSection, webinarSuggestSection: werbinarSuggestSectionModel)
        }
    }

    // MARK: Participant: Lobby
    /// [LobbyParticipant] to [LobbyParticipantCellModel]
    private func lobbyParticipantsToLobbyCellModels(_ lobbyParticipants: [LobbyParticipant]) {
        if lobbyParticipants.isEmpty {
            didChangeLobbyCellModels([])
            return
        }
        let showRoomInfo = meeting.data.roleStrategy.showRoomInfo
        var cellModels: [LobbyParticipantCellModel] = []
        for lobbyParticipant in lobbyParticipants {
            let cellModel = createLobbyCellModel(lobbyParticipant, showRoomInfo: showRoomInfo)
            cellModels.append(cellModel)
        }
        didChangeLobbyCellModels(cellModels)
    }

    /// insert [LobbyParticipantCellModel] in data source
    private func didChangeLobbyCellModels(_ cellModels: [LobbyParticipantCellModel]) {
        var newLobbySection: ParticipantsSectionModel?
        if !cellModels.isEmpty {
            let header = I18n.View_MV_WaitingWithNumber(cellModels.count)
            let showButton = cellModels.count > 1
            let actionName = showButton ? I18n.View_M_AdmitAllButton : ""
            newLobbySection = ParticipantsSectionModel(header: header, actionName: actionName, itemType: .lobby, items: cellModels)
        }
        if lobbySectionModel == newLobbySection {
            Self.logger.debug("participant dataSource no need update lobby")
            return
        }
        Self.logger.debug("participant dataSource update lobby count: \(newLobbySection?.realItems.count)")
        updateParticipantDataSouce(lobbySection: newLobbySection, invitedSection: invitedSectionModel, inMeetSection: inMeetSectionModel, webinarSuggestSection: werbinarSuggestSectionModel)
    }

    // MARK: Participant: update
    func updateParticipantDataSouce(lobbySection: ParticipantsSectionModel?, invitedSection: ParticipantsSectionModel?,
                                    inMeetSection: ParticipantsSectionModel?, webinarSuggestSection: ParticipantsSectionModel?) {
        // 顺序 : 呼叫中 > 等候中 > 在会中 > Webinar 建议参会
        var elements: [ParticipantsSectionModel] = []
        if let e0 = invitedSection {
            elements.append(e0)
        }
        if let e1 = lobbySection {
            elements.append(e1)
        }
        if let e2 = inMeetSection {
            elements.append(e2)
        }
        if let e3 = webinarSuggestSection {
            elements.append(e3)
        }
        updateDataSourceCollapsedStyle(elements)
        updateParticipantDataSource(elements)
        updateBreakoutRoomData()
    }

    private func updateMeetingRole() {
        var apply = false
        participantSectionModels.forEach { section in
            section.realItems.forEach { item in
                if let model = item as? ParticipantCellModelUpdate {
                    model.updateRole(with: meeting)
                    if !apply { apply = true }
                }
            }
        }
        if apply {
            participantReloadTrigger.excute(())
        }
    }

    private func updateShareContentChanged() {
        var apply = false
        participantSectionModels.forEach { section in
            section.realItems.forEach { item in
                if let model = item as? ParticipantCellModelUpdate {
                    model.updateShowShareIcon(with: meeting.data.inMeetingInfo)
                    if !apply { apply = true }
                }
            }
        }
        if apply {
            reSortInMeetCellModels()
            participantReloadTrigger.excute(())
        }
    }

    private func updateFocusChanged() {
        var apply = false
        participantSectionModels.forEach { section in
            section.realItems.forEach { item in
                if let model = item as? ParticipantCellModelUpdate {
                    model.updateShowFocus(with: meeting.data.inMeetingInfo)
                    if !apply { apply = true }
                }
            }
        }

        if apply {
            reSortInMeetCellModels()
            participantReloadTrigger.excute(())
        }
    }

    func updateDeviceImgChanged() {
        var apply = false
        participantSectionModels.forEach { section in
            section.realItems.forEach { item in
                if let model = item as? ParticipantCellModelUpdate {
                    model.updateDeviceImg(with: duplicatedIds)
                    if !apply { apply = true }
                }
            }
        }

        if apply {
            participantReloadTrigger.excute(())
        }
    }

    func updateAttendeeDeviceImgChanged() {
        var apply = false
        attendeeSectionModels.forEach { section in
            section.realItems.forEach { item in
                if let model = item as? ParticipantCellModelUpdate {
                    model.updateDeviceImg(with: duplicatedIds)
                    if !apply { apply = true }
                }
            }
        }

        if apply {
            attendeeReloadTrigger.excute(())
        }
    }

    /// 对会中的人重排序
    private func reSortInMeetCellModels() {
        if let inMeetSectionModel = inMeetSectionModel {
            // 排序
            let models = inMeetSectionModel.realItems.compactMap { $0 as? InMeetParticipantCellModel }
            let inMeetCellModels = sortInMeetParticipantCellModels(models)
            let sections = ParticipantsSectionModel(header: inMeetSectionModel.header, headerIcon: inMeetSectionModel.headerIcon, actionName: inMeetSectionModel.actionName, state: .joined, itemType: inMeetSectionModel.itemType, items: inMeetCellModels)
            updateParticipantsSectionsIfNeeded(newInMeetSection: sections, newInvitedSection: nil)
        }
    }

    @RwAtomic
    private(set) var collapsedTypes: Set<ParticipantState> = []
    func updateCollapsedTypes(_ types: Set<ParticipantState>) {
        if self.collapsedTypes != types {
            self.collapsedTypes = types
            updateDataSourceCollapsedStyle(participantSectionModels)
            participantReloadTrigger.excute(())
        }
    }

    private func updateDataSourceCollapsedStyle(_ dataSource: [ParticipantsSectionModel]) {
        // handle collaspe/expand state
        if dataSource.count == 1, let inMeetSection = dataSource.first(where: { $0.itemType == .inMeet }),
           collapsedTypes.contains(.joined) {
            // 如果只有joined分组，则展开分组
            collapsedTypes.remove(.joined)
            inMeetSection.headerIcon = .expandDownN2
            inMeetSection.recoverItems()
            inMeetSection.recoverActionName()
            return
        }

        dataSource.forEach { sectionModel in
            if collapsedTypes.contains(sectionModel.itemType.state) {
                sectionModel.headerIcon = .expandRightN2
                sectionModel.clearItems()
                sectionModel.clearActionName()
            } else {
                sectionModel.headerIcon = .expandDownN2
                sectionModel.recoverItems()
                sectionModel.recoverActionName()
            }
        }
    }

    private func updateParticipantListState() {
        var state: ParticipantsListState = .none
        let isLockWarn = meeting.setting.isMeetingLocked && !meeting.setting.canInviteWhenLocked
        if isLockWarn {
            state = .lock
        } else {
            let maxNumber = meeting.setting.maxParticipantNum + meeting.setting.maxAttendeeNum
            let currentNumber = meeting.participant.currentRoom.count + meeting.participant.attendee.count
            if currentNumber >= maxNumber {
                state = .overlay(members: maxNumber)
            }
        }
        if state != participantListState {
            participantListState = state
            listerners.forEach { $0.participantsListStateDidChange(state) }
        }
    }

    private func updateParticipantDataSource(_ newSectionModels: [ParticipantsSectionModel]) {
        // 更新数据源缓存
        participantSectionModels = newSectionModels
        participantReloadTrigger.excute(())
    }

    // MARK: - Search
    /// Parameter complet: hasResult -> Void
    func searchAction(with keyword: String, complet: @escaping ((Bool) -> Void)) {
        searchParticipants(keyword: keyword) { [weak self] (shouldCallback, cellModels, _) in
            if shouldCallback {
                complet(!cellModels.isEmpty)
                self?.didChangeSearchCellModels(cellModels)
            }
        }
    }

    /// replace [SearchParticipantCellModel] to data source
    private func didChangeSearchCellModels(_ cellModels: [SearchParticipantCellModel]) {
        guard searchDataSource != cellModels else {
            Self.logger.debug("participant dataSource no need update search")
            return
        }
        Self.logger.debug("participant dataSource update search count: \(cellModels.count)")
        searchDataSource = cellModels
        listerners.forEach { $0.searchDataSourceDidChange(cellModels) }
    }

    private var searchRequestKey = ""
    /// [SearchResult] to [SearchParticipantCellModel]
    /// Parameter completion: (shouldCallback, result, hasMore)
    private func searchParticipants(keyword: String, completion: @escaping (Bool, [SearchParticipantCellModel], Bool) -> Void) {
        if keyword.isEmpty {
            completion(true, [], false)
            return
        }

        Self.logger.debug("start search: kw = \(keyword.hash)")
        let key = UUID().uuidString
        self.searchRequestKey = key
        let canShowExternal = self.meeting.accountInfo.canShowExternal
        // 获取搜索结果
        // nolint-next-line: magic number
        let request = SearchParticipantRequest(meetingId: self.meetingId, breakoutRoomId: meeting.setting.breakoutRoomId, query: keyword, count: 50, queryType: .queryAll)
        self.httpClient.getResponse(request, context: request) { [weak self] (result) in
            guard let self = self, self.searchRequestKey == key else { // 过滤旧请求
                completion(false, [], false)
                return
            }

            guard let resp = result.value else {
                completion(true, [], false)
                return
            }

            Self.logger.debug("searching finished: kw = \(keyword.hash), result = \(resp.users.count)")
            // try fix crash https://t.wtturl.cn/UHU1Y5C/
            self.searchQueue.async {
                let hasMore = false
                var pids: [ParticipantId] = []
                var lobbys: [LobbyParticipant] = []
                var boxes: [(String?, String?, ParticipantSearchBox)] = []
                for r in resp.users {
                    if let user = r.toUser(canShowExternal: canShowExternal) {
                        let box = ParticipantSearchUserBox(user, highlightPattern: keyword)
                        if box.state == .joined || box.state == .inviting, let p = user.participant {
                            pids.append(p.participantId)
                            boxes.append((p.identifier, nil, box))
                        } else if box.state == .idle || box.state == .busy, let p = user.byteviewUser {
                            pids.append(p.participantId)
                            boxes.append((p.identifier, nil, box))
                        } else if box.state == .waiting, let p = user.lobbyParticipant {
                            lobbys.append(p)
                            boxes.append((nil, p.identifier, box))
                        } else {
                            boxes.append((nil, nil, box))
                        }
                    } else if let room = r.toRoom() {
                        let box = ParticipantSearchRoomBox(room, highlightPattern: keyword)
                        if box.state == .joined || box.state == .inviting, let p = room.participant {
                            pids.append(p.participantId)
                            boxes.append((p.identifier, nil, box))
                        } else if box.state == .waiting, let p = room.lobbyParticipant {
                            lobbys.append(p)
                            boxes.append((nil, p.identifier, box))
                        } else {
                            boxes.append((nil, nil, box))
                        }
                    }
                }

                var participantUserInfos: [ParticipantUserInfo] = []
                var lobbyUserInfos: [ParticipantUserInfo] = []
                let wrapper: () -> Void = { [weak self] in
                    guard let self = self, key == self.searchRequestKey else {
                        completion(false, [], false)
                        return
                    }
                    let duplicatedParticipantIds = self.duplicatedIds
                    let result = self.combineSearchResult(boxes: boxes, participantUserInfos: participantUserInfos, lobbyUserInfos: lobbyUserInfos)
                    let hasCohostAuthority = self.meeting.setting.hasCohostAuthority
                    let hostEnabled = self.meeting.setting.isHostEnabled
                    let meetingSubType = self.meeting.subType
                    let cellModels = result.compactMap { [weak self] box -> SearchParticipantCellModel? in
                        guard let self = self else { return nil }
                        return self.createSearchCellModel(box, duplicatedParticipantIds: duplicatedParticipantIds, hasCohostAuthority: hasCohostAuthority, hostEnabled: hostEnabled, meetingSubType: meetingSubType)
                    }
                    completion(true, cellModels, hasMore)
                }

                let participantService = self.httpClient.participantService
                // 个人状态可能随时变化，不能取缓存(usingCache)
                participantService.participantInfo(pids: pids, meetingId: self.meetingId) { [weak self] infos in
                    self?.searchQueue.async {
                        participantUserInfos = infos
                        wrapper()
                    }
                }

                participantService.participantInfo(pids: lobbys, meetingId: self.meetingId) { [weak self] infos in
                    self?.searchQueue.async {
                        lobbyUserInfos = infos
                        wrapper()
                    }
                }
            }
        }
    }

    private func combineSearchResult(boxes: [(String?, String?, ParticipantSearchBox)], participantUserInfos: [ParticipantUserInfo],
                                     lobbyUserInfos: [ParticipantUserInfo]) -> [ParticipantSearchBox] {
        // 将userInfos根据identifier存储为字典
        var userInfoCache: [String: ParticipantUserInfo] = [:]
        participantUserInfos.filter { $0.pid != nil }.forEach { userInfoCache[$0.pid!.identifier] = $0 }
        // 将lobbyInfos根据identifier存储为字典
        var lobbyInfoCache: [String: ParticipantUserInfo] = [:]
        lobbyUserInfos.filter { $0.pid != nil }.forEach { lobbyInfoCache[$0.pid!.identifier] = $0 }
        // 原始搜索结果进行匹配
        return boxes.map { (pid, lid, box) -> ParticipantSearchBox in
            if let id = pid {
                box.userInfo = userInfoCache[id]
            } else if let id = lid {
                box.userInfo = lobbyInfoCache[id]
            }
            return box
        }
    }

    // MARK: - Other
    private func updateBreakoutRoomData() {
        let newValue = BreakoutRoomData(isInBreakoutRoom: meeting.data.isInBreakoutRoom,
                                        askForHelpEnabled: meeting.setting.showsAskHostForHelp && breakoutRoom?.roomInfo?.status == .onTheCall,
                                        info: meeting.data.breakoutRoomInfo, participantsCount: inMeetSectionModel?.realItems.count ?? 0)
        if newValue != breakoutRoomData {
            breakoutRoomData = newValue
            listerners.forEach { $0.breakoutRoomDataDidChange(newValue) }
        }
    }

    private func updateSettingFeature() {
        listerners.forEach { $0.settingFeatureEnabled(meeting.setting.showsHostControl) }
    }

    private func updateCancelAllInvitedButton() {
        guard let invitedSectionModel = invitedSectionModel else { return }
        let ringingCount = invitedSectionModel.realItems.count - feedbackCellModels.count
        let showButton = meeting.setting.canCancelInvite && ringingCount > 1
        let actionName = showButton ? I18n.View_MV_CancelAll_BlueButton : ""
        if invitedSectionModel.actionName != actionName {
            invitedSectionModel.actionName = actionName
            participantReloadTrigger.excute(())
        }
    }
}

// MARK: - InMeetDataListener
extension ParticipantsViewModel: InMeetDataListener, InMeetLobbyViewModelObserver, MyselfListener, MeetingSettingListener, InMeetShareDataListener {

    func didChangeLobbyParticipants(_ lobbyParticipants: [LobbyParticipant]) {
        didChangeLobbysTrigger.excute(lobbyParticipants)
    }

    func didChangeInMeetingInfo(_ inMeetingInfo: VideoChatInMeetingInfo, oldValue: VideoChatInMeetingInfo?) {
        if updateParticipantsAfterMeetingInfoChanged {
            updateParticipantsAfterMeetingInfoChanged = false
            let feedbacks = invitedFeedbackParticipants.values.map { $0 }
            let currentRoom = meeting.participant.currentRoom
            let changeModel = ParticipantsChangeModel(callings: currentRoom.ringingDict.map(\.value), onTheCalls: currentRoom.nonRingingDict.map(\.value), feedbacks: feedbacks)
            didChangeParticipantsTrigger.excute(changeModel)
        } else {
            let focusChanged = inMeetingInfo.focusingUser != oldValue?.focusingUser
            if focusChanged { updateFocusChanged() }
        }
        updateParticipantListState()
    }

    // MARK: - InMeetShareDataListener

    func didChangeShareContent(to newScene: InMeetShareScene, from oldScene: InMeetShareScene) {
        if newScene.shareScreenData?.identifier != oldScene.shareScreenData?.identifier || newScene.magicShareData?.identifier != oldScene.magicShareData?.identifier || newScene.whiteboardData?.sharer.identifier != oldScene.whiteboardData?.sharer.identifier || newScene.whiteboardData?.whiteboardIsSharing != oldScene.whiteboardData?.whiteboardIsSharing {
            updateShareContentChanged()
        }
    }

    func didUpgradeMeeting(_ type: MeetingType, oldValue: MeetingType) {
        if type == .meet, oldValue != type {
            // 会议升级后立即刷新当前搜索
            listerners.forEach { $0.didUpgradeMeeting() }
        }
    }

    func didChangeMyself(_ myself: Participant, oldValue: Participant?) {
        listerners.forEach { $0.muteAllAuthorityChange() }
    }

    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        switch key {
        case .hasCohostAuthority:
            if let suggests = participantSectionModels.first(where: { $0.itemType == .suggest }) {
                // 刷新webinar建议列表header上的一键呼叫按钮
                let showButton = suggests.realItems.count > 1 && isOn
                let actionName = showButton ? I18n.View_MV_CallAll_Button : ""
                suggests.actionName = actionName
                participantReloadTrigger.excute(())
            }
        case .canCancelInvite:
            updateCancelAllInvitedButton()
        case .showsHostControl:
            updateSettingFeature()
        case .isHostControlEnabled:
            listerners.forEach { $0.muteAllAuthorityChange() }
        case .isHostEnabled:
            updateMeetingRole()
            listerners.forEach { $0.muteAllAuthorityChange() }
        case .showsAskHostForHelp:
            updateBreakoutRoomData()
        default:
            break
        }
    }
}

// MARK: - InMeetParticipantListener
extension ParticipantsViewModel: InMeetParticipantListener {

    func didReceiveSuggestedParticipants(_ suggested: GetSuggestedParticipantsResponse) {
        let changed = suggested.toChanged(meetingId: meetingId)
        if suggestedChanged != changed {
            suggestedChanged = changed
            participantsToSuggestionCellModels(changed.suggestedParticipants, sips: changed.sipRooms, interpreters: changed.preSetInterpreterParticipants)
        }
        if calendarRejectParticpants != changed.declinedParticipants || calendarRejectDefaultCount != changed.initialDeclinedCount {
            didChangeCalendarRejectPartcipants(changed.declinedParticipants, initialCount: changed.initialDeclinedCount)
        }
    }

    func didChangeWebinarAttendeeNum(_ num: Int64) {
        attendeeNumChangedIfNeeded(num)
    }

    func didChangeWebinarAttendees(_ output: InMeetParticipantOutput) {
        didChangeAttendeesTrigger.excute(output.newData.all)
    }

    func didChangeCurrentRoomParticipants(_ output: InMeetParticipantOutput) {
        let feedback: (Participant, inout Bool) -> Void = { [weak self] p, update in
            guard let self = self else { return }
            let key = p.participantId.ringingIdentifier
            let old = self.invitedFeedbackParticipants[key]
            let areadyRinging = self.invitedSectionModel?.realItems.compactMap { $0 as? InvitedParticipantCellModel }.contains(where: { $0.participant.participantId.ringingIdentifier == p.participantId.ringingIdentifier }) == true
            let needRefreshFeedback = p.hasRefuseReply(inviterID: self.meeting.account.id) && old != nil
            if p.hasInviteFeedback, (areadyRinging || needRefreshFeedback) {
                if old == nil || old?.joinTime != p.joinTime || old?.refuseReplyTime != p.refuseReplyTime {
                    self.invitedFeedbackParticipants[key] = p
                    self.invitedFeedbackTimes[key] = Date().timeIntervalSince1970
                    update = true
                }
            }
        }
        // 呼叫反馈 （和PM确认可以只在参会人列表打开时记录，V6.4+）
        var updateFeedback: Bool = false
        output.modify.ringing.removes.forEach { (_, p) in
            feedback(p, &updateFeedback)
        }
        output.modify.nonRinging.removes.forEach { (_, p) in
            feedback(p, &updateFeedback)
        }
        if updateFeedback {
            removeInvitedFeedbacks(after: 3)
        }
        if meeting.data.inMeetingInfo == nil {
            updateParticipantsAfterMeetingInfoChanged = true
            return
        }
        let feedbacks = invitedFeedbackParticipants.values.map { $0 }
        let currentRoom = meeting.participant.currentRoom
        let changeModel = ParticipantsChangeModel(callings: currentRoom.ringingDict.map(\.value), onTheCalls: currentRoom.nonRingingDict.map(\.value), feedbacks: feedbacks)
        didChangeParticipantsTrigger.excute(changeModel)
        updateParticipantListState()
    }

    /// x秒后，移除呼叫反馈
    private func removeInvitedFeedbacks(after seconds: Int) {
        DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(seconds)) { [weak self] in
            guard let self = self else { return }
            var update: Bool = false
            self.invitedFeedbackTimes.forEach { (key: String, value: TimeInterval) in
                if Date().timeIntervalSince1970 - value >= TimeInterval(seconds) {
                    self.invitedFeedbackParticipants.removeValue(forKey: key)
                    self.invitedFeedbackTimes.removeValue(forKey: key)
                    if !update {
                        update = true
                    }
                }
            }
            if update {
                let feedbacks = self.invitedFeedbackParticipants.values.map { $0 }
                let currentRoom = self.meeting.participant.currentRoom
                let changeModel = ParticipantsChangeModel(callings: currentRoom.ringingDict.map(\.value), onTheCalls: currentRoom.nonRingingDict.map(\.value), feedbacks: feedbacks)
                self.didChangeParticipantsTrigger.excute(changeModel)
                self.updateParticipantListState()
            }
        }
    }
}

extension ParticipantsViewModel: BreakoutRoomManagerObserver {
    func breakoutRoomInfoChanged(_ info: BreakoutRoomInfo?) {
        updateBreakoutRoomData()
    }
}


extension ParticipantsViewModel: InMeetStatusReactionViewModelObserver {
    func handsUpReactionCountChanged(_ count: Int, attendeeCount: Int) {
        participantReloadTrigger.excute(())
    }
}

extension ParticipantsViewModel {
    struct BreakoutRoomData: Equatable {
        var isInBreakoutRoom = false
        var askForHelpEnabled = false
        var info: BreakoutRoomInfo?
        var participantsCount = 0
    }
}
