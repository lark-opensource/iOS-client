//
//  CopyMeetingInviteLinkAction.swift
//  ByteView
//
//  Created by kiri on 2021/6/6.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewSetting

enum CopyMeetingInviteLinkAction {
    static func copy(meeting: InMeetMeeting, token: PasteboardToken) {
        meeting.setting.fetchCopyInfo { [weak meeting] result in
            guard let meeting = meeting else { return }
            switch result {
            case .success(let info):
                if meeting.security.copy(info.copyContent, token: token, shouldImmunity: true) {
                    Toast.showOnVCScene(I18n.View_M_JoiningInfoCopied)
                }
            case .failure:
                if meeting.setting.isMeetingLocked {
                    Toast.showOnVCScene(I18n.View_MV_MeetingLocked_Toast)
                }
            }
        }
    }
}
