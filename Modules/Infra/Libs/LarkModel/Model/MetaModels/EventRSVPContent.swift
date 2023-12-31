//
//  EventRSVPContent.swift
//  LarkModel
//
//  Created by pluto on 2023/1/30.
//

import Foundation
import RustPB

public typealias EventRSVPCardInfo = RustPB.Basic_V1_RSVPCardInfo

public struct GeneralCalendarEventRSVPContent: MessageContent {
    private var pb: EventRSVPCardInfo
    public init(pb: EventRSVPCardInfo) {
        self.pb = pb
    }

    public var messageId: Int64 {
        return self.pb.messageID
    }

    public var chatID: Int64 {
        return self.pb.chatID
    }

    public var key: String {
        return self.pb.basicEventInfo.key
    }

    public var cardStatus: EventRSVPCardInfo.EventRSVPCardStatus {
        return self.pb.cardStatus
    }

    public var title: String {
        return self.pb.basicEventInfo.summary
    }

    public var originalTime: Int {
        return Int(self.pb.basicEventInfo.originalTime)
    }

    public var startTime: Int64 {
        return self.pb.basicEventInfo.startTime
    }

    public var endTime: Int64 {
        return self.pb.basicEventInfo.endTime
    }

    public var rrepeat: String {
        return self.pb.basicEventInfo.rrule
    }

    public var isAllDay: Bool {
        return self.pb.basicEventInfo.isAllDay
    }

    public var isTimeUpdated: Bool {
        return self.pb.cardChangeInfo.isTimeChange
    }

    public var isRruleUpdated: Bool {
        return self.pb.cardChangeInfo.isRruleChange
    }
    
    public var isLocationUpdated: Bool {
        return self.pb.cardChangeInfo.isLocationChange
    }
    
    public var isResourceUpdated: Bool {
        return self.pb.cardChangeInfo.isResourceChange
    }

    public var isShowConflict: Bool {
        return self.pb.basicEventInfo.conflictType == .normal
    }

    public var isRecurrenceConflict: Bool {
        return self.pb.basicEventInfo.conflictType == .recurrence
    }

    public var conflictTime: Int64 {
        return self.pb.basicEventInfo.conflictTime
    }

    public var meetingRoom: String {
        return zip(pb.basicEventInfo.meetingRooms, pb.basicEventInfo.isMeetingRoomsDisabled)
            .filter { ( _, isDisabled) in
                return !isDisabled
            }.map { item in
                item.0
            }.joined(separator: ",")
    }

    public var location: String {
        return self.pb.basicEventInfo.location
    }

    public var description: String {
        return self.pb.basicEventInfo.description_p
    }

    public var attendeeRsvpInfo: [Basic_V1_AttendeeRSVPInfo] {
        return self.pb.attendeeRsvpInfo
    }

    public var isJoined: Bool {
        return self.pb.isJoined
    }

    public var isAllUserInGroupReplyed: Bool {
        !pb.attendeeRsvpInfo.contains { $0.status == .needsAction }
    }

    public var isWebinar: Bool {
        return self.pb.basicEventInfo.isWebinar
    }

    public var selfAttendeeStatus: RustPB.Calendar_V1_CalendarEventAttendee.Status {
        get {
            switch self.pb.basicEventInfo.selfAttendeeStatus {
            case 1:
                return .needsAction
            case 2:
                return .accept
            case 3:
                return .tentative
            case 4:
                return .decline
            case 5:
                return .removed
            default:
                return .needsAction
            }
        }
        set {
            var statusVal: Int32 = 1
            switch newValue {
            case .needsAction:
                statusVal = 1
            case .accept:
                statusVal = 2
            case .tentative:
                statusVal = 3
            case .decline:
                statusVal = 4
            case .removed:
                statusVal = 5
            @unknown default:
                statusVal = 1
            }
            self.pb.basicEventInfo.selfAttendeeStatus = statusVal
        }
    }

    public var eventAttendeeCount: Int64 {
        return self.pb.attendeeCount
    }

    public var needActionCount: Int64 {
        return self.pb.needsActionCount
    }

    public var acceptCount: Int64 {
        return self.pb.acceptCount
    }

    public var tentativeCount: Int64 {
        return self.pb.tentativeCount
    }

    public var declineCount: Int64 {
        return self.pb.declineCount
    }

    public var isAttendeeOverflow: Bool {
        return self.pb.isAttendeeOverflow
    }

    public var currentUserMainCalendarId: String {
        return self.pb.basicEventInfo.calendarID
    }

    public var organizerCalendarId: Int64 {
        return self.pb.basicEventInfo.organizerCalendarID
    }

    public var isOptional: Bool {
        return self.pb.basicEventInfo.isOptional
    }

    public var isInValid: Bool {
        get { return self.pb.cardStatus == .invalid }
        set { self.pb.cardStatus = newValue ? .invalid : .normal }
    }

    public var isUpdated: Bool {
        return self.pb.cardStatus == .updated
    }

    public var isCrossTenant: Bool {
        return self.pb.basicEventInfo.isCrossTenant
    }

    public var relationTag: String? {
        if self.pb.basicEventInfo.hasRelationTag,
                  !self.pb.basicEventInfo.relationTag.tagDataItems.isEmpty,
                  let tagDataItem = self.pb.basicEventInfo.relationTag.tagDataItems.first(where: { $0.reqTagType == .relationTag }) {
                   return tagDataItem.textVal
               }
               return nil
    }

    public func complement(entity: RustPB.Basic_V1_Entity, message: Message) {}

    public var meetingNotes: RustPB.Basic_V1_MeetingNotesInfo? {
        if self.pb.notesInfo.docURL.isEmpty {
            return nil
        }
        return self.pb.notesInfo
    }
}
