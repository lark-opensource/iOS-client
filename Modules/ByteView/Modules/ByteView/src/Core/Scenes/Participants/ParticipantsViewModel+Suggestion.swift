//
//  ParticipantsViewModel+Suggestion.swift
//  ByteView
//
//  Created by wulv on 2022/5/24.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork
import ByteViewTracker

extension ParticipantsViewModel {
    enum InviteAllError: Error, Equatable {
        /// 全部失败
        case fail
        /// 部分失败
        case partiFail(Int)
    }

    /// 批量呼叫人数上限
    var max_invite: Int { suggestionConfig.maxCallNumber }
    var overMaxInviteCount: Bool {
        suggestionCellModels.count > max_invite
    }

    /// [Participant] to [SuggestionParticipantCellModel]
    func participantsToSuggestionCellModels(_ participants: [Participant], sips: [String: CalendarInfo.CalendarRoom], interpreters: [Participant]) {
        if participants.isEmpty {
            didChangeSuggestCellModels([])
            return
        }
        var cellModels: [SuggestionParticipantCellModel] = []
        let preInterpreterIds = interpreters.map { $0.user.id }
        let meetingSubType = meeting.subType
        for p in participants {
            var participant = p
            let role = participant.role
            participant.isHost = participant.isHost && !participant.isLarkGuest &&
            meeting.data.roleStrategy.participantCanBecomeHost(role: role)
            var sip: CalendarInfo.CalendarRoom?
            if let address = participant.sipAddress {
                // sip的头像昵称信息从sips中取
                sip = sips[address]
            }
            let cellModel = createSuggestionCellModel(participant, sip: sip, preInterpreterIds: preInterpreterIds, meetingSubType: meetingSubType)
            cellModels.append(cellModel)
        }
        didChangeSuggestCellModels(cellModels)
    }

    private func createSuggestionCellModel(_ participant: Participant, sip: CalendarInfo.CalendarRoom?, preInterpreterIds: [String], meetingSubType: MeetingSubType) -> SuggestionParticipantCellModel {
        let model = SuggestionParticipantCellModel.create(with: participant,
                                                          sip: sip,
                                                          preInterpreterIds: preInterpreterIds,
                                                          userInfo: nil,
                                                          meetingSubType: meetingSubType,
                                                          meeting: meeting)
        return model
    }

    /// replace [SuggestionParticipantCellModel] to data source
    private func didChangeSuggestCellModels(_ cellModels: [SuggestionParticipantCellModel]) {
        if suggestionCellModels == cellModels {
            Self.logger.debug("participant dataSource no need update sugesstion")
            return
        }
        Self.logger.debug("participant dataSource update sugesstion count: \(cellModels.count)")
        updateSuggestionDataSource(cellModels)
        if isWebinar {
            didChangeWebinarSuggestCellModels(cellModels)
        }
    }

    private func updateSuggestionDataSource(_ newCellModels: [SuggestionParticipantCellModel]) {
        // 更新数据源缓存
        suggestionCellModels = newCellModels
        guard !suggestionDataSourceIsLock else {
            Self.logger.debug("participant dataSource update sugesstion fail, sugesstion is locked")
            return
        }
        reloadSuggestionData()
    }

    private func reloadSuggestionData() {
        let newDataSource = suggestionCellModels
        DispatchQueue.main.async {
            // 更新数据源
            self.suggestionDataSource = newDataSource
            self.listerners.forEach { $0.suggestionDataSourceDidChange(newDataSource) }
        }
    }

    // MARK: - Ations

    func suggestionCall(with model: SuggestionParticipantCellModel) {
        let participant = model.participant
        ParticipantTracks.trackInviteFromSuggestList(userId: participant.user.id)
        ParticipantTracks.trackCalling(participant: participant)
        ParticipantTracks.trackCoreManipulation(isSelf: false, description: "Invite From Suggest List", participant: participant)
        if participantListState != .none, let text = participantListState.toastText {
            Toast.show(text)
            return
        }
        if model.isConveniencePSTN, let bindId = model.participant.pstnInfo?.bindId, let displayName = model.displayName {
            meeting.participant.invitePSTN(userId: bindId, name: displayName)
        } else if let address = participant.sipAddress {
            meeting.participant.inviteUsers(pstnInfos: [PSTNInfo(sipAddress: address)])
        } else if let address = participant.pstnAddress, let displayName = model.displayName {
            meeting.participant.inviteUsers(pstnInfos: [PSTNInfo(pstnAddress: address, displayName: displayName)])
        } else if participant.type == .room {
            meeting.participant.inviteUsers(roomIds: [participant.user.id])
        } else {
            meeting.participant.inviteUsers(userIds: [participant.user.id])
        }
    }

    func suggestionMoreCall(with model: SuggestionParticipantCellModel, sender: UIButton,
                            viewControllerShowed: ((UIViewController?, Error?) -> Void)?) {
        if participantListState != .none, let text = participantListState.toastText {
            Toast.show(text)
            return
        }
        lastPIDForShowingInvite = model.uniqueId
        showInviteActionSheet(model, sender: sender, needTrack: true, viewControllerShowed: viewControllerShowed)
    }

    func showInviteActionSheet(_ model: SuggestionParticipantCellModel, sender: UIButton, needTrack: Bool, useCache: Bool = false,
                               animated: Bool = true, viewControllerShowed: ((UIViewController?, Error?) -> Void)?) {
        ConveniencePSTN.showCallActions(service: meeting.service,
                                        from: sender, userId: model.participant.user.id, animated: animated, useCache: useCache,
                                        completion: viewControllerShowed) { [weak self] action in
            guard let self = self else { return }
            if needTrack {
                VCTracker.post(name: .vc_meeting_onthecall_click,
                               params: [.click: action.trackEvent,
                                        .location: "suggestions_list",
                                        .suggestionNum: self.suggestionDataSource.count,
                                        "feedback_status": model.participant.offlineReason.trackFeedback])
            }
            switch action {
            case .vcCall:
                if let address = model.participant.sipAddress {
                    self.meeting.participant.inviteUsers(pstnInfos: [PSTNInfo(sipAddress: address)])
                } else if let address = model.participant.pstnAddress, let displayName = model.displayName {
                    self.meeting.participant.inviteUsers(pstnInfos: [PSTNInfo(pstnAddress: address, displayName: displayName)])
                } else if model.participant.type == .room {
                    self.meeting.participant.inviteUsers(roomIds: [model.participant.user.id])
                } else {
                    self.meeting.participant.inviteUsers(userIds: [model.participant.user.id])
                }
            case .pstnCall(let phone):
                if let displayName = model.displayName {
                    self.meeting.participant.invitePSTN(userId: model.participant.user.id, name: displayName, mainAddress: phone)
                }
            }
        }
    }

    // MARK: - 批量呼叫

    func changeSuggestionMultiple(_ multiple: Bool) {
        if !suggestionCellModels.isEmpty {
            suggestionCellModels.forEach {
                $0.updateMultiple(multiple)
            }
            reloadSuggestionData()
        }
        if !multiple {
            // 解除锁定态，更新数据源
            reloadSuggestionData()
        }
    }

    func changeAllSuggestionSelected(_ selected: Bool) {
        guard suggestionIsMultiple, !suggestionCellModels.isEmpty else { return }
        if selected {
            if overMaxInviteCount {
                changeSuggestionSelected(true, to: max_invite - 1)
            } else {
                changeSuggestionSelected(s: true)
            }
        } else {
            changeSuggestionSelected(s: false)
        }
    }

    private func changeSuggestionSelected(s: Bool) {
        suggestionCellModels.forEach {
            $0.updateSelected(s)
            $0.updateEnabled(true)
        }
        reloadSuggestionData()
    }

    private func changeSuggestionSelected(_ selected: Bool, from: Int = 0, to index: Int) {
        guard from < index, index < suggestionCellModels.count else { return }
        for (i, e) in suggestionCellModels.enumerated() {
            if from...index ~= i {
                e.updateSelected(selected)
                e.updateEnabled(true)
            } else {
                e.updateSelected(!selected)
                e.updateEnabled(false)
            }
        }
        reloadSuggestionData()
    }

    func updateSuggestionEnabledIfNeeded() {
        let unSeleted = suggestionCellModels.filter { !$0.isSelected }
        if suggestionCellModels.count - unSeleted.count >= max_invite {
            var reload = false
            unSeleted.forEach {
                if $0.isEnabled {
                    if !reload { reload = true }
                    $0.updateEnabled(false)
                }
            }
            if reload {
                reloadSuggestionData()
            }
        } else {
            var reload = false
            unSeleted.forEach {
                if !$0.isEnabled {
                    if !reload { reload = true }
                    $0.updateEnabled(true)
                }
            }
            if reload {
                reloadSuggestionData()
            }
        }
    }

    /// 呼叫全部建议人员
    /// return: 是否超出限制人数
    func suggestionInviteAll(_ completion: @escaping ((Result<Void, InviteAllError>) -> Void)) {
        guard overMaxInviteCount else {
            inviteSuggestions(suggestionCellModels, completion: completion)
            return
        }
        let invites = suggestionCellModels.prefix(max_invite)
        inviteSuggestions(Array(invites), completion: completion)
    }

    // 呼叫选中的建议人员
    func suggestionInviteSelected(_ completion: @escaping ((Result<Void, InviteAllError>) -> Void)) {
        inviteSuggestions(selectedSuggestions, completion: completion)
    }

    private func inviteSuggestions(_ suggestions: [SuggestionParticipantCellModel], completion: @escaping ((Result<Void, InviteAllError>) -> Void)) {
        var userIds: [String] = []
        var roomIds: [String] = []
        var pstnInfos: [PSTNInfo] = []
        suggestions.forEach {
            if $0.isConveniencePSTN, let bindId = $0.participant.pstnInfo?.bindId, let displayName = $0.displayName {
                pstnInfos.append(PSTNInfo(conveniencePstnId: bindId, displayName: displayName))
            } else if let address = $0.participant.sipAddress {
                pstnInfos.append(PSTNInfo(sipAddress: address))
            } else if let address = $0.participant.pstnAddress, let displayName = $0.displayName {
                pstnInfos.append(PSTNInfo(pstnAddress: address, displayName: displayName))
            } else if $0.participant.type == .room {
                roomIds.append($0.participant.user.id)
            } else {
                userIds.append($0.participant.user.id)
            }
        }

        meeting.participant.inviteUsers(userIds: userIds, roomIds: roomIds, pstnInfos: pstnInfos, source: .suggestList) { result in
            if let value = result.value {
                if value.failedCount > 0 {
                    // 部分失败
                    Toast.show(I18n.View_MV_UnableCallNumber(value.failedCount))
                    completion(.failure(.partiFail(Int(value.failedCount))))
                } else {
                    /* 邀请成功 */
                    completion(.success(()))
                }
            } else {
                /* 失败，通用错误处理 */
                completion(.failure(.fail))
            }
        }
    }
}

extension ParticipantsViewModel {

    enum SuggestionSelectType {
        /// 全部未选
        case none
        /// 选中部分
        case part
        /// 全部选中
        case all
    }

    /// 建议列表选中的状态（全选/部分选/全不选）
    var suggestionSelectedType: SuggestionSelectType {
        var same: Bool?
        var isPart: Bool = false
        suggestionDataSource.forEach {
            if same == nil {
                same = $0.isSelected
            } else if let same = same, $0.isSelected != same {
                isPart = true
                return
            }
        }
        if isPart {
            if suggestionDataSource.filter({ $0.isSelected }).count >= max_invite {
                return .all
            }
            return .part
        }
        return same == true ? .all : .none
    }

    /// 选中的建议人员
    var selectedSuggestions: [SuggestionParticipantCellModel] {
        suggestionDataSource.filter { $0.isSelected }
    }

    /// 是否展示拒绝面板
    var showReject: Bool {
        // 仅日程会议展示
        meeting.isCalendarMeeting
    }

    /// 批量呼叫/呼叫全部是否可用
    var multiInviteEnabled: Bool {
        !suggestionDataSource.isEmpty && !inviteCooling
    }

    /// 是否有权限批量呼叫/呼叫全部
    var multiInviteLimited: Bool {
        !meeting.setting.hasCohostAuthority
    }

    /// 建议列表是否锁定态
    private var suggestionDataSourceIsLock: Bool {
        suggestionIsMultiple
    }
}

// MARK: - Reject Participants
extension ParticipantsViewModel {

    func didChangeCalendarRejectPartcipants(_ participants: [Participant], initialCount: Int64) {
        Logger.meeting.info("calendarRejectParticipants receive, count: \(participants.count), initialCount: \(initialCount)")
        if calendarRejectParticpants == participants {
            Self.logger.debug("no need update calendar reject participants, update initialCount = \(initialCount)")
            calendarRejectDefaultCount = initialCount
            listerners.forEach { $0.calendarRejectParticipantsDidChange(calendarRejectParticpants, initialCount: calendarRejectDefaultCount) }
            return
        }
        Self.logger.debug("update calendar reject participants count: \(participants.count), update initialCount = \(initialCount)")
        calendarRejectParticpants = participants
        calendarRejectDefaultCount = initialCount
        listerners.forEach { $0.calendarRejectParticipantsDidChange(calendarRejectParticpants, initialCount: calendarRejectDefaultCount) }
    }
}
