//
//  ParticipantActionService.swift
//  ByteView
//
//  Created by wulv on 2023/6/8.
//

import Foundation
import UniverseDesignIcon
import ByteViewTracker
import ByteViewNetwork

/// (由外部变量控制的)异化行为
class ParticipantActionHeterization {
    var hasSignleVideo: Bool = false
    var hasChangeOrder: Bool = false
}

protocol ParticipantActionProvider: AnyObject {
    var heterization: ParticipantActionHeterization { get }
    func track(_ event: TrackEventName, params: TrackParams)
    func toast(_ message: String)
}

final class ParticipantActionService {
    typealias ActionCallback = (ParticipantActionType) -> Void
    typealias ActionDataCallback = (ParticipantActionType, Dictionary<String, Any>) -> Void

    private let meeting: InMeetMeeting
    private let context: InMeetViewContext
    private let actionHeterization = ParticipantActionHeterization()
    private var acting: ParticipantAction?

    init(meeting: InMeetMeeting, context: InMeetViewContext) {
        self.meeting = meeting
        self.context = context
    }

    func actionVC(participant: Participant, lobbyParticipant: LobbyParticipant? = nil, userInfo: ParticipantActionUserInfo, source: ParticipantActionSource, heterization: ((ParticipantActionHeterization) -> Void)? = nil, dataCallBack: ActionDataCallback? = nil) -> ParticipantActionViewController? {
        heterization?(actionHeterization)
        let resolver = actionResolver(participant, lobbyParticipant: lobbyParticipant, info: userInfo, source: source)
        let actions = resolver.getActions()
        if !actions.isEmpty {
            var title = userInfo.display
            if source == .invitee {
                title.append(contentsOf: I18n.View_M_CallingParentheses)
            } else if source == .lobby {
                title.append(contentsOf: " (\(I18n.View_M_WaitingEllipsis))")
            } else if meeting.account == participant.user {
                title.append(contentsOf: I18n.View_M_MeParentheses)
            }

            let vm = ParticipantActionViewModel(title: title, sections: actions, source: source)
            vm.didTap = { [weak self] action in
                guard let self = self else { return }
                action.didTap { [weak self] data in
                    guard let self = self else { return }
                    self.acting = action // 与 service 同生命周期，确保 action 内异步操作可以执行
                    dataCallBack?(action.type, data ?? [:])
                    self.afterTap(action)
                }
            }
            let vc = ParticipantActionViewController(viewModel: vm)
            return vc
        }
        return nil
    }

    func actionVC(participant: Participant, lobbyParticipant: LobbyParticipant? = nil, userInfo: ParticipantActionUserInfo, source: ParticipantActionSource, heterization: ((ParticipantActionHeterization) -> Void)? = nil, callBack: ActionCallback? = nil) -> ParticipantActionViewController? {
        actionVC(participant: participant, lobbyParticipant: lobbyParticipant, userInfo: userInfo, source: source, heterization: heterization) { type, _ in callBack?(type) }
    }

    func actionVC(participant: Participant, lobbyParticipant: LobbyParticipant? = nil, info: ParticipantActionContext.UserInfo, source: ParticipantActionSource, heterization: ((ParticipantActionHeterization) -> Void)? = nil, dataCallBack: ActionDataCallback? = nil) -> ParticipantActionViewController? {
        actionVC(participant: participant, lobbyParticipant: lobbyParticipant, userInfo: info, source: source, heterization: heterization, dataCallBack: dataCallBack)
    }

    private func actionResolver(_ p: Participant, lobbyParticipant: LobbyParticipant?, info: ParticipantActionUserInfo, source: ParticipantActionSource) -> ParticipantActionResolver {
        let context = actionContext(p, lobbyParticipant: lobbyParticipant, info: info, source: source)
        return ParticipantActionResolver(context: context, service: self)
    }

    private func actionContext(_ p: Participant, lobbyParticipant: LobbyParticipant?, info: ParticipantActionUserInfo, source: ParticipantActionSource) -> ParticipantActionContext {
        ParticipantActionContext(source: source, participant: p, lobbyParticipant: lobbyParticipant, userInfo: info, meeting: meeting, inMeetContext: context)
    }

    private func afterTap(_ action: ParticipantAction) {
        if let baseAction = action as? BaseParticipantAction {
            log(baseAction)
        }
    }

    private func log(_ action: BaseParticipantAction) {
        ParticipantTracks.trackCoreManipulation(isSelf: action.isSelf, description: action.title, participant: action.participant)
    }
}

extension ParticipantActionService: ParticipantActionProvider {

    var heterization: ParticipantActionHeterization { actionHeterization }

    func track(_ event: TrackEventName, params: TrackParams) {
        VCTracker.post(name: event, params: params)
    }

    func toast(_ message: String) {
        Util.runInMainThread {
            guard !message.isEmpty else { return }
            Toast.showOnVCScene(message)
        }
    }
}
