//
//  ParticipantMakeHostAction.swift
//  ByteView
//
//  Created by wulv on 2023/6/12.
//

import Foundation
import ByteViewNetwork
import ByteViewUI

class ParticipantMakeHostAction: BaseParticipantAction {

    override var title: String { I18n.View_M_MakeHost }

    override var show: Bool {
        !isSelf && !canCancelInvite && meeting.setting.hasCohostAuthority && meeting.myself.meetingRole == .host
        && participant.canBecomeHost(hostEnabled: meeting.setting.isHostEnabled, isInterview: meeting.isInterviewMeeting)
        && participant.capabilities.canBeHost
    }

    override func action(_ end: @escaping (Dictionary<String, Any>?) -> Void) {
        ParticipantTracks.trackParticipantAction(.setHost, isFromGridView: source.fromGrid, isSharing: meeting.shareData.isSharingContent, isRooms: participant.type == .room)
        let httpClient = meeting.httpClient
        let request = TransferHostRequest(meetingId: meeting.meetingId, targetUser: participant.user)
        httpClient.getResponse(request) { [weak self]  (result) in
            switch result {
            case .success(let response):
                Logger.ui.debug("Check user capabilities result: \(response.checkResult), keys count: \(response.keys.count)")
                switch response.checkResult {
                case .neednotice:
                    httpClient.i18n.get(response.keys) { [weak self] in
                        if let notices = $0.value {
                            Util.runInMainThread {
                                let values: [String] = response.keys.map { notices[$0] ?? "" }
                                self?.popupParticipantCapabilities(notices: values)
                            }
                        }
                    }
                case .success:
                    self?.transferHost()
                default: break
                }
            case .failure(let error):
                Logger.ui.debug("Check user capabilities failed: \(error)")
            }
        }
        end(nil)
    }
}

extension ParticipantMakeHostAction {

    private func popupParticipantCapabilities(notices: [String]) {
        let title = I18n.View_M_MakeHostQuestion(userInfo.display)

        let textView = UITextView()
        var text = ""
        for (index, element) in notices.enumerated() {
            text.append("\(index + 1). " + element + "\n")
        }
        text = text.vc.substring(from: 0, length: text.count - 1)
        text = I18n.View_M_MeetingManagementFeaturesNotSupported + "\n" + text
        textView.text = text
        textView.textContainerInset = .zero
        textView.font = .systemFont(ofSize: 16)
        textView.textColor = UIColor.ud.textTitle
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.isSelectable = false
        ByteViewDialog.Builder()
            .title(title)
            .contentView(textView)
            .leftTitle(I18n.View_G_CancelButton)
            .rightTitle(I18n.View_G_ConfirmButton)
            .rightHandler({ [weak self] _ in
                self?.transferHost()
            })
            .show()
    }

    private func transferHost() {
        ParticipantTracks.trackTransferHost(to: participant, isSearch: source.isSearch)
        var request = HostManageRequest(action: .transferHost, meetingId: meeting.meetingId)
        request.participantId = participant.user
        meeting.httpClient.send(request)
    }
}
