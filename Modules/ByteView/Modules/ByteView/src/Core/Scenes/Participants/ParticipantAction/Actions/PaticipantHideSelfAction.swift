//
//  PaticipantHideSelfAction.swift
//  ByteView
//
//  Created by wulv on 2023/6/12.
//

import Foundation

class PaticipantHideSelfAction: BaseParticipantAction {

    override var title: String { inMeetContext.isSettingHideSelf ? I18n.View_G_ShowMe : I18n.View_G_HideMe }

    override var show: Bool { isSelf && Display.pad && inMeetContext.hideSelfEnabled }

    override func action(_ end: @escaping (Dictionary<String, Any>?) -> Void) {
        inMeetContext.isSettingHideSelf = !inMeetContext.isSettingHideSelf
        if let mode = inMeetContext.sceneManager?.sceneMode {
            InMeetSceneTracks.trackClickHideSelf(isHideSelf: inMeetContext.isSettingHideSelf, location: source.fromGrid ? "user_icon" : "userlist", scene: mode)
        }
        end(nil)
    }
}
