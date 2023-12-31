//
//  ParticipantRenameAction.swift
//  ByteView
//
//  Created by wulv on 2023/6/12.
//

import Foundation

class ParticipantRenameAction: BaseParticipantAction {

    override var title: String { I18n.View_G_More_ChangeName }

    override var show: Bool { renameShow }

    override func action(_ end: @escaping (Dictionary<String, Any>?) -> Void) {
        ParticipantTracks.trackParticipantAction(.rename, isFromGridView: source.fromGrid, isSharing: meeting.shareData.isSharingContent)
        RenameRequestor.rename(meeting: meeting, name: userInfo.display, participant: participant, isSelf: isSelf)
        end(nil)
    }
}

extension ParticipantRenameAction {

    private var renameShow: Bool {
        !meeting.isWebinarAttendee && (isSelf ? meeting.setting.canRenameSelf : meeting.setting.canRenameOther)
    }
}
