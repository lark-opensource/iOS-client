//
//  ParticipantStopShareAction.swift
//  ByteView
//
//  Created by wulv on 2023/6/12.
//

import Foundation
import ByteViewNetwork

class ParticipantStopShareAction: BaseParticipantAction {

    override var title: String { I18n.View_VM_StopSharing }

    override var color: UIColor { .ud.functionDangerContentDefault}

    override var show: Bool {
        !isSelf && !canCancelInvite && meeting.setting.hasCohostAuthority && meeting.shareData.checkIsUserSharingContent(with: participant.user)
    }

    override func action(_ end: @escaping (Dictionary<String, Any>?) -> Void) {
        let request = HostManageRequest(action: .stopCurrentSharing, meetingId: meeting.meetingId,
                                        breakoutRoomId: meeting.setting.breakoutRoomId)
        meeting.httpClient.send(request)
        ParticipantTracks.trackStopShare(isSearch: source.isSearch, userId: meeting.account.id, deviceId: meeting.account.deviceId)
        end(nil)
    }
}
