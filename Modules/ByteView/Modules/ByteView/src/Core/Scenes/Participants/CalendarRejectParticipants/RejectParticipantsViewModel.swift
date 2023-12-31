//
//  RejectParticipantsViewModel.swift
//  ByteView
//
//  Created by wulv on 2022/5/23.
//

import Foundation
import ByteViewNetwork
import ByteViewTracker

class RejectParticipantsViewModel {

    /// 数据源
    @RwAtomic
    private(set) var rejectDataSource: [RejectParticipantCellModel] = []
    private var participants: [Participant]
    var listCount: Int {
        participants.count
    }

    /// 数据源更新回调(非主线程）
    var didChangeRejectDataSource: (([RejectParticipantCellModel]) -> Void)?

    @RwAtomic
    private var rejectRequestKey: String = ""

    /// 上次展开邀请action sheet时，对应的参会人ID
    var lastPIDForShowingInvite: String?

    /// 建议列表人数（目前仅用于埋点）
    var getSuggestionNum: (() -> Int)

    /// 获取参会人列表状态，用于判断是否能呼叫
    var getListState: (() -> ParticipantsListState)

    let meeting: InMeetMeeting
    init(meeting: InMeetMeeting, participants: [Participant], suggestionNum: @escaping (() -> Int), getListState: @escaping (() -> ParticipantsListState)) {
        self.meeting = meeting
        self.participants = participants
        self.getSuggestionNum = suggestionNum
        self.getListState = getListState
        updateParticipants(participants, force: true)
    }
}

// MARK: - Public
extension RejectParticipantsViewModel {

    func updateParticipants(_ participants: [Participant], force: Bool = false) {
        guard force || self.participants != participants else { return }
        self.participants = participants
        participantsToRejectCellModels(participants)
    }

    func rejectParticipantMoreCall(with model: RejectParticipantCellModel, sender: UIButton,
                                   viewControllerShowed: ((UIViewController?, Error?) -> Void)?) {
        let participantListState = getListState()
        if participantListState != .none, let text = participantListState.toastText {
            Toast.show(text)
            return
        }
        lastPIDForShowingInvite = model.participant.user.id
        showInviteActionSheet(model, sender: sender, needTrack: true, viewControllerShowed: viewControllerShowed)
    }

    func showInviteActionSheet(_ model: RejectParticipantCellModel, sender: UIButton, needTrack: Bool, useCache: Bool = false,
                               animated: Bool = true, viewControllerShowed: ((UIViewController?, Error?) -> Void)?) {
        ConveniencePSTN.showCallActions(service: meeting.service,
                                        from: sender, userId: model.participant.user.id, animated: animated, useCache: useCache,
                                        completion: viewControllerShowed) { [weak self] action in
            guard let self = self else { return }
            if needTrack {
                VCTracker.post(name: .vc_meeting_onthecall_click,
                               params: [.click: action.trackEvent,
                                        .location: "reject_list",
                                        .suggestionNum: self.getSuggestionNum()])
            }
            switch action {
            case .vcCall:
                if model.participant.type == .room {
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

    func rejectParticipantCall(with participant: Participant) {
        let participantListState = getListState()
        if participantListState != .none, let text = participantListState.toastText {
            Toast.show(text)
            return
        }
        if participant.type == .room {
            meeting.participant.inviteUsers(roomIds: [participant.user.id])
        } else {
            meeting.participant.inviteUsers(userIds: [participant.user.id])
        }
    }

    func jumpToUserProfile(participantId: ParticipantId, isLarkGuest: Bool) {
        if meeting.setting.isBrowseUserProfileEnabled, !isLarkGuest, let userId = participantId.larkUserId {
            InMeetUserProfileAction.show(userId: userId, meeting: meeting)
        }
    }
}

// MARK: - Privete
extension RejectParticipantsViewModel {

    /// [Participant] to [RejectParticipantCellModel]
    private func participantsToRejectCellModels(_ participants: [Participant]) {
        let key = UUID().uuidString
        rejectRequestKey = key
        // 个人状态可能随时变化，不能取缓存(usingCache)
        let participantService = meeting.httpClient.participantService
        participantService.participantInfo(pids: participants, meetingId: meeting.meetingId, usingCache: false) { [weak self] (aps) in
            DispatchQueue.global().async {
                guard let self = self, self.rejectRequestKey == key else { return }
                let meetingSubType = self.meeting.subType
                var cellModels: [RejectParticipantCellModel] = []
                for (p, ap) in zip(participants, aps) {
                    var participant = p
                    let role = participant.role
                    participant.isHost = participant.isHost && !participant.isLarkGuest &&
                    self.meeting.data.roleStrategy.participantCanBecomeHost(role: role)
                    // 拒绝日程列表的participant不会返回userTenantID，需要从ParticipantUserInfo里取
                    if !ap.isUnknown {
                        // 过滤拉取用户信息失败的情况
                        participant.tenantId = ap.tenantId
                    }
                    let cellModel = self.createRejectCellModel(participant, userInfo: ap, meetingSubType: meetingSubType)
                    cellModels.append(cellModel)
                }
                self.didChangeRejectCellModels(cellModels)
            }
        }
    }

    private func createRejectCellModel(_ participant: Participant, userInfo: ParticipantUserInfo, meetingSubType: MeetingSubType) -> RejectParticipantCellModel {
        let model = RejectParticipantCellModel.create(with: participant,
                                                      userInfo: userInfo,
                                                      meetingSubType: meetingSubType,
                                                      meeting: meeting)
        return model
    }

    /// replace [RejectParticipantCellModel] to data source
    private func didChangeRejectCellModels(_ cellModels: [RejectParticipantCellModel]) {
        if cellModels != rejectDataSource {
            rejectDataSource = cellModels
            didChangeRejectDataSource?(rejectDataSource)
        }
    }
}
