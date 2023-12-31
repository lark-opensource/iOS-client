//
//  CohostTracks.swift
//  ByteView
//
//  Created by wulv on 2020/8/20.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewTracker
import ByteViewNetwork

final class CohostTracks {
    static let userListPage = TrackEventName.vc_meeting_page_userlist

    /// 设置为联席主持人
    static func trackAssignCohost(user: ByteviewUser, isSearch: Bool) {
        trackCohostForParticipant(action: "assign_cohost", userId: user.id, deviceId: user.deviceId, isSearch: isSearch)
    }

    /// 撤销联席主持人
    static func trackWithdrawCohost(user: ByteviewUser, isSearch: Bool) {
        trackCohostForParticipant(action: "withdraw_cohost", userId: user.id, deviceId: user.deviceId, isSearch: isSearch)
    }

    /// 收回主持人权限
    static func trackReclaimHostAuthority(user: ByteviewUser, isSearch: Bool) {
        trackCohostForParticipant(action: "reclaim_host", userId: user.id, deviceId: user.deviceId, isSearch: isSearch)
    }

    private static func trackCohostForParticipant(action: String, userId: String, deviceId: String, isSearch: Bool) {
        VCTracker.post(name: userListPage,
                       params: [.from_source: isSearch ? "search_userlist" : "userlist",
                                .action_name: action,
                                .extend_value: ["attendee_uuid": userId,
                                                "attendee_device_id": deviceId]])
    }
}
