//
//  RenameTracks.swift
//  ByteView
//
//  Created by fakegourmet on 2022/1/4.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewTracker

final class RenameTracks {

    private enum Event {
        static let HostPanelClick = TrackEventName.vc_meeting_hostpanel_click
        static let PopupView = TrackEventName.vc_meeting_popup_view
        static let PopupClick = TrackEventName.vc_meeting_popup_click
    }

    /// 更改会中改名权限
    static func clickEnableRename(enabled: Bool, fromSouce: String, isMeetingLocked: Bool) {
        VCTracker.post(name: Event.HostPanelClick,
                       params: [.click: "allow_participant_rename",
                                "is_meeting_locked": isMeetingLocked,
                                "is_check": enabled,
                                ".from_source": fromSouce])
    }

    /// 改名弹窗事件
    static func clickRenamePopup(isConfirmed: Bool, isSelf: Bool) {
        var params: TrackParams = [.click: isConfirmed ? "confirm" : "cancel",
                                   .content: "meeting_rename",
                                   .target: TrackEventName.vc_meeting_onthecall_view]
        if isConfirmed {
            params[.option] = isSelf ? "own_rename" : "host_participant"
        }
        VCTracker.post(name: Event.PopupClick,
                       params: params)
    }

    /// 主持人改名事件
    static func showRenameToast() {
        VCTracker.post(name: Event.PopupView,
                       params: [.content: "already_renamed"])
    }
}
