//
//  ParticipantWithdrawUnmuteAction.swift
//  ByteView
//
//  Created by wulv on 2023/6/12.
//

import Foundation

class ParticipantWithdrawUnmuteAction: BaseParticipantAction {

    override var title: String { withDrawUnmuteTitle }

    override var show: Bool { isSelf && (participant.isMicHandsUp || participant.isCameraHandsUp) }

    override func action(_ end: @escaping (Dictionary<String, Any>?) -> Void) {
        HandsUpTracks.trackHandsDownBySelf(isSearch: source.isSearch)
        if participant.isMicHandsUp  {
            meeting.microphone.putDownHands()
            UserActionTracks.trackHandsDownMicAction()
        }
        if participant.isCameraHandsUp {
            meeting.camera.putDownHands()
        }
        end(nil)
    }
}

extension ParticipantWithdrawUnmuteAction {

    private var withDrawUnmuteTitle: String {
        let title: String
        if participant.isMicHandsUp, participant.isCameraHandsUp {
            title = I18n.View_G_WithdrawSpeakCamTab
        } else if participant.isCameraHandsUp {
            title = I18n.View_G_WithdrawCamTab
        } else {
            title = I18n.View_G_WithdrawSpeakTab
        }
        return title
    }
}
