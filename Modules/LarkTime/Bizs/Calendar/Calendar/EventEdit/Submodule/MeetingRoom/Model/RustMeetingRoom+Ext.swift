//
//  RustMeetingRoom+Ext.swift
//  Calendar
//
//  Created by 张威 on 2020/4/25.
//

import Foundation

extension Rust.MeetingRoom {

    // 判断是否是审批类会议室
    var needsApproval: Bool {
        resourceSchema.hasApprovalKey
    }

    // 判断是否有个性化表单
    var hasForm: Bool {
        let meetingRoom = CalendarMeetingRoom.makeMeetingRoom(fromResource: self, buildingName: "", tenantId: "")
        return meetingRoom.resourceCustomization != nil
    }

    func shouldTriggerApproval(duration: Int64) -> Bool {
        schemaExtraData.cd.approvalType.shouldTriggerApprovalOff(duration: duration)
    }
}
