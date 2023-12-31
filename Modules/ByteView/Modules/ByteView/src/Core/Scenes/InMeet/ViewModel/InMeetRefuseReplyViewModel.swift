//
//  InMeetRefuseReplyViewModel.swift
//  ByteView
//
//  Created by shin on 2023/3/23.
//

import Foundation
import ByteViewNetwork

final class InMeetRefuseReplyViewModel {
    let resolver: InMeetViewModelResolver
    private let meeting: InMeetMeeting
    /// 当前拒绝回复人
    @RwAtomic private var refuseReplyUsers: [ByteviewUser] = []
    private var hasShowSuggestParticipantsVC: Bool = false

    init(resolver: InMeetViewModelResolver) {
        self.meeting = resolver.meeting
        self.resolver = resolver
        self.meeting.participant.addListener(self)
        self.resolver.viewContext.addListener(self, for: [.suggestedParticipantsAppear, .suggestedParticipantsDisappear])
        Logger.ringRefuse.info("InMeetRefuseReplyViewModel init")
    }
}

extension InMeetRefuseReplyViewModel: InMeetParticipantListener {

    func didReceiveSuggestedParticipants(_ suggested: GetSuggestedParticipantsResponse) {
        let removeUsers = suggested.removeReplyUsers.map { user in
            ParticipantId(id: user.id, type: user.type)
        }
        var refuseUsers: [ByteviewUser] = Array(self.refuseReplyUsers)
        refuseUsers.removeAll { user in
            let participantId = ParticipantId(id: user.id, type: user.type)
            return removeUsers.contains { $0 == participantId }
        }
        let upsertUsers = suggested.upsertReplyUsers
        refuseUsers.append(contentsOf: upsertUsers)
        refuseReplyUsers = refuseUsers
        refuseReplyStatusChanged(refuseUsers, shouldShowToast: !hasShowSuggestParticipantsVC)
    }

    private func refuseReplyStatusChanged(_ users: [ByteviewUser], shouldShowToast: Bool) {
        if !shouldShowToast {
            refuseReplyUsers = []
            return
        }
        let count = users.count
        if count == 1, let user = users.first {
            meeting.httpClient.participantService.participantInfo(pid: user.participantId, meetingId: meeting.meetingId) { [weak self] ap in
                self?.showToast(title: I18n.View_G_VaryNameReplyWhyWait(ap.name))
            }
        } else if count > 1 {
            showToast(title: I18n.View_G_VaryNumberReplyWhyWait(String(count)))
        }
    }

    private func showToast(title: String) {
        let toast = AnchorToastDescriptor(type: .participants, title: title, actionTitle: " " + I18n.View_G_ViewDeclined)
        toast.identifier = .refuseReply
        toast.duration = 6
        toast.pressToastAction = { [weak self, weak toast] in
            guard let self = self, let toast = toast else { return }
            AnchorToast.dismiss(toast)
            self.meeting.router.startParticipants(meeting: self.meeting, resolver: self.resolver, autoScrollToLobby: .suggest)
        }
        toast.deinitAction = { [weak self] in
            // 当前展示的 toast 是拒绝回复，则不重置拒绝人数据
            if AnchorToast.shared.current?.identifier != .refuseReply {
                self?.refuseReplyUsers = []
            }
        }
        AnchorToast.show(toast)
    }
}

extension InMeetRefuseReplyViewModel: InMeetViewChangeListener {
    func viewDidChange(_ change: InMeetViewChange, userInfo: Any?) {
        switch change {
        case .suggestedParticipantsAppear:
            hasShowSuggestParticipantsVC = true
        case .suggestedParticipantsDisappear:
            hasShowSuggestParticipantsVC = false
        default:
            break
        }
    }
}
