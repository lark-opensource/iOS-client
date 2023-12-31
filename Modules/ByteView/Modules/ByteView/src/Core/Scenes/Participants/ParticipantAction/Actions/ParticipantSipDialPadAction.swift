//
//  ParticipantSipDialPadAction.swift
//  ByteView
//
//  Created by wulv on 2023/6/12.
//

import Foundation

class ParticipantSipDialPadAction: BaseParticipantAction {

    override var title: String { I18n.View_MV_SipDisplayDialPad }

    override var show: Bool {
        !isSelf && !meeting.isWebinarAttendee && !canCancelInvite && meeting.setting.isDialpadEnabled && [.pstnUser, .h323User, .sipUser].contains(participant.type)
    }

    override func action(_ end: @escaping (Dictionary<String, Any>?) -> Void) {
        let vm = MeetDialViewModel(title: userInfo.display, participant: participant, meeting: meeting)
        let viewController = MeetDialViewController(viewModel: vm)
        let regularConfig = DynamicModalConfig(presentationStyle: .formSheet, needNavigation: true)
        let compactConfig = DynamicModalConfig(presentationStyle: .fullScreen, needNavigation: true)
        meeting.router.presentDynamicModal(viewController, regularConfig: regularConfig, compactConfig: compactConfig)
        end(nil)
    }
}
