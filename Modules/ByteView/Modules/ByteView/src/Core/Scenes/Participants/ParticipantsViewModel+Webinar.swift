//
//  ParticipantsViewModel+Webinar.swift
//  ByteView
//
//  Created by wulv on 2022/9/26.
//

import Foundation
import ByteViewNetwork

extension ParticipantsViewModel {

    var isWebinar: Bool {
        meeting.subType == .webinar
    }
}

// MARK: - 嘉宾：建议参会
extension ParticipantsViewModel {

    /// insert [SuggestionParticipantCellModel] in data source
    func didChangeWebinarSuggestCellModels(_ cellModels: [SuggestionParticipantCellModel]) {
        var newWebinarSuggestSection: ParticipantsSectionModel?
        if !cellModels.isEmpty {
            let header = I18n.View_M_SuggestionsNumberBraces(cellModels.count)
            let showButton = cellModels.count > 1 && meeting.setting.hasCohostAuthority
            let actionName = showButton ? I18n.View_MV_CallAll_Button : ""
            newWebinarSuggestSection = ParticipantsSectionModel(header: header, actionName: actionName, itemType: .suggest, items: cellModels)
        }
        if newWebinarSuggestSection == werbinarSuggestSectionModel {
            Self.logger.debug("participant dataSource no need update webinar suggestion")
            return
        }
        Self.logger.debug("participant dataSource update webinar suggestion count: \(newWebinarSuggestSection?.realItems.count)")
        updateParticipantDataSouce(lobbySection: lobbySectionModel, invitedSection: invitedSectionModel, inMeetSection: inMeetSectionModel, webinarSuggestSection: newWebinarSuggestSection)
    }
}

// MARK: - 观众
extension ParticipantsViewModel {

    /// 观众人数变化
    func attendeeNumChangedIfNeeded(_ num: Int64?) {
        if let num = num, num != attendeeNum {
            attendeeNum = num
            listerners.forEach { $0.attendeeNumDidChange(num) }
            updateInMeetAttendeeCount()
            attendeeReloadTrigger.excute(())
        }
    }

    // MARK: 会中 & 呼叫

    /// [Participant] to [AttendeeParticipantCellModel]
    func participantsToAttendeeCellModels(_ participants: [Participant]) {
        // 更新多设备信息
        let oldAttendeeIds = attendeeIds
        attendeeIds = participants.filter { $0.status == .onTheCall }.map { $0.user.id }
        // 构建cellModel
        if participants.isEmpty {
            updateCellModelsIfNeeded(attendeeCellModels: [], invitedCellModels: [])
        } else {
            let duplicatedParticipantIds = duplicatedIds
            let hasCohostAuthority = meeting.setting.hasCohostAuthority
            let meetingSubType = meeting.subType
            var attendeeCellModels: [AttendeeParticipantCellModel] = []
            var invitedCellModels: [InvitedParticipantCellModel] = []
            participants.forEach {
                if $0.status == .ringing {
                    let cellModel = createInvitedCellModel($0, hasCohostAuthority: hasCohostAuthority, meetingSubType: meetingSubType)
                    invitedCellModels.append(cellModel)
                } else {
                    let cellModel = createAttendeeCellModel($0, duplicatedParticipantIds: duplicatedParticipantIds, hasCohostAuthority: hasCohostAuthority)
                    attendeeCellModels.append(cellModel)
                }
            }
            // 排序
            attendeeCellModels = sortAttendeeParticipantCellModels(attendeeCellModels)
            invitedCellModels = sortWebinarInvitedParticipantCellModels(invitedCellModels)
            // 更新数据源
            updateCellModelsIfNeeded(attendeeCellModels: attendeeCellModels, invitedCellModels: invitedCellModels)
        }
        // 更新嘉宾多设备信息
        if oldAttendeeIds != attendeeIds {
            updateDeviceImgChanged()
        }
    }

    ///  sorted [AttendeeParticipantCellModel]
    private func sortAttendeeParticipantCellModels(_ cellModels: [AttendeeParticipantCellModel]) -> [AttendeeParticipantCellModel] {
        return ParticipantsSortTool.sortAttendee(cellModels)
    }

    /// sorted webinar [InvitedParticipantCellModel]
    private func sortWebinarInvitedParticipantCellModels(_ cellModels: [InvitedParticipantCellModel]) -> [InvitedParticipantCellModel] {
        return ParticipantsSortTool.sortAttendee(cellModels)
    }

    private func createAttendeeCellModel(_ participant: Participant, duplicatedParticipantIds: Set<String>, hasCohostAuthority: Bool) -> AttendeeParticipantCellModel {
        let model = AttendeeParticipantCellModel.create(with: participant, userInfo: nil, meeting: meeting, hasCohostAuthority: hasCohostAuthority, isDuplicated: duplicatedParticipantIds.contains(participant.user.id))
        return model
    }

    /// insert [AttendeeParticipantCellModel] & [InvitedParticipantCellModel] in data source
    private func updateCellModelsIfNeeded(attendeeCellModels: [AttendeeParticipantCellModel], invitedCellModels: [InvitedParticipantCellModel]) {
        // 构造section
        let newAttendeeSection = createAttendeeInMeetSection(attendeeCellModels, invitedCount: invitedCellModels.count)
        let newInvitedSection = createAttendeeInvitedSection(invitedCellModels)
        // 按需更新
        updateAttendeeSectionsIfNeeded(newAttendeeSection: newAttendeeSection, newInvitedSection: newInvitedSection)
    }

    private func createAttendeeInMeetSection(_ cellModels: [AttendeeParticipantCellModel], invitedCount: Int) -> ParticipantsSectionModel? {
        guard !cellModels.isEmpty else { return nil }
        let num = inMeetAttendeeCount(inviteCount: invitedCount)
        let header = I18n.View_MV_InMeetingWithNumber(num)
        let newInMeetSection = ParticipantsSectionModel(header: header, itemType: .inMeet, items: cellModels)
        return newInMeetSection
    }

    private func createAttendeeInvitedSection(_ cellModels: [InvitedParticipantCellModel]) -> ParticipantsSectionModel? {
        var newInvitedSection: ParticipantsSectionModel?
        if !cellModels.isEmpty {
            let ringingCount = cellModels.count
            let header = I18n.View_MV_CallingWithNumber(ringingCount)
            let showButton = meeting.setting.canCancelInvite && ringingCount > 1
            let actionName = showButton ? I18n.View_MV_CancelAll_BlueButton : ""
            newInvitedSection = ParticipantsSectionModel(header: header, actionName: actionName, itemType: .invite, items: cellModels)
        }
        return newInvitedSection
    }

    private func updateAttendeeSectionsIfNeeded(newAttendeeSection: ParticipantsSectionModel?, newInvitedSection: ParticipantsSectionModel?) {
        let oldAttendeeSection = attendeeSectionModels.first(where: { $0.itemType == .inMeet })
        let oldInvitedSection = attendeeSectionModels.first(where: { $0.itemType == .invite })
        let lobbySection = attendeeSectionModels.first(where: { $0.itemType == .lobby })
        if oldInvitedSection == newInvitedSection, oldAttendeeSection == newAttendeeSection {
            Self.logger.debug("attendee dataSource no need update inviting or inMeeting")
            return
        } else if oldInvitedSection == newInvitedSection {
            // 邀请人员相同，仅更新会中
            Self.logger.debug("attendee dataSource update inMeet count: \(newAttendeeSection?.realItems.count)")
            updateAttendeeDataSouce(invitedSection: oldInvitedSection, lobbySection: lobbySection, attendeeSection: newAttendeeSection)
        } else if oldAttendeeSection == newAttendeeSection {
            // 会中人员相同，仅更新邀请
            Self.logger.debug("attendee dataSource update invite count: \(newInvitedSection?.realItems.count)")
            updateAttendeeDataSouce(invitedSection: newInvitedSection, lobbySection: lobbySection, attendeeSection: oldAttendeeSection)
        } else {
            // 会中和邀请都要更新
            Self.logger.debug("attendee dataSource update invite count: \(newInvitedSection?.realItems.count), inMeet count: \(newAttendeeSection?.realItems.count)")
            updateAttendeeDataSouce(invitedSection: newInvitedSection, lobbySection: lobbySection, attendeeSection: newAttendeeSection)
        }
    }

    // MARK: 等候

    /// [LobbyParticipant] to [LobbyParticipantCellModel]
    func attendeeLobbyParticipantsToLobbyCellModels(_ lobbyParticipants: [LobbyParticipant]) {
        if lobbyParticipants.isEmpty {
            didChangeAttendeeLobbyCellModels([])
            return
        }
        let showRoomInfo = meeting.data.roleStrategy.showRoomInfo
        var cellModels: [LobbyParticipantCellModel] = []
        for lobbyParticipant in lobbyParticipants {
            let cellModel = createLobbyCellModel(lobbyParticipant, showRoomInfo: showRoomInfo)
            cellModels.append(cellModel)
        }
        didChangeAttendeeLobbyCellModels(cellModels)
    }

    /// insert [LobbyParticipantCellModel] in data source
    private func didChangeAttendeeLobbyCellModels(_ cellModels: [LobbyParticipantCellModel]) {
        let attendeeSection = attendeeSectionModels.first(where: { $0.itemType == .inMeet })
        let invitedSection = attendeeSectionModels.first(where: { $0.itemType == .invite })
        let oldLobbySection = attendeeSectionModels.first(where: { $0.itemType == .lobby })
        var newLobbySection: ParticipantsSectionModel?
        if !cellModels.isEmpty {
            let header = I18n.View_MV_WaitingWithNumber(cellModels.count)
            let showButton = cellModels.count > 1
            let actionName = showButton ? I18n.View_M_AdmitAllButton : ""
            newLobbySection = ParticipantsSectionModel(header: header, actionName: actionName, itemType: .lobby, items: cellModels)
        }
        if oldLobbySection == newLobbySection {
            Self.logger.debug("attendee dataSource no need update lobby")
            return
        }
        Self.logger.debug("attendee dataSource update lobby count: \(newLobbySection?.realItems.count)")
        updateAttendeeDataSouce(invitedSection: invitedSection, lobbySection: newLobbySection, attendeeSection: attendeeSection)
    }

    /// webinar 会中观众列表非全量，人数需单独计算
    private func inMeetAttendeeCount(inviteCount: Int? = nil) -> Int {
        let invite = inviteCount ?? attendeeDataSource.first(where: { $0.itemType == .invite })?.realItems.count ?? 0
        return Int(attendeeNum) - invite
    }

    private func updateInMeetAttendeeCount(inMeetSection: ParticipantsSectionModel? = nil, inviteCount: Int? = nil) {
        let inMeet = inMeetSection ?? attendeeSectionModels.first(where: { $0.itemType == .inMeet })
        let inMeetCount = inMeetAttendeeCount(inviteCount: inviteCount)
        inMeet?.header = I18n.View_MV_InMeetingWithNumber(inMeetCount)
    }

    // MARK: 刷新

    private func updateAttendeeDataSouce(invitedSection: ParticipantsSectionModel?,
                                         lobbySection: ParticipantsSectionModel?,
                                         attendeeSection: ParticipantsSectionModel?) {
        // 顺序 : 呼叫中 > 等候中 > 在会中
        var elements: [ParticipantsSectionModel] = []
        if let e0 = invitedSection {
            elements.append(e0)
        }
        if let e1 = lobbySection {
            elements.append(e1)
        }
        if let e2 = attendeeSection {
            elements.append(e2)
        }
        updateAttendeeDataSourceCollapsedStyle(elements)
        updateAttendeeDataSource(elements)
    }

    func updateAttendeeDataSourceCollapsedStyle(_ dataSource: [ParticipantsSectionModel]) {
        // handle collaspe/expand state
        if dataSource.count == 1, let attendeeSection = dataSource.first(where: { $0.itemType == .inMeet }),
           attendeeCollapsedTypes.contains(.joined) {
            // 如果只有joined分组，则展开分组
            attendeeCollapsedTypes.remove(.joined)
            attendeeSection.headerIcon = .expandDownN2
            attendeeSection.recoverItems()
            attendeeSection.recoverActionName()
            return
        }

        dataSource.forEach { sectionModel in
            if attendeeCollapsedTypes.contains(sectionModel.itemType.state) {
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

    private func updateAttendeeDataSource(_ newSectionModels: [ParticipantsSectionModel]) {
        // 更新数据源缓存
        attendeeSectionModels = newSectionModels
        attendeeReloadTrigger.excute(())
    }
}
