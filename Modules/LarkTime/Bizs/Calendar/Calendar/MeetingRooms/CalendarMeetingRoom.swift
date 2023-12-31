//
//  CalendarMeetingRoom.swift
//  Calendar
//
//  Created by 张威 on 2020/4/30.
//

import RustPB
import EventKit
import CalendarFoundation

/// 会议室

struct CalendarMeetingRoom: CustomPermissionConvertible, PBModelConvertible {
    typealias PBModel = RustPB.Calendar_V1_CalendarEventAttendee

    private var pb: PBModel

    init(from pb: PBModel) {
        assert(pb.category == .resource)
        self.pb = pb
        self.permission = pb.hasIsEditable && !pb.isEditable ? .readable : .writable
        self.isAvailable = pb.status != .decline
    }

    func getPBModel() -> PBModel {
        return pb
    }

    var uniqueId: String { pb.attendeeCalendarID }

    var tenantId: String { pb.resource.tenantID }

    /// floor? + name + capacity? + building?
    var fullName: String { pb.displayName }

    private(set) var isAvailable: Bool

    var isDisabled: Bool { pb.resource.isDisabled }

    var status: AttendeeStatus {
        get { pb.status }
        set { pb.status = newValue }
    }

    var permission: PermissionOption

    var formCompleted = true

    // variable from resource
    /// floor? + name
    private(set) var tupleName: String?

    /// floor? + name + building?
    private(set) var tripleName: String?

    typealias ResourceInfo = (floorStr: String, capaticty: Int32, buildingStr: String, weight: Int32)
    private(set) var resourceInfo: ResourceInfo?
}

extension CalendarMeetingRoom: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "uniqueId: \(uniqueId), isAvailable: \(isAvailable), isDisabled: \(isDisabled), status: \(status)"
    }
}

// MARK: Transform From Resource PBModel

extension CalendarMeetingRoom {

    typealias ResourcePBModel = RustPB.Calendar_V1_CalendarResource
    typealias RoomDisplayNames = (tuple: String, triple: String, full: String)

    private static func displayName(
        ofResource pbResource: ResourcePBModel,
        withBuildingName buildingName: String
    ) -> RoomDisplayNames {
        let space = " "
        var tuple = pbResource.floorName
        if !pbResource.name.isEmpty {
            tuple += !tuple.isEmpty ? "-" : ""
            tuple += pbResource.name
        }

        var triple = tuple
        var full = tuple

        if pbResource.capacity > 0 {
            full += "(\(pbResource.capacity))"
        }
        if !buildingName.isEmpty {
            full += !full.isEmpty ? space : ""
            full += buildingName

            triple += !triple.isEmpty ? space : ""
            triple += buildingName
        }
        full += full.isEmpty ? space : ""
        return (tuple, triple, full)
    }

    static func makeMeetingRoom(
        fromResource pbResource: ResourcePBModel,
        buildingName: String,
        tenantId: String
    ) -> Self {
        var pb = PBModel()
        pb.category = .resource
        pb.id = ""
        let names = displayName(ofResource: pbResource, withBuildingName: buildingName)
        pb.displayName = names.full
        pb.attendeeCalendarID = pbResource.calendarID
        pb.status = .needsAction
        pb.resource.isDisabled = pbResource.isDisabled
        pb.resource.tenantID = tenantId
        pb.attendeeSchema = pbResource.resourceSchema
        pb.schemaExtraData = pbResource.schemaExtraData

        var meetingRoom = Self(from: pb)
        meetingRoom.isAvailable = pbResource.status == .free
        meetingRoom.tupleName = names.tuple
        meetingRoom.tripleName = names.triple
        meetingRoom.resourceInfo = (pbResource.floorName, pbResource.capacity,
                                    buildingName, pbResource.weight)
        return meetingRoom
    }

    static func toAttendeeEntity(
        fromResource pbResource: ResourcePBModel,
        buildingName: String,
        tenantId: String
    ) -> PBAttendee {
        let room = makeMeetingRoom(fromResource: pbResource, buildingName: buildingName, tenantId: tenantId)
        return PBAttendee(pb: room.getPBModel())
    }
}

// 会议室表单相关
extension CalendarMeetingRoom {

    // 需要填写的表单
    var resourceCustomization: Rust.ResourceCustomization? {
        get {
            let first = pb.schemaExtraData.bizData.first(where: { $0.type == .resourceCustomization })
            return first?.resourceCustomization
        }
        set {
            guard let newValue = newValue else { return }
            pb.schemaExtraData.bizData = pb.schemaExtraData.bizData.map { data in
                var data = data
                if data.type == .resourceCustomization {
                    data.resourceCustomization = newValue
                }
                return data
            }
        }
    }
}

// MARK: Properties About Approval

extension CalendarMeetingRoom {

    /// 描述会议室是否是审批类会议室（不依赖bizData数据）
    var needsApproval: Bool {
        pb.attendeeSchema.hasApprovalKey
    }

    /// 判定会议室是否需要条件审批（不依赖bizData数据）
    var needsConditionalApproval: Bool {
        pb.attendeeSchema.hasConditionalApprovalKey
    }

    /// 审批跳转链接
    var approvalLink: String? {
        pb.attendeeSchema.approvalLink
    }

    /// 判断是否发起过审批
    var hasApprovalRequest: Bool {
        pb.schemaExtraData.cd.approvalRequest != nil
    }

    /// 审批类会议室的申请人 chatterId
    var applicantChatterId: String? {
        pb.schemaExtraData.cd.approvalRequest?.createChatterID
    }

    /// 判断 duration 时长下是否会触发条件审批
    func shouldTriggerApproval(duration: Int64) -> Bool {
        pb.schemaExtraData.cd.approvalType.shouldTriggerApprovalOff(duration: duration)
    }

}

extension CalendarMeetingRoom: Equatable {

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.uniqueId == rhs.uniqueId
    }

}

typealias MeetingRoomEndDateInfo = (roomName: String, furthestDate: Date)

// MARK: Properties of Meeting Room Reservation

extension CalendarMeetingRoom {

    // 会议室限时策略
    var resourceStrategy: Rust.ResourceStrategy? {
        pb.schemaExtraData.cd.resourceStrategy
    }

    // 会议室征用策略
    var resourceRequisition: Rust.ResourceRequisition? {
        pb.schemaExtraData.cd.resourceRequisition
    }

    /// 根据 instance 起止时间刷新 isAvailable（会议室征用）
    /// - Parameters:
    ///   - insStart: instance 开始时间
    ///   - insEnd: instance 结束时间
    mutating func resetAvailableStateWith(insStart: Int64, insEnd: Int64) {
        self.isAvailable = self.isAvailable && !isInRequiRangeOn(start: insStart, end: insEnd)
    }

    func isInRequiRangeOn(start: Int64, end: Int64) -> Bool {
        guard let resourceRequisition = resourceRequisition else {
            return false
        }

        let resEnd = resourceRequisition.endTime > 0 ? resourceRequisition.endTime : 7_258_089_600

        guard end >= start && resEnd >= resourceRequisition.startTime else {
            assertionFailure("instance.endTime < instance.startTime")
            return false
        }

        let instanceRange = start..<end
        let requiRange = resourceRequisition.startTime..<resEnd
        let hasIntersection = instanceRange.overlaps(requiRange)
        return hasIntersection
    }
}

// MARK: Conflictable With Rrule
extension CalendarMeetingRoom {
    func conflictWithRrule(rrule: EKRecurrenceRule?) -> Bool {
        guard let rrule = rrule else { return false }
        let furthestBookTime = resourceStrategy?.furthestBookTime ?? Rust.ResourceStrategy.maxReservableDate
        if let endDate = rrule.recurrenceEnd?.endDate {
            return furthestBookTime.dayEnd() < endDate.dayEnd()
        }
        return true
    }
}

extension Array where Element == CalendarMeetingRoom {
    /// 是否包含全量审批会议室
    func hasFullApprovalMeetingRoom() -> Bool {
        return self.filter { $0.status != .removed }.contains { $0.needsApproval }
    }

    /// 是否包含触发条件审批的会议室
    func hasConditionApprovalMeetingRoom(duration: Int64) -> Bool {
        return self.filter { $0.status != .removed }.contains {
            $0.shouldTriggerApproval(duration: duration)
        }
    }
    /// 会议室最长可预约截止时间
    func meetingRoomMaxEndDateInfo() -> MeetingRoomEndDateInfo? {
        return self.filter { $0.status != .removed }
        .map { meetingRoom -> MeetingRoomEndDateInfo in
            let furthestBookTime = meetingRoom.resourceStrategy?.furthestBookTime ?? Rust.ResourceStrategy.maxReservableDate
            return (meetingRoom.fullName, furthestBookTime)
        }
        .sorted { $0.1 < $1.1 }
        .first
    }
}
